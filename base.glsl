#version 330 core

in vec3 vertexPos;
in vec2 fragTexCoord;
in vec4 fragColor;

out vec4 finalColor;

uniform float u_time;
uniform vec2 u_resolution;

const float maxDistance = 100.0;
const float epsilon     = 0.001;

const uint  imax        = 5u;

uniform vec3 camera_pos;
uniform vec3 camera_rot;
const float fov = 0.25;

const uint nLights = 1u;

// This will be replaced in opal.py

struct Hit {

    float   d;          // SDF Distance
    float   len;        // Length of the ray from the origin

    bool    hit;        // If the ray hit something
    
    vec3    pos;        // Absolute ray hit position
    vec3    dir;        // Absolute ray direction

    vec3    rfp;        // object reference pose        for mapping
    mat3    rfr;        // object reference rotation    for mapping

    vec3    normal;     // Normal of the hit surface
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

/* - - - - - -  MATERIAL HELPERS - - - - */

uint hash(uint x, uint seed) {
    const uint m = 0x5bd1e995U;
    uint hash = seed;
    // process input
    uint k = x;
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

// implementation of MurmurHash (https://sites.google.com/site/murmurhash/) for a  
// 2-dimensional unsigned integer input vector.

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
}

float interpolate(float value1, float value2, float value3, float value4, vec2 t) {
    return mix(mix(value1, value2, t.x), mix(value3, value4, t.x), t.y);
}

vec2 fade(vec2 t) {
    // 6t^5 - 15t^4 + 10t^3
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

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
            vec2 random_offset = vec2(h & 0xFFu, (h >> 8) & 0xFFu) / 255.0; // [0,1)

            // Interpolate between center of cell and random offset
            vec2 offset = mix(vec2(0.5), random_offset, clamp(randomness, 0.0, 1.0));

            vec2 feature = vec2(i, j) + offset;
            float dist = length(fract - feature);

            minDist = min(minDist, dist);
        }
    }

    return minDist;
}

