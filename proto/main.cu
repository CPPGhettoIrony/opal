#include <raylib.h>
#include <cuda_runtime.h>
#include <math.h>

#include "render.cuh"

#define BSIZE 16

__global__
void renderPixel(int width, int height, vec3 c_pos, vec3 c_rot, Light *ls, Color* pixels)
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
    pixels[idx].r = (unsigned char)(final.x * 255);
    pixels[idx].g = (unsigned char)(final.y * 255);
    pixels[idx].b = (unsigned char)(final.z * 255);
    pixels[idx].a = (unsigned char)(final.w * 255);
}


int main(void)
{
    const int screenWidth  = 512;
    const int screenHeight = 512;

    InitWindow(screenWidth, screenHeight, "CUDA Raymarch Test");

    // Raylib image + texture (CPU → GPU)
    Image canvas = GenImageColor(screenWidth, screenHeight, BLACK);
    Texture2D tex = LoadTextureFromImage(canvas);

    // Camera
    Camera camera = {0};
    camera.position = {0.0f, 0.1f, -1.5f};
    camera.target   = {0.0f, 0.0f,  1.0f};
    camera.up       = {0.0f, 1.0f,  0.0f};
    camera.fovy     = 45.0f;
    camera.projection = CAMERA_PERSPECTIVE;

    // Convert to your vec3
    vec3 c_pos(camera.position.x, camera.position.y, camera.position.z);
    vec3 c_target(camera.target.x, camera.target.y, camera.target.z);

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

    // GPU pixel buffer
    Color* dPixels = nullptr;
    cudaMalloc(&dPixels, screenWidth * screenHeight * sizeof(Color));

    // Block + grid
    dim3 block(BSIZE, BSIZE);
    dim3 grid(
        (screenWidth  + BSIZE - 1) / BSIZE,
        (screenHeight + BSIZE - 1) / BSIZE
    );

    SetTargetFPS(60);

    // Update camera
    // UpdateCamera(&camera, CAMERA_FREE);

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
        dPixels
    );
    cudaDeviceSynchronize();

    // Copy results back
    cudaMemcpy(
        canvas.data,
        dPixels,
        screenWidth * screenHeight * sizeof(Color),
        cudaMemcpyDeviceToHost
    );

    // Update GPU texture
    UpdateTexture(tex, canvas.data);

    while (!WindowShouldClose())
    {

        // Draw to screen
        BeginDrawing();
            ClearBackground(BLACK);
            DrawTexture(tex, 0, 0, WHITE);
            DrawFPS(10, 10);
        EndDrawing();
    }

    // Cleanup
    cudaFree(dPixels);
    cudaFree(dLight);
    UnloadTexture(tex);
    UnloadImage(canvas);

    CloseWindow();
    return 0;
}
