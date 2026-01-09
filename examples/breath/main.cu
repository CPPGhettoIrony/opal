#define RAYGUI_IMPLEMENTATION

#include <context.cuh>

DECLARE_WINDOW(fpsWindow, 10, 10, 100, 100) {
    DrawFPS(position.x + scroll.x + 5, position.y + scroll.y + 25);
}

int main() {

    Context context(vec3(0., 0., -1.5), vec3(0.));

    while (RUNNING) {
        context.processViewport();
        context.beginRender();
            context.renderViewport();
            DRAW_WINDOW(fpsWindow, "FPS", context.localArgs)
        context.endRender();
    }

    return 0;
}