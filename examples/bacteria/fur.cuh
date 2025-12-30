#ifndef _FUR_CUH
#define _FUR_CUH

#include <bump.cuh>

__device__
float fur(vec3 p, vec2 curl = vec2(0.3f, 0.6f), float wdensity = 20.f, float spread = 0.06f, float spreadalong = 5.f, float density = 15.f, float randomness = 100.f, float thickness = 0.1f, 
    float maxthickness = -0.1f, float lengthFactor = 0.5f, float thicknessOffset = 0.1, uint seed1 = 0u, uint seed2 = 1u, uint seed3 = 2u) 
{
    // --- 1. Calcular la forma "Raw" (Sin escalar) ---
    // Mantenemos tu lógica intacta para no alterar el diseño visual
    
    vec2 pxz = vec2(p.x, p.z);
    vec2 pxy = vec2(p.x, p.y);
    vec2 pyz = vec2(p.z, p.y);

    vec2 dist = vec2(perlin(pxy * curl * wdensity, seed1), perlin(pyz * curl * wdensity, seed2));
    dist *= spread * p.y * spreadalong;

    // Calculamos el valor "crudo"
    // Nota: Aquí NO dividimos voronoi internamente, lo haremos al final globalmente
    float rawShape = (voronoi((pxz + dist) * density, randomness, seed3) 
                      + max(-thickness + p.y, -maxthickness)) 
                      - p.y * lengthFactor 
                      - thicknessOffset;

    // --- 2. Calcular el Factor de Corrección (Estimación de Lipschitz) ---
    // Buscamos cuál es la compresión máxima en cualquier eje.
    // density afecta a XZ, lengthFactor afecta a Y.
    float globalScale = max(density, lengthFactor);
    
    // Si usas mucha distorsión (spread), el gradiente aumenta, así que añadimos un margen de seguridad.
    // Un valor empírico seguro es sumar un poco si hay spread.
    if (spread > 0.001f) {
        globalScale += spread * wdensity * 0.5f; 
    }
    
    // Evitamos dividir por cero o números muy pequeños
    globalScale = max(globalScale, 1.0f);

    // --- 3. Normalizar ---
    // Al dividir el TOTAL, mantenemos la posición del cero (la forma) intacta,
    // pero suavizamos la distancia para que el raymarcher no salte.
    return rawShape / globalScale;
}

#endif