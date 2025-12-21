#ifndef _ARGS_CUH
#define _ARGS_CUH

#include <transform.cuh>
#include <gui.cuh>

// Arguments for scene parameters
struct Args {
    vec3 pos;
    mat3 rot;
};

#define WINDOW_WIDTH 220

DECLARE_WINDOW(window, 10, 10, WINDOW_WIDTH + 30, 400)

static void drawWindow(Vector2 position, Vector2 size, Args& a) {

    static vec3  rot(0.f);

    ADD_VEC3_SLIDER(position, WINDOW_WIDTH, -1, 1, a.pos);
    ADD_VEC3_SLIDER(position, WINDOW_WIDTH, -3.14, 3.14, rot);

    a.rot = rotationFromEuler(rot);
}

__host__
void updateArgs(Args& a) {
    DRAW_WINDOW(window, "Control Panel", drawWindow, a)
}

#endif