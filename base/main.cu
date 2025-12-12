#include <GL/glew.h>
#include <raylib.h>
#include <cuda_runtime.h>
#include <cuda_gl_interop.h>
#include <cstdio>

#include "render.cuh" 

#define BSIZE 16

#ifndef WIDTH
    #define WIDTH 512
#endif

#ifndef HEIGHT
    #define HEIGHT 512
#endif

// Macro para chequear errores de CUDA (vital para debuggear caídas de FPS)
#define checkCudaErrors(val) check_cuda( (val), #val, __FILE__, __LINE__ )
void check_cuda(cudaError_t result, char const *const func, const char *const file, int const line) {
    if (result) {
        fprintf(stderr, "CUDA error at %s:%d code=%d(%s) \"%s\" \n",
                file, line, static_cast<unsigned int>(result), cudaGetErrorName(result), func);
        exit(EXIT_FAILURE);
    }
}

// -----------------------------------------------------------------------------
// Kernel Básico (Escribe en un buffer plano, muy estable)
// -----------------------------------------------------------------------------
__global__
void renderKernel(uchar4* buffer, int width, int height,
                  vec3 c_pos, vec3 c_rot, Light* lights, const Args* a)
{
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    if (x >= width || y >= height) return;

    // UVs
    float fx = (float)x / float(width);
    float fy = 1.0f - (float)y / float(height); 
    vec2 uv(fx, fy);
    vec2 resolution(float(width) / float(height), 1.0f);
    vec2 normCoord = (vec2(2.0f) * uv - vec2(1.0f)) * resolution;

    // Ray
    vec3 ro = c_pos;
    vec3 rd = rotationFromEuler(c_rot) * normalize(vec3(normCoord * FOV, 1.0));

    // Render
    vec4 col = render(ro, rd, lights, *a);

    // Escribir en buffer lineal
    int idx = y * width + x;
    buffer[idx] = make_uchar4(
        (unsigned char)(col.x * 255.0f),
        (unsigned char)(col.y * 255.0f),
        (unsigned char)(col.z * 255.0f),
        (unsigned char)(col.w * 255.0f)
    );
}

