float4 RL_LJ_Evaluation(int2 particle_id, float4 reference_pos, float4 neighbor_pos)
{
	
  //	printf("Disclaimer: This emulation model just serve as a place holder provided by Chen Yang, the results may not 100% reflects the on board running result!\n");
	// the logic here is not what the custom func is doing, don't use this result for verification
	printf("Ref Particle ID:%d, Neighbor Partciel ID: %d, Distance (%f,%f,%f) (%f,%f,%f)\n",particle_id.x, particle_id.y, reference_pos.x,reference_pos.y,reference_pos.z,neighbor_pos.x,neighbor_pos.y,neighbor_pos.z);
	float dx = reference_pos.x - neighbor_pos.x;
	float dy = reference_pos.y - neighbor_pos.y;
	float dz = reference_pos.z - neighbor_pos.z;
	float r2 = dx*dx + dy*dy + dz*dz;
	
	printf("Distance square is %f\n", r2);
	
	float inv_r2 = 1 / r2;
	float inv_r4 = inv_r2 * inv_r2;
	float inv_r8 = inv_r4 * inv_r4;
	float inv_r14 = inv_r8 * inv_r4 * inv_r2;
	
	float LJ_Force = 48*inv_r14 - 24*inv_r8;
	
	printf("Total force is %e\n", LJ_Force);
	
	float LJ_Force_x = LJ_Force * dx;
	float LJ_Force_y = LJ_Force * dy;
	float LJ_Force_z = LJ_Force * dz;
	
	float4 LJ_Force_Components = (float4){LJ_Force_x, LJ_Force_y, LJ_Force_z,0.0f};
	
	printf("Evaluated force components are %e, %e, %e\n", LJ_Force_x, LJ_Force_y, LJ_Force_z);
	
	return LJ_Force_Components;
}