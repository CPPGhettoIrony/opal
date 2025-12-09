#include "transform.cuh"

__host__ __device__
mat3 rotationFromEuler(vec3 euler) {
    float cx = cos(euler.x), sx = sin(euler.x);
    float cy = cos(euler.y), sy = sin(euler.y);
    float cz = cos(euler.z), sz = sin(euler.z);

    mat3 rx = mat3(
        1.0, 0.0, 0.0,
        0.0, cx, -sx,
        0.0, sx, cx
    );

    mat3 ry = mat3(
        cy, 0.0, sy,
        0.0, 1.0, 0.0,
        -sy, 0.0, cy
    );

    mat3 rz = mat3(
        cz, -sz, 0.0,
        sz, cz, 0.0,
        0.0, 0.0, 1.0
    );

    return ry * rz * rx; 
}

// We are applying the transform to the space, not the primitive, so we must apply the inverse transform
__host__ __device__
vec3 applyTransform(vec3 p, vec3 pos, mat3 rot) {
    return transpose(rot) * (p - pos);
}