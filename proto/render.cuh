#ifndef _RENDER_CUH
#define _RENDER_CUH

#include "hit.cuh"
#include "light.cuh"
#include "consts.cuh"
#include "transform.cuh"

#include "hit.cuh"
#include "scene.cuh"
#include "materials.cuh"

// Raymarching loop
__host__ __device__
Hit raymarch(vec3 ro, vec3 rd) {

    const vec2 e = vec2(EPSILON, 0.0);

    Hit h, h1, h2, h3, h4, h5, h6;

    float t = 0.0;

    for (int i = 0; i < 512 && t < MAX_DISTANCE; ++i) {

        vec3 p = ro + rd * t;

        h  = scene(p, vec3(0, 0, 0));

        if (h.d < EPSILON) {

            h1 = scene(p + vec3(e.x, e.y, e.y), vec3(0, 0, 0));
            h2 = scene(p - vec3(e.x, e.y, e.y), vec3(0, 0, 0));

            h3 = scene(p + vec3(e.y, e.x, e.y), vec3(0, 0, 0));
            h4 = scene(p - vec3(e.y, e.x, e.y), vec3(0, 0, 0));

            h5 = scene(p + vec3(e.y, e.y, e.x), vec3(0, 0, 0));
            h6 = scene(p - vec3(e.y, e.y, e.x), vec3(0, 0, 0));

            vec3 normal = normalize(vec3(h1.d - h2.d, h3.d - h4.d, h5.d - h6.d));

            h = scene(p, normal);

            h.dir = normalize(rd);
            h.len = t;
            h.hit = true;

            return h;
        }
            
        t += h.d;
    }

    h.hit = false;

    return h; // background
}

__host__ __device__
Hit neg_scene(vec3 p, vec3 n) {
    Hit ret = scene(p, n);
    ret.d = -ret.d;
    return ret;
}

// Raymarching loop within objects for transparency
__host__ __device__
Hit reverse_raymarch(vec3 ro, vec3 rd) {

    const vec2 e = vec2(EPSILON, 0.0);

    Hit h, h1, h2, h3, h4, h5, h6;

    float t = 0.0;

    for (int i = 0; i < 512 && t < MAX_DISTANCE; ++i) {

        vec3 p = ro + rd * t;

        h  = neg_scene(p, vec3(0, 0, 0));

        if (h.d < EPSILON) {

            h1 = neg_scene(p + vec3(e.x, e.y, e.y), vec3(0, 0, 0));
            h2 = neg_scene(p - vec3(e.x, e.y, e.y), vec3(0, 0, 0));

            h3 = neg_scene(p + vec3(e.y, e.x, e.y), vec3(0, 0, 0));
            h4 = neg_scene(p - vec3(e.y, e.x, e.y), vec3(0, 0, 0));

            h5 = neg_scene(p + vec3(e.y, e.y, e.x), vec3(0, 0, 0));
            h6 = neg_scene(p - vec3(e.y, e.y, e.x), vec3(0, 0, 0));

            vec3 normal = normalize(vec3(h1.d - h2.d, h3.d - h4.d, h5.d - h6.d));

            h = neg_scene(p, normal);

            h.dir = normalize(rd);
            h.len = t;
            h.hit = true;

            return h;
        }
            
        t += h.d;
    }

    h.hit = false;

    return h; // background
}

__host__ __device__
vec3 clampv01(vec3 v) {
    return vec3(clamp(v.x, .0f, 1.f), clamp(v.y, .0f, 1.f), clamp(v.z, .0f, 1.f));
}

// Basic lighting
__host__ __device__
vec3 phong(vec3 col, Hit h, Light l, vec3 viewDir) {

    //return vec3(mix(vec3(0.5), vec3(1), dot(viewDir, h.normal))) * col;

    // If the light is a point, the light direction is the difference between the light position and hit position
    vec3 vec = l.point? normalize(h.pos - l.vec) : l.vec;

    vec3 ambient = col * (l.amb);

    float diff = max(dot(h.normal, -vec), 0.0f);
    vec3 diffuse = col * diff;

    vec3 reflectDir = reflect(vec, h.normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.f), h.shn);
    vec3 specular = h.spc * vec3(spec); // white highlight

    return clamp((ambient + diffuse + specular) * l.col * l.str, vec3(.0), vec3(1.));
}

//Process all lights
__host__ __device__
vec3 lighting(Hit h, Light *ls, vec3 viewDir) {

    vec3 col = vec3(0.0);

    // All colors must be added
    for (uint i = 0u; i < N_LIGHTS; ++i) {
        float s = ls[i].str;
        if (s > 0.0) {
            vec3 contrib = phong(h.col, h, ls[i], viewDir) * s;
            col += contrib;
        }
    }

    return col;
}

