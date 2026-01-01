#ifndef _ARGS_CUH
#define _ARGS_CUH

#include <transform.cuh>
#include <gui.cuh>

#include <eyeParams.cuh>

// Arguments for scene parameters
struct Args {
    eyeParams eye1;

    vec3 eye_dim    = vec3(0.08, 0.073, 0.028);
    vec3 eye_pos    = vec3(.0, .0, 0.018);
    mat3 eye_rot    = mat3(1.f);
    
    float eyeline_len = 0.022f;
    float eyeline_rad = 0.79;
    float eyeline_thk = 0.94;
    float eyeline_off = 0.0126;

    float eyes_separation = 0.097;
    float eyes_angle      = 0.469;
};

#define WINDOW_WIDTH 220
DECLARE_WINDOW(window, 10, 10, WINDOW_WIDTH + 80, 1000)

static void drawWindow(Vector2 position, Vector2 scroll, Args& a) {

    static vec3 rot(.0);

    eyeControlGUI(position, scroll, WINDOW_WIDTH, a.eye1);

    ADD_LABEL(position, scroll, "Eye Spacing Controls")
    ADD_SEPARATOR(position, scroll, WINDOW_WIDTH);

    ADD_LABEL(position, scroll, "\t Eyes Separation")
    ADD_SLIDER(position, scroll, WINDOW_WIDTH, 0, 1, a.eyes_separation);
    ADD_LABEL(position, scroll, "\t Eyes Angle")
    ADD_SLIDER(position, scroll, WINDOW_WIDTH, 0, 3.14, a.eyes_angle);

    ADD_LABEL(position, scroll, "Other Properties")
    ADD_SEPARATOR(position, scroll, WINDOW_WIDTH)

    ADD_LABEL(position, scroll, "\t Dimensions")
    ADD_VEC3_SLIDER(position, scroll, WINDOW_WIDTH, 0.01, 0.15, a.eye_dim)
    ADD_LABEL(position, scroll, "\t Position")
    ADD_VEC3_SLIDER(position, scroll, WINDOW_WIDTH, -0.2, 0.2, a.eye_pos)
    ADD_LABEL(position, scroll, "\t Rotation")
    ADD_VEC3_SLIDER(position, scroll, WINDOW_WIDTH, -6.28, 6.28, rot)
    ADD_LABEL(position, scroll, "\t Eyeline Length")
    ADD_SLIDER(position, scroll, WINDOW_WIDTH, 0, 1, a.eyeline_len)
    ADD_LABEL(position, scroll, "\t Eyeline Thickness")
    ADD_SLIDER(position, scroll, WINDOW_WIDTH, 0, 1, a.eyeline_thk)
    ADD_LABEL(position, scroll, "\t Eyeline Radius")
    ADD_SLIDER(position, scroll, WINDOW_WIDTH, 0, 1, a.eyeline_rad)
    ADD_LABEL(position, scroll, "\t Eyeline Offset")
    ADD_SLIDER(position, scroll, WINDOW_WIDTH, -0.1, 0.1, a.eyeline_off)    

    a.eye_rot = rotationFromEuler(rot);
}

__host__
void updateArgs(Args& a) {
    DRAW_WINDOW(window, "Eye Control Panel", drawWindow, a)
}

#endif