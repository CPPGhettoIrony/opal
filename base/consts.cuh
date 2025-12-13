
#ifndef _CONSTS_CUH
#define _CONSTS_CUH

#ifdef RENDER
    #define MAX_DISTANCE    1024
    #define STEPS           2048
    #define STEP_SIZE       0.1f
#else
    #define MAX_DISTANCE    100.0
    #define STEPS           512
    #define STEP_SIZE       1.f
#endif

#define EPSILON         0.001f
#define IMAX            5
#define FOV             0.25f



#define N_LIGHTS        1

#endif