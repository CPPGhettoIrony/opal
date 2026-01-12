#ifndef _ARGS_CUH
#define _ARGS_CUH

#include <transform.cuh>
#include <gui.cuh>

#include <eyeParams.cuh>

// Arguments for scene parameters
struct Args {

    eyeParams eye1, eye2;
    int eye_mode;

    vec3 eye_dim    = vec3(0.08, 0.073, 0.028);
    vec3 eye_pos    = vec3(.0, .0, 0.018);
    mat3 eye_rot    = mat3(1.f);

    vec3 eyeline_dim_offset = vec3(.0);
    mat3 eyeline_rot_offset = mat3(1.);
    float eyeline_separation_offset = 0;
    float eyeline_angle_offset = 0;

    float eyeline_len = 0.022f;
    float eyeline_rad = 0.79;
    float eyeline_thk = 0.94;
    float eyeline_off = 0.0126;

    float eyes_separation = 0.097;
    float eyes_angle      = 0.469;
};

#define WINDOW_WIDTH 220

DECLARE_WINDOW(eyeControls, 10, 10, (WINDOW_WIDTH + 50)*2, 800) {
    CALL_GUI(dualEyeControlGUI, WINDOW_WIDTH + 50, a.eye1, a.eye2, a.eye_mode)
}

DECLARE_WINDOW(eyeAdjustments, 300, 10, WINDOW_WIDTH + 160, 1200) {

    static vec3 rot(.0), e_rot(.0);

    ADD_LABEL("Eye Spacing Controls")
    ADD_SEPARATOR(WINDOW_WIDTH);

    ADD_LABEL("\t Eyes Separation")
    ADD_SLIDER(WINDOW_WIDTH, 0, 1, a.eyes_separation);
    ADD_LABEL("\t Eyes Angle")
    ADD_SLIDER(WINDOW_WIDTH, 0, 3.14, a.eyes_angle);

    ADD_LABEL("Transform")
    ADD_SEPARATOR(WINDOW_WIDTH)

    ADD_LABEL("\t Dimensions")
    ADD_VEC3_SLIDER(WINDOW_WIDTH, 0.01, 0.15, a.eye_dim)
    ADD_LABEL("\t Position")
    ADD_VEC3_SLIDER(WINDOW_WIDTH, -0.2, 0.2, a.eye_pos)
    ADD_LABEL("\t Rotation")
    ADD_VEC3_SLIDER(WINDOW_WIDTH, -6.28, 6.28, rot)

    ADD_LABEL("Eyeline Properties")
    ADD_SEPARATOR(WINDOW_WIDTH)

    ADD_LABEL("\t Eyeline Length")
    ADD_SLIDER(WINDOW_WIDTH, 0, 1, a.eyeline_len)
    ADD_LABEL("\t Eyeline Thickness")
    ADD_SLIDER(WINDOW_WIDTH, 0, 1, a.eyeline_thk)
    ADD_LABEL("\t Eyeline Radius")
    ADD_SLIDER(WINDOW_WIDTH, 0, 1, a.eyeline_rad)
    ADD_LABEL("\t Eyeline Offset")
    ADD_SLIDER(WINDOW_WIDTH, -0.1, 0.1, a.eyeline_off) 
    
    ADD_LABEL("Eyeline Adjustments")
    ADD_SEPARATOR(WINDOW_WIDTH)

    ADD_LABEL("\t Eyeline Dimension Offset")
    ADD_VEC3_SLIDER(WINDOW_WIDTH, 0, 1, a.eyeline_dim_offset)
    ADD_LABEL("\t Eyeline Rotation Offset")
    ADD_VEC3_SLIDER(WINDOW_WIDTH, -6.28, 6.28, e_rot)
    ADD_LABEL("\t Eyeline Separation Offset")
    ADD_SLIDER(WINDOW_WIDTH, -1, 1, a.eyeline_separation_offset)
    ADD_LABEL("\t Eyeline Angle Offset")
    ADD_SLIDER(WINDOW_WIDTH, -1, 1, a.eyeline_angle_offset)

    a.eye_rot = rotationFromEuler(rot);
    a.eyeline_rot_offset = rotationFromEuler(e_rot);

}

__host__
void updateArgs(Args& a) {
    DRAW_WINDOW(eyeControls, "Eye Control Panel", a)
    DRAW_WINDOW(eyeAdjustments, "Eye Adjustments", a)
}

#endif