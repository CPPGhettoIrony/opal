#ifndef _PRIMITIVES_CUH
#define _PRIMITIVES_CUH

#include "hit.cuh"

#include <glm/glm.hpp>
using namespace glm;

#include "materials.cuh"
#include "transform.cuh"
#include "consts.cuh"

/* - - - - - -  PRIMITIVES - - - - - - */

// Empty Hit
__device__
Hit empty(vec3 p) {
    Hit ret;
    ret.d       = 1.f;
    ret.pos     = p;
    ret.rfp     = p; 
    ret.rfr     = mat3(1.);
    return ret;   
}

// Sphere
__device__
float sphere(vec3 p, vec3 pos, float r) {
    return length(p - pos) - r;
}
__device__
Hit sphere(vec3 p, vec3 pos, float r, vec3 n, uint matID, Args a) {
    Hit ret;
    ret.d       = sphere(p , pos, r);
    ret.pos     = p;
    ret.rfp     = pos; 
    ret.rfr     = mat3(1.);
    ret = getMaterial(ret, n, matID, a); 
    return ret;
}

// Ground
__device__
float ground(vec3 p, float h) {
    return p.y - h;
}
__device__
Hit ground(vec3 p, float h, vec3 n, uint matID, Args a) {
    Hit ret;
    ret.d       = p.y - h;
    ret.pos     = p;
    ret.rfp     = vec3(.0); 
    ret.rfr     = mat3(1.);
    ret = getMaterial(ret, n, matID, a);
    return ret;
}

// Box
__device__
float box( vec3 p, vec3 b ) {
    vec3 q = abs(p) - b;
    return length(max(q,vec3(0.0))) + min(max(q.x,max(q.y,q.z)),0.0f);
}
__device__
float box(vec3 p, vec3 pos, mat3 rot, vec3 b ) {
    return box(applyTransform(p, pos, rot), b);
}
__device__
Hit box(vec3 p, vec3 pos, mat3 rot, vec3 b, vec3 n, uint matID, Args a) {
    Hit ret;
    ret.d       = box(p, pos, rot, b);
    ret.pos     = p;
    ret.rfp     = pos;
    ret.rfr     = rot;
    ret = getMaterial(ret, n, matID, a); 
    return ret;
}

// Torus
__device__
float torus( vec3 p, float r1, float r2 ) {
  vec2 q = vec2(length(vec2(p.x, p.z))-r1,p.y);
  return length(q)-r2;
}
__device__
float torus(vec3 p, vec3 pos, mat3 rot, float r1, float r2) {
    return torus(applyTransform(p, pos, rot), r1, r2);
}
__device__
Hit torus(vec3 p, vec3 pos, mat3 rot, float r1, float r2, vec3 n, uint matID, Args a) {
    Hit ret;
    ret.d       = torus(p, pos, rot, r1, r2);
    ret.pos     = p;
    ret.rfp     = pos;
    ret.rfr     = rot;
    ret = getMaterial(ret, n, matID, a); 
    return ret;
}

// Link
__device__
float link( vec3 p, float le, float r1, float r2 ) {
    vec3 q = vec3( p.x, max(abs(p.y)-le,0.0f), p.z );
    return length(vec2(length(vec2(q.x, q.y))-r1,q.z)) - r2;
}
__device__
float link(vec3 p, vec3 pos, mat3 rot, float le, float r1, float r2) {
    return link(applyTransform(p, pos, rot), le, r1, r2);
}
__device__
Hit link(vec3 p, vec3 pos, mat3 rot, float le, float r1, float r2, vec3 n, uint matID, Args a) {
    Hit ret;
    ret.d       = link(p, pos, rot, le, r1, r2);
    ret.pos     = p;
    ret.rfp     = pos;
    ret.rfr     = rot;
    ret = getMaterial(ret, n, matID, a); 
    return ret;
}

// Cone
__device__
float cone(vec3 p, vec2 q) {
    // c is the sin/cos of the angle, h is height
    // Alternatively pass q instead of (c,h),
    // which is the point at the base in 2D

    vec2 w = vec2( length(vec2(p.x, p.z)), p.y );
    vec2 a = w - q*clamp(dot(w,q)/dot(q,q), 0.0f, 1.0f );
    vec2 b = w - q*vec2(clamp( w.x/q.x, 0.0f, 1.0f ), 1.0f );
    float k = sign( q.y );
    float d = min(dot( a, a ),dot(b, b));
    float s = max( k*(w.x*q.y-w.y*q.x),k*(w.y-q.y)  );
    return sqrt(d)*sign(s);
}
__device__
float cone(vec3 p, vec3 pos, mat3 rot, float r, float h) {
    return cone(applyTransform(p, pos, rot), vec2(r, -h));
}
__device__
Hit cone(vec3 p, vec3 pos, mat3 rot, float r, float h, vec3 n, uint matID, Args a) {
    Hit ret;
    ret.d       = cone(p, pos, rot, r, h);
    ret.pos     = p;
    ret.rfp     = pos;
    ret.rfr     = rot;
    ret = getMaterial(ret, n, matID, a); 
    return ret;
}

