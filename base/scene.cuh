#ifndef _SCENE_CUH
#define _SCENE_CUH

#include <glm/glm.hpp>
using namespace glm;

#include <uv.cuh>
#include <hit.cuh>
#include <primitives.cuh>

__device__
float sphereWrapper(vec3 p, Args a) {
    return sphere(p, vec3(0., 0., 0.), 0.15f);
}

__device__
Hit scene(vec3 p, vec3 n, Args args){

    // Para distorsionar una superficie, primero se obtiene su normal y UV
    // Hit uvn;                // Posición de referencia
    // getUVAndNormal(uvn, p, vec3(0.), args, sphereWrapper)
                                            // Función (debe tener como argumentos la posición del rayo (p), y los argumentos (a))
    // Se crea un nuevo espacio que se distorsiona según los parámetros obtenidos

    
    // vec3 q = p;
    // q -= uvn.un * 0.05f * perlin(uvn.uv * 20.f, 0u) ; // Se desplaza con respecto a la normal según las coordenadas uv

    // float s = sphere(q, vec3(0.), 0.2f) / 20; // dividimos por si las moscas (suele arreglar artifactos)
                                                // Lo malo es que la transparencia se pierde
                                                // El UV también puede utilizarse para cambiar el color entre otras propiedades
    
    // return toHit(s, p, vec3(.0), mat3(1.), n, 2u, args);

    // Para warpear una superficie sobre otra
    // Hit uvn;                // Posición de referencia
    // getUVAndNormal(uvn, p, vec3(0.), args, sphereWrapper)
    //                         // Esta función especial transforma las coordenadas globales a las locales con respecto a una superficie
    // vec3 q = wrap(uvn.uv, sphereWrapper(p, args), 10.f);
    
    // float v = fur(q); // Se utilizan estas coordenadas nuevas
    // Hit fur = toHit(v, p, vec3(.0), mat3(1.), n, 5u, args);
    // return join(fur, sphere(p, vec3(0., 0.0, 0.0), 0.4, n, 1u, args));
    
    Hit b = sphere(p, vec3(-0.15, -0.15, 0), 0.2, n, 2u, args);
    Hit c = sphere(p, vec3(0.15,  -0.15, 0), 0.2, n, 1u, args);
    Hit a = sphere(p, vec3(0,      0.15, 0), 0.2, n, 3u, args);

    float smooth = sin(args.t) * 0.25 + 0.3;

    return join(a, join(b, c, smooth), smooth);
}

#endif