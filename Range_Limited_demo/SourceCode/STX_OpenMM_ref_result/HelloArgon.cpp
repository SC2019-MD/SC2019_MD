// -----------------------------------------------------------------------------
//           OpenMM(tm) HelloArgon example in C++ (June 2009)
// -----------------------------------------------------------------------------
// This program demonstrates a simple molecular simulation using the OpenMM
// API for GPU-accelerated molecular dynamics simulation. The primary goal is
// to make sure you can compile, link, and run with OpenMM and view the output.
// The example is available in C++, C, and Fortran 95.
//
// The system modeled here is a small number of argon atoms in a vacuum.
// A multi-frame PDB file is written to stdout which  can be read by VMD or 
// other visualization tool to produce an animation of the resulting trajectory.
// -----------------------------------------------------------------------------

#include "OpenMM.h"
#include <cstdio>
#include <fstream>
#include<iostream>
// Forward declaration of routine for printing one frame of the
// trajectory, defined later in this source file.
void writePdbFrame(int frameNum, const OpenMM::State&,const OpenMM::State&);

void simulateArgon(char* fileName, int numatoms, int nsteps)
{
    // Load any shared libraries containing GPU implementations.
  std::ifstream infile(fileName);
  OpenMM::Platform::loadPluginsFromDirectory(
        OpenMM::Platform::getDefaultPluginsDirectory());

    // Create a system with nonbonded forces.
    OpenMM::System system;
    OpenMM::NonbondedForce* nonbond = new OpenMM::NonbondedForce(); 
    system.addForce(nonbond);
    float x,y,z;

    std::vector<OpenMM::Vec3> initPosInNm(numatoms);
    int a=0;
    std::cout<<"INITIAL COORDINATES"<<std::endl;
    while(infile >> x  >> y >> z)
      {
	
	std::cout<<"("<<x<<","<<y<<","<<z<<")"<<std::endl;

	initPosInNm[a++] = OpenMM::Vec3(x,y,z); 
	system.addParticle(39.95);
	nonbond->addParticle(0.0, 0.3350, 0.996);
      }
    
    // Create three atoms.
#if 0
    for (int a = 0; a < numatoms; ++a) 
    {
        
      // initPosInNm[a] = OpenMM::Vec3(0.5*a,0,0); // location, nm

        system.addParticle(39.95); // mass of Ar, grams per mole

        // charge, L-J sigma (nm), well depth (kJ)
        nonbond->addParticle(0.0, 0.3350, 0.996); // vdWRad(Ar)=.188 nm
    }
#endif
    OpenMM::VerletIntegrator integrator(0.004); // step size in ps

    // Let OpenMM Context choose best platform.
    OpenMM::Context context(system, integrator);
    printf( "REMARK  Using OpenMM platform %s\n", 
        context.getPlatform().getName().c_str() );

    // Set starting positions of the atoms. Leave time and velocity zero.
    context.setPositions(initPosInNm);

    // Simulate.
    for (int frameNum=1; frameNum<=nsteps;frameNum++) {
        // Output current state information.
      OpenMM::State state1    = context.getState(OpenMM::State::Positions);
      OpenMM::State state2    = context.getState(OpenMM::State::Energy);
      //        const double  timeInPs = state.getTime();
        writePdbFrame(frameNum, state1,state2); // output coordinates

	//        if (timeInPs >= 10.)
	//  break;

        // Advance state many steps at a time, for efficient use of OpenMM.
        integrator.step(10); // (use a lot more than this normally)
    }
}

int main(int argc, char** argv) 
{

  if(argc!=3)
    {
      std::cout<<"Usage: ./HelloArgon <file of atoms> <nsteps>"<<std::endl;
      exit(1);
    }

  int number_of_lines = 0;
  std::string line;
  std::ifstream myfile(argv[1]);
  int nsteps = atoi(argv[2]);
    while (std::getline(myfile, line))
        ++number_of_lines;
    std::cout << "Number of atoms in pdb file: " << number_of_lines<<std::endl;

    try {
      simulateArgon(argv[1],number_of_lines,nsteps);
        return 0; // success!
    }
    // Catch and report usage and runtime errors detected by OpenMM and fail.
    catch(const std::exception& e) {
        printf("EXCEPTION: %s\n", e.what());
        return 1; // failure!
    }
}

// Handy homebrew PDB writer for quick-and-dirty trajectory output.
void writePdbFrame(int frameNum, const OpenMM::State& state1, const OpenMM::State& state2) 
{
    // Reference atomic positions in the OpenMM State.
  const std::vector<OpenMM::Vec3>& posInNm = state1.getPositions();
    const float energy=state2.getPotentialEnergy();
    // Use PDB MODEL cards to number trajectory frames
#if 1
    printf("MODEL     %d\n", frameNum); // start of frame
    for (int a = 0; a < (int)posInNm.size(); ++a)
    {
        printf("ATOM  %5d  AR   AR     1    ", a+1); // atom number
        printf("%8.3f%8.3f%8.3f  1.00  0.00\n",      // coordinates
            // "*10" converts nanometers to Angstroms
            posInNm[a][0]*10, posInNm[a][1]*10, posInNm[a][2]*10);

    }
#endif
    printf("Energy: %.8f\n",energy);
    printf("ENDMDL\n"); // end of frame
}
