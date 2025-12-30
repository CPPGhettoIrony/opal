#ifndef _LIGHTS_CUH
#define _LIGHTS_CUH

#include <consts.cuh>
#include <light.cuh>
#include <args.cuh>

__global__ void initLights(Light* ls) {
    ls[0] = Light(vec3(1.0, 1.0, 1.0), false, normalize(vec3(0.75, -1.0, 0.3)), 0.9f, 0.6f);
}

__global__ void updateLights(Light* ls, Args* args) {}

#endif 