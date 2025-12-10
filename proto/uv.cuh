#ifndef _UV_CUH
#define _UV_CUH

#include <glm/glm.hpp>
using namespace glm;

__host__ __device__
vec2 averagev2(vec3 n, vec2 fx, vec2 fy, vec2 fz) {
    float f = max(max(n.x, n.y), n.z);
    return (f == n.x)? fx : ((f == n.y)? fy : fz);
}

__host__ __device__
vec3 modv(vec3 v, float mx, float offset) {
    return vec3(mod(v.x + offset, mx), mod(v.y + offset, mx), mod(v.z + offset, mx));
}

#endif