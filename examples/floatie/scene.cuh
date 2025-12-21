#ifndef _SCENE_CUH
#define _SCENE_CUH

#include <glm/glm.hpp>
using namespace glm;

#include <uv.cuh>
#include <hit.cuh>
#include <primitives.cuh>
#include <materials.cuh>

__device__
Hit scene(vec3 p, vec3 n, Args args){
    Hit ret = torus(p, args.pos, args.rot, 0.2, 0.09, n, PLASTIC, args);
    return ret;
}

#endif