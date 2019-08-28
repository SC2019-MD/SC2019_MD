// Copyright (C) 2013-2018 Altera Corporation, San Jose, California, USA. All rights reserved.
// Permission is hereby granted, free of charge, to any person obtaining a copy of this
// software and associated documentation files (the "Software"), to deal in the Software
// without restriction, including without limitation the rights to use, copy, modify, merge,
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to
// whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
// 
// This agreement shall be governed in all respects by the laws of the State of California and
// by the laws of the United States of America.

 // ACL kernel for adding two input vectors
// __kernel void vector_add(__global const float *x, 
//                         __global const float *y, 
//                         __global float *restrict z)

//#define WORKSIZE 5

__kernel void LJ(
			__global const int *restrict ref_id,
			__global const int *restrict neighbor_id, 
			__global const float *restrict ref_x, 
            __global const float *restrict ref_y, 
            __global const float *restrict ref_z,
			//__global const int2 *restrict particle_id,
            //__global const float4 *restrict ref,
			__global const float *restrict neighbor_x,
			__global const float *restrict neighbor_y,
			__global const float *restrict neighbor_z,
			//__global const float4 *restrict neighbor,
			//__global float4 *restrict Force_out,
			__global float *restrict Force_out_x,
			__global float *restrict Force_out_y,
			__global float *restrict Force_out_z
			)
{
	int2 particle_id;
	float4 ref, neighbor;
	float4 Force_out;
	
	unsigned i = get_global_id(0);
	
//	#pragma unroll 1
//	for (int i = 0; i < WORKSIZE; ++i){
	particle_id.x = ref_id[i];
	particle_id.y = neighbor_id[i];
	ref.x = ref_x[i];
	ref.y = ref_y[i];
	ref.z = ref_z[i];
	ref.w = 0;
	neighbor.x = neighbor_x[i];
	neighbor.y = neighbor_y[i];
	neighbor.z = neighbor_z[i];
	neighbor.w = 0;
	
	printf("PID %d: Ref Particle ID:%d, Neighbor Partciel ID: %d, Distance (%f,%f,%f) (%f,%f,%f)\n",i, particle_id.x, particle_id.y, ref.x, ref.y, ref.z, neighbor.x, neighbor.y, neighbor.z);
	
	float dx = ref.x - neighbor.x;
	float dy = ref.y - neighbor.y;
	float dz = ref.z - neighbor.z;
	float r2 = dx*dx + dy*dy + dz*dz;
	printf("PID %d: Distance square is %f\n", i, r2);
	
	float inv_r2 = 1 / r2;
	float inv_r4 = inv_r2 * inv_r2;
	float inv_r8 = inv_r4 * inv_r4;
	float inv_r14 = inv_r8 * inv_r4 * inv_r2;
	
	float LJ_Force = 48*inv_r14 - 24*inv_r8;
	
	printf("PID %d: Total force is %e\n", i, LJ_Force);
	
	Force_out_x[i] = LJ_Force * dx;
	Force_out_y[i] = LJ_Force * dy;
	Force_out_z[i] = LJ_Force * dz;
	
//	}
}

