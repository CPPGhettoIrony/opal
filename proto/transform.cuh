#ifndef _TRANSFORM_CUH
#define _TRANSFORM_CUH

#include <glm/glm.hpp>
using namespace glm;

__host__ __device__
mat3 rotationFromEuler(vec3 euler);

__host__ __device__
vec3 applyTransform(vec3 p, vec3 pos, mat3 rot);

#endif