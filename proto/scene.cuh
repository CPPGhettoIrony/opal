#ifndef _SCENE_CUH
#define _SCENE_CUH

#include <glm/glm.hpp>
using namespace glm;

#include "hit.cuh"
#include "primitives.cuh"

__device__
Hit scene(vec3 p, vec3 n){

    Hit b = sphere(p, vec3(-0.15, -0.15, 0), 0.2, n, 2u);
    Hit c = sphere(p, vec3(0.15,  -0.15, 0), 0.2, n, 1u);
    Hit a = sphere(p, vec3(0,      0.15, 0), 0.2, n, 3u);

    // Smooth operators between transparent materials don't render properly i don't know why
    return join(a, join(b, c, 0.1), 0.1);
}

#endif