__host__ __device__
vec3 shadow(vec3 col, Hit h, Light l) {

    vec3 vec = l.point? normalize(h.pos - l.vec) : l.vec;

    Hit shd = raymarch(h.pos + h.normal * vec3(EPSILON * 2), -vec);

    if(!shd.hit) return col;

    float d = dot(h.normal, vec);
    if(d < 0 && shd.hit && (shd.len < length(h.pos - l.vec) || !l.point)) {
        vec3 sc = col*(1+d);
        col = mix(mix(sc, mix(col, shd.col, shd.trs), l.amb), col, shd.trs);
    }

    return col;

}

__host__ __device__
vec3 shadows(vec3 col, Hit h, Light *ls) {

    for(uint i = 0u; i < N_LIGHTS; ++i)
        col = shadow(col, h, ls[i]);

    return col;
}

__host__ __device__
vec3 basic_shading(Hit hit, Light *ls, vec3 viewDir) {

    //Line thickness
    if(abs(dot(viewDir, hit.normal)) < hit.lth) return hit.lco;

    vec3 col = hit.col;
    // Add lighting
    col = lighting(hit, ls, viewDir);

    return col;
}

__host__ __device__
Hit get_other_side(vec3 rd, Hit hit, Light *ls, vec3 viewDir) {

    Hit thr = reverse_raymarch(hit.pos - hit.normal * vec3(EPSILON * 4.), rd);
    thr.col = basic_shading(thr, ls, viewDir);

    return thr;
}

__host__ __device__
Hit get_transparency(vec3 rd, Hit hit, Light *ls, vec3 viewDir) {

    Hit thr = get_other_side(rd, hit, ls, viewDir);
    Hit next = raymarch(thr.pos - thr.normal * vec3(EPSILON * 4.), thr.dir);
    if(!next.hit) world(next);
    thr.col = mix(thr.col, next.col, thr.trs);
    thr.pos = next.pos - next.normal * vec3(EPSILON * 4);

    return thr;
}

__host__ __device__
Hit get_reflection(vec3 rd, Hit hit, Light *ls, vec3 viewDir) {

    vec3 refDir = reflect(rd, hit.normal);
    Hit ref     = raymarch(hit.pos + hit.normal * vec3(EPSILON * 2.), refDir);
    
    if(ref.hit) ref.col = basic_shading(ref, ls, viewDir);
    else {
        world(ref);
        return ref;
    }

    return ref;

}

__host__ __device__
vec4 render(vec3 ro, vec3 rd, Light *ls) {

    vec3 viewDir = normalize(-rd);

    Hit hit = raymarch(ro, rd);

    // The skybox (when theres no hit, it renders the skybox, there's nothing to shadow or reflect there)
    if(hit.hit) {

        //return vec4(hit.col, 1.);
        //return vec4(vec3(mix(vec3(0.5), vec3(1), dot(viewDir, hit.normal))), 1.) * vec4(hit.col, 1.);

        vec3 col = basic_shading(hit, ls, viewDir);

        if(col == hit.lco) return vec4(col, 1);

        if(hit.ref > 0) {

            // Calculate reflection on the first iteration
            Hit ref = get_reflection(rd, hit, ls, viewDir);

            // Apply first iteration reflection + shading + line thickness
            col = mix(col, ref.col, hit.ref);

            // Final reflection value
            float fref  = ref.ref;

            // Apply every iteration
            for(uint i = 1u; i <= IMAX; ++i) {

                if(!ref.hit) break;

                ref     = get_reflection(ref.dir, ref, ls, viewDir);
                fref   *= ref.ref;

                col     = mix(col, ref.col, fref);

            }

        }

        if(hit.trs > 0) {

            //get first iteration of transparency
            Hit thr = get_transparency(rd, hit, ls, viewDir);

            col = mix(col, thr.col, hit.trs);

            // Final transparency value
            float ftrs  = thr.trs;

            // Apply every iteration
            for(uint i = 1u; i <= IMAX; ++i) {

                if(!thr.hit) break;

                thr     = get_transparency(thr.dir, thr, ls, viewDir);
                ftrs   *= thr.trs;

                col     = mix(col, thr.col, ftrs);

            }

        } 

        // Get projected shadow from other objects
        col = shadows(col, hit, ls);

        return vec4(col, 1.0);

    }

    world(hit);

    return vec4(hit.col, 1.);

}

#endif