// Capsule 
__device__
float capsule( vec3 p, float r, float h ) {
    p.y -= clamp( p.y, 0.0f, h );
    return length( p ) - r;
}
__device__
float capsule(vec3 p, vec3 pos, mat3 rot, float r, float h) {
    return capsule(applyTransform(p, pos, rot), r, h);
}
__device__
Hit capsule(vec3 p, vec3 pos, mat3 rot, float r, float h, vec3 n, uint matID, Args a) {
    Hit ret;
    ret.d       = capsule(p, pos, rot, r, h);
    ret.len     = 0.0;
    ret.pos     = p;
    ret.rfp     = pos;
    ret.rfr     = rot;
    ret = getMaterial(ret, n, matID, a); 
    return ret;
}

// Cylinder
__device__
float cylinder( vec3 p, float r, float h ) {
    vec2 d = abs(vec2(length(vec2(p.x, p.z)),p.y)) - vec2(r,h);
    return min(max(d.x,d.y),0.0f) + length(max(d,0.0f));
}
__device__
float cylinder(vec3 p, vec3 pos, mat3 rot, float r, float h) {
    return cylinder(applyTransform(p, pos, rot), r, h);
}
__device__
Hit cylinder(vec3 p, vec3 pos, mat3 rot, float r, float h, vec3 n, uint matID, Args a) {
    Hit ret;
    ret.d       = cylinder(p, pos, rot, r, h);
    ret.pos     = p;
    ret.rfp     = pos;
    ret.rfr     = rot;
    ret = getMaterial(ret, n, matID, a); 
    return ret;
}

// Octahedron
__device__
float octahedron( vec3 p, float s ) {

  p = abs(p);
  float m = p.x+p.y+p.z-s;
  vec3 q;
       if( 3.0*p.x < m ) q = p;
  else if( 3.0*p.y < m ) q = vec3(p.y, p.z, p.x);
  else if( 3.0*p.z < m ) q = vec3(p.z, p.x, p.y);
  else return m*0.57735027;
    
  float k = clamp(0.5f*(q.z-q.y+s),0.0f,s); 
  return length(vec3(q.x,q.y-s+k,q.z-k)); 

}
__device__
float octahedron(vec3 p, vec3 pos, mat3 rot, float s) {
    return octahedron(applyTransform(p, pos, rot), s);
}
__device__
Hit octahedron(vec3 p, vec3 pos, mat3 rot, float s, vec3 n, uint matID, Args a) {
    Hit ret;
    ret.d       = octahedron(p, pos, rot, s);
    ret.len     = 0.0;
    ret.pos     = p;
    ret.rfp     = pos;
    ret.rfr     = rot;
    ret = getMaterial(ret, n, matID, a); 
    return ret;
}

// Ellipsoid
__device__
float ellipsoid( vec3 p, vec3 r ) {
  float k0 = length(p/r);
  float k1 = length(p/(r*r));
  return k0*(k0-1.0)/k1;
}
__device__
float ellipsoid(vec3 p, vec3 pos, mat3 rot, vec3 b ) {
    return ellipsoid(applyTransform(p, pos, rot), b);
}
__device__
Hit ellipsoid(vec3 p, vec3 pos, mat3 rot, vec3 b, vec3 n, uint matID, Args a) {
    Hit ret;
    ret.d       = ellipsoid(p, pos, rot, b);
    ret.len     = 0.0;
    ret.pos     = p;
    ret.rfp     = pos;
    ret.rfr     = rot;
    ret = getMaterial(ret, n, matID, a); 
    return ret;
}
__device__
float slope(vec3 p, vec3 pos, vec3 normal) {
    return dot((p - pos), normal);
}
__device__
Hit slope(vec3 p, vec3 pos, vec3 normal, vec3 n, uint matID, Args a) {
    Hit ret;
    ret.d       = slope(p, pos, normal);
    ret.pos     = p;
    ret.rfp     = pos;
    ret.rfr     = mat3(1);
    ret = getMaterial(ret, n, matID, a);
    return ret;
}
__device__
Hit toHit(float d, vec3 p, vec3 rfp, mat3 rfr, vec3 n, uint matID, Args a) {
    Hit ret;
    ret.d       = d;
    ret.pos     = p;
    ret.rfp     = rfp;
    ret.rfr     = rfr;
    ret = getMaterial(ret, n, matID, a);
    return ret;
}

