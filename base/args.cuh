#ifndef _ARGS_CUH
#define _ARGS_CUH

// Arguments for scene parameters

struct Args {
    float t = 0;
};

__host__
void updateArgs(Args& a) {
    a.t += 0.01;
}

#endif