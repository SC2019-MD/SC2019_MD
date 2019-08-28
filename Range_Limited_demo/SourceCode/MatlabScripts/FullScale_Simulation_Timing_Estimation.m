%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Full scale simulation for the LJArgon Dataset
% Input dataset is LJArgon
% Perform force evaluation and energy evaluation for verification
% 
% Function:
%       Generate on-chip RAM initialization file (*.mif)
%       Generate simulation verification file
%
% Cell Mapping: ApoA1, follow the HDL design (cell id starts from 1 in each dimension)
%       Filter 0: 222(home)
%       Filter 1: 223(face)
%       Filter 2: 231(edge) 232(face)
%       Filter 3: 233(edge) 311(corner)
%       Filter 4: 312(edge) 313(corner)
%       Filter 5: 321(edge) 322(face)
%       Filter 6: 323(edge) 331(corner)
%       Filter 7: 332(edge) 333(corner)
%
% Data Organization in array:
%       1, posx; 2, posy; 3, posz
%
% Process:
%       0, Run LJArgon_Position_Data_Analyze, find the min and max value of the r2, based on that to generate the lookup table
%       1, Run LJ_no_smooth_poly_interpolation_accuracy, to generate the interpolation file
%       2, import the raw LJArgon data, and pre-processing
%       3, mapping the LJArgon data into cells
%
% Output file:
%       VERIFICATION_PARTICLE_PAIR_INPUT.txt (Particle_Pair_Gen_HalfShell.v)
%       VERIFICATION_PARTICLE_PAIR_DISTANCE_AND_FORCE.txt (RL_LJ_Top.v)
%       VERIFICATION_PARTICLE_PAIR_NEIGHBOR_ACC_FORCE.txt (RL_LJ_Top.v)             % Verify the accumulated neighbor particle force after each reference particle
%
% By: Chen Yang
% 10/29/2018
% Boston University, CAAD Lab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;

START_TIME = cputime;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Simulation Control Parameter
ENABLE_VERIFICATION = 0;                            % Enable verification for a certain reference particle
ENERGY_EVALUATION_STEPS = 10;                       % Every few iterations, evaluate energy once
CONSIDER_MOTION_UPDATE_TIME = 0;                    % Consider the motion update delay
%% Dataset Parameters
SIMULATION_TIME_STEP = 2E-15;                       % 2 femtosecond
CUTOFF_RADIUS = single(7.65);                       % Unit Angstrom, Cutoff Radius
CELL_COUNT_X = 7;
CELL_COUNT_Y = 7;
CELL_COUNT_Z = 7;
TOTAL_CELL_COUNT = CELL_COUNT_X * CELL_COUNT_Y * CELL_COUNT_Z;
%TOTAL_CELL_COUNT = 125;
TOTAL_PARTICLE = 23588;                             % particle count in benchmark
COMMON_PATH = '';
%INPUT_FILE_NAME = 'input_positions_ljargon.txt';
AVG_PARTICLE_PER_CELL = ceil(TOTAL_PARTICLE / TOTAL_CELL_COUNT);
%% HDL design parameters
NUM_FILTER = 8;                                     % Number of filters in the pipeline
FILTER_BUFFER_DEPTH = 32;                           % Filter buffer depth, if buffer element # is larger than this value, pause generating particle pairs into filter bank
NUM_PIPELINES = 90;
NUM_MOTION_UPDATE = 1;                              % Units for motion update
NUM_NEIGHBOR_CELLS = 13;                            % Neighbor cells
%% Pipeline Timing
FREQUENCY = 350;                                    % Unit MHz
MOTION_UPDATE_FREQUENCY = 357;                      % Unit MHz
SHORT_RANGE_LATENCY = 42;                           % Cycles
MOTION_UPDATE_LATENCY = 14;                         % Cycles
ADDER_TREE_LATENCY = 7;
MUX_TREE_LATENCY = 3;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Extact workload from the input dataset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%max_particle_per_cell = max(particle_in_cell_counter(:));
particles_within_cutoff = ceil(0.5 * AVG_PARTICLE_PER_CELL * (4/3*pi));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Design 1: MEM1 + Distribute1: All pipelines working on same reference particle, with Global Memory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NUM_PIPELINES = 52
NUM_MOTION_UPDATE = 10;                              % Units for motion update
FREQUENCY = 352;                                    % Unit MHz
%% Short range time per iteration
% Readout 14 cells particles and send to one of the 100 input caches on each pipeline
initial_cycles_fill_input_cache = (NUM_NEIGHBOR_CELLS+1) * AVG_PARTICLE_PER_CELL;       % Unit: cycles
% Determine how many reference particles each pipeline get
neighbor_particle_per_pipe = ceil((NUM_NEIGHBOR_CELLS+1) * AVG_PARTICLE_PER_CELL / NUM_PIPELINES);
% run cycles for each refernce particle
run_cycles_per_reference_particle = ceil(particles_within_cutoff/NUM_PIPELINES);
% Total evaluation time (depends which one take longer, runtime, or loading data time)
if initial_cycles_fill_input_cache < run_cycles_per_reference_particle*AVG_PARTICLE_PER_CELL
    short_range_iteration_cycles = run_cycles_per_reference_particle * TOTAL_PARTICLE + SHORT_RANGE_LATENCY + initial_cycles_fill_input_cache+MUX_TREE_LATENCY+ADDER_TREE_LATENCY;