// CSG Operations
__device__
Hit blendMaterials(Hit r, Hit a, Hit b, float hBlend) {

    r.col       = mix(b.col, a.col, hBlend);
    r.ref       = mix(b.ref, a.ref, hBlend);
    
    r.shn       = mix(b.shn, a.shn, hBlend);        
    r.spc       = mix(b.spc, a.spc, hBlend);

    r.lth       = mix(b.lth, a.lth, hBlend);
    r.lco       = mix(b.lco, a.lco, hBlend);

    r.trs       = mix(b.trs, a.trs, hBlend);

    r.matID     = b.matID;

    return r;     

}
__device__
Hit morph(Hit a, Hit b, float k) {
    Hit r;

    r.d     = mix(b.d, a.d, k);
    r       = blendMaterials(r, a, b, k);

    return r;
}
__device__
Hit changeMaterial(Hit a, vec3 n, uint matID, Args args) {
    a = getMaterial(a, n, matID, args);
    return a;
}

// polynomial smooth‑min helper
__device__
float smin(float d1, float d2, float k, float& h)
{
    h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}
__device__
float join(float a, float b) {
    return (a < b) ? a : b;
}
__device__
float join(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}
__device__
Hit join(Hit a, Hit b) {
    return (a.d < b.d) ? a : b;
}
__device__
Hit join(Hit a, Hit b, float k) {

    // 1) choose the winner by raw distance
    Hit r = (a.d < b.d) ? a : b;
    
    // 2) compute the blended distance (also get blend factor h)
    float     hBlend;
    r.d     = smin(a.d, b.d, k, hBlend);

    r = blendMaterials(r, a, b, hBlend);

    // r.hit, r.pos, r.len remain intact, so the marcher keeps working
    return r;
}
__device__
float smax(float d1, float d2, float k, float &h) {
    h = clamp(0.5 - 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) + k * h * (1.0 - h);
}
__device__
float subtract(float a, float b) {
    return (a > -b) ? a : b;
}
__device__
float subtract(float a, float b, float k) {
    float h = clamp(0.5 - 0.5 * (-b - a) / k, 0.0, 1.0);
    return mix(-b, a, h) + k * h * (1.0 - h);
}
__device__
Hit subtract(Hit a, Hit b) {
    Hit r = (a.d > -b.d) ? a : b;
    r.d = max(a.d, -b.d);
    return r;
}
__device__
Hit subtract(Hit a, Hit b, float k) {

    Hit r = (a.d > -b.d) ? a : b; // Choose the winner by raw distance for initial guess

    float hBlend;
    // The smooth maximum for a and -b.d
    r.d = smax(a.d, -b.d, k, hBlend);

    r = blendMaterials(r, a, b, hBlend);

    return r;
}
__device__
float intersect(float a, float b) {
    return (a > b) ? a : b;
}
__device__
float intersect(float a, float b, float k) {
    float h = clamp(0.5 - 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) + k * h * (1.0 - h);
}
__device__
Hit intersect(Hit a, Hit b) {
    return (a.d > b.d) ? a : b;
}
__device__
Hit intersect(Hit a, Hit b, float k) {
    
    Hit r = (a.d > b.d) ? a : b; // Choose the winner by raw distance for initial guess

    float hBlend;
    // The smooth maximum for a and -b.d
    r.d = smax(a.d, b.d, k, hBlend);

    r = blendMaterials(r, a, b, hBlend);

    return r;
}
__device__
Hit color(Hit a, Hit b, float k, vec3 n, Args args) {

    Hit ab      = changeMaterial(a, n, b.matID, args);
    Hit area    = intersect(a,  b);

    float d;
    if(k == 0) d = area.d < EPSILON? 1 : 0;
    else
        d = (area.d >= EPSILON)? clamp(k - area.d, .0f, k)/k : 1;

    return morph(ab, a, d);
}
__device__
float joint(float a, float b, float c, float k) {
    k = (c >= EPSILON)? clamp(k - c, k, .0f) : k;
    return join(join(a, c), b, k);
}
__device__
Hit joint(Hit a, Hit b, Hit c, float k) {
    k = (c.d >= EPSILON)? clamp(k - c.d, k, .0f) : k;
    return join(join(a, c), b, k);
}


#endif