int main()
{

    #ifndef NVIDIA_DESKTOP
        setenv("__NV_PRIME_RENDER_OFFLOAD", "1", 1);
        setenv("__GLX_VENDOR_LIBRARY_NAME", "nvidia", 1);
    #endif

    // --- Init ---
    SetConfigFlags(FLAG_VSYNC_HINT | FLAG_WINDOW_RESIZABLE); // VSync ayuda a no saturar la cola
    InitWindow(WIDTH, HEIGHT, "CUDA Stable Raymarcher");
    SetTargetFPS(60); // Limitar FPS es clave para no sobrecalentar/saturar
    glewInit();

    // --- OpenGL Texture ---
    Texture texture;
    glGenTextures(1, &texture.id);
    glBindTexture(GL_TEXTURE_2D, texture.id);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, WIDTH, HEIGHT, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glBindTexture(GL_TEXTURE_2D, 0);

    texture.width = WIDTH;
    texture.height = HEIGHT;
    texture.format = PIXELFORMAT_UNCOMPRESSED_R8G8B8A8;
    texture.mipmaps = 1;

    // --- Registrar para escritura estándar ---
    cudaGraphicsResource* cudaTexResource;
    checkCudaErrors(cudaGraphicsGLRegisterImage(&cudaTexResource, texture.id, GL_TEXTURE_2D, cudaGraphicsRegisterFlagsWriteDiscard));

    // --- Allocations (SOLO UNA VEZ) ---
    Light hLight(vec3(1.0, 1.0, 1.0), false, normalize(vec3(0.75, -1.0, 0.3)), 0.9f, 0.6f);
    Light* dLights;
    checkCudaErrors(cudaMalloc(&dLights, sizeof(Light)));
    checkCudaErrors(cudaMemcpy(dLights, &hLight, sizeof(Light), cudaMemcpyHostToDevice));

    // ** AQUÍ ESTA LA CLAVE **
    // Reservamos el buffer de píxeles UNA VEZ. No en el bucle.
    uchar4* d_pixelBuffer;
    checkCudaErrors(cudaMalloc(&d_pixelBuffer, WIDTH * HEIGHT * sizeof(uchar4)));

    dim3 block(BSIZE, BSIZE);
    dim3 grid((WIDTH + BSIZE - 1) / BSIZE, (HEIGHT + BSIZE - 1) / BSIZE);

    vec3 eye(.0, .0, -1.5), tgt(.0), yp(.0);

    Rectangle viewRect{0, 0, WIDTH, HEIGHT};

    Args localArgs, *deviceArgs;
    checkCudaErrors(cudaMalloc(&deviceArgs, sizeof(Args)));

    while (!WindowShouldClose())
    {

        if(IsKeyDown(KEY_R)) {
            eye = vec3(.0, .0, -1.5);
            tgt = vec3(.0);
        }

        Vector2 delt = GetMouseDelta(),
                mpos = GetMousePosition();

        if(IsMouseButtonDown(MOUSE_BUTTON_LEFT)) {
            yp.x = -delt.x * 0.01;
            yp.y = -delt.y * 0.01;
        } else yp.x = yp.y = .0;

        if(IsMouseButtonDown(MOUSE_BUTTON_MIDDLE)) {
            viewRect.x += delt.x;
            viewRect.y += delt.y;
        }

        //yp = (mp + res/vec2(2.))/res/vec2(2.) * vec2(PI*2) - vec2(PI);

        eye = rotate_point_zy(yp.y, eye, tgt);
        eye = rotate_point_xz(yp.x, eye, tgt);

        vec3 fw = normalize(tgt - eye);
        vec3 c_rot(asinf(fw.y), -atan2f(fw.x, fw.z), 0);

        if(GetMouseWheelMove()) {
            if(IsKeyDown(KEY_LEFT_CONTROL)) {
                viewRect.width  +=  GetMouseWheelMove()*20;
                viewRect.height +=  GetMouseWheelMove()*20;               
            } else eye += fw * (GetMouseWheelMove()/2.f);
        }

        vec3 fwa = tgt - eye;
        vec3 fwx = vec3(fwa.x, 0.f, fwa.z) * 0.01f;

        if(IsKeyDown(KEY_W)) {
            eye += fwx;
            tgt += fwx;
        }

        if(IsKeyDown(KEY_A)) {
            vec3 v = rotate_point_xz(PI/2, fwx, vec3(0.));
            eye += v;
            tgt += v;
        }

        if(IsKeyDown(KEY_S)) {
            eye -= fwx;
            tgt -= fwx;
        }

        if(IsKeyDown(KEY_D)) {
            vec3 v = rotate_point_xz(-PI/2, fwx, vec3(0.));
            eye += v;
            tgt += v;
        }

        if(IsKeyDown(KEY_Z)) {
            eye.y += length(fwx);
            tgt.y += length(fwx);
        }

        if(IsKeyDown(KEY_X)) {
            eye.y -= length(fwx);
            tgt.y -= length(fwx);
        }

        updateArgs(localArgs);
        checkCudaErrors(cudaMemcpy(deviceArgs, &localArgs, sizeof(Args), cudaMemcpyHostToDevice));

        // 1. Ejecutar Kernel sobre el buffer persistente (d_pixelBuffer)
        // Esto es pura memoria de GPU, rapidísimo.
        renderKernel<<<grid, block>>>(d_pixelBuffer, WIDTH, HEIGHT, eye, c_rot, dLights, deviceArgs);

        // Chequeo de errores asíncrono
        checkCudaErrors(cudaGetLastError());

        // 2. Map Texture
        checkCudaErrors(cudaGraphicsMapResources(1, &cudaTexResource));
        cudaArray_t textureArray;
        checkCudaErrors(cudaGraphicsSubResourceGetMappedArray(&textureArray, cudaTexResource, 0, 0));

        // 3. Copia Device -> Array (Muy rápida, dentro de VRAM)
        checkCudaErrors(cudaMemcpy2DToArray(
            textureArray, 0, 0,
            d_pixelBuffer, WIDTH * sizeof(uchar4), 
            WIDTH * sizeof(uchar4), HEIGHT, 
            cudaMemcpyDeviceToDevice
        ));

        // 4. Unmap
        checkCudaErrors(cudaGraphicsUnmapResources(1, &cudaTexResource));

        // 5. SINCRONIZACIÓN (LA CURA PARA EL LAG PROGRESIVO)
        // Esto obliga a la CPU a esperar a que la GPU termine antes de intentar dibujar el frame.
        // Previene que se acumulen 1000 frames en la cola.
        checkCudaErrors(cudaDeviceSynchronize());

        // --- Draw ---
        BeginDrawing();
            ClearBackground(DARKGRAY);
            DrawTexturePro(texture, {0, 0, WIDTH, HEIGHT}, viewRect, {0, 0} , 0, WHITE);
            DrawFPS(viewRect.x, viewRect.y);
        EndDrawing();
    }

    // --- Cleanup ---
    checkCudaErrors(cudaFree(deviceArgs));
    checkCudaErrors(cudaFree(d_pixelBuffer)); // Liberamos el buffer al final
    checkCudaErrors(cudaFree(dLights));
    checkCudaErrors(cudaGraphicsUnregisterResource(cudaTexResource));
    glDeleteTextures(1, &texture.id);
    CloseWindow();

    return 0;
}