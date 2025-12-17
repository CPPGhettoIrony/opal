#ifndef _ARGS_CUH
#define _ARGS_CUH

#include <gui.cuh>

// Arguments for scene parameters
struct Args {
    float t = 0;
    vec3 col;
    vec3 pos;
    mat3 rot;
};

DECLARE_WINDOW(window, 10, 10, 220, 180)

static float f = 0.1;

static void drawWindow(Vector2 position, Vector2 size, Args& a) {

    static Color c{255, 0, 0, 1};
    static vec3  rot(0.f), pos(0.f);

    GuiSlider(Rectangle{position.x + 15, position.y + 25, 180, 10}, "0", "1", &f, 0, 1);
    GuiColorPicker(Rectangle{position.x + 10, position.y + 45, 180, 40}, "Color", &c);

    GuiSlider(Rectangle{position.x + 15, position.y + 100, 180, 10}, "0", "3.14", &rot.x, 0, 3.14);
    GuiSlider(Rectangle{position.x + 15, position.y + 115, 180, 10}, "0", "3.14", &rot.y, 0, 3.14);
    GuiSlider(Rectangle{position.x + 15, position.y + 130, 180, 10}, "0", "3.14", &rot.z, 0, 3.14);

    GuiSlider(Rectangle{position.x + 15, position.y + 145, 180, 10}, "-1", "1", &pos.x, -1, 1);
    GuiSlider(Rectangle{position.x + 15, position.y + 160, 180, 10}, "-1", "1", &pos.y, -1, 1);
    GuiSlider(Rectangle{position.x + 15, position.y + 175, 180, 10}, "-1", "1", &pos.z, -1, 1);

    a.rot = rotationFromEuler(rot);
    a.pos = pos;
    
    a.col.x = float(c.r) / 255.f;
    a.col.y = float(c.g) / 255.f;
    a.col.z = float(c.b) / 255.f;
}

__host__
void updateArgs(Args& a) {
    DRAW_WINDOW(window, "Control Panel", drawWindow, a)
    a.t += f * 0.1;
}

#endif