#include <GL/glew.h>
#include <raylib.h>
#include <rlgl.h>
#include <cuda_runtime.h>
#include <math.h>

#include "render.cuh"

#define BSIZE 16

__global__
void renderPixel(int width, int height, vec3 c_pos, vec3 c_rot, Light *ls, uchar4* pixels)
{
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x >= width || y >= height) return;

    vec2 uv(float(x) / float(width), 1 - float(y) / float(height));
    vec2 resolution(float(width) / float(height), 1.f);

    vec2 normCoord =
        (vec2(2.0f) * uv - vec2(1.0f)) * resolution;

    vec3 ro = c_pos;
    vec3 rd = rotationFromEuler(c_rot)
              * normalize(vec3(normCoord * FOV, 1.0));

    vec4 final = render(ro, rd, ls);

    int idx = y * width + x;
    pixels[idx].x = (unsigned char)(final.x * 255);
    pixels[idx].y = (unsigned char)(final.y * 255);
    pixels[idx].z = (unsigned char)(final.z * 255);
    pixels[idx].w = (unsigned char)(final.w * 255);
}


int main(void)
{
    const int screenWidth  = 512;
    const int screenHeight = 512;

    InitWindow(screenWidth, screenHeight, "CUDA Raymarch Test");
    SetTargetFPS(60);

    glewExperimental = true;
    int ok = glewInit();

    Texture texture;

    texture.width = screenWidth;
    texture.height = screenHeight;
    size_t bufferSize = screenHeight * screenWidth * sizeof(uchar4);
    
    unsigned char *cudaBuffer = nullptr;
    uchar4 *gpuBuffer = nullptr;

    cudaMalloc(&gpuBuffer, bufferSize);
    cudaBuffer = new unsigned char[bufferSize];

    glGenTextures(1, &texture.id);
    glBindTexture(GL_TEXTURE_2D, texture.id);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, screenWidth, screenHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glBindTexture(GL_TEXTURE_2D, 0);

    texture.format = PIXELFORMAT_UNCOMPRESSED_R8G8B8A8;
    texture.mipmaps = 1;

    // Camera
    Camera camera = {0};
    camera.position = {0.0f, 0.1f, -1.5f};
    camera.target   = {0.0f, 0.0f,  1.0f};
    camera.up       = {0.0f, 1.0f,  0.0f};
    camera.fovy     = 45.0f;
    camera.projection = CAMERA_PERSPECTIVE;

    // Lights
    Light hLight(
        vec3(1.0, 1.0, 1.0),
        false,
        normalize(vec3(0.75, -1, 0.3)),
        0.9f,
        0.6f
    );

    // GPU allocate light
    Light* dLight;
    cudaMalloc(&dLight, sizeof(Light));
    cudaMemcpy(dLight, &hLight, sizeof(Light), cudaMemcpyHostToDevice);

    // Block + grid
    dim3 block(BSIZE, BSIZE);
    dim3 grid(
        (screenWidth  + BSIZE - 1) / BSIZE,
        (screenHeight + BSIZE - 1) / BSIZE
    );

    while (!WindowShouldClose())
    {

        // Update camera
        UpdateCamera(&camera, CAMERA_FREE);

        // Compute rotation
        vec3 eye(camera.position.x, camera.position.y, camera.position.z);
        vec3 tgt(camera.target.x, camera.target.y, camera.target.z);
        vec3 fw = normalize(tgt - eye);

        vec3 c_rot(asinf(fw.y), atan2f(fw.x, fw.z), 0);

        // Launch CUDA kernel
        renderPixel<<<grid, block>>>(
            screenWidth, screenHeight,
            eye, c_rot,
            dLight,
            gpuBuffer
        );
        
        cudaDeviceSynchronize();

        cudaMemcpy(cudaBuffer, gpuBuffer, bufferSize, cudaMemcpyDeviceToHost);

        glBindTexture(GL_TEXTURE_2D, texture.id);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, texture.width, texture.height, GL_RGBA, GL_UNSIGNED_BYTE, cudaBuffer);
        glBindTexture(GL_TEXTURE_2D, 0);

        // Draw to screen
        BeginDrawing();
            ClearBackground(BLACK);
            DrawTexture(texture, 0, 0, WHITE);
            DrawFPS(10, 10);
        EndDrawing();
    }

    // Cleanup

    cudaFree(gpuBuffer);
    delete[] cudaBuffer;
    glDeleteTextures(1, &texture.id);
    cudaFree(dLight);

    CloseWindow();
    return 0;
}
