#ifndef _EYE_CUH
#define _EYE_CUH

#include <primitives.cuh>
#include <glm/glm.hpp>
using namespace glm;

#include <eyeParams.cuh>

__device__
float eyeSocket(vec3 p, vec3 dim, eyeParams params) {

    float base_upper = ellipsoid(p, vec3(dim.x, dim.y * params.uppercut, dim.z));
    float base_lower = ellipsoid(p, vec3(dim.x, dim.y * params.lowercut, dim.z));
    
    float cut_upper = slope(p, vec3(0.,  0.001, 0.), vec3(0.,  1, 0.));
    float cut_lower = slope(p, vec3(0., -0.001, 0.), vec3(0., -1, 0.));

    return join(intersect(base_lower, cut_lower), intersect(base_upper, cut_upper));
}
 
__device__
Hit eye(vec3 p, Hit input, vec3 pos, mat3 rot, 
    vec3 eye_dim, vec2 iris_dim, 
    eyeParams params,
    vec3 n, uint eye_mat, uint mascara_mat, Args args) 
{

    vec3 dim = eye_dim;

    vec3 eye_pos = pos - rot * vec3(0., 0., - dim.z - 0.01);

    float socket    = eyeSocket(applyTransform(p, pos, rot), dim, params);
    float eye       = ellipsoid(applyTransform(p, eye_pos, rot), dim);

    Hit socket_hit  = toHit(socket, p, pos, rot, n, mascara_mat, args);
    Hit eye_hit     = toHit(eye, p, pos, rot, min(dim.x, dim.y)*2.f, n, eye_mat, args);

    Hit output      = subtract(input, socket_hit, 0.01 * length(dim));

    return join(output, eye_hit);

}


#endif