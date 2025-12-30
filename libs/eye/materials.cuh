#ifndef _MATERIALS_CUH
#define _MATERIALS_CUH

#include <hit.cuh>
#include <args.cuh>
#include <eyeParams.cuh>
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
Hit eyeMat(Hit h, Args a) {    
    h.col = vec3(1);
    h.ref = 0.2;
    h.shn = 128;
    h.spc = 2;
    h.lth = 0;
    h.trs = 0;

    return h;
}

__device__
Hit irisMat(Hit h, Args a) {

    h.col = vec3(0.1, 0.8, 0.5);
    h.ref = 0.4;
    h.shn = 200;
    h.spc = 3;
    h.lth = 0;
    h.trs = 0;

    return h;
}

__device__
Hit pupilMat(Hit h, Args a) {

    h.col = vec3(0.);
    h.ref = 0.1;
    h.shn = 250;
    h.spc = 3;
    h.lth = 0;
    h.trs = 0;

    return h;
}

__device__
Hit skinMat(Hit h, Args a) {

    h.col = vec3(0.8, 0.5, 0.1);
    h.ref = 0;
    h.shn = 64;
    h.spc = 1;
    h.lth = 0;
    h.trs = 0;

    return h;
}

__device__
Hit eye_material(Hit h, Args a, eyeParams p){

    float dist = length(distance(h.uv/p.pupilDim, p.pupilPosition * h.rfs)/h.rfs);

    if(dist < p.irisRadius * p.pupilRadius)
        return pupilMat(h, a);
    else if(dist < p.irisRadius)
        return irisMat(h, a);
    else
        return eyeMat(h, a);
} 

#define EYE     1
#define SKIN    3

__device__
Hit getMaterial(Hit hit, vec3 norm, uint matID, Args args) {

    hit = getUV(hit, norm, matID);

    switch(matID) {
        case EYE:       return eye_material(hit, args, args.eye1);
        case SKIN:      return skinMat(hit, args);
        default:        return def(hit);   
    }
    
}

#endif