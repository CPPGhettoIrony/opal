#include <raylib.h>
#include <raymath.h>
#include <math.h>   // for atan2f, asinf

int main(void)
{
    // Initialization
    const int screenWidth = 512;
    const int screenHeight = 512;

    InitWindow(screenWidth, screenHeight, "OPAL Shader Explorer");

    // Dummy texture for fullscreen shader pass
    Image imRed = GenImageColor(screenWidth, screenHeight, (Color){255,0,0,255});
    Texture texRed = LoadTextureFromImage(imRed);
    UnloadImage(imRed);

    Shader shader = LoadShader(0, "./base.glsl");

    // Get uniform locations
    int locResolution = GetShaderLocation(shader, "u_resolution");
    int locCameraPos  = GetShaderLocation(shader, "camera_pos");
    int locCameraRot  = GetShaderLocation(shader, "camera_rot");

    Vector2 resolution = { (float)screenWidth, (float)screenHeight };

    // Free camera setup
    Camera camera = {0};
    camera.position = (Vector3){0.0f, 0.1f, -1.5f};
    camera.target   = (Vector3){0.0f, 0.0f, 1.0f};
    camera.up       = (Vector3){0.0f, 1.0f, 0.0f};
    camera.fovy     = 45.0f;
    camera.projection = CAMERA_PERSPECTIVE;

    Vector3 cam_pos;

    SetTargetFPS(60);

    while (!WindowShouldClose())
    {
        // Update camera with free movement
        UpdateCamera(&camera, CAMERA_FREE);

        // Compute Euler rotation (yaw, pitch) from forward vector
        Vector3 forward = Vector3Normalize(Vector3Subtract(camera.target, camera.position));
        Vector3 camRot = {asinf(forward.y) , atan2f(forward.x, forward.z), 0}; // yaw, pitch

        cam_pos = camera.position;
        cam_pos.x *= -1;

        BeginDrawing();
            ClearBackground(RAYWHITE);

            BeginShaderMode(shader);

                // Send uniforms
                SetShaderValue(shader, locResolution, &resolution, SHADER_UNIFORM_VEC2);
                SetShaderValue(shader, locCameraPos, &cam_pos, SHADER_UNIFORM_VEC3);
                SetShaderValue(shader, locCameraRot, &camRot, SHADER_UNIFORM_VEC3);

                DrawTexture(texRed, 0, 0, WHITE);

            EndShaderMode();
        EndDrawing();
    }

    // De-Initialization
    UnloadShader(shader);
    UnloadTexture(texRed);
    CloseWindow();

    return 0;
}