#ifndef _SCENE_CUH
#define _SCENE_CUH

#include <glm/glm.hpp>
using namespace glm;

#include "hit.cuh"
#include "primitives.cuh"

__device__
Hit scene(vec3 p, vec3 n, Args args){

    Hit b = sphere(p, vec3(-0.15, -0.15, 0), 0.2, n, 2u, args);
    Hit c = sphere(p, vec3(0.15,  -0.15, 0), 0.2, n, 1u, args);
    Hit a = sphere(p, vec3(0,      0.15, 0), 0.2, n, 3u, args);

    float smooth = sin(args.t) * 0.25 + 0.3;

    return join(a, join(b, c, smooth), smooth);
}

#endif