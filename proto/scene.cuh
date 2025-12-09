#ifndef _SCENE_CUH
#define _SCENE_CUH

#include "hit.cuh"

#include <glm/glm.hpp>
using namespace glm;

__host__ __device__
Hit scene(vec3 p, vec3 n);

#endif