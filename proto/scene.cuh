#ifndef _SCENE_CUH
#define _SCENE_CUH

#include "hit.cuh"

#include <glm/glm.hpp>
using namespace glm;

#include "scene.cuh"
#include "primitives.cuh"


// n equals the normal, if calculated. if n != 0, then material functions must be executed
__host__ __device__
Hit scene(vec3 p, vec3 n){

    Hit b = sphere(p, vec3(-0.15, -0.15, 0), 0.2, n, 2u);
    Hit c = sphere(p, vec3(0.15,  -0.15, 0), 0.2, n, 1u);
    Hit a = sphere(p, vec3(0,      0.15, 0), 0.2, n, 3u);

    return union_(a, union_(b, c), 0.1);
}

#endif