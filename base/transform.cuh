#ifndef _TRANSFORM_CUH
#define _TRANSFORM_CUH

#include <glm/glm.hpp>
using namespace glm;

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

__host__ vec3 rotate_point_xz(float angleInRads, vec3 p, vec3 o)
{
  float s = sin(angleInRads);
  float c = cos(angleInRads);

  // translate point back to origin:
  p.x -= o.x;
  p.z -= o.z;

  // rotate point
  float xnew = p.x * c - p.z * s;
  float ynew = p.x * s + p.z * c;

  // translate point back:
  p.x = xnew + o.x;
  p.z = ynew + o.z;

  return p;
}

__host__ vec3 rotate_point_zy(float angleInRads, vec3 p, vec3 o)
{

  float s = sin(angleInRads);
  float c = cos(angleInRads);

  // translate point back to origin:
  p.z -= o.z;
  p.y -= o.y;

  // rotate point
  float xnew = p.z * c - p.y * s;
  float ynew = p.z * s + p.y * c;

  // translate point back:
  p.z = xnew + o.z;
  p.y = ynew + o.y;

  return p;
}

#define TRANSFORM_HIT(p, hit, _pos, _rot, ...)\
{\
    vec3 tmp = p;\
    p = applyTransform(p, _pos, _rot);\
    __VA_ARGS__\
    p = tmp;\
    hit.pos = p;\
    hit.rfp += _pos;\
    hit.rfr += _rot;\
}



#endif