else
    short_range_iteration_cycles = initial_cycles_fill_input_cache * TOTAL_PARTICLE + SHORT_RANGE_LATENCY + initial_cycles_fill_input_cache+MUX_TREE_LATENCY+ADDER_TREE_LATENCY;
end
short_range_iteration_time = short_range_iteration_cycles / FREQUENCY;    % Unit: us
%% Motion update time per iteration
% Motion update has a throughput of 1
motion_update_cycles = TOTAL_PARTICLE / NUM_MOTION_UPDATE + MOTION_UPDATE_LATENCY;
motion_update_time = motion_update_cycles /MOTION_UPDATE_FREQUENCY;       % Unit: us
%% Total time per iteration
% Walltime per iteration (unit us)
if CONSIDER_MOTION_UPDATE_TIME
    iteration_time = short_range_iteration_time + motion_update_time;
else
    iteration_time = short_range_iteration_time;
end
%% Simulation time per day
day_time = 24*60*60*10^6;               % Unit: us
iterations_per_day = day_time / iteration_time;
% Unit us
Simulation_Period_Per_Day = iterations_per_day * SIMULATION_TIME_STEP * 10^6;
fprintf('MEM1 + Distribute1: Iteration time is %fus, Simulation time per day is %f us\n',iteration_time,Simulation_Period_Per_Day);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Design 2: MEM2 + Distribute1: All pipelines working on same reference particle, with distributed Memory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NUM_PIPELINES = 35;
NUM_MOTION_UPDATE = 10;                              % Units for motion update
FREQUENCY = 338;                                    % Unit MHz
%% Short range time per iteration
% Readout 14 cells particles and send to one of the 100 input caches on each pipeline
initial_cycles_fill_input_cache = (NUM_NEIGHBOR_CELLS+1) * AVG_PARTICLE_PER_CELL / 14;       % Unit: cycles
% Determine how many reference particles each pipeline get
neighbor_particle_per_pipe = ceil((NUM_NEIGHBOR_CELLS+1) * AVG_PARTICLE_PER_CELL / NUM_PIPELINES);
% run cycles for each refernce particle
run_cycles_per_reference_particle = ceil(particles_within_cutoff/NUM_PIPELINES);
% Total evaluation time (depends which one take longer, runtime, or loading data time)
if initial_cycles_fill_input_cache < run_cycles_per_reference_particle*AVG_PARTICLE_PER_CELL
    short_range_iteration_cycles = run_cycles_per_reference_particle * TOTAL_PARTICLE + SHORT_RANGE_LATENCY + initial_cycles_fill_input_cache+MUX_TREE_LATENCY+ADDER_TREE_LATENCY;
else
    short_range_iteration_cycles = initial_cycles_fill_input_cache * TOTAL_PARTICLE + SHORT_RANGE_LATENCY + initial_cycles_fill_input_cache+MUX_TREE_LATENCY+ADDER_TREE_LATENCY;
end
short_range_iteration_time = short_range_iteration_cycles / FREQUENCY;    % Unit: us
%% Motion update time per iteration
% Motion update has a throughput of 1
motion_update_cycles = TOTAL_PARTICLE / NUM_MOTION_UPDATE + MOTION_UPDATE_LATENCY;
motion_update_time = motion_update_cycles /MOTION_UPDATE_FREQUENCY;       % Unit: us
%% Total time per iteration
% Walltime per iteration (unit us)
if CONSIDER_MOTION_UPDATE_TIME
    iteration_time = short_range_iteration_time + motion_update_time;
else
    iteration_time = short_range_iteration_time;
