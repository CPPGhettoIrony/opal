#ifndef _SCENE_CUH
#define _SCENE_CUH

#include <glm/glm.hpp>
using namespace glm;

#include <uv.cuh>
#include <hit.cuh>
#include <primitives.cuh>
#include <materials.cuh>

#include <args.cuh>
#include <fur.cuh>

__device__
float capsuleWrapper(vec3 p, Args a) {
    return capsule(p, a.pos, a.rot, 0.2, 0.4);
}

__device__
Hit scene(vec3 p, vec3 n, Args args){
    // Para warpear una superficie sobre otra
    Hit cap = capsule(p, args.pos, args.rot, 0.2, 0.4, n, PLASTIC, args); // Superficie sobre la que se "warpeara" otra
    getUVAndNormal(cap, p, args, capsuleWrapper)
    //                         // Esta función especial transforma las coordenadas globales a las locales con respecto a una superficie
    vec3 q = wrap(cap.uv, cap.d, 10.f);
    float v = fur(q); // Se utilizan estas coordenadas nuevas
    Hit fur = toHit(v, p, vec3(.0), mat3(1.), n, 5u, args);
    return join(fur, cap);
}

#endif