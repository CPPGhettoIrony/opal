#ifndef _EYEPARAMS
#define _EYEPARAMS

#include <gui.cuh>

#include <glm/glm.hpp>
using namespace glm;

struct eyeParams {
    float   uppercut        = 1,
            lowercut        = 1,
            irisRadius      = 0.2,
            pupilRadius     = 0.25;
    vec2    pupilPosition   = vec2(0.f),
            pupilDim        = vec2(1.f);
};

DECLARE_GUI(eyeControlGUI, float width, eyeParams& params) {

    ADD_LABEL("Blink Controls")
    ADD_SEPARATOR(width)

    ADD_LABEL("\t Upper Eyelid")
    ADD_SLIDER(width, 0.01, 1, params.uppercut)
    ADD_LABEL("\t Lower Eyelid")
    ADD_SLIDER(width, 0.01, 1, params.lowercut)
    ADD_SEPARATOR(width)

    ADD_LABEL("Iris Controls")
    ADD_SEPARATOR(width)

    ADD_LABEL("\t Position")
    ADD_VEC2_SLIDER(width, -1, 1, params.pupilPosition)
    ADD_LABEL("\t Iris Radius")
    ADD_SLIDER(width, 0.2, 1, params.irisRadius)
    ADD_LABEL("\t Pupil Radius")
    ADD_SLIDER(width, 0.2, 1, params.pupilRadius)
    ADD_LABEL("\t Pupil Dimensions")
    ADD_VEC2_SLIDER(width, 0.01, 1, params.pupilDim)

    ADD_SEPARATOR(width)

}

#define EYE_SYNC                0
#define EYE_MOSTLY_SYNC         1
#define EYE_SEMI_INDEPENDENT    2
#define EYE_MOSTLY_INDEPENDENT  3
#define EYE_INDEPENDENT         4

__host__ 
void synchronizeEye(int mode, eyeParams reference, eyeParams& output) {
    switch(mode) {
        case EYE_SYNC:
            output = reference;
            break;
        case EYE_MOSTLY_SYNC:
            output.pupilPosition    = reference.pupilPosition;
        case EYE_SEMI_INDEPENDENT:
            output.irisRadius       = reference.irisRadius;
            output.pupilRadius      = reference.pupilRadius;
        case EYE_MOSTLY_INDEPENDENT:
            output.pupilDim         = reference.pupilDim;
        case EYE_INDEPENDENT:
            break;
    }
}

DECLARE_GUI(dualEyeControlGUI, float width, eyeParams& params_A, eyeParams& params_B, int& mode) {

    static bool eyeDropboxEditMode;

    ADD_LABEL("Eye Controls")
    ADD_SEPARATOR(width*2)

    position.y += 15;

    Vector2 position_B = position;

    CALL_GUI(eyeControlGUI, width, params_A)

    Vector2 position_C = position;

    position_B.x += width;
    position = position_B;

    CALL_GUI(eyeControlGUI, width, params_B)

    position = position_C;

    ADD_LABEL("Eye Position Mode")

    if (GuiDropdownBox(GET_RECTANGLE(150, 15), "Sync;Mostly Sync;Semi Independent;Mostly Independent;Independent;", &mode, eyeDropboxEditMode))
        eyeDropboxEditMode = !eyeDropboxEditMode;

    synchronizeEye(mode, params_A, params_B);
}

#endif