vec3 bumpNormal(vec2 uv, vec3 normal, vec3 h, float bumpStrength) {

    // Compute gradient (partial derivatives)
    float dx = (h.y - h.x) / epsilon;
    float dy = (h.z - h.x) / epsilon;

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

float map_A(float i, float min0, float max0) {
    return (clamp(i, min0, max0) - min0) / (max0 - min0);  
}

// ONLY USE WITH A FUNCTION THAT HAS A VEC2 AS INPUT AND RETURNS A FLOAT
#define BUMP(func, hit, strength) bumpNormal(hit.uv, hit.normal, vec3(func(hit.uv), func(vec2(epsilon, .0) + hit.uv), func(vec2(.0, epsilon) + hit.uv)), strength)

// Direction & Fresnel

vec3 direction(Hit h) {return normalize(camera_pos - h.pos);}

float fresnel(Hit h) {return dot(normalize(camera_pos - h.pos), h.normal);}

/* - - - - - -  MATERIALS - - - - - - */

Hit world(Hit h) {
    h.col = vec3(0.4,0.7,1);
    return h;
}

// Default material
Hit def(Hit h) {
    
    h.col = vec3(1.);
    h.ref = 0;
    h.shn = 64;
    h.spc = 1;

    return h;
}

float c_bump(vec2 uv) {
    uv *= 30;
    return 1-map_A(voronoi(uv, 1., 0u), 0.3, 0.4);
}
  
Hit cartoon(Hit h, vec3 col) {    

    h.col = mix(col, col * 1.2, fresnel(h));
    h.lco = h.col *.3;
    h.ref = 0;
    h.shn = 64;
    h.spc = 1;
    h.lth = 0;

    h.trs = 0.2;

    //h.normal = BUMP(c_bump, h, 0.002);

    return h;

}

Hit A(Hit h) {return cartoon(h, vec3(1.0, 0.3, 0.));}
Hit B(Hit h) {return cartoon(h, vec3(0., 1.0, 0.3));}
Hit C(Hit h) {return cartoon(h, vec3(0., 0.3, 1.0));}

float f_bump(vec2 uv) {
    return map_A(1 - distance(uv, vec2(0.5)), 0.5, 0.6);
}

Hit floor(Hit h) {

    float d = f_bump(h.uv);

    h.col = (d>0.)? vec3(1., 1., 0) : vec3(0.,0.,1.);
    h.lco = h.col *.3;
    h.ref = 0.3;
    h.shn = 64;
    h.spc = 1;
    h.lth = 0;
    h.trs = 0;

    //h.normal = BUMP(f_bump, h, 0.2);

    return h;
}


// Mix diferent hits based on the three UV planes for mapping

vec2 averagev2(vec3 n, vec2 fx, vec2 fy, vec2 fz) {
    float f = max(max(n.x, n.y), n.z);
    return (f == n.x)? fx : ((f == n.y)? fy : fz);
}

vec3 modv(vec3 v, float mx, float offset) {
    return vec3(mod(v.x + offset, mx), mod(v.y + offset, mx), mod(v.z + offset, mx));
}

Hit getMaterial(Hit h, vec3 norm, uint matID) {

    h.matID = matID;

    vec3 surfacePosition = modv(h.pos - h.rfp, 1., 0.);

    vec3 n = pow(abs(norm), vec3(8.0));
    n /= max(dot(norm, vec3(1.0)), epsilon);

    h.normal = norm;

    vec2 uvX = surfacePosition.yz;
    vec2 uvY = surfacePosition.xz;
    vec2 uvZ = surfacePosition.xy;

    h.uv = averagev2(n, uvX, uvY, uvZ);

    switch(matID) {
     case 0u:
            return def(h);
     case 1u:
            return A(h);
     case 2u:
            return B(h);
     case 3u:
            return C(h);
     case 4u:
            return floor(h);

        default:
            return def(h);
    }
    
}


/* - - - - - - ROTATION + TRANSLATION - - - - */


mat3 rotationFromEuler(vec3 euler) {
    float cx = cos(euler.x), sx = sin(euler.x);
    float cy = cos(euler.y), sy = sin(euler.y);
    float cz = cos(euler.z), sz = sin(euler.z);

    mat3 rx = mat3(
        1.0, 0.0, 0.0,
        0.0, cx, -sx,
        0.0, sx, cx
    );

    mat3 ry = mat3(
        cy, 0.0, sy,
        0.0, 1.0, 0.0,
        -sy, 0.0, cy
    );

    mat3 rz = mat3(
        cz, -sz, 0.0,
        sz, cz, 0.0,
        0.0, 0.0, 1.0
    );

    return ry * rz * rx; 
}

// We are applying the transform to the space, not the primitive, so we must apply the inverse transform
vec3 applyTransform(vec3 p, vec3 pos, mat3 rot) {
    return transpose(rot) * (p - pos);
}

/* - - - - - -  PRIMITIVES - - - - - - */

// Sphere

float sphere(vec3 p, vec3 pos, float r) {
    return length(p - pos) - r;
}

Hit sphere(vec3 p, vec3 pos, float r, vec3 n, uint matID) {
    Hit ret;
    ret.d       = sphere(p , pos, r);
    ret.pos     = p;
    ret.rfp     = pos; 
    ret.rfr     = mat3(1.);
    ret = getMaterial(ret, n, matID); 
    return ret;
}

// Ground

float ground(vec3 p, float h) {
    return p.y - h;
}

Hit ground(vec3 p, float h, vec3 n, uint matID) {
    Hit ret;
    ret.d       = p.y - h;
    ret.pos     = p;
    ret.rfp     = vec3(.0); 
    ret.rfr     = mat3(1.);
    ret = getMaterial(ret, n, matID);
    return ret;
}

// Box

float box( vec3 p, vec3 b ) {
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float box(vec3 p, vec3 pos, mat3 rot, vec3 b ) {
    return box(applyTransform(p, pos, rot), b);
}

Hit box(vec3 p, vec3 pos, mat3 rot, vec3 b, vec3 n, uint matID) {
    Hit ret;
    ret.d       = box(p, pos, rot, b);
    ret.pos     = p;
    ret.rfp     = pos;
    ret.rfr     = rot;
    ret         = getMaterial(ret, n, matID); 
    return ret;
}

// Torus

float torus( vec3 p, float r1, float r2 ) {
  vec2 q = vec2(length(p.xz)-r1,p.y);
  return length(q)-r2;
}

float torus(vec3 p, vec3 pos, mat3 rot, float r1, float r2) {
    return torus(applyTransform(p, pos, rot), r1, r2);
}

Hit torus(vec3 p, vec3 pos, mat3 rot, float r1, float r2, vec3 n, uint matID) {
    Hit ret;
    ret.d       = torus(p, pos, rot, r1, r2);
    ret.pos     = p;
    ret.rfp     = pos;
    ret.rfr     = rot;
    ret         = getMaterial(ret, n, matID); 
    return ret;
}

// Link

float link( vec3 p, float le, float r1, float r2 ) {
    vec3 q = vec3( p.x, max(abs(p.y)-le,0.0), p.z );
    return length(vec2(length(q.xy)-r1,q.z)) - r2;
}

float link(vec3 p, vec3 pos, mat3 rot, float le, float r1, float r2) {
    return link(applyTransform(p, pos, rot), le, r1, r2);
}

Hit link(vec3 p, vec3 pos, mat3 rot, float le, float r1, float r2, vec3 n, uint matID) {
    Hit ret;
    ret.d       = link(p, pos, rot, le, r1, r2);
    ret.pos     = p;
    ret.rfp     = pos;
    ret.rfr     = rot;
    ret         = getMaterial(ret, n, matID); 
    return ret;
}

// Cone

float cone(vec3 p, vec2 q) {
    // c is the sin/cos of the angle, h is height
    // Alternatively pass q instead of (c,h),
    // which is the point at the base in 2D

    vec2 w = vec2( length(p.xz), p.y );
    vec2 a = w - q*clamp( dot(w,q)/dot(q,q), 0.0, 1.0 );
    vec2 b = w - q*vec2( clamp( w.x/q.x, 0.0, 1.0 ), 1.0 );
    float k = sign( q.y );
    float d = min(dot( a, a ),dot(b, b));
    float s = max( k*(w.x*q.y-w.y*q.x),k*(w.y-q.y)  );
    return sqrt(d)*sign(s);
}

float cone(vec3 p, vec3 pos, mat3 rot, float r, float h) {
    return cone(applyTransform(p, pos, rot), vec2(r, -h));
}

Hit cone(vec3 p, vec3 pos, mat3 rot, float r, float h, vec3 n, uint matID) {
    Hit ret;
    ret.d       = cone(p, pos, rot, r, h);
    ret.pos     = p;
    ret.rfp     = pos;
    ret.rfr     = rot;
    ret         = getMaterial(ret, n, matID); 
    return ret;
}

// Capsule 

float capsule( vec3 p, float r, float h ) {
    p.y -= clamp( p.y, 0.0, h );
    return length( p ) - r;
}

float capsule(vec3 p, vec3 pos, mat3 rot, float r, float h) {
    return capsule(applyTransform(p, pos, rot), r, h);
}

Hit capsule(vec3 p, vec3 pos, mat3 rot, float r, float h, vec3 n, uint matID) {
    Hit ret;
    ret.d       = capsule(p, pos, rot, r, h);
    ret.len     = 0.0;
    ret.pos     = p;
    ret.rfp     = pos;
    ret.rfr     = rot;
    ret         = getMaterial(ret, n, matID); 
    return ret;
}

// Cylinder

float cylinder( vec3 p, float r, float h ) {
    vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float cylinder(vec3 p, vec3 pos, mat3 rot, float r, float h) {
    return cylinder(applyTransform(p, pos, rot), r, h);
}

Hit cylinder(vec3 p, vec3 pos, mat3 rot, float r, float h, vec3 n, uint matID) {
    Hit ret;
    ret.d       = cylinder(p, pos, rot, r, h);
    ret.pos     = p;
    ret.rfp     = pos;
    ret.rfr     = rot;
    ret         = getMaterial(ret, n, matID); 
    return ret;
}

// Octahedron

float octahedron( vec3 p, float s ) {

  p = abs(p);
  float m = p.x+p.y+p.z-s;
  vec3 q;
       if( 3.0*p.x < m ) q = p.xyz;
  else if( 3.0*p.y < m ) q = p.yzx;
  else if( 3.0*p.z < m ) q = p.zxy;
  else return m*0.57735027;
    
  float k = clamp(0.5*(q.z-q.y+s),0.0,s); 
  return length(vec3(q.x,q.y-s+k,q.z-k)); 

}

float octahedron(vec3 p, vec3 pos, mat3 rot, float s) {
    return octahedron(applyTransform(p, pos, rot), s);
}

Hit octahedron(vec3 p, vec3 pos, mat3 rot, float s, vec3 n, uint matID) {
    Hit ret;
    ret.d       = octahedron(p, pos, rot, s);
    ret.len     = 0.0;
    ret.pos     = p;
    ret.rfp     = pos;
    ret.rfr     = rot;
    ret         = getMaterial(ret, n, matID); 
    return ret;
}

// Ellipsoid

float ellipsoid( vec3 p, vec3 r ) {
  float k0 = length(p/r);
  float k1 = length(p/(r*r));
  return k0*(k0-1.0)/k1;
}

float ellipsoid(vec3 p, vec3 pos, mat3 rot, vec3 b ) {
    return ellipsoid(applyTransform(p, pos, rot), b);
}

Hit ellipsoid(vec3 p, vec3 pos, mat3 rot, vec3 b, vec3 n, uint matID) {
    Hit ret;
    ret.d       = ellipsoid(p, pos, rot, b);
    ret.len     = 0.0;
    ret.pos     = p;
    ret.rfp     = pos;
    ret.rfr     = rot;
    ret         = getMaterial(ret, n, matID); 
    return ret;
}

float slope(vec3 p, vec3 pos, vec3 normal) {
    return dot((p - pos), normal);
}

Hit slope(vec3 p, vec3 pos, vec3 normal, vec3 n, uint matID) {
    Hit ret;
    ret.d       = slope(p, pos, normal);
    ret.pos     = p;
    ret.rfp     = pos;
    ret.rfr     = mat3(1);
    ret         = getMaterial(ret, n, matID);
    return ret;
}

Hit toHit(float d, vec3 p, vec3 rfp, mat3 rfr, vec3 n, uint matID) {
    Hit ret;
    ret.d       = d;
    ret.pos     = p;
    ret.rfp     = rfp;
    ret.rfr     = rfr;
    ret         = getMaterial(ret, n, matID);
    return ret;
}

// Unary operators

Hit displace(Hit h, float d) {
    h.d   -= d;
    return h;
}

// CSG Operations

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

Hit morph(Hit a, Hit b, float k) {
    Hit r;

    r.d     = mix(b.d, a.d, k);
    r       = blendMaterials(r, a, b, k);

    return r;
}

Hit changeMaterial(Hit a, vec3 n, uint matID) {
    a = getMaterial(a, n, matID);
    return a;
}

// polynomial smooth‑min helper
float smin(float d1, float d2, float k, out float h)
{
    h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

float union_(float a, float b) {
    return (a < b) ? a : b;
}

float union_(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

Hit union_(Hit a, Hit b) {
    return (a.d < b.d) ? a : b;
}

Hit union_(Hit a, Hit b, float k) {

    // 1) choose the winner by raw distance
    Hit r = (a.d < b.d) ? a : b;
    
    // 2) compute the blended distance (also get blend factor h)
    float     hBlend;
    r.d     = smin(a.d, b.d, k, hBlend);

    r = blendMaterials(r, a, b, hBlend);

    // r.hit, r.pos, r.len remain intact, so the marcher keeps working
    return r;
}

float smax(float d1, float d2, float k, out float h) {
    h = clamp(0.5 - 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) + k * h * (1.0 - h);
}

float subtract(float a, float b) {
    return (a > -b) ? a : b;
}

float subtract(float a, float b, float k) {
    float h = clamp(0.5 - 0.5 * (-b - a) / k, 0.0, 1.0);
    return mix(-b, a, h) + k * h * (1.0 - h);
}

Hit subtract(Hit a, Hit b) {
    Hit r = (a.d > -b.d) ? a : b;
    r.d = max(a.d, -b.d);
    return r;
}

Hit subtract(Hit a, Hit b, float k) {

    Hit r = (a.d > -b.d) ? a : b; // Choose the winner by raw distance for initial guess

    float hBlend;
    // The smooth maximum for a and -b.d
    r.d = smax(a.d, -b.d, k, hBlend);

    r = blendMaterials(r, a, b, hBlend);

    return r;
}

float intersect(float a, float b) {
    return (a > b) ? a : b;
}

float intersect(float a, float b, float k) {
    float h = clamp(0.5 - 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) + k * h * (1.0 - h);
}

Hit intersect(Hit a, Hit b) {
    return (a.d > b.d) ? a : b;
}

Hit intersect(Hit a, Hit b, float k) {
    
    Hit r = (a.d > b.d) ? a : b; // Choose the winner by raw distance for initial guess

    float hBlend;
    // The smooth maximum for a and -b.d
    r.d = smax(a.d, b.d, k, hBlend);

    r = blendMaterials(r, a, b, hBlend);

    return r;
}

Hit color(Hit a, Hit b, float k, vec3 n) {

    Hit ab      = changeMaterial(a, n, b.matID);
    Hit area    = intersect(a,  b);

    float d;
    if(k == 0) d = area.d < epsilon? 1 : 0;
    else
        d = (area.d >= epsilon)? clamp(k - area.d, 0, k)/k : 1;

    return morph(ab, a, d);
}

float joint(float a, float b, float c, float k) {
    k = (c >= epsilon)? clamp(k - c, k, 0) : k;
    return union_(union_(a, c), b, k);
}

Hit joint(Hit a, Hit b, Hit c, float k) {
    k = (c.d >= epsilon)? clamp(k - c.d, k, 0) : k;
    return union_(union_(a, c), b, k);
}

/*
    THIS IS PROOF THAT:
        ·   From slopes complex meshes can be rendered

    This shader code will be ported to c++ in a way that, using pragmas, the compiler will produce:
        ·   glsl code
        ·   opencl code
        ·   cuda code
        ·   rocm code
        ·   openVINO code for intel NPUs
        ·   code for NVIDIA NPUs
    
    Or syncrhonized combinations of these

*/

// n equals the normal, if calculated. if n != 0, then material functions must be executed
Hit scene(vec3 p, vec3 n){

    /*
	float   a = slope(p, vec3(0, 1, 2), vec3(0, 1, 0)),
            b = slope(p, vec3(0, 0, 1), vec3(0, 0,-1)),
            c = slope(p, vec3(0, 0, 2), vec3(0,-1, 0)),
            d = slope(p, vec3(0, 0, 2), vec3(0, 0, 1)),
            e = slope(p, vec3(0, 0, 2), vec3(-1,0, 0)),
            f = slope(p, vec3(1, 0, 2), vec3(1, 0, 0));

    float k = 0.1;

    float dst;
    dst = intersect(a,   b, k);
    dst = intersect(dst, c, k);
    dst = intersect(dst, d, k);
    dst = intersect(dst, e, k);
    dst = intersect(dst, f, k);

	return toHit(dst, p, vec3(0), mat3(1), 3u);
    */

    Hit     a   = box(p, vec3(0.6, 1, 0.25), mat3(1), vec3(0.3), n, 1u),
            b   = sphere(p, vec3(0.2, 1, 0.25), 0.2, n, 2u),
            c   = union_(a, b, 0.3);

    float   fa  = box(p, vec3(0.6, 1, -0.25), mat3(1), vec3(0.3)),
            fb  = sphere(p, vec3(0.2, 1, -0.25), 0.2),
            fc  = union_(fa, fb, 0.3);
    
    Hit     cc  = toHit(fc, p, vec3(0, 0, 0.25), mat3(1), n, 3u);

    Hit     gr  = ground(p, 0, n, 4u);

    return union_(gr, union_(c, cc, 0.1));
}

// Raymarching loop
Hit raymarch(vec3 ro, vec3 rd) {

    const vec2 e = vec2(epsilon, 0.0);

    Hit h, h1, h2, h3, h4, h5, h6;

    float t = 0.0;

    for (int i = 0; i < 512 && t < maxDistance; ++i) {

        vec3 p = ro + rd * t;

        h  = scene(p, vec3(0, 0, 0));

        if (h.d < epsilon) {

            h1 = scene(p + e.xyy, vec3(0, 0, 0));
            h2 = scene(p - e.xyy, vec3(0, 0, 0));

            h3 = scene(p + e.yxy, vec3(0, 0, 0));
            h4 = scene(p - e.yxy, vec3(0, 0, 0));

            h5 = scene(p + e.yyx, vec3(0, 0, 0));
            h6 = scene(p - e.yyx, vec3(0, 0, 0));

            vec3 normal = normalize(vec3(h1.d - h2.d, h3.d - h4.d, h5.d - h6.d));

            h = scene(p, normal);

            h.dir = normalize(-rd);
            h.len = t;
            h.hit = true;

            return h;
        }
            
        t += h.d;
    }

    h.hit = false;

    return h; // background
}

Hit neg_scene(vec3 p, vec3 n) {
    Hit ret = scene(p, n);
    ret.d = -ret.d;
    return ret;
}

// Raymarching loop within objects for transparency
Hit reverse_raymarch(vec3 ro, vec3 rd) {

    const vec2 e = vec2(epsilon, 0.0);

    Hit h, h1, h2, h3, h4, h5, h6;

    float t = 0.0;

    for (int i = 0; i < 512 && t < maxDistance; ++i) {

        vec3 p = ro + rd * t;

        h  = neg_scene(p, vec3(0, 0, 0));

        if (h.d < epsilon) {

            h1 = neg_scene(p + e.xyy, vec3(0, 0, 0));
            h2 = neg_scene(p - e.xyy, vec3(0, 0, 0));

            h3 = neg_scene(p + e.yxy, vec3(0, 0, 0));
            h4 = neg_scene(p - e.yxy, vec3(0, 0, 0));

            h5 = neg_scene(p + e.yyx, vec3(0, 0, 0));
            h6 = neg_scene(p - e.yyx, vec3(0, 0, 0));

            vec3 normal = normalize(vec3(h1.d - h2.d, h3.d - h4.d, h5.d - h6.d));

            h = neg_scene(p, normal);

            h.dir = normalize(-rd);
            h.len = t;
            h.hit = true;

            return h;
        }
            
        t += h.d;
    }

    h.hit = false;

    return h; // background
}

struct Light {
    vec3    col;    //  color
    bool    point;  //  false = directional, true = point
    vec3    vec;    //          Direction           Position
    float   str;    //  Strength
    float   amb;    //  Ambient 
};

vec3 clampv01(vec3 v) {
    return vec3(clamp(v.x, 0, 1), clamp(v.y, 0, 1), clamp(v.z, 0, 1));
}

// Basic lighting
vec3 phong(vec3 col, Hit h, Light l, vec3 viewDir) {

    // If the light is a point, the light direction is the difference between the light position and hit position
    vec3 vec = l.point? normalize(h.pos - l.vec) : l.vec;

    vec3 ambient = col * (l.amb);

    float diff = max(dot(h.normal, -vec), 0.0);
    vec3 diffuse = col * diff;

    vec3 reflectDir = reflect(vec, h.normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0), h.shn);
    vec3 specular = h.spc * vec3(spec); // white highlight

    return (ambient + diffuse + specular) * l.col * l.str;
}

//Process all lights
vec3 lighting(Hit h, Light ls[nLights], vec3 viewDir) {

    vec3 col = vec3(0.0);

    // All colors must be added
    for (uint i = 0u; i < nLights; ++i) {
        float s = ls[i].str;
        if (s > 0.0) {
            vec3 contrib = phong(h.col, h, ls[i], viewDir) * s;
            col += contrib;
        }
    }

    return col;
}

vec3 shadow(vec3 col, Hit h, Light l) {

    vec3 vec = l.point? normalize(h.pos - l.vec) : l.vec;

    Hit shd = raymarch(h.pos + h.normal * epsilon * 2, -vec);

    float d = dot(h.normal, vec);

    if(d < 0 && shd.hit && (shd.len < length(h.pos - l.vec) || !l.point)) {
        vec3 sc = col*(1+d);
        col = mix(sc, col, l.amb);
    }

    return col;

}

vec3 shadows(vec3 col, Hit h, Light ls[nLights]) {

    for(uint i = 0u; i < nLights; ++i)
        col = shadow(col, h, ls[i]);

    return col;
}

vec3 basic_shading(Hit hit, Light ls[nLights], vec3 viewDir) {

    //Line thickness
    if(abs(dot(viewDir, hit.normal)) < hit.lth) return hit.lco;

    vec3 col = hit.col;
    // Add lighting
    col = lighting(hit, ls, viewDir);

    return col;
}

//vec3 get_reflection(Hit hit, Light ls[nlights], vec3 viewDir)

vec4 render(vec3 ro, vec3 rd, Light ls[nLights]) {

    vec3 viewDir = normalize(-rd);

    Hit hit = raymarch(ro, rd);

    // The skybox (when theres no hit, it renders the skybox, there's nothing to shadow or reflect there)
    if(hit.hit) {

        //return vec4(vec3(mix(vec3(0.5), vec3(1), dot(viewDir, hit.normal))), 1.) * vec4(hit.col, 1.);

        vec3 col = basic_shading(hit, ls, viewDir);

        if(col == hit.lco) return vec4(col, 1);

        if(hit.ref > 0) {

            // Calculate reflection on the first iteration
            vec3 refDir = reflect(rd, hit.normal);
            Hit ref     = raymarch(hit.pos + hit.normal * epsilon * 2., refDir);

            // Apply first iteration reflection + shading + line thickness
            
            vec3 rcol;
            
            if(ref.hit) rcol = basic_shading(ref, ls, viewDir);
            else rcol = world(ref).col;

            col         = mix(col, rcol, hit.ref);

            // Final reflection value
            float fref  = hit.ref;

            // Apply every iteration
            for(uint i = 1u; i <= imax; ++i) {

                if(!ref.hit) break;

                refDir  = reflect(refDir, ref.normal);
                ref     = raymarch(ref.pos + ref.normal * epsilon * 2., refDir);

                if(ref.hit) {
                    viewDir = normalize(ref.pos - ro);
                    bool line = abs(dot(refDir, ref.normal)) < ref.lth;
                    ref.col = line? ref.lco :lighting(ref, ls, viewDir);
                    ref.col = shadows(ref.col, ref, ls);
                } else ref = world(ref);

                fref   *= ref.ref;

                col     = mix(col, rcol, fref);

            }

        } 

        // Get projected shadow from other objects
        col = shadows(col, hit, ls);

        return vec4(col, 1.0);

    }

    return vec4(world(hit).col, 1.);

}

void main() {

    vec2 uv = vec2(1 - fragTexCoord.x, fragTexCoord.y);

    vec2 normCoord = (2.0 * (vec2(1) - uv) * u_resolution - u_resolution) / u_resolution.y;

    vec3 ro = camera_pos;
    vec3 rd = rotationFromEuler(camera_rot) * normalize(vec3(normCoord * fov, 1.0));


    Light ls[nLights] = Light[](
        Light(vec3(1.0, 1.0, 1.0), 
        false, 
        normalize(vec3(0.75, -1, 0.3)), 
        0.9,
        0.6)
    );

    finalColor = render(ro, rd, ls);
}