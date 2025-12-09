#ifndef _CAMERA_CUH
#define _CAMERA_CUH

#include <glm/glm.hpp>
using namespace glm;

struct Cam {

    vec3 pos, rot;

    __host__ __device__
    Cam(const vec3& p, const vec3& r): pos(p), rot(r) {}

    __host__ __device__
    Cam(): pos(vec3(0.f)), rot(vec3(0.f)) {}
};

#endif