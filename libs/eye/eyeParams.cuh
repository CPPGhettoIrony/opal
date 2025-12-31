#ifndef _EYEPARAMS
#define _EYEPARAMS

#include <gui.cuh>

#include <glm/glm.hpp>
using namespace glm;

struct eyeParams {
    float   uppercut        = 1,
            lowercut        = 1,
            irisRadius      = 0.5,
            pupilRadius     = 0.25;
    vec2    pupilPosition   = vec2(0.f),
            pupilDim        = vec2(1.f);
};

static void eyeControlGUI(Vector2& position, Vector2 scroll, float width, eyeParams& params) {

    ADD_LABEL(position, scroll, "Blink Controls")
    ADD_SEPARATOR(position, scroll, width)

    ADD_LABEL(position, scroll, "\t Upper Eyelid")
    ADD_SLIDER(position, scroll, width, 0.01, 1, params.uppercut)
    ADD_LABEL(position, scroll, "\t Lower Eyelid")
    ADD_SLIDER(position, scroll, width, 0.01, 1, params.lowercut)
    ADD_SEPARATOR(position, scroll, width)

    ADD_LABEL(position, scroll, "Iris Controls")
    ADD_SEPARATOR(position, scroll, width)

    ADD_LABEL(position, scroll, "\t Position")
    ADD_VEC2_SLIDER(position, scroll, width, -1, 1, params.pupilPosition)
    ADD_LABEL(position, scroll, "\t Iris Radius")
    ADD_SLIDER(position, scroll, width, 0.2, 1, params.irisRadius)
    ADD_LABEL(position, scroll, "\t Pupil Radius")
    ADD_SLIDER(position, scroll, width, 0.2, 1, params.pupilRadius)
    ADD_LABEL(position, scroll, "\t Pupil Dimensions")
    ADD_VEC2_SLIDER(position, scroll, width, 0.01, 1, params.pupilDim)

    ADD_SEPARATOR(position, scroll, width)

}

static void doubleEyeControlGUI(Vector2& position, Vector2 scroll, float width, eyeParams& params) {

    eyeControlGUI(position, scroll, width, params);

}

#endif