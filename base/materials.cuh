#ifndef _MATERIALS_CUH
#define _MATERIALS_CUH

#include <hit.cuh>
#include <bump.cuh>
#include <uv.cuh>
#include <consts.cuh>

struct Args;

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
Hit material(Hit h, Args a) {    

    h.col = vec3(0, 1., 0);
    h.lco = h.col * vec3(0.3);
    h.ref = 0;
    h.shn = 128;
    h.spc = 2;
    h.lth = 0;
    h.trs = 0;

    return h;
}

#define MATERIAL 1

__device__
Hit getMaterial(Hit hit, vec3 norm, uint matID, Args args) {

    hit = getUV(hit, norm, matID);

    switch(matID) {
        case MATERIAL:  return material(hit, args);
        default:        return def(hit);   
    }
    
}

#endif