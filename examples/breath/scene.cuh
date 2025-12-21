#ifndef _SCENE_CUH
#define _SCENE_CUH

#include <glm/glm.hpp>
using namespace glm;

#include <uv.cuh>
#include <hit.cuh>
#include <primitives.cuh>
#include <materials.cuh>

__device__
Hit scene(vec3 p, vec3 n, Args args){

    float smooth = sin(args.t)/2 + 0.5;

    Hit ret;

    Hit a = sphere(p, args.pos + args.rot * vec3(-0.15, -0.1, 0),  args.rot, 0.2, n, PLASTIC1, args);
    Hit b = sphere(p, args.pos + args.rot * vec3(0.15, -0.1, 0),   args.rot, 0.2, n, PLASTIC2, args);
    Hit c = sphere(p, args.pos + args.rot * vec3(0, 0.2, 0),       args.rot, 0.2, n, PLASTIC3, args);

    ret = join(join(a, b, smooth), c, smooth);

    return ret;
}

#endif