#define RAYGUI_IMPLEMENTATION

#include <context.cuh>

DECLARE_WINDOW(fpsWindow, 10, 10, 100, 100)

static void drawFPSWindow(Vector2 p, Vector2 s, Args& a) {
    DrawFPS(p.x + 5, p.y + 25);
}


int main() {

    Context context(vec3(0., 0., -1.5), vec3(0.));

    while (RUNNING) {
        context.processViewport();
        context.beginRender();
            DRAW_WINDOW(fpsWindow, "FPS", drawFPSWindow, context.localArgs)
        context.endRender();
    }

    return 0;
}