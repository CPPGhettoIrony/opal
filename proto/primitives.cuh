#ifndef _PRIMITIVES_CUH
#define _PRIMITIVES_CUH

#include "hit.cuh"

#include <glm/glm.hpp>
using namespace glm;

__host__ __device__
float sphere(vec3 p, vec3 pos, float r);

__host__ __device__
Hit sphere(vec3 p, vec3 pos, float r, vec3 n, uint matID);

__host__ __device__
float ground(vec3 p, float h);

__host__ __device__
Hit ground(vec3 p, float h, vec3 n, uint matID);

__host__ __device__
float box( vec3 p, vec3 b );

__host__ __device__
float box(vec3 p, vec3 pos, mat3 rot, vec3 b );

__host__ __device__
Hit box(vec3 p, vec3 pos, mat3 rot, vec3 b, vec3 n, uint matID);

__host__ __device__
float torus( vec3 p, float r1, float r2 );

__host__ __device__
float torus(vec3 p, vec3 pos, mat3 rot, float r1, float r2);

__host__ __device__
Hit torus(vec3 p, vec3 pos, mat3 rot, float r1, float r2, vec3 n, uint matID);

__host__ __device__
float link( vec3 p, float le, float r1, float r2 );

__host__ __device__
float link(vec3 p, vec3 pos, mat3 rot, float le, float r1, float r2);

__host__ __device__
Hit link(vec3 p, vec3 pos, mat3 rot, float le, float r1, float r2, vec3 n, uint matID);

__host__ __device__
float cone(vec3 p, vec2 q);

__host__ __device__
float cone(vec3 p, vec3 pos, mat3 rot, float r, float h);

__host__ __device__
Hit cone(vec3 p, vec3 pos, mat3 rot, float r, float h, vec3 n, uint matID);

__host__ __device__
float capsule( vec3 p, float r, float h );

__host__ __device__
float capsule(vec3 p, vec3 pos, mat3 rot, float r, float h);

__host__ __device__
Hit capsule(vec3 p, vec3 pos, mat3 rot, float r, float h, vec3 n, uint matID);

__host__ __device__
float cylinder( vec3 p, float r, float h );

__host__ __device__
float cylinder(vec3 p, vec3 pos, mat3 rot, float r, float h);

__host__ __device__
Hit cylinder(vec3 p, vec3 pos, mat3 rot, float r, float h, vec3 n, uint matID);

__host__ __device__
float octahedron( vec3 p, float s );

__host__ __device__
float octahedron(vec3 p, vec3 pos, mat3 rot, float s);

__host__ __device__
Hit octahedron(vec3 p, vec3 pos, mat3 rot, float s, vec3 n, uint matID);

__host__ __device__
float ellipsoid( vec3 p, vec3 r );

__host__ __device__
float ellipsoid(vec3 p, vec3 pos, mat3 rot, vec3 b );

__host__ __device__
Hit ellipsoid(vec3 p, vec3 pos, mat3 rot, vec3 b, vec3 n, uint matID);

__host__ __device__
float slope(vec3 p, vec3 pos, vec3 normal);

__host__ __device__
Hit slope(vec3 p, vec3 pos, vec3 normal, vec3 n, uint matID);

__host__ __device__
Hit toHit(float d, vec3 p, vec3 rfp, mat3 rfr, vec3 n, uint matID);

__host__ __device__
Hit blendMaterials(Hit r, Hit a, Hit b, float hBlend);

__host__ __device__
Hit morph(Hit a, Hit b, float k);

__host__ __device__
Hit changeMaterial(Hit a, vec3 n, uint matID);

__host__ __device__
float smin(float d1, float d2, float k, float& h);

__host__ __device__
float union_(float a, float b);

__host__ __device__
float union_(float a, float b, float k);

__host__ __device__
Hit union_(Hit a, Hit b);

__host__ __device__
Hit union_(Hit a, Hit b, float k);

__host__ __device__
float smax(float d1, float d2, float k, float &h);

__host__ __device__
float subtract(float a, float b);

__host__ __device__
float subtract(float a, float b, float k);

__host__ __device__
Hit subtract(Hit a, Hit b);

__host__ __device__
Hit subtract(Hit a, Hit b, float k);

__host__ __device__
float intersect(float a, float b);

__host__ __device__
float intersect(float a, float b, float k);

__host__ __device__
Hit intersect(Hit a, Hit b);

__host__ __device__
Hit intersect(Hit a, Hit b, float k);

__host__ __device__
Hit color(Hit a, Hit b, float k, vec3 n);

__host__ __device__
float joint(float a, float b, float c, float k);

__host__ __device__
Hit joint(Hit a, Hit b, Hit c, float k);


#endif