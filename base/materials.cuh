#ifndef _MATERIALS_CUH
#define _MATERIALS_CUH

#include <hit.cuh>
#include <args.cuh>
#include <bump.cuh>
#include <uv.cuh>
#include <consts.cuh>

/* - - - - - -  MATERIALS - - - - - - */

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
Hit cartoon(Hit h, Args a, vec3 col) {    

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
    h.shn = 64;
    h.spc = 2;
    h.lth = 0;

    h.trs = 0;

    //h.normal = BUMP(c_bump, h, 0.002);

    return h;
}

__device__
Hit A(Hit h, Args a) {return cartoon(h, a, a.col);}

__device__
Hit B(Hit h, Args a) {return cartoon(h, a, vec3(a.col.z, a.col.x, a.col.y));}

__device__
Hit C(Hit h, Args a) {return cartoon(h, a, vec3(a.col.y, a.col.z, a.col.x));}

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

    //h.normal = BUMP(f_bump, h, 0.2);

    return h;
}

__device__
Hit getMaterial(Hit hit, vec3 norm, uint matID, Args args) {

    hit.matID = matID;

    vec3 surfacePosition = applyTransform(hit.pos - norm * hit.d, hit.rfp, hit.rfr);
    vec3 localNorm = transpose(hit.rfr) * norm;

    vec3 n = pow(abs(localNorm), vec3(8.0));
    n /= max(dot(localNorm, vec3(1.0)), EPSILON);

    hit.un = norm;
    hit.normal = norm;

    vec2 uvX(surfacePosition.y, surfacePosition.z);
    vec2 uvY(surfacePosition.x, surfacePosition.z);
    vec2 uvZ(surfacePosition.x, surfacePosition.y);

    hit.uv = averagev2(n, uvX, uvY, uvZ);

    switch(matID) {
        case 1:  return A(hit, args);      
        case 2:  return B(hit, args);      
        case 3:  return C(hit, args);      
        case 4:  return floor(hit, args);
        case 5:  return hair(hit, args);  
        default: return def(hit);   
    }
    
}

#endif