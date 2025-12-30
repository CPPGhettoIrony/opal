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

static void eyeControlGUI(Vector2& position, float width, eyeParams& params) {

    ADD_LABEL(position, "Blink Controls")
    ADD_SEPARATOR(position, width)
    ADD_LABEL(position, "\tUpper Eyelid")
    ADD_SLIDER(position, width, 0.01, 1, params.uppercut)
    ADD_LABEL(position, "\tLower Eyelid")
    ADD_SLIDER(position, width, 0.01, 1, params.lowercut)
    ADD_SEPARATOR(position, width)
    ADD_LABEL(position, "Iris Controls")
    ADD_SEPARATOR(position, width)
    ADD_LABEL(position, "\tPosition")
    ADD_VEC2_SLIDER(position, width, -1, 1, params.pupilPosition)
    ADD_LABEL(position, "\tIris Radius")
    ADD_SLIDER(position, width, 0.2, 1, params.irisRadius)
    ADD_LABEL(position, "\tPupil Radius")
    ADD_SLIDER(position, width, 0.2, 1, params.pupilRadius)
    ADD_LABEL(position, "\tPupil Dimensions")
    ADD_VEC2_SLIDER(position, width, 0.01, 1, params.pupilDim)
    ADD_SEPARATOR(position, width)

}

#endif