end
%% Simulation time per day
day_time = 24*60*60*10^6;               % Unit: us
iterations_per_day = day_time / iteration_time;
% Unit us
Simulation_Period_Per_Day = iterations_per_day * SIMULATION_TIME_STEP * 10^6;
fprintf('MEM2 + Distribute1: Iteration time is %fus, Simulation time per day is %f us\n',iteration_time,Simulation_Period_Per_Day);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Design 3: MEM1 + Distribute2: All pipelines working on same cell, different reference particle, with global Memory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NUM_PIPELINES = 51;
NUM_MOTION_UPDATE = 10;                              % Units for motion update
FREQUENCY = 343;                                    % Unit MHz
%% Short range time per iteration
% Readout 14 cells particles and send to one of the 100 input caches on each pipeline
initial_cycles_fill_input_cache = (NUM_NEIGHBOR_CELLS+1) * AVG_PARTICLE_PER_CELL;       % Unit: cycles
% Determine how many reference particles each pipeline get
ref_particle_per_pipe = ceil(AVG_PARTICLE_PER_CELL / NUM_PIPELINES);
% Run cycles for each refernce particle
run_cycles_per_reference_particle = particles_within_cutoff;
% Run cycles for each home cell
run_cycles_per_cell = run_cycles_per_reference_particle * ref_particle_per_pipe;
% Total evaluation time (depends which one take longer, runtime, or loading data time)
if initial_cycles_fill_input_cache < run_cycles_per_cell
    short_range_iteration_cycles = run_cycles_per_cell * TOTAL_CELL_COUNT + SHORT_RANGE_LATENCY + initial_cycles_fill_input_cache+MUX_TREE_LATENCY;
else
    short_range_iteration_cycles = initial_cycles_fill_input_cache * TOTAL_CELL_COUNT + SHORT_RANGE_LATENCY + initial_cycles_fill_input_cache+MUX_TREE_LATENCY;
end
short_range_iteration_time = short_range_iteration_cycles / FREQUENCY;    % Unit: us
%% Motion update time per iteration
% Motion update has a throughput of 1
motion_update_cycles = TOTAL_PARTICLE / NUM_MOTION_UPDATE + MOTION_UPDATE_LATENCY;
motion_update_time = motion_update_cycles /MOTION_UPDATE_FREQUENCY;       % Unit: us
%% Total time per iteration
% Walltime per iteration (unit us)
if CONSIDER_MOTION_UPDATE_TIME
    iteration_time = short_range_iteration_time + motion_update_time;
else
    iteration_time = short_range_iteration_time;
end
%% Simulation time per day
day_time = 24*60*60*10^6;               % Unit: us
iterations_per_day = day_time / iteration_time;
% Unit us
Simulation_Period_Per_Day = iterations_per_day * SIMULATION_TIME_STEP * 10^6;
fprintf('MEM1 + Distribute2: Iteration time is %fus, Simulation time per day is %f us\n',iteration_time,Simulation_Period_Per_Day);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Design 4: MEM2 + Distribute2: All pipelines working on same cell, different reference particle, with distributed Memory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NUM_PIPELINES = 35;
NUM_MOTION_UPDATE = 10;                             % Units for motion update
FREQUENCY = 340;                                    % Unit MHz
%% Short range time per iteration
% Readout 14 cells particles and send to one of the 100 input caches on each pipeline
initial_cycles_fill_input_cache = (NUM_NEIGHBOR_CELLS+1) * AVG_PARTICLE_PER_CELL /14;       % Unit: cycles
% Determine how many reference particles each pipeline get
ref_particle_per_pipe = ceil(AVG_PARTICLE_PER_CELL / NUM_PIPELINES);
% Run cycles for each refernce particle
run_cycles_per_reference_particle = particles_within_cutoff;
% Run cycles for each home cell
run_cycles_per_cell = run_cycles_per_reference_particle * ref_particle_per_pipe;
% Total evaluation time (depends which one take longer, runtime, or loading data time)
if initial_cycles_fill_input_cache < run_cycles_per_cell
    short_range_iteration_cycles = run_cycles_per_cell * TOTAL_CELL_COUNT + SHORT_RANGE_LATENCY + initial_cycles_fill_input_cache+MUX_TREE_LATENCY;
else
    short_range_iteration_cycles = initial_cycles_fill_input_cache * TOTAL_CELL_COUNT + SHORT_RANGE_LATENCY + initial_cycles_fill_input_cache+MUX_TREE_LATENCY;
end
short_range_iteration_time = short_range_iteration_cycles / FREQUENCY;    % Unit: us
%% Motion update time per iteration
% Motion update has a throughput of 1
motion_update_cycles = TOTAL_PARTICLE / NUM_MOTION_UPDATE + MOTION_UPDATE_LATENCY;
motion_update_time = motion_update_cycles /MOTION_UPDATE_FREQUENCY;       % Unit: us
%% Total time per iteration
% Walltime per iteration (unit us)
if CONSIDER_MOTION_UPDATE_TIME
    iteration_time = short_range_iteration_time + motion_update_time;
