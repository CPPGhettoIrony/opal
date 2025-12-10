#ifndef _MATERIALS_CUH
#define _MATERIALS_CUH

#include "hit.cuh"

#include "bump.cuh"
#include "uv.cuh"
#include "consts.cuh"

/* - - - - - -  MATERIALS - - - - - - */

__host__ __device__
Hit world(Hit h) {
    h.col = vec3(0.4,0.7,1);
    return h;
}

// Default material

__host__ __device__
Hit def(Hit h) {
    h.col = vec3(1.);
    h.ref = 0;
    h.shn = 64;
    h.spc = 1;
    return h;
}

__host__ __device__
float c_bump(vec2 uv) {
    uv *= 30;
    return 1-map_A(voronoi(uv, 1., 0u), 0.3, 0.4);
}

__host__ __device__
Hit cartoon(Hit h, vec3 col) {    

    h.col = col;
    h.lco = h.col * vec3(0.3);
    h.ref = 0.2;
    h.shn = 128;
    h.spc = 2;
    h.lth = 0;

    h.trs = 0.4;

    h.normal = BUMP(c_bump, h, 0.002);

    return h;
}

__host__ __device__
Hit A(Hit h) {return cartoon(h, vec3(1.0, 0.3, 0.));}

__host__ __device__
Hit B(Hit h) {return cartoon(h, vec3(0., 1.0, 0.3));}

__host__ __device__
Hit C(Hit h) {return cartoon(h, vec3(0., 0.3, 1.0));}

__host__ __device__
float f_bump(vec2 uv) {
    return map_A(1 - distance(uv, vec2(0.5)), 0.5, 0.6);
}

__host__ __device__
Hit floor(Hit h) {

    float d = f_bump(h.uv);

    h.col = (d>0.)? vec3(1., 1., 0) : vec3(0.,0.,1.);
    h.lco = h.col * vec3(0.3);
    h.ref = 0.3;
    h.shn = 64;
    h.spc = 1;
    h.lth = 0;
    h.trs = 0;

    //h.normal = BUMP(f_bump, h, 0.2);

    return h;
}

__host__ __device__
Hit getMaterial(Hit h, vec3 norm, uint matID) {

    h.matID = matID;

    vec3 surfacePosition = modv(h.pos - h.rfp, 1., 0.);

    vec3 n = pow(abs(norm), vec3(8.0));
    n /= max(dot(norm, vec3(1.0)), EPSILON);

    h.normal = norm;

    vec2 uvX(surfacePosition.y, surfacePosition.z);
    vec2 uvY(surfacePosition.x, surfacePosition.z);
    vec2 uvZ(surfacePosition.x, surfacePosition.y);

    h.uv = averagev2(n, uvX, uvY, uvZ);

    switch(matID) {
        case 1:  return A(h);      
        case 2:  return B(h);      
        case 3:  return C(h);      
        case 4:  return floor(h);  
        default: return def(h);   
    }
    
}

#endif