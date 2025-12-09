#include "bump.cuh"
#include "consts.cuh"

__host__ __device__
uint hash(uint x, uint seed) {
    const uint m = 0x5bd1e995U;
    uint hash = seed;
    // process first vector element
    uint k = x; 
    k *= m;
    k ^= k >> 24;
    k *= m;
    hash *= m;
    hash ^= k;
    return hash;    
}

__host__ __device__
uint hash(uvec2 x, uint seed){
    const uint m = 0x5bd1e995U;
    uint hash = seed;
    // process first vector element
    uint k = x.x; 
    k *= m;
    k ^= k >> 24;
    k *= m;
    hash *= m;
    hash ^= k;
    // process second vector element
    k = x.y; 
    k *= m;
    k ^= k >> 24;
    k *= m;
    hash *= m;
    hash ^= k;
	// some final mixing
    hash ^= hash >> 13;
    hash *= m;
    hash ^= hash >> 15;
    return hash;
}

__host__ __device__
vec2 gradientDirection(uint hash) {
    switch (int(hash) & 3) { // look at the last two bits to pick a gradient direction
        case 0:
            return vec2(1.0, 1.0);
        case 1:
            return vec2(-1.0, 1.0);
        case 2:
            return vec2(1.0, -1.0);
        case 3:
            return vec2(-1.0, -1.0);
    }
    return vec2(1.0, 1.0);
}

__host__ __device__
float interpolate(float value1, float value2, float value3, float value4, vec2 t) {
    return mix(mix(value1, value2, t.x), mix(value3, value4, t.x), t.y);
}

__host__ __device__
vec2 fade(vec2 t) {
    // 6t^5 - 15t^4 + 10t^3
	return t * t * t * (t * (t * vec2(6.0) - vec2(15.0)) + vec2(10.0));
}

__host__ __device__
float perlin(vec2 position, uint seed) {
    vec2 floorPosition = floor(position);
    vec2 fractPosition = position - floorPosition;
    uvec2 cellCoordinates = uvec2(floorPosition);
    float value1 = dot(gradientDirection(hash(cellCoordinates, seed)), fractPosition);
    float value2 = dot(gradientDirection(hash((cellCoordinates + uvec2(1, 0)), seed)), fractPosition - vec2(1.0, 0.0));
    float value3 = dot(gradientDirection(hash((cellCoordinates + uvec2(0, 1)), seed)), fractPosition - vec2(0.0, 1.0));
    float value4 = dot(gradientDirection(hash((cellCoordinates + uvec2(1, 1)), seed)), fractPosition - vec2(1.0, 1.0));
    return interpolate(value1, value2, value3, value4, fade(fractPosition));
}

__host__ __device__
float perlin(vec2 position, int frequency, int octaveCount, float persistence, float lacunarity, uint seed) {
    float value = 0.0;
    float amplitude = 1.0;
    float currentFrequency = float(frequency);
    uint currentSeed = seed;
    for (int i = 0; i < octaveCount; i++) {
        currentSeed = hash(currentSeed, 0x0U); // create a new seed for each octave
        value += perlin(position * currentFrequency, currentSeed) * amplitude;
        amplitude *= persistence;
        currentFrequency *= lacunarity;
    }
    return value;
}

__host__ __device__
float voronoi(vec2 uv, float randomness, uint seed) {
    vec2 cell = floor(uv);
    vec2 fract = uv - cell;

    float minDist = 1e10;

    // Check neighboring cells (3x3 grid)
    for (int j = -1; j <= 1; ++j) {
        for (int i = -1; i <= 1; ++i) {
            uvec2 neighbor = uvec2(cell) + uvec2(i, j);

            // Hash determines the feature point inside the cell
            uint h = hash(neighbor, seed);
            vec2 random_offset = vec2(h & 0xFFu, (h >> 8) & 0xFFu) / vec2(255.0); // [0,1)

            // Interpolate between center of cell and random offset
            vec2 offset = mix(vec2(0.5), random_offset, clamp(randomness, 0.0f, 1.0f));

            vec2 feature = vec2(i, j) + offset;
            float dist = length(fract - feature);

            minDist = min(minDist, dist);
        }
    }

    return minDist;
}

__host__ __device__
vec3 bumpNormal(vec2 uv, vec3 normal, vec3 h, float bumpStrength) {

    // Compute gradient (partial derivatives)
    float dx = (h.y - h.x) / EPSILON;
    float dy = (h.z - h.x) / EPSILON;

    // Robust tangent space basis from normal
    vec3 up = abs(normal.y) < 0.999 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
    vec3 T = normalize(cross(up, normal));
    vec3 B = normalize(cross(normal, T));

    // Perturb the normal using the gradient
    vec3 bumped = normal 
                - T * dx * bumpStrength
                - B * dy * bumpStrength;

    return normalize(bumped);
}

__host__ __device__
float map_A(float i, float min0, float max0) {
    return (clamp(i, min0, max0) - min0) / (max0 - min0);  
}