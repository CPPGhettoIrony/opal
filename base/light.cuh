#ifndef _LIGHT_CUH
#define _LIGHT_CUH

#include <glm/glm.hpp>
using namespace glm;

struct __align__(16) Light {

    vec3    col;    //  color
    bool    point;  //  false = directional, true = point
    vec3    vec;    //          Direction           Position
    float   str;    //  Strength
    float   amb;    //  Ambient 

    float pad0, pad1, pad2;

    __device__
    Light(const vec3& col, bool point, const vec3& vec, float str, float amb)
        : col(col), point(point), vec(vec), str(str), amb(amb) {}

};

#endif
