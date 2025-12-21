#ifndef _MATERIALS_CUH
#define _MATERIALS_CUH

#include <hit.cuh>
#include <args.cuh>
#include <bump.cuh>
#include <uv.cuh>
#include <consts.cuh>


// Skybox
__device__
Hit world(Hit h, Args a) {
    h.col = vec3(0.4,0.7,1);
    return h;
}

// Default material
__device__
Hit def(Hit h) {
    h.col = vec3(1.);
    h.ref = 0;
    h.shn = 64;
    h.spc = 1;
    return h;
}

__device__
float c_bump(vec2 uv) {
    uv *= 30;
    return 1-map_A(perlin(uv, 0u), 0.3, 0.4);
}

__device__
Hit plastic(Hit h, Args a, vec3 col) {    

    h.col = col;
    h.lco = h.col * vec3(0.3);
    h.ref = 0.2;
    h.shn = 128;
    h.spc = 2;
    h.lth = 0;

    h.trs = 0.2;

    h.normal = BUMP(c_bump, h, 0.002);

    return h;
}

__device__
Hit hair(Hit h, Args a) {    

    h.col = vec3(0.2);
    h.ref = 0;
    h.shn = 128;
    h.spc = 2;
    h.lth = 0;

    h.trs = 0;

    return h;
}

#define PLASTIC  1
#define FLOOR    4
#define HAIR     5

__device__
Hit getMaterial(Hit hit, vec3 norm, uint matID, Args args) {

    hit = getUV(hit, norm, matID);

    switch(matID) {
        case PLASTIC:   return plastic(hit, args, vec3(0, 1, 0.2));        
        case HAIR:      return hair(hit, args);  
        default:        return def(hit);   
    }
    
}

#endif