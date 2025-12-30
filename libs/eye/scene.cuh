#ifndef _SCENE_CUH
#define _SCENE_CUH

#include <glm/glm.hpp>
using namespace glm;

#include <materials.cuh>
#include <eye.cuh>

__device__
Hit scene(vec3 p, vec3 n, Args args){

    float radius = 0.2;
    float head      = sphere(p, vec3(0., 0., radius), radius);
    Hit head_hit    = toHit(head, p, vec3(.0, .0, radius), mat3(1.), n, SKIN, args);

    return eye(p, head_hit, args.eye_pos, args.eye_rot, args.eye_dim, vec2(1.f), args.eye1, n, EYE, SKIN, args);

}

#endif