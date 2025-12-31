#ifndef _ARGS_CUH
#define _ARGS_CUH

#include <transform.cuh>
#include <gui.cuh>

#include <eyeParams.cuh>

// Arguments for scene parameters
struct Args {
    eyeParams eye1;
    vec3 eye_dim    = vec3(0.1, 0.1, 0.05);
    vec3 eye_pos    = vec3(.0);
    mat3 eye_rot    = mat3(1.f);
};

#define WINDOW_WIDTH 220
DECLARE_WINDOW(window, 10, 10, WINDOW_WIDTH + 80, 700)

static void drawWindow(Vector2 position, Vector2 scroll, Args& a) {

    static vec3 rot(.0);

    eyeControlGUI(position, scroll, WINDOW_WIDTH, a.eye1);

    ADD_VEC3_SLIDER(position, scroll, WINDOW_WIDTH, 0.01, 0.15, a.eye_dim)
    ADD_VEC3_SLIDER(position, scroll, WINDOW_WIDTH, -0.2, 0.2, a.eye_pos)
    ADD_VEC3_SLIDER(position, scroll, WINDOW_WIDTH, -6.28, 6.28, rot)

    a.eye_rot = rotationFromEuler(rot);
}

__host__
void updateArgs(Args& a) {
    DRAW_WINDOW(window, "Control Panel", drawWindow, a)
}

#endif