#ifndef _RENDER_CUH
#define _RENDER_CUH

#include "hit.cuh"
#include "light.cuh"
#include "consts.cuh"
#include "transform.cuh"

__host__ __device__
vec4 render(vec3 ro, vec3 rd, Light *ls);

#endif