else
    iteration_time = short_range_iteration_time;
end
%% Simulation time per day
day_time = 24*60*60*10^6;               % Unit: us
iterations_per_day = day_time / iteration_time;
% Unit us
Simulation_Period_Per_Day = iterations_per_day * SIMULATION_TIME_STEP * 10^6;
fprintf('MEM2 + Distribute2: Iteration time is %fus, Simulation time per day is %f us\n',iteration_time,Simulation_Period_Per_Day);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Design 5: MEM1 + Distribute3: Each pipeline working on different home cells, with global memory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NUM_PIPELINES = 51;
NUM_MOTION_UPDATE = 10;                             % Units for motion update
FREQUENCY = 346;                                    % Unit MHz
%% Short range time per iteration
% Readout all cells particles and send to one of the 100 input caches on each pipeline
initial_cycles_fill_input_cache = TOTAL_PARTICLE;       % Unit: cycles
% For each iteration, determine how many rounds it will take
rounds_per_iteration = ceil(TOTAL_CELL_COUNT / NUM_PIPELINES);
% The time it takes for each round, suppose fully saturated
round_cycles = AVG_PARTICLE_PER_CELL * particles_within_cutoff;
% Cycles it take to finish one iteration
short_range_iteration_cycles = rounds_per_iteration * round_cycles + SHORT_RANGE_LATENCY+MUX_TREE_LATENCY+initial_cycles_fill_input_cache;
short_range_iteration_time = short_range_iteration_cycles / FREQUENCY;    % Unit: us
%% Motion update time per iteration
% Motion update has a throughput of 1
motion_update_cycles = TOTAL_PARTICLE / NUM_MOTION_UPDATE + MOTION_UPDATE_LATENCY;
motion_update_time = motion_update_cycles /MOTION_UPDATE_FREQUENCY;       % Unit: us
%% Total time per iteration
% Walltime per iteration (unit us)
if CONSIDER_MOTION_UPDATE_TIME
    iteration_time = short_range_iteration_time + motion_update_time;
else
    iteration_time = short_range_iteration_time;
end
%% Simulation time per day
day_time = 24*60*60*10^6;               % Unit: us
iterations_per_day = day_time / iteration_time;
% Unit us
Simulation_Period_Per_Day = iterations_per_day * SIMULATION_TIME_STEP * 10^6;
fprintf('MEM1 + Distribute3: Iteration time is %fus, Simulation time per day is %f us\n',iteration_time,Simulation_Period_Per_Day);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Design 6: MEM2 + Distribute3: Each pipeline working on different home cells, with distributed memory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NUM_PIPELINES = 41;
NUM_MOTION_UPDATE = 10;                             % Units for motion update
FREQUENCY = 346;                                    % Unit MHz
%% Short range time per iteration
% For each iteration, determine how many rounds it will take
rounds_per_iteration = ceil(TOTAL_CELL_COUNT / NUM_PIPELINES);
% The time it takes for each round, suppose fully saturated
round_cycles = AVG_PARTICLE_PER_CELL * particles_within_cutoff;
% Cycles it take to finish one iteration
short_range_iteration_cycles = rounds_per_iteration * round_cycles + SHORT_RANGE_LATENCY;
short_range_iteration_time = short_range_iteration_cycles / FREQUENCY;    % Unit: us
%% Motion update time per iteration
% Motion update has a throughput of 1
motion_update_cycles = TOTAL_PARTICLE / NUM_MOTION_UPDATE + MOTION_UPDATE_LATENCY;
motion_update_time = motion_update_cycles /MOTION_UPDATE_FREQUENCY;       % Unit: us
%% Total time per iteration
% Walltime per iteration (unit us)
if CONSIDER_MOTION_UPDATE_TIME
    iteration_time = short_range_iteration_time + motion_update_time;
else
    iteration_time = short_range_iteration_time;
end
%% Simulation time per day
day_time = 24*60*60*10^6;               % Unit: us
iterations_per_day = day_time / iteration_time;
% Unit us
Simulation_Period_Per_Day = iterations_per_day * SIMULATION_TIME_STEP * 10^6;
fprintf('MEM2 + Distribute3: Iteration time is %fus, Simulation time per day is %f us\n',iteration_time,Simulation_Period_Per_Day);


%% Measure the total runtime
END_TIME = cputime;
fprintf('Total runtime is %d seconds.\n', END_TIME-START_TIME);

