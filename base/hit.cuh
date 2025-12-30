#ifndef _HIT_CUH
#define _HIT_CUH

#include <glm/glm.hpp>
using namespace glm;

struct Hit {

    float   d;          // SDF Distance
    float   len;        // Length of the ray from the origin

    bool    hit;        // If the ray hit something
    
    vec3    pos;        // Absolute ray hit position
    vec3    dir;        // Absolute ray direction

    vec3    rfp;        // object reference pose        for mapping
    mat3    rfr;        // object reference rotation    for mapping
    float   rfs = 1;    // object reference scale       for mapping

    vec3    normal;     // Normal of the hit surface
    vec3    un;         // Unshaded normal
    
    vec2    uv;         // UV coordinates

    uint    matID;      // Used for material operators;

    vec3    col;        // Unshaded color   
    float   ref;        // Reflectivity     
    float   shn;        // Shininess
    float   spc;        // Specular
    float   trs;        // Transparency

    vec3    lco;        // Line color
    float   lth;        // Line thickness

};

#endif