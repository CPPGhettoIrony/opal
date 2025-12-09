#ifndef _MATERIALS_CUH
#define _MATERIALS_CUH

#include "hit.cuh"

__host__ __device__
void world(Hit& h);

__host__ __device__
void getMaterial(Hit& h, vec3 norm, uint matID);

#endif