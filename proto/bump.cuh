#ifndef _BUMP_CUH
#define _BUMP_CUH

#include <glm/glm.hpp>
using namespace glm;

__host__ __device__
float perlin(vec2 position, uint seed);

__host__ __device__
float perlin(vec2 position, int frequency, int octaveCount, float persistence, float lacunarity, uint seed);

__host__ __device__
float voronoi(vec2 uv, float randomness, uint seed);

__host__ __device__
vec3 bumpNormal(vec2 uv, vec3 normal, vec3 h, float bumpStrength);

__host__ __device__
float map_A(float i, float min0, float max0);

// ONLY USE WITH A FUNCTION THAT HAS A VEC2 AS INPUT AND RETURNS A FLOAT
#define BUMP(func, hit, strength) bumpNormal(hit.uv, hit.normal, vec3(func(hit.uv), func(vec2(EPSILON, .0) + hit.uv), func(vec2(.0, EPSILON) + hit.uv)), strength)

#endif