#ifndef _RENDER_CUH
#define _RENDER_CUH

#include "hit.cuh"
#include "light.cuh"
#include "consts.cuh"
#include "transform.cuh"

#include "args.cuh"
#include "hit.cuh"
#include "scene.cuh"
#include "materials.cuh"

// Raymarching loop
__device__
Hit raymarch(vec3 ro, vec3 rd, Args a) {

    const vec2 e = vec2(EPSILON, 0.0);

    Hit h, h1, h2, h3, h4, h5, h6;

    float t = 0.0;

    for (int i = 0; i < 512 && t < MAX_DISTANCE; ++i) {

        vec3 p = ro + rd * t;

        h  = scene(p, vec3(0, 0, 0), a);

        if (h.d < EPSILON) {

            h1 = scene(p + vec3(e.x, e.y, e.y), vec3(0, 0, 0), a);
            h2 = scene(p - vec3(e.x, e.y, e.y), vec3(0, 0, 0), a);

            h3 = scene(p + vec3(e.y, e.x, e.y), vec3(0, 0, 0), a);
            h4 = scene(p - vec3(e.y, e.x, e.y), vec3(0, 0, 0), a);

            h5 = scene(p + vec3(e.y, e.y, e.x), vec3(0, 0, 0), a);
            h6 = scene(p - vec3(e.y, e.y, e.x), vec3(0, 0, 0), a);

            vec3 normal = normalize(vec3(h1.d - h2.d, h3.d - h4.d, h5.d - h6.d));

            h = scene(p, normal, a);

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

__device__
Hit neg_scene(vec3 p, vec3 n, Args a) {
    Hit ret = scene(p, n, a);
    ret.d = -ret.d;
    return ret;
}

// Raymarching loop within objects for transparency
__device__
Hit reverse_raymarch(vec3 ro, vec3 rd, Args a) {

    const vec2 e = vec2(EPSILON, 0.0);

    Hit h, h1, h2, h3, h4, h5, h6;

    float t = 0.0;

    for (int i = 0; i < 512 && t < MAX_DISTANCE; ++i) {

        vec3 p = ro + rd * t;

        h  = neg_scene(p, vec3(0, 0, 0), a);

        if (h.d < EPSILON) {

            h1 = neg_scene(p + vec3(e.x, e.y, e.y), vec3(0, 0, 0), a);
            h2 = neg_scene(p - vec3(e.x, e.y, e.y), vec3(0, 0, 0), a);

            h3 = neg_scene(p + vec3(e.y, e.x, e.y), vec3(0, 0, 0), a);
            h4 = neg_scene(p - vec3(e.y, e.x, e.y), vec3(0, 0, 0), a);

            h5 = neg_scene(p + vec3(e.y, e.y, e.x), vec3(0, 0, 0), a);
            h6 = neg_scene(p - vec3(e.y, e.y, e.x), vec3(0, 0, 0), a);

            vec3 normal = normalize(vec3(h1.d - h2.d, h3.d - h4.d, h5.d - h6.d));
            h.un = normal;

            h = neg_scene(p, normal, a);

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

__device__
vec3 clampv01(vec3 v) {
    return vec3(clamp(v.x, .0f, 1.f), clamp(v.y, .0f, 1.f), clamp(v.z, .0f, 1.f));
}

// Basic lighting
__device__
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
__device__
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

__device__
vec3 shadow(vec3 col, Hit h, Light l, Args a) {

    vec3 vec = l.point? normalize(h.pos - l.vec) : l.vec;

    Hit shd = raymarch(h.pos + h.normal * vec3(EPSILON * 2), -vec, a);

    if(!shd.hit) return col;

    float d = dot(h.normal, vec);
    if(d < 0 && shd.hit && (shd.len < length(h.pos - l.vec) || !l.point)) {
        vec3 sc = col*(1+d);
        col = mix(mix(sc, mix(col, shd.col, shd.trs), l.amb), col, shd.trs);
    }

    return col;

}

__device__
vec3 shadows(vec3 col, Hit h, Light *ls, Args a) {

    for(uint i = 0u; i < N_LIGHTS; ++i)
        col = shadow(col, h, ls[i], a);

    return col;
}

__device__
vec3 basic_shading(Hit hit, Light *ls, vec3 viewDir, bool line) {

    //Line thickness
    if(abs(dot(viewDir, hit.un)) < hit.lth && line) return hit.lco;

    vec3 col = hit.col;
    // Add lighting
    col = lighting(hit, ls, viewDir);

    return col;
}

__device__
Hit get_other_side(vec3 rd, Hit hit, Light *ls, vec3 viewDir, Args a) {

    Hit thr = reverse_raymarch(hit.pos - hit.normal * vec3(EPSILON * 4.), rd, a);
    
    // Solo calculamos luz si realmente golpeamos la cara interna
    if(thr.hit)
        thr.col = basic_shading(thr, ls, viewDir, true);
    else
        thr.col = hit.col; 

    return thr;
}


__device__
Hit get_transparency(vec3 rd, Hit hit, Light *ls, vec3 viewDir, Args a) {

    // 1. Obtener la cara trasera
    Hit thr = get_other_side(rd, hit, ls, viewDir, a);

    // SAFETY CHECK PARA NVIDIA:
    // Si el rayo inverso falló (por ejemplo, geometría muy fina o error de float),
    // abortamos. Usar thr.normal aquí si !thr.hit causaría NaNs (pantalla negra).
    if(!thr.hit) return thr;

    // 2. Calcular qué hay DETRÁS del objeto transparente
    Hit next = raymarch(thr.pos - thr.normal * vec3(EPSILON * 4.), thr.dir, a);
    
    if(!next.hit) next = world(next, a);
    
    // Mezclar colores
    thr.col = mix(thr.col, next.col, thr.trs);
    
    // 3. ACTUALIZAR EL ESTADO PARA EL BUCLE
    // Debemos mover la posición para la siguiente iteración
    thr.pos = next.pos - next.normal * vec3(EPSILON * 4.);
    
    // IMPORTANTE: Debemos pasar el estado de hit del objeto SIGUIENTE.
    // Si next no golpeó nada (es cielo), thr.hit debe ser false para
    // que el bucle en render() se detenga.
    thr.hit = next.hit; 

    return thr;
}

__device__
Hit get_reflection(vec3 rd, Hit hit, Light *ls, vec3 viewDir, Args a) {

    vec3 refDir = reflect(rd, hit.normal);
    Hit ref     = raymarch(hit.pos + hit.normal * vec3(EPSILON * 2.), refDir, a);
    
    if(ref.hit) ref.col = basic_shading(ref, ls, viewDir, false);
    else return world(ref, a);

    return ref;

}

__device__
vec4 render(vec3 ro, vec3 rd, Light *ls, Args a) {

    vec3 viewDir = normalize(-rd);

    Hit hit = raymarch(ro, rd, a);

    // The skybox (when theres no hit, it renders the skybox, there's nothing to shadow or reflect there)
    if(hit.hit) {

        //return vec4(hit.col, 1.);
        //return vec4(vec3(mix(vec3(0.5), vec3(1), dot(viewDir, hit.normal))), 1.) * vec4(hit.col, 1.);

        vec3 col = basic_shading(hit, ls, viewDir, true);

        if(col == hit.lco) return vec4(col, 1);

        if(hit.ref > 0) {

            // Calculate reflection on the first iteration
            Hit ref = get_reflection(rd, hit, ls, viewDir, a);

            // Apply first iteration reflection + shading + line thickness
            col = mix(col, ref.col, hit.ref);

            // Final reflection value
            float fref  = ref.ref;

            // Apply every iteration
            for(uint i = 1u; i <= IMAX; ++i) {

                if(!ref.hit) break;

                ref     = get_reflection(ref.dir, ref, ls, viewDir, a);
                fref   *= ref.ref;

                col     = mix(col, ref.col, fref);

            }

        }

        if(hit.trs > 0) {

            //get first iteration of transparency
            Hit thr = get_transparency(rd, hit, ls, viewDir, a);

            col = mix(col, thr.col, hit.trs);

            // Final transparency value
            float ftrs  = thr.trs;

            // Apply every iteration
            for(uint i = 1u; i <= IMAX; ++i) {

                if(!thr.hit) break;

                thr     = get_transparency(thr.dir, thr, ls, viewDir, a);
                ftrs   *= thr.trs;

                col     = mix(col, thr.col, ftrs);

            }

        } 

        // Get projected shadow from other objects
        col = shadows(col, hit, ls, a);

        return vec4(col, 1.0);

    }

    hit = world(hit, a);

    return vec4(hit.col, 1.);

}

#endif