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
    return 1-map_A(voronoi(uv, 1., 0u), 0.3, 0.4);
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

__device__
float f_bump(vec2 uv) {
    return map_A(1 - distance(uv, vec2(0.5)), 0.5, 0.6);
}

__device__
Hit floor(Hit h, Args a) {

    float d = f_bump(h.uv * 20.f);

    h.col = (d>0.)? vec3(1., 1., 0) : vec3(0.,0.,1.);
    h.lco = h.col * vec3(0.3);
    h.ref = 0.3;
    h.shn = 64;
    h.spc = 1;
    h.lth = 0;
    h.trs = 0;

    return h;
}

#define PLASTIC1 1
#define PLASTIC2 2
#define PLASTIC3 3
#define FLOOR    4
#define HAIR     5

__device__
Hit getMaterial(Hit hit, vec3 norm, uint matID, Args args) {

    hit = getUV(hit, norm, matID);

    switch(matID) {
        case PLASTIC1:  return plastic(hit, args, args.col);      
        case PLASTIC2:  return plastic(hit, args, vec3(args.col.z, args.col.x, args.col.y));     
        case PLASTIC3:  return plastic(hit, args, vec3(args.col.y, args.col.z, args.col.x));     
        case FLOOR:     return floor(hit, args);
        case HAIR:      return hair(hit, args);  
        default:        return def(hit);   
    }
    
}

#endif