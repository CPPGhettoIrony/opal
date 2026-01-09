#ifndef _ARGS_CUH
#define _ARGS_CUH

#include <transform.cuh>
#include <gui.cuh>

// Arguments for scene parameters
struct Args {
    vec3 col;
    vec3 lcol = vec3(1, 1, 1);
    vec3 pos;
    mat3 rot;
    float t;
};

#define WINDOW_WIDTH 350

DECLARE_WINDOW(window, 10, 10, WINDOW_WIDTH + 30, 550) {

    static Color c{255, 0, 0, 0}, l{255, 255, 255,0};
    static vec3  rot(0.f);

    ADD_ELEMENT(GuiColorPicker, WINDOW_WIDTH, 100, "Color", &c);
    ADD_ELEMENT(GuiColorPicker, WINDOW_WIDTH, 100, "Color", &l);

    static float f = 0.01;

    ADD_SLIDER(WINDOW_WIDTH, 0, 0.1, f)

    ADD_VEC3_SLIDER(WINDOW_WIDTH, -1, 1, a.pos);
    ADD_VEC3_SLIDER(WINDOW_WIDTH, -3.14, 3.14, rot);

    a.rot = rotationFromEuler(rot);
    
    a.col.x = float(c.r) / 255.f;
    a.col.y = float(c.g) / 255.f;
    a.col.z = float(c.b) / 255.f;

    a.lcol.x = float(l.r) / 255.f;
    a.lcol.y = float(l.g) / 255.f;
    a.lcol.z = float(l.b) / 255.f;

    a.t += f;
}

__host__
void updateArgs(Args& a) {
    DRAW_WINDOW(window, "Control Panel", a)
}

#endif