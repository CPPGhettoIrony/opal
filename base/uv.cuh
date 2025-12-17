#ifndef _UV_CUH
#define _UV_CUH

#include <hit.cuh>

#include <glm/glm.hpp>
using namespace glm;

__device__
vec2 averagev2(vec3 n, vec2 fx, vec2 fy, vec2 fz) {
    float f = max(max(n.x, n.y), n.z);
    return (f == n.x)? fx : ((f == n.y)? fy : fz);
}

__device__
vec3 modv(vec3 v, float mx, float offset) {
    return vec3(mod(v.x + offset, mx), mod(v.y + offset, mx), mod(v.z + offset, mx));
}

__device__
Hit getUV(Hit hit, vec3 norm, uint matID) {

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

    return hit;
}

#define getUVAndNormal(hit, p, a, f) {\
\
    vec2 e(EPSILON, 0.f);\
\
    float   h1 = f(p + vec3(e.x, e.y, e.y), a),\
            h2 = f(p - vec3(e.x, e.y, e.y), a),\
            h3 = f(p + vec3(e.y, e.x, e.y), a),\
            h4 = f(p - vec3(e.y, e.x, e.y), a),\
            h5 = f(p + vec3(e.y, e.y, e.x), a),\
            h6 = f(p - vec3(e.y, e.y, e.x), a);\
\
    vec3 norm = normalize(vec3(h1 - h2, h3 - h4, h5 - h6));\
\
    vec3 surfacePosition = applyTransform(hit.pos - norm * hit.d, hit.rfp, hit.rfr); \
    vec3 localNorm = transpose(hit.rfr) * norm; \
\
    vec3 n = pow(abs(localNorm), vec3(8.0));\
    n /= max(dot(localNorm, vec3(1.0)), EPSILON);\
\
    hit.un = norm;\
\
    vec2 uvX(surfacePosition.y, surfacePosition.z);\
    vec2 uvY(surfacePosition.x, surfacePosition.z);\
    vec2 uvZ(surfacePosition.x, surfacePosition.y);\
\
    hit.uv = averagev2(n, uvX, uvY, uvZ);\
}

#endif