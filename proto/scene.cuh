#ifndef _SCENE_CUH
#define _SCENE_CUH

#include "hit.cuh"

#include <glm/glm.hpp>
using namespace glm;

#include "scene.cuh"
#include "primitives.cuh"

__host__ __device__
Hit test(vec3 p, vec3 pos, vec3 n) {
    Hit     a   = box(p, vec3(0, 0, 0) + pos, mat3(1), vec3(0.2), n, 1u),
            b   = sphere(p, vec3(0, 0.2, 0) + pos, 0.2, n, 2u),
            c   = union_(a, b, 0.1);
    return c;
}

// n equals the normal, if calculated. if n != 0, then material functions must be executed
__host__ __device__
Hit scene(vec3 p, vec3 n){

    /*
	float   a = slope(p, vec3(0, 1, 2), vec3(0, 1, 0)),
            b = slope(p, vec3(0, 0, 1), vec3(0, 0,-1)),
            c = slope(p, vec3(0, 0, 2), vec3(0,-1, 0)),
            d = slope(p, vec3(0, 0, 2), vec3(0, 0, 1)),
            e = slope(p, vec3(0, 0, 2), vec3(-1,0, 0)),
            f = slope(p, vec3(1, 0, 2), vec3(1, 0, 0));

    float k = 0.1;

    float dst;
    dst = intersect(a,   b, k);
    dst = intersect(dst, c, k);
    dst = intersect(dst, d, k);
    dst = intersect(dst, e, k);
    dst = intersect(dst, f, k);

	return toHit(dst, p, vec3(0), mat3(1), 3u);
    */

    Hit a = ground(p, -0.3, n, 4u);
    Hit b = sphere(p, vec3(-0.15, 0., 0.5), 0.2, n, 2u);
    Hit c = sphere(p, vec3(0.15, 0., 0.5), 0.2, n, 1u);

    return union_(a, union_(b, c, 0.1));
}

#endif