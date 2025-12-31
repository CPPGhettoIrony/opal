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
float eyeLine(vec3 p, vec3 dim, float rad, float thick, float length, float offset, eyeParams params) {

    float z = dim.z*(1 + length);

    vec3    eyeline_dim_A(dim.x * rad, dim.y * rad, z),
            eyeline_dim_B(dim.x * rad * thick, dim.y * rad * thick, z);

    vec3 q = p - vec3(0., 0., offset);

    float   eyeline = eyeSocket(q, eyeline_dim_B, params);
            eyeline = subtract(
                        eyeSocket(q, eyeline_dim_A, params),
                        eyeline, 0.01);
            eyeline = subtract(eyeline, q.z);

    return eyeline;

}

__device__ 
Hit eyeLine(vec3 p, vec3 pos, mat3 rot, 
    vec3 dim, float rad, float thick, float length, float offset, eyeParams params,
    vec3 n, uint mat, Args args) 
{
    float eyeline   = eyeLine(applyTransform(p, pos, rot), dim, rad, thick, length, offset, params);
    return toHit(eyeline, p, pos, rot, n, mat, args);
}

__device__
Hit eye(vec3 p, Hit input, vec3 pos, mat3 rot, 
    vec3 eye_dim, eyeParams params,
    vec3 n, uint eye_mat, uint skin_mat, Args args) 
{

    vec3 eye_pos = pos - rot * vec3(0., 0., - eye_dim.z - 0.01);

    float socket    = eyeSocket(applyTransform(p, pos, rot), eye_dim, params);
    float eye       = ellipsoid(applyTransform(p, eye_pos, rot), eye_dim);

    Hit socket_hit  = toHit(socket, p, pos, rot, n, skin_mat, args);
    Hit eye_hit     = toHit(eye, p, pos, rot, min(eye_dim.x, eye_dim.y)*2.f, n, eye_mat, args);

    Hit output      = subtract(input, socket_hit, 0.01 * length(eye_dim));

    return join(output, eye_hit);

}

__device__
Hit eyes(vec3 p, Hit input, vec3 pos, mat3 rot, 
    vec3 eye_dim, 
    float separation, float angle,
    eyeParams params_A, eyeParams params_B,
    vec3 n, uint eye_mat_A, uint eye_mat_B, uint skin_mat, Args args) 
{

    input = eye(p, input, pos + rot * vec3(- separation, 0, 0), 
                    rot * rotationFromEuler(vec3(0., -angle, .0)), 
                    eye_dim, params_A, n, eye_mat_A, skin_mat, args);

    input = eye(p, input, pos + rot * vec3(+ separation, 0, 0), 
                    rot * rotationFromEuler(vec3(0., angle, .0)), 
                    eye_dim, params_B, n, eye_mat_B, skin_mat, args);

    return input;

}

#endif