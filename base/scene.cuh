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

    Hit ret = sphere(p, vec3(.0), 0.2, n, MATERIAL, args);

    return ret;
}

#endif