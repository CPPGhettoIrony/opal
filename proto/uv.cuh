#ifndef _UV_CUH
#define _UV_CUH

#include <glm/glm.hpp>
using namespace glm;

__host__ __device__
vec2 averagev2(vec3 n, vec2 fx, vec2 fy, vec2 fz);

__host__ __device__
vec3 modv(vec3 v, float mx, float offset);

#endif