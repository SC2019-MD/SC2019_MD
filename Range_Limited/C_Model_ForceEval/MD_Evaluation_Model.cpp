#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <time.h>
#include <string>
#include <fstream>
#include <ctime>

int MD_Evaluation_Model(){

	int NUM_ITERATION = 100;

	// Argon
	float kb = 1.380e-23;									// Boltzmann constant (J/K)
	float Nav = 6.022e23;									// Avogadro constant, # of atoms per mol
	float Ar_weight = 39.95;								// g/mol value of Argon atom
	float EPS = 1.995996 * 1.995996;//0.996;										// Unit: kJ
	float SIGMA = 0.1675*2;//3.35;//3.4;								// Unit Angstrom
	float SIGMA_12 = pow(SIGMA,12);
	float SIGMA_6 = pow(SIGMA,6);
	float MASS = Ar_weight / Nav / 1000;					// Unit kg
	float SIMULATION_TIME_STEP = 2E-15;						// 2 femtosecond
	float CUTOFF_RADIUS = 8;								// Unit Angstrom, Cutoff Radius
	float CUTOFF_RADIUS_2 = CUTOFF_RADIUS*CUTOFF_RADIUS;    // Cutoff distance square
	// Dataset parameters
	float bounding_box_x = 24;
	float bounding_box_y = 24;
	float bounding_box_z = 24;
	int TOTAL_PARTICLE_NUM = 500;
	std::string input_file_path = "C:/Users/Ethan/Desktop/WorkingFolder/Ethan_RL_Pipeline_1st_Order_SingleFloat_18.0/SourceCode/MatlabScripts/";
	std::string input_file_name = "ar_gas.pdb";
	std::string input_file_read_path = input_file_path + input_file_name;

	// Particle Array
	float particle[500][11];									// 0~2: posx, posy, posz; 3~5: vx, vy, vz; 6~8: fx, fy, fz; 9: LJ Potential Energy; 10: Kinetic Energy

	
	// Readin particle information
	std::ifstream file(input_file_read_path);
	std::string str;
	float tmp_x, tmp_y, tmp_z;
	// Discard the unwanted lines
	for(int i = 0; i < 5; i++){
		std::getline(file, str);
	}
	for(int i = 0; i < TOTAL_PARTICLE_NUM; i++){
		std::getline(file, str);
		sscanf(str.c_str(), "%*s %*s %*s %*s %*s %*s %f %f %f", &tmp_x, &tmp_y, &tmp_z);
		particle[i][0] = tmp_x;
		particle[i][1] = tmp_y;
		particle[i][2] = tmp_z;
		particle[i][3] = 0;
		particle[i][4] = 0;
		particle[i][5] = 0;
	};

	for(int iteration_ptr = 0; iteration_ptr < NUM_ITERATION; iteration_ptr++){
		// System energy
		float System_Energy = 0;
		// System kinetic energy
		float System_Kinetic_Energy = 0;
		// Traverse all the particles in the simualtion space
		for(int ref_ptr = 0; ref_ptr < TOTAL_PARTICLE_NUM; ref_ptr++){
			float Evdw_acc = 0;
			float Fx_acc = 0;
			float Fy_acc = 0;
			float Fz_acc = 0;
			float ref_x = particle[ref_ptr][0];
			float ref_y = particle[ref_ptr][1];
			float ref_z = particle[ref_ptr][2];
			int neighbor_particle_num = 0;
			for(int neighbor_ptr = 0; neighbor_ptr < TOTAL_PARTICLE_NUM; neighbor_ptr++){
				// Get r2
				float neighbor_x = particle[neighbor_ptr][0];
				float neighbor_y = particle[neighbor_ptr][1];
				float neighbor_z = particle[neighbor_ptr][2];
				float dx = ref_x - neighbor_x;
				float dy = ref_y - neighbor_y;
				float dz = ref_z - neighbor_z;
				// Apply periodic boundary
				if(dx >= 0){
					dx -= bounding_box_x * (int)(dx/bounding_box_x+0.5);
				}
				else{
					dx -= bounding_box_x * (int)(dx/bounding_box_x-0.5);
				}
				if(dy >= 0){
					dy -= bounding_box_y * (int)(dy/bounding_box_y+0.5);
				}
				else{
					dy -= bounding_box_y * (int)(dy/bounding_box_y-0.5);
				}
				if(dz >= 0){
					dz -= bounding_box_z * (int)(dz/bounding_box_z+0.5);
				}
				else{
					dz -= bounding_box_z * (int)(dz/bounding_box_z-0.5);
				}
				float r2 = dx*dx + dy*dy + dz*dz;
				// Apply cutoff
				if(r2 > 0 && r2 <= CUTOFF_RADIUS_2){
					neighbor_particle_num++;
					//// Potential Energy
					float inv_r2 = 1 / r2;
					float inv_r8 = pow(inv_r2, 4);
					float inv_r14 = pow(inv_r2, 7);
					float inv_r6 = pow(inv_r2, 3);
					float inv_r12= pow(inv_r2, 6);
					float vdw12 = 4 * EPS * SIGMA_12 * inv_r12;
					float vdw6 = 4 * EPS * SIGMA_6 * inv_r6;
					float vdw14 = 48 * EPS * SIGMA_12 * inv_r14;
					float vdw8  = 24 * EPS * SIGMA_6  * inv_r8;
					// LJ Force and Energy
					float Fvdw = vdw14 - vdw8;
					float Evdw = vdw12 - vdw6;
					// Accumualte Force
					Fx_acc += Fvdw * dx;
					Fy_acc += Fvdw * dy;
					Fz_acc += Fvdw * dz;
					// Accumulate Energy
					Evdw_acc += Evdw;

				}
			}
			// Record the vdw energy
			particle[ref_ptr][9] = Evdw_acc;
			// Record the force value
			particle[ref_ptr][6] = Fx_acc;
			particle[ref_ptr][7] = Fy_acc;
			particle[ref_ptr][8] = Fz_acc;

			//// Evaluate Kinetic Energy
			float acceleration_x = Fx_acc / MASS;
			float acceleration_y = Fy_acc / MASS;
			float acceleration_z = Fz_acc / MASS;
			// Velocity
			float vx = particle[ref_ptr][3];
			float vy = particle[ref_ptr][4];
			float vz = particle[ref_ptr][5];
			vx += acceleration_x * SIMULATION_TIME_STEP;
			vy += acceleration_y * SIMULATION_TIME_STEP;
			vz += acceleration_z * SIMULATION_TIME_STEP;
			// Kinetic energy
			float Eknetic = 0.5 * MASS * (vx*vx + vy*vy +vz*vz);
			// Write back Kinetic energy
			particle[ref_ptr][10] = Eknetic;
			// Write back new velocity
			particle[ref_ptr][3] = vx;
			particle[ref_ptr][4] = vy;
			particle[ref_ptr][5] = vz;

			// Accumualte to System total energy
			//System_Energy += Evdw_acc + Eketic;
			System_Energy += Evdw_acc;
			System_Kinetic_Energy += Eknetic;
		}

		System_Energy *= 0.5;		// LJ potential should only count once towards both particles
		printf("Iteration %d, System energy is %f, Kinetic Energy is %f\n", iteration_ptr, System_Energy,System_Kinetic_Energy);

		/*****************************************
		// Motion update here
		*****************************************/
		for(int i = 0; i < TOTAL_PARTICLE_NUM; i++){
			float posx = particle[i][0];
			float posy = particle[i][1];
			float posz = particle[i][2];
			float vx = particle[i][3];
			float vy = particle[i][4];
			float vz = particle[i][5];
			posx += vx * SIMULATION_TIME_STEP;
			posy += vy * SIMULATION_TIME_STEP;
			posz += vz * SIMULATION_TIME_STEP;
			// Apply periodic boundary
			if(posx < 0){
				posx += bounding_box_x;
			}
			else if(posx >= bounding_box_x){
				posx -= bounding_box_x;
			}
			if(posy < 0){
				posy += bounding_box_y;
			}
			else if(posy >= bounding_box_y){
				posy -= bounding_box_y;
			}
			if(posz < 0){
				posz += bounding_box_z;
			}
			else if(posz >= bounding_box_z){
				posz -= bounding_box_z;
			}

			// Write back position and velocity
			particle[i][0] = posx;
			particle[i][1] = posy;
			particle[i][2] = posz;
			// Clear force value
			particle[i][6] = 0;
			particle[i][7] = 0;
			particle[i][8] = 0;
		}
	}
	return 1;
}