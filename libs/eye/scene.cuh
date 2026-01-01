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

    head_hit = eyes(p, head_hit, args.eye_pos, args.eye_rot, args.eye_dim, args.eyes_separation, args.eyes_angle, args.eye1, args.eye1, 
                    n, EYE, EYE, SKIN, args);

    Hit eyeline_hit = eyeLines(p, args.eye_pos, args.eye_rot, args.eye_dim, args.eyes_separation, args.eyes_angle, args.eyeline_rad, 
        args.eyeline_thk, args.eyeline_len, 
        args.eyeline_off, args.eye1, args.eye1, n, MASC, args);

    return join(head_hit, eyeline_hit);

}

#endif