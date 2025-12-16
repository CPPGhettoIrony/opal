#ifndef _ARGS_CUH
#define _ARGS_CUH

#include <gui.cuh>

// Arguments for scene parameters
struct Args {
    float t = 0;
    vec3 col;
};

DECLARE_WINDOW(window, 10, 10, 220, 180)

static float f = 0.0;

static void drawWindow(Vector2 position, Vector2 size, Args& a) {

    static Color c;

    GuiSlider(Rectangle{position.x + 10, position.y + 30, 180, 10}, "0", "1", &f, 0, 1);
    GuiColorPicker(Rectangle{position.x + 10, position.y + 45, 180, 40}, "Color", &c);

    a.col.x = float(c.r) / 255.f;
    a.col.y = float(c.g) / 255.f;
    a.col.z = float(c.b) / 255.f;
}

__host__
void updateArgs(Args& a) {
    DRAW_WINDOW(window, "Breathe Speed", drawWindow, a)
    a.t += f * 0.1;
}

#endif