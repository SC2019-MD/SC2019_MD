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
% 01/10/2019
% Boston University, CAAD Lab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear;

START_TIME = cputime;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Simulation Control Parameter
ENABLE_INTERPOLATION = 1;                            % Choose to use direct computation or interpolation to evaluat the force and energy
ENABLE_VERIFICATION = 0;                             % Enable verification for a certain reference particle
ENABLE_SCATTER_PLOTTING = 0;                         % Ploting out the particle positions after each iteration ends
ENABLE_PRINT_DETAIL_MESSAGE = 0;                     % Print out detailed message showing which step the program is working on
ENABLE_OUTPUT_ENERGY_FILE = 0;                       % Print out the energy result to an output file
%ENABLE_ENERGY_EVALUATION = 1;                       % Enable the generation of LJ potential
%GEN_INPUT_MIF_FILE = 1;                             % Generate the memory initialization file for on-chip ram (.mif)
%GEN_PAIRWISE_INPUT_DATA_TO_FILTER = 0;              % Generate VERIFICATION_PARTICLE_PAIR_INPUT.txt
%GEN_PAIRWISE_FORCE_VALUE = 1;                       % Generate VERIFICATION_PARTICLE_PAIR_DISTANCE_AND_FORCE.txt
%GEN_PAIRWISE_NEIGHBOR_ACC_FORCE = 1;                % Generate VERIFICATION_PARTICLE_PAIR_NEIGHBOR_ACC_FORCE.txt (if this one need to be generated, GEN_PAIRWISE_FORCE_VALUE has to be 1)
SIMULATION_TIMESTEP = 10;                         % Total timesteps to simulate
ENERGY_EVALUATION_STEPS = 1;                         % Every few iterations, evaluate energy once
%% Dataset Parameters
% Input & Output Scale Parameters (Determined by the LJ_no_smooth_poly_interpolation_accuracy.m)
INPUT_SCALE_INDEX = 1;                        % if the readin position data is in the unit of meter, it turns out that the minimum r2 value can be too small, lead to the overflow when calculating the r^-14, thus scale to A
OUTPUT_SCALE_INDEX = 1;                       % The scale value for the results of r14 & r8 term
% Dataset Paraemeters
DATASET_NAME = 'LJArgon';
% Ar
kb = 1.380e-23;                               % Boltzmann constant (J/K)
Nav = 6.022e23;                               % Avogadro constant, # of atoms per mol
Ar_weight = 39.95;                            % g/mol value of Argon atom
EPS = 1.995996 * 1.995996;                    % Extracted from OpenMM, unit kJ      %0.996;% Unit: kJ	%0.238;% Unit kcal/mol	%kb * 120;% Unit J
SIGMA = 2.1;%3.4;%0.8;%0.1675*2;                   % Extracted from LJArgon, unit Angstrom        %3.35;%3.4;% Unit Angstrom    %3.4e-10;% Unit meter, the unit should be in consistant with position value
MASS = Ar_weight / Nav / 10^3;                % Unit kg
SIMULATION_TIME_STEP = 2E-15;                 % 2 femtosecond
CUTOFF_RADIUS = single(8.5);%single(SIGMA*2.5);%single(8);%single(7.65);      % Unit Angstrom, Cutoff Radius
CUTOFF_RADIUS_2 = CUTOFF_RADIUS^2;            % Cutoff distance square
EXCLUSION = single(2^-1);                     % Unit Angstrom, If the particle pairs has closers distance than this value, then don't evaluate
EXCLUSION_2 = EXCLUSION ^ 2;                  % Exclusion distance square
% LJArgon min r2 is 2.242475 ang^2
% Here we choose a interpolation range that is consistant with ApoA1
RAW_R2_MIN = 2^-12;%2.242475;                 % Currently this value is not used
SCALED_R2_MIN = RAW_R2_MIN * INPUT_SCALE_INDEX^2;
MIN_LOG_INDEX = floor(log(EXCLUSION_2)/log(2));
MIN_RANGE = 2^MIN_LOG_INDEX;                  % minimal range for the evaluation
MAX_LOG_INDEX = ceil(log(CUTOFF_RADIUS_2)/log(2));
MAX_RANGE = 2^MAX_LOG_INDEX;                  % maximum range for the evaluation (currently this is the cutoff radius)
%% Interpolation Parameters
INTERPOLATION_ORDER = 1;
SEGMENT_NUM = MAX_LOG_INDEX-MIN_LOG_INDEX;    % # of segment
BIN_NUM = 256;                                % # of bins per segment
%% Benmarck Related Parameters (related with CUTOFF_RADIUS)
CELL_COUNT_X = 7;%5;%3;
CELL_COUNT_Y = 6;%5;%3;
CELL_COUNT_Z = 6;%5;%3;
BOUNDING_BOX_SIZE_X = double(CELL_COUNT_X * CUTOFF_RADIUS);
BOUNDING_BOX_SIZE_Y = double(CELL_COUNT_Y * CUTOFF_RADIUS);
BOUNDING_BOX_SIZE_Z = double(CELL_COUNT_Z * CUTOFF_RADIUS);
CELL_PARTICLE_MAX = 200;                            % The maximum possible particle count in each cell
TOTAL_PARTICLE = 20000;%10000;%864;%500;%19000;                   % particle count in benchmark
MEM_DATA_WIDTH = 32*3;                              % Memory Data Width (3*32 for position)
COMMON_PATH = "";
INPUT_FILE_FORMAT = "txt";%"pdb";                   % The input file format, can be "txt" or "pdb"
INPUT_FILE_NAME = "input_positions_ljargon_20000_box_58_49_49.txt";%"input_positions_ljargon_10000_40box.txt";%"ar_gas.pdb";%"input_positions_ljargon.txt";
%% HDL design parameters
NUM_FILTER = 8;                                     % Number of filters in the pipeline
FILTER_BUFFER_DEPTH = 32;                           % Filter buffer depth, if buffer element # is larger than this value, pause generating particle pairs into filter bank
%% Output result file
if ENABLE_OUTPUT_ENERGY_FILE
    OUTPUT_FILE_NAME = strcat('Output_Energy_FullScale_Sim_',DATASET_NAME,'_',num2str(TOTAL_PARTICLE),'_iter_',num2str(SIMULATION_TIMESTEP),'.txt');
    OUTPUT_FILE_ID = fopen(OUTPUT_FILE_NAME,'w');
end


%% Data Arraies for processing
%% Position data arrays
raw_position_data = zeros(TOTAL_PARTICLE,3);                                            % The raw input data
position_data = single(zeros(TOTAL_PARTICLE,3));                                        % The shifted input data
position_data_history = single(zeros(SIMULATION_TIMESTEP,TOTAL_PARTICLE,3));            % Record the history position data, 1:3 Position x,y,z; 4: LJ Energy, 5: Kinetic Energy
energy_data_history = single(zeros(SIMULATION_TIMESTEP,3));                             % Record the history of energy, 1: LJ potential, 2: Kinectic energy, 3: Total energy
% counters tracking the # of particles in each cell
particle_in_cell_counter = zeros(CELL_COUNT_X,CELL_COUNT_Y,CELL_COUNT_Z);
% 3D array holding sorted cell particles(cell_id, particle_id, particle_info), cell_id = (cell_x-1)*9*7+(cell_y-1)*7+cell_z
% Particle info: 1~3:position(x,y,z), 4~6:force component in each direction(x,y,z), 7~9: velocity component in each direction, 10: LJ energy, 11: kinetic energy, 12:# of partner particles
cell_particle = single(zeros(CELL_COUNT_X*CELL_COUNT_Y*CELL_COUNT_Z,CELL_PARTICLE_MAX,12));
%% Temp arraies holding the updated cell particle information during motion update process
tmp_particle_in_cell_counter = zeros(CELL_COUNT_X,CELL_COUNT_Y,CELL_COUNT_Z);
tmp_cell_particle = single(zeros(CELL_COUNT_X*CELL_COUNT_Y*CELL_COUNT_Z,CELL_PARTICLE_MAX,12));
%% Input to filters in each pipeline
filter_input_particle_reservoir = single(zeros(NUM_FILTER,2*CELL_PARTICLE_MAX,7));      % Hold all the particles that need to send to each filter to process, 1:x; 2:y; 3:z; 4-6:cell_ID x,y,z; 7: particle_in_cell_counter
filter_input_particle_num = zeros(NUM_FILTER,3);                                        % Record how many reference particles each filter need to evaluate: 1: total particle this filter need to process; 2: # of particles from 1st cell; 3: # of particles from 2nd cell
%% Simulation Control Parameters
% Assign the Home cell
% Cell numbering mechanism: cell_id = (cell_x-1)*CELL_COUNT_Y*CELL_COUNT_Z + (cell_y-1)*CELL_COUNT_Z + cell_z;
%HOME_CELL_X = 2;                                    % Home cell coordiante
%HOME_CELL_Y = 2;
%HOME_CELL_Z = 2;
HOME_CELL_X_RANGE = 1:CELL_COUNT_X;             % Home cell coordiante
HOME_CELL_Y_RANGE = 1:CELL_COUNT_Y;
HOME_CELL_Z_RANGE = 1:CELL_COUNT_Z;
% The subset of cell initalization file need to generate (the cell number starting from 1)
% Cell numbering mechanism: cell_id = (cell_x-1)*CELL_COUNT_Y*CELL_COUNT_Z + (cell_y-1)*CELL_COUNT_Z + cell_z;
%GEN_CELL_RANGE_X = [1 2 3];
%GEN_CELL_RANGE_Y = [1 2 3];
%GEN_CELL_RANGE_Z = [1 2 3];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Preprocessing the Raw Input data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Load the data from input file
input_file_path = strcat(COMMON_PATH, INPUT_FILE_NAME);
fprintf('*** Start reading data from input file %s ***\n', input_file_path);
% Open File
fp = fopen(input_file_path);
if fp == -1
        fprintf('failed to open %s\n',input_file_path);
end
% Read in line by line
line_counter = 1;
% Read txt input file
if INPUT_FILE_FORMAT == "txt"
    while ~feof(fp)
        tline = fgets(fp);
        line_elements = textscan(tline,'%s %f64 %f64 %f64');
        raw_position_data(line_counter,1) = line_elements{2} * INPUT_SCALE_INDEX;
        raw_position_data(line_counter,2) = line_elements{3} * INPUT_SCALE_INDEX;
        raw_position_data(line_counter,3) = line_elements{4} * INPUT_SCALE_INDEX;
        line_counter = line_counter + 1;
    end
% Read pdb input file
elseif INPUT_FILE_FORMAT == "pdb"
    % Readout the top 5 lines, contains no data information
    tline = fgets(fp);
    tline = fgets(fp);
    tline = fgets(fp);
    tline = fgets(fp);
    tline = fgets(fp);
    while line_counter <= TOTAL_PARTICLE
        tline = fgets(fp);
        line_elements = textscan(tline,'%s %s %s %s %s %s %f64 %f64 %f64 %s %s %s');
        raw_position_data(line_counter,1) = line_elements{7} * INPUT_SCALE_INDEX;
        raw_position_data(line_counter,2) = line_elements{8} * INPUT_SCALE_INDEX;
        raw_position_data(line_counter,3) = line_elements{9} * INPUT_SCALE_INDEX;
        line_counter = line_counter + 1;
    end
end
% Close File
fclose(fp);
fprintf('Particle data loading finished!\n');

%% Find the min, max of raw data in each dimension
min_x  = min(raw_position_data(1:TOTAL_PARTICLE,1));
max_x  = max(raw_position_data(1:TOTAL_PARTICLE,1));
min_y  = min(raw_position_data(1:TOTAL_PARTICLE,2));
max_y  = max(raw_position_data(1:TOTAL_PARTICLE,2));
min_z  = min(raw_position_data(1:TOTAL_PARTICLE,3));
max_z  = max(raw_position_data(1:TOTAL_PARTICLE,3));
% Original range is (0.0011,347.7858), (4.5239e-04,347.7855), (3.1431e-04,347.7841)
% shift all the data to positive
position_data(1:TOTAL_PARTICLE,1) = raw_position_data(1:TOTAL_PARTICLE,1)-min_x;          % range: 0 ~ 347.7847
position_data(1:TOTAL_PARTICLE,2) = raw_position_data(1:TOTAL_PARTICLE,2)-min_y;          % range: 0 ~ 347.7851
position_data(1:TOTAL_PARTICLE,3) = raw_position_data(1:TOTAL_PARTICLE,3)-min_z;          % range: 0 ~ 347.7838
fprintf('All particles shifted to align on (0,0,0)\n');
if ENABLE_SCATTER_PLOTTING
    % Print out the initial particle location
    clf;
    scatter3(position_data(:,1),position_data(:,2),position_data(:,3));
    title('Initial Position');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Mapping the initial particles to cell list
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('*** Start mapping paricles to cells! ***\n');
out_range_particle_counter = 0;
for i = 1:TOTAL_PARTICLE
    % determine the cell each particle belongs to
    if position_data(i,1) ~= 0
        cell_x = floor(position_data(i,1) / CUTOFF_RADIUS)+1;
    else
        cell_x = 1;
    end
    if position_data(i,2) ~= 0
        cell_y = floor(position_data(i,2) / CUTOFF_RADIUS)+1;
    else
        cell_y = 1;
    end
    if position_data(i,3) ~= 0
        cell_z = floor(position_data(i,3) / CUTOFF_RADIUS)+1;
    else
        cell_z = 1;
    end
    % write the particle information to cell list
    if cell_x > 0 && cell_x <= CELL_COUNT_X && cell_y > 0 && cell_y <= CELL_COUNT_Y && cell_z > 0 && cell_z <= CELL_COUNT_Z
        % increment counter
        counter_temp = particle_in_cell_counter(cell_x, cell_y, cell_z) + 1;
        particle_in_cell_counter(cell_x, cell_y, cell_z) = counter_temp;
        cell_id = (cell_x-1)*CELL_COUNT_Y*CELL_COUNT_Z + (cell_y-1)*CELL_COUNT_Z + cell_z;
        cell_particle(cell_id,counter_temp,1) = position_data(i,1);
        cell_particle(cell_id,counter_temp,2) = position_data(i,2);
        cell_particle(cell_id,counter_temp,3) = position_data(i,3);
    else
        out_range_particle_counter = out_range_particle_counter + 1;
        fprintf('Out of range particle is (%f,%f,%f)\n', position_data(i,1:3));
    end
end
fprintf('Particles mapping to cells finished! Total of %d particles falling out of the range.\n', out_range_particle_counter);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Load in interpolation index data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fileID_0  = fopen('c0_14.txt', 'r');
fileID_1  = fopen('c1_14.txt', 'r');
if INTERPOLATION_ORDER > 1
    fileID_2  = fopen('c2_14.txt', 'r');
end
if INTERPOLATION_ORDER > 2
    fileID_3  = fopen('c3_14.txt', 'r');
end

fileID_4  = fopen('c0_8.txt', 'r');
fileID_5  = fopen('c1_8.txt', 'r');
if INTERPOLATION_ORDER > 1
    fileID_6  = fopen('c2_8.txt', 'r');
end
if INTERPOLATION_ORDER > 2
    fileID_7  = fopen('c3_8.txt', 'r');
end

fileID_8  = fopen('c0_12.txt', 'r');
fileID_9  = fopen('c1_12.txt', 'r');
if INTERPOLATION_ORDER > 1
    fileID_10  = fopen('c2_12.txt', 'r');
end
if INTERPOLATION_ORDER > 2
    fileID_11  = fopen('c3_12.txt', 'r');
end

fileID_12  = fopen('c0_6.txt', 'r');
fileID_13  = fopen('c1_6.txt', 'r');
if INTERPOLATION_ORDER > 1
    fileID_14  = fopen('c2_6.txt', 'r');
end
if INTERPOLATION_ORDER > 2
    fileID_15  = fopen('c3_6.txt', 'r');
end

% Fetch the index for the polynomials
read_in_c0_vdw14 = textscan(fileID_0, '%f');
read_in_c1_vdw14 = textscan(fileID_1, '%f');
if INTERPOLATION_ORDER > 1
    read_in_c2_vdw14 = textscan(fileID_2, '%f');
end
if INTERPOLATION_ORDER > 2
    read_in_c3_vdw14 = textscan(fileID_3, '%f');
end
read_in_c0_vdw8 = textscan(fileID_4, '%f');
read_in_c1_vdw8 = textscan(fileID_5, '%f');
if INTERPOLATION_ORDER > 1
    read_in_c2_vdw8 = textscan(fileID_6, '%f');
end
if INTERPOLATION_ORDER > 2
    read_in_c3_vdw8 = textscan(fileID_7, '%f');
end
read_in_c0_vdw12 = textscan(fileID_8, '%f');
read_in_c1_vdw12 = textscan(fileID_9, '%f');
if INTERPOLATION_ORDER > 1
    read_in_c2_vdw12 = textscan(fileID_10, '%f');
end
if INTERPOLATION_ORDER > 2
    read_in_c3_vdw12 = textscan(fileID_11, '%f');
end
read_in_c0_vdw6 = textscan(fileID_12, '%f');
read_in_c1_vdw6 = textscan(fileID_13, '%f');
if INTERPOLATION_ORDER > 1
    read_in_c2_vdw6 = textscan(fileID_14, '%f');
end
if INTERPOLATION_ORDER > 2
    read_in_c3_vdw6 = textscan(fileID_15, '%f');
end
% close file
fclose(fileID_0);
fclose(fileID_1);
if INTERPOLATION_ORDER > 1
    fclose(fileID_2);
end
if INTERPOLATION_ORDER > 2
    fclose(fileID_3);
end
fclose(fileID_4);
fclose(fileID_5);
if INTERPOLATION_ORDER > 1
    fclose(fileID_6);
end
if INTERPOLATION_ORDER > 2
    fclose(fileID_7);
end
fclose(fileID_8);
fclose(fileID_9);
if INTERPOLATION_ORDER > 1
    fclose(fileID_10);
end
if INTERPOLATION_ORDER > 2
    fclose(fileID_11);
end
fclose(fileID_12);
fclose(fileID_13);
if INTERPOLATION_ORDER > 1
    fclose(fileID_14);
end
if INTERPOLATION_ORDER > 2
    fclose(fileID_15);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FULL SIMULATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
energy_evaluation_counter = 0;
for sim_iteration = 1:SIMULATION_TIMESTEP
    % Evaluate energy every 10 simulation steps
    if mod(sim_iteration,ENERGY_EVALUATION_STEPS) == 0
        ENABLE_ENERGY_EVALUATION = 1;
    else
        ENABLE_ENERGY_EVALUATION = 0;
    end

    fprintf('*** Iteration %d: Starts! ***\n', sim_iteration);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Force and Energy Evaluation
    %% Traverse all the cells as home cell
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for homecell_ptr_x = 1:length(HOME_CELL_X_RANGE)
        HOME_CELL_X = HOME_CELL_X_RANGE(homecell_ptr_x);
        for homecell_ptr_y = 1:length(HOME_CELL_Y_RANGE)
            HOME_CELL_Y = HOME_CELL_Y_RANGE(homecell_ptr_y);
            for homecell_ptr_z = 1:length(HOME_CELL_Z_RANGE)
                HOME_CELL_Z = HOME_CELL_Z_RANGE(homecell_ptr_z);

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %% Genearating input particle pairs
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %% Collect particles from neighbor cells and assign to the filter that will process it (mapping scheme is shown in the global comment section) 
                %fprintf('*** Iteration %d: Start mapping cell paricles to each filter! ***\n', sim_iteration);
                for filter_id = 1:NUM_FILTER
                    switch filter_id
                        % Process home cell 222
                        case 1
                            neighbor_cell_x = HOME_CELL_X;
                            neighbor_cell_y = HOME_CELL_Y;
                            neighbor_cell_z = HOME_CELL_Z;
                            % Get the neighbor cell id
                            neighbor_cell_id = (neighbor_cell_x-1)*CELL_COUNT_Y*CELL_COUNT_Z + (neighbor_cell_y-1)*CELL_COUNT_Z + neighbor_cell_z;
                            % Get the # of particles in the current evaluated neighbor cell
                            tmp_particle_num = particle_in_cell_counter(neighbor_cell_x,neighbor_cell_y,neighbor_cell_z);
                            filter_input_particle_num(filter_id,1) = tmp_particle_num;
                            filter_input_particle_num(filter_id,2) = tmp_particle_num;
                            % Assign the particles from neighbor cell to reservoir
                            filter_input_particle_reservoir(filter_id,1:tmp_particle_num,1:3) = cell_particle(neighbor_cell_id,1:tmp_particle_num,1:3);
                            % Assign the particles ID
                            for particle_ptr = 1:tmp_particle_num
                                filter_input_particle_reservoir(filter_id,particle_ptr,4:6) = [neighbor_cell_x,neighbor_cell_y,neighbor_cell_z];
                                filter_input_particle_reservoir(filter_id,particle_ptr,7) = particle_ptr;
                            end
                        % Process neighbor cell 223
                        case 2
                            neighbor_cell_x = HOME_CELL_X;
                            neighbor_cell_y = HOME_CELL_Y;
                            if(HOME_CELL_Z < CELL_COUNT_Z)
                                neighbor_cell_z = HOME_CELL_Z+1;
                            else
                                neighbor_cell_z = 1;
                            end
                            % Get the neighbor cell id
                            neighbor_cell_id = (neighbor_cell_x-1)*CELL_COUNT_Y*CELL_COUNT_Z + (neighbor_cell_y-1)*CELL_COUNT_Z + neighbor_cell_z;
                            % Get the # of particles in the current evaluated neighbor cell
                            tmp_particle_num = particle_in_cell_counter(neighbor_cell_x,neighbor_cell_y,neighbor_cell_z);
                            filter_input_particle_num(filter_id,1) = tmp_particle_num;
                            filter_input_particle_num(filter_id,2) = tmp_particle_num;
                            % Assign the particles from neighbor cell to reservoir
                            filter_input_particle_reservoir(filter_id,1:tmp_particle_num,1:3) = cell_particle(neighbor_cell_id,1:tmp_particle_num,1:3);
                            % Assign the particles ID
                            for particle_ptr = 1:tmp_particle_num
                                filter_input_particle_reservoir(filter_id,particle_ptr,4:6) = [neighbor_cell_x,neighbor_cell_y,neighbor_cell_z];
                                filter_input_particle_reservoir(filter_id,particle_ptr,7) = particle_ptr;
                            end
                        % Process neighbor cell 231, 232
                        case 3
                            % Processing 1st cell
                            neighbor_cell_x = HOME_CELL_X;
                            if HOME_CELL_Y < CELL_COUNT_Y
                                neighbor_cell_y = HOME_CELL_Y+1;
                            else
                                neighbor_cell_y = 1;
                            end
                            if HOME_CELL_Z > 1
                                neighbor_cell_z = HOME_CELL_Z-1;
                            else
                                neighbor_cell_z = CELL_COUNT_Z;
                            end
                            % Get the neighbor cell id
                            neighbor_cell_id = (neighbor_cell_x-1)*CELL_COUNT_Y*CELL_COUNT_Z + (neighbor_cell_y-1)*CELL_COUNT_Z + neighbor_cell_z;
                            % Get the # of particles in the current evaluated neighbor cell
                            tmp_particle_num_1 = particle_in_cell_counter(neighbor_cell_x,neighbor_cell_y,neighbor_cell_z);
                            % Assign the particles from neighbor cell to reservoir
                            filter_input_particle_reservoir(filter_id,1:tmp_particle_num_1,1:3) = cell_particle(neighbor_cell_id,1:tmp_particle_num_1,1:3);
                            % Assign the particles ID
                            for particle_ptr = 1:tmp_particle_num_1
                                filter_input_particle_reservoir(filter_id,particle_ptr,4:6) = [neighbor_cell_x,neighbor_cell_y,neighbor_cell_z];
                                filter_input_particle_reservoir(filter_id,particle_ptr,7) = particle_ptr;
                            end

                            % Process 2nd cell
                            neighbor_cell_x = HOME_CELL_X;
                            if HOME_CELL_Y < CELL_COUNT_Y
                                neighbor_cell_y = HOME_CELL_Y+1;
                            else
                                neighbor_cell_y = 1;
                            end
                            neighbor_cell_z = HOME_CELL_Z;
                            % Get the neighbor cell id
                            neighbor_cell_id = (neighbor_cell_x-1)*CELL_COUNT_Y*CELL_COUNT_Z + (neighbor_cell_y-1)*CELL_COUNT_Z + neighbor_cell_z;
                            % Get the # of particles in the current evaluated neighbor cell
                            tmp_particle_num_2 = particle_in_cell_counter(neighbor_cell_x,neighbor_cell_y,neighbor_cell_z);
                            filter_input_particle_num(filter_id,1) = tmp_particle_num_1 + tmp_particle_num_2;
                            filter_input_particle_num(filter_id,2) = tmp_particle_num_1;
                            filter_input_particle_num(filter_id,3) = tmp_particle_num_2;
                            % Assign the particles from neighbor cell to reservoir
                            filter_input_particle_reservoir(filter_id,tmp_particle_num_1+1:tmp_particle_num_1+tmp_particle_num_2,1:3) = cell_particle(neighbor_cell_id,1:tmp_particle_num_2,1:3);
                            % Assign the particles ID
                            for particle_ptr = tmp_particle_num_1+1:tmp_particle_num_1+tmp_particle_num_2
                                filter_input_particle_reservoir(filter_id,particle_ptr,4:6) = [neighbor_cell_x,neighbor_cell_y,neighbor_cell_z];
                                filter_input_particle_reservoir(filter_id,particle_ptr,7) = particle_ptr-tmp_particle_num_1;
                            end

                        % Process neighbor cell 233, 311
                        case 4
                            % Processing 1st cell
                            neighbor_cell_x = HOME_CELL_X;
                            if HOME_CELL_Y < CELL_COUNT_Y
                                neighbor_cell_y = HOME_CELL_Y+1;
                            else
                                neighbor_cell_y = 1;
                            end
                            if(HOME_CELL_Z < CELL_COUNT_Z)
                                neighbor_cell_z = HOME_CELL_Z+1;
                            else
                                neighbor_cell_z = 1;
                            end
                            % Get the neighbor cell id
                            neighbor_cell_id = (neighbor_cell_x-1)*CELL_COUNT_Y*CELL_COUNT_Z + (neighbor_cell_y-1)*CELL_COUNT_Z + neighbor_cell_z;
                            % Get the # of particles in the current evaluated neighbor cell
                            tmp_particle_num_1 = particle_in_cell_counter(neighbor_cell_x,neighbor_cell_y,neighbor_cell_z);
                            % Assign the particles from neighbor cell to reservoir
                            filter_input_particle_reservoir(filter_id,1:tmp_particle_num_1,1:3) = cell_particle(neighbor_cell_id,1:tmp_particle_num_1,1:3);
                            % Assign the particles ID
                            for particle_ptr = 1:tmp_particle_num_1
                                filter_input_particle_reservoir(filter_id,particle_ptr,4:6) = [neighbor_cell_x,neighbor_cell_y,neighbor_cell_z];
                                filter_input_particle_reservoir(filter_id,particle_ptr,7) = particle_ptr;
                            end

                            % Process 2nd cell
                            if HOME_CELL_X < CELL_COUNT_X
                                neighbor_cell_x = HOME_CELL_X+1;
                            else
                                neighbor_cell_x = 1;
                            end
                            if HOME_CELL_Y > 1
                                neighbor_cell_y = HOME_CELL_Y-1;
                            else
                                neighbor_cell_y = CELL_COUNT_Y;
                            end
                            if HOME_CELL_Z > 1
                                neighbor_cell_z = HOME_CELL_Z-1;
                            else
                                neighbor_cell_z = CELL_COUNT_Z;
                            end
                            % Get the neighbor cell id
                            neighbor_cell_id = (neighbor_cell_x-1)*CELL_COUNT_Y*CELL_COUNT_Z + (neighbor_cell_y-1)*CELL_COUNT_Z + neighbor_cell_z;
                            % Get the # of particles in the current evaluated neighbor cell
                            tmp_particle_num_2 = particle_in_cell_counter(neighbor_cell_x,neighbor_cell_y,neighbor_cell_z);
                            filter_input_particle_num(filter_id,1) = tmp_particle_num_1 + tmp_particle_num_2;
                            filter_input_particle_num(filter_id,2) = tmp_particle_num_1;
                            filter_input_particle_num(filter_id,3) = tmp_particle_num_2;
                            % Assign the particles from neighbor cell to reservoir
                            filter_input_particle_reservoir(filter_id,tmp_particle_num_1+1:tmp_particle_num_1+tmp_particle_num_2,1:3) = cell_particle(neighbor_cell_id,1:tmp_particle_num_2,1:3);
                            % Assign the particles ID
                            for particle_ptr = tmp_particle_num_1+1:tmp_particle_num_1+tmp_particle_num_2
                                filter_input_particle_reservoir(filter_id,particle_ptr,4:6) = [neighbor_cell_x,neighbor_cell_y,neighbor_cell_z];
                                filter_input_particle_reservoir(filter_id,particle_ptr,7) = particle_ptr-tmp_particle_num_1;
                            end

                        % Process neighbor cell 312, 313
                        case 5
                            % Processing 1st cell
                            if HOME_CELL_X < CELL_COUNT_X
                                neighbor_cell_x = HOME_CELL_X+1;
                            else
                                neighbor_cell_x = 1;
                            end
                            if HOME_CELL_Y > 1
                                neighbor_cell_y = HOME_CELL_Y-1;
                            else
                                neighbor_cell_y = CELL_COUNT_Y;
                            end
                            neighbor_cell_z = HOME_CELL_Z;
                            % Get the neighbor cell id
                            neighbor_cell_id = (neighbor_cell_x-1)*CELL_COUNT_Y*CELL_COUNT_Z + (neighbor_cell_y-1)*CELL_COUNT_Z + neighbor_cell_z;
                            % Get the # of particles in the current evaluated neighbor cell
                            tmp_particle_num_1 = particle_in_cell_counter(neighbor_cell_x,neighbor_cell_y,neighbor_cell_z);
                            % Assign the particles from neighbor cell to reservoir
                            filter_input_particle_reservoir(filter_id,1:tmp_particle_num_1,1:3) = cell_particle(neighbor_cell_id,1:tmp_particle_num_1,1:3);
                            % Assign the particles ID
                            for particle_ptr = 1:tmp_particle_num_1
                                filter_input_particle_reservoir(filter_id,particle_ptr,4:6) = [neighbor_cell_x,neighbor_cell_y,neighbor_cell_z];
                                filter_input_particle_reservoir(filter_id,particle_ptr,7) = particle_ptr;
                            end

                            % Process 2nd cell
                            if HOME_CELL_X < CELL_COUNT_X
                                neighbor_cell_x = HOME_CELL_X+1;
                            else
                                neighbor_cell_x = 1;
                            end
                            if HOME_CELL_Y > 1
                                neighbor_cell_y = HOME_CELL_Y-1;
                            else
                                neighbor_cell_y = CELL_COUNT_Y;
                            end
                            if(HOME_CELL_Z < CELL_COUNT_Z)
                                neighbor_cell_z = HOME_CELL_Z+1;
                            else
                                neighbor_cell_z = 1;
                            end
                            % Get the neighbor cell id
                            neighbor_cell_id = (neighbor_cell_x-1)*CELL_COUNT_Y*CELL_COUNT_Z + (neighbor_cell_y-1)*CELL_COUNT_Z + neighbor_cell_z;
                            % Get the # of particles in the current evaluated neighbor cell
                            tmp_particle_num_2 = particle_in_cell_counter(neighbor_cell_x,neighbor_cell_y,neighbor_cell_z);
                            filter_input_particle_num(filter_id,1) = tmp_particle_num_1 + tmp_particle_num_2;
                            filter_input_particle_num(filter_id,2) = tmp_particle_num_1;
                            filter_input_particle_num(filter_id,3) = tmp_particle_num_2;
                            % Assign the particles from neighbor cell to reservoir
                            filter_input_particle_reservoir(filter_id,tmp_particle_num_1+1:tmp_particle_num_1+tmp_particle_num_2,1:3) = cell_particle(neighbor_cell_id,1:tmp_particle_num_2,1:3);
                            % Assign the particles ID
                            for particle_ptr = tmp_particle_num_1+1:tmp_particle_num_1+tmp_particle_num_2
                                filter_input_particle_reservoir(filter_id,particle_ptr,4:6) = [neighbor_cell_x,neighbor_cell_y,neighbor_cell_z];
                                filter_input_particle_reservoir(filter_id,particle_ptr,7) = particle_ptr-tmp_particle_num_1;
                            end

                        % Process neighbor cell 321, 322
                        case 6
                            % Processing 1st cell
                            if HOME_CELL_X < CELL_COUNT_X
                                neighbor_cell_x = HOME_CELL_X+1;
                            else
                                neighbor_cell_x = 1;
                            end
                            neighbor_cell_y = HOME_CELL_Y;
                            if HOME_CELL_Z > 1
                                neighbor_cell_z = HOME_CELL_Z-1;
                            else
                                neighbor_cell_z = CELL_COUNT_Z;
                            end
                            % Get the neighbor cell id
                            neighbor_cell_id = (neighbor_cell_x-1)*CELL_COUNT_Y*CELL_COUNT_Z + (neighbor_cell_y-1)*CELL_COUNT_Z + neighbor_cell_z;
                            % Get the # of particles in the current evaluated neighbor cell
                            tmp_particle_num_1 = particle_in_cell_counter(neighbor_cell_x,neighbor_cell_y,neighbor_cell_z);
                            % Assign the particles from neighbor cell to reservoir
                            filter_input_particle_reservoir(filter_id,1:tmp_particle_num_1,1:3) = cell_particle(neighbor_cell_id,1:tmp_particle_num_1,1:3);
                            % Assign the particles ID
                            for particle_ptr = 1:tmp_particle_num_1
                                filter_input_particle_reservoir(filter_id,particle_ptr,4:6) = [neighbor_cell_x,neighbor_cell_y,neighbor_cell_z];
                                filter_input_particle_reservoir(filter_id,particle_ptr,7) = particle_ptr;
                            end

                            % Process 2nd cell
                            if HOME_CELL_X < CELL_COUNT_X
                                neighbor_cell_x = HOME_CELL_X+1;
                            else
                                neighbor_cell_x = 1;
                            end
                            neighbor_cell_y = HOME_CELL_Y;
                            neighbor_cell_z = HOME_CELL_Z;
                            % Get the neighbor cell id
                            neighbor_cell_id = (neighbor_cell_x-1)*CELL_COUNT_Y*CELL_COUNT_Z + (neighbor_cell_y-1)*CELL_COUNT_Z + neighbor_cell_z;
                            % Get the # of particles in the current evaluated neighbor cell
                            tmp_particle_num_2 = particle_in_cell_counter(neighbor_cell_x,neighbor_cell_y,neighbor_cell_z);
                            filter_input_particle_num(filter_id,1) = tmp_particle_num_1 + tmp_particle_num_2;
                            filter_input_particle_num(filter_id,2) = tmp_particle_num_1;
                            filter_input_particle_num(filter_id,3) = tmp_particle_num_2;
                            % Assign the particles from neighbor cell to reservoir
                            filter_input_particle_reservoir(filter_id,tmp_particle_num_1+1:tmp_particle_num_1+tmp_particle_num_2,1:3) = cell_particle(neighbor_cell_id,1:tmp_particle_num_2,1:3);
                            % Assign the particles ID
                            for particle_ptr = tmp_particle_num_1+1:tmp_particle_num_1+tmp_particle_num_2
                                filter_input_particle_reservoir(filter_id,particle_ptr,4:6) = [neighbor_cell_x,neighbor_cell_y,neighbor_cell_z];
                                filter_input_particle_reservoir(filter_id,particle_ptr,7) = particle_ptr-tmp_particle_num_1;
                            end

                        % Process neighbor cell 323, 331
                        case 7
                            % Processing 1st cell
                            if HOME_CELL_X < CELL_COUNT_X
                                neighbor_cell_x = HOME_CELL_X+1;
                            else
                                neighbor_cell_x = 1;
                            end
                            neighbor_cell_y = HOME_CELL_Y;
                            if(HOME_CELL_Z < CELL_COUNT_Z)
                                neighbor_cell_z = HOME_CELL_Z+1;
                            else
                                neighbor_cell_z = 1;
                            end
                            % Get the neighbor cell id
                            neighbor_cell_id = (neighbor_cell_x-1)*CELL_COUNT_Y*CELL_COUNT_Z + (neighbor_cell_y-1)*CELL_COUNT_Z + neighbor_cell_z;
                            % Get the # of particles in the current evaluated neighbor cell
                            tmp_particle_num_1 = particle_in_cell_counter(neighbor_cell_x,neighbor_cell_y,neighbor_cell_z);
                            % Assign the particles from neighbor cell to reservoir
                            filter_input_particle_reservoir(filter_id,1:tmp_particle_num_1,1:3) = cell_particle(neighbor_cell_id,1:tmp_particle_num_1,1:3);
                            % Assign the particles ID
                            for particle_ptr = 1:tmp_particle_num_1
                                filter_input_particle_reservoir(filter_id,particle_ptr,4:6) = [neighbor_cell_x,neighbor_cell_y,neighbor_cell_z];
                                filter_input_particle_reservoir(filter_id,particle_ptr,7) = particle_ptr;
                            end

                            % Process 2nd cell
                            if HOME_CELL_X < CELL_COUNT_X
                                neighbor_cell_x = HOME_CELL_X+1;
                            else
                                neighbor_cell_x = 1;
                            end
                            if HOME_CELL_Y < CELL_COUNT_Y
                                neighbor_cell_y = HOME_CELL_Y+1;
                            else
                                neighbor_cell_y = 1;
                            end
                            if HOME_CELL_Z > 1
                                neighbor_cell_z = HOME_CELL_Z-1;
                            else
                                neighbor_cell_z = CELL_COUNT_Z;
                            end
                            % Get the neighbor cell id
                            neighbor_cell_id = (neighbor_cell_x-1)*CELL_COUNT_Y*CELL_COUNT_Z + (neighbor_cell_y-1)*CELL_COUNT_Z + neighbor_cell_z;
                            % Get the # of particles in the current evaluated neighbor cell
                            tmp_particle_num_2 = particle_in_cell_counter(neighbor_cell_x,neighbor_cell_y,neighbor_cell_z);
                            filter_input_particle_num(filter_id,1) = tmp_particle_num_1 + tmp_particle_num_2;
                            filter_input_particle_num(filter_id,2) = tmp_particle_num_1;
                            filter_input_particle_num(filter_id,3) = tmp_particle_num_2;
                            % Assign the particles from neighbor cell to reservoir
                            filter_input_particle_reservoir(filter_id,tmp_particle_num_1+1:tmp_particle_num_1+tmp_particle_num_2,1:3) = cell_particle(neighbor_cell_id,1:tmp_particle_num_2,1:3);
                            % Assign the particles ID
                            for particle_ptr = tmp_particle_num_1+1:tmp_particle_num_1+tmp_particle_num_2
                                filter_input_particle_reservoir(filter_id,particle_ptr,4:6) = [neighbor_cell_x,neighbor_cell_y,neighbor_cell_z];
                                filter_input_particle_reservoir(filter_id,particle_ptr,7) = particle_ptr-tmp_particle_num_1;
                            end

                        % Process neighbor cell 332, 333
                        case 8
                            % Processing 1st cell
                            if HOME_CELL_X < CELL_COUNT_X
                                neighbor_cell_x = HOME_CELL_X+1;
                            else
                                neighbor_cell_x = 1;
                            end
                            if HOME_CELL_Y < CELL_COUNT_Y
                                neighbor_cell_y = HOME_CELL_Y+1;
                            else
                                neighbor_cell_y = 1;
                            end
                            neighbor_cell_z = HOME_CELL_Z;
                            % Get the neighbor cell id
                            neighbor_cell_id = (neighbor_cell_x-1)*CELL_COUNT_Y*CELL_COUNT_Z + (neighbor_cell_y-1)*CELL_COUNT_Z + neighbor_cell_z;
                            % Get the # of particles in the current evaluated neighbor cell
                            tmp_particle_num_1 = particle_in_cell_counter(neighbor_cell_x,neighbor_cell_y,neighbor_cell_z);
                            % Assign the particles from neighbor cell to reservoir
                            filter_input_particle_reservoir(filter_id,1:tmp_particle_num_1,1:3) = cell_particle(neighbor_cell_id,1:tmp_particle_num_1,1:3);
                            % Assign the particles ID
                            for particle_ptr = 1:tmp_particle_num_1
                                filter_input_particle_reservoir(filter_id,particle_ptr,4:6) = [neighbor_cell_x,neighbor_cell_y,neighbor_cell_z];
                                filter_input_particle_reservoir(filter_id,particle_ptr,7) = particle_ptr;
                            end

                            % Process 2nd cell
                            if HOME_CELL_X < CELL_COUNT_X
                                neighbor_cell_x = HOME_CELL_X+1;
                            else
                                neighbor_cell_x = 1;
                            end
                            if HOME_CELL_Y < CELL_COUNT_Y
                                neighbor_cell_y = HOME_CELL_Y+1;
                            else
                                neighbor_cell_y = 1;
                            end
                            if(HOME_CELL_Z < CELL_COUNT_Z)
                                neighbor_cell_z = HOME_CELL_Z+1;
                            else
                                neighbor_cell_z = 1;
                            end
                            % Get the neighbor cell id
                            neighbor_cell_id = (neighbor_cell_x-1)*CELL_COUNT_Y*CELL_COUNT_Z + (neighbor_cell_y-1)*CELL_COUNT_Z + neighbor_cell_z;
                            % Get the # of particles in the current evaluated neighbor cell
                            tmp_particle_num_2 = particle_in_cell_counter(neighbor_cell_x,neighbor_cell_y,neighbor_cell_z);
                            filter_input_particle_num(filter_id,1) = tmp_particle_num_1 + tmp_particle_num_2;
                            filter_input_particle_num(filter_id,2) = tmp_particle_num_1;
                            filter_input_particle_num(filter_id,3) = tmp_particle_num_2;
                            % Assign the particles from neighbor cell to reservoir
                            filter_input_particle_reservoir(filter_id,tmp_particle_num_1+1:tmp_particle_num_1+tmp_particle_num_2,1:3) = cell_particle(neighbor_cell_id,1:tmp_particle_num_2,1:3);
                            % Assign the particles ID
                            for particle_ptr = tmp_particle_num_1+1:tmp_particle_num_1+tmp_particle_num_2
                                filter_input_particle_reservoir(filter_id,particle_ptr,4:6) = [neighbor_cell_x,neighbor_cell_y,neighbor_cell_z];
                                filter_input_particle_reservoir(filter_id,particle_ptr,7) = particle_ptr-tmp_particle_num_1;
                            end
                    end
                end
                if ENABLE_PRINT_DETAIL_MESSAGE
                    fprintf('Iteration %d, Homecell(%d,%d,%d): Mapping cell particles to filters done!\n', sim_iteration, HOME_CELL_X, HOME_CELL_Y, HOME_CELL_Z);
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %% Evaluate Force with data from 8 filters (currently the order of data from filters is not guaranteed)
                %% Including arbitration
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                %% Start Evaluation
                % Home cell id
                home_cell_id = (HOME_CELL_X-1)*CELL_COUNT_Y*CELL_COUNT_Z + (HOME_CELL_Y-1)*CELL_COUNT_Z + HOME_CELL_Z;
                % Collect home cell particle count
                home_cell_particle_num = particle_in_cell_counter(HOME_CELL_X,HOME_CELL_Y,HOME_CELL_Z);
                % Find the maximum # of particle one filter need to process
                filter_process_particle_max = max(filter_input_particle_num(:,1));
                %% Traverse all the reference particles
                for ref_particle_ptr = 1:home_cell_particle_num
                    % Get ref particle position
                    ref_pos_x = cell_particle(home_cell_id,ref_particle_ptr,1);
                    ref_pos_y = cell_particle(home_cell_id,ref_particle_ptr,2);
                    ref_pos_z = cell_particle(home_cell_id,ref_particle_ptr,3);
                    tmp_force_acc_x = single(0);
                    tmp_force_acc_y = single(0);
                    tmp_force_acc_z = single(0);
                    tmp_potential_acc = single(0);
                    tmp_neighbor_force_x = single(0);
                    tmp_neighbor_force_y = single(0);
                    tmp_neighbor_force_z = single(0);
                    tmp_counter_particles_within_cutoff = 0;
                    % Traverse paticle from each cells one at a time
                    % mimic clock cycle
                    for neighbor_particle_ptr = 1:filter_process_particle_max
                        % Traverse each filter and applying filtering logic
                        for filter_id = 1:NUM_FILTER
                            % Only cover the valid data in each filter reservoir
                            if neighbor_particle_ptr <= filter_input_particle_num(filter_id,1)
                                neighbor_pos_x = filter_input_particle_reservoir(filter_id,neighbor_particle_ptr,1);
                                neighbor_pos_y = filter_input_particle_reservoir(filter_id,neighbor_particle_ptr,2);
                                neighbor_pos_z = filter_input_particle_reservoir(filter_id,neighbor_particle_ptr,3);
                                % Calculate dx, dy, dz, r2
                                dx = ref_pos_x - neighbor_pos_x;
                                dy = ref_pos_y - neighbor_pos_y;
                                dz = ref_pos_z - neighbor_pos_z;
                                % Apply periodic boundary condition
                                dx = dx - BOUNDING_BOX_SIZE_X * round(dx/BOUNDING_BOX_SIZE_X);
                                dy = dy - BOUNDING_BOX_SIZE_Y * round(dy/BOUNDING_BOX_SIZE_Y);
                                dz = dz - BOUNDING_BOX_SIZE_Z * round(dz/BOUNDING_BOX_SIZE_Z);
                                % Evaluated R2
                                r2 = dx*dx + dy*dy + dz*dz;
                                % Pass the filter
                                if r2 >= EXCLUSION_2 &&  r2 < CUTOFF_RADIUS_2
                                    tmp_counter_particles_within_cutoff = tmp_counter_particles_within_cutoff + 1;
                                    %% Force Evaluation
                                    % Using Table lookup for evaluation
                                    if ENABLE_INTERPOLATION
                                        seg_ptr = 0;        % The first segment will be #0, second will be #1, etc....
                                        while(r2 >= MIN_RANGE * 2^(seg_ptr+1))
                                            seg_ptr = seg_ptr + 1;
                                        end
                                        if(seg_ptr >= SEGMENT_NUM)      % if the segment pointer is larger than the maximum number of segment, then error out
                                            disp('Error occur: could not locate the segment for the input r2');
                                            return;
                                        end
                                        % Locate the bin in the current segment
                                        segment_min = single(MIN_RANGE * 2^seg_ptr);
                                        segment_max = single(segment_min * 2);
                                        segment_step = single((segment_max - segment_min) / BIN_NUM);
                                        bin_ptr = floor((r2 - segment_min)/segment_step) + 1;            % the bin_ptr will give which bin it locate
                                        % Calculate the index for table lookup
                                        lut_index = seg_ptr * BIN_NUM + bin_ptr;
                                        % Fetch the index for the polynomials
                                        c0_vdw14 = single(read_in_c0_vdw14{1}(lut_index));
                                        c1_vdw14 = single(read_in_c1_vdw14{1}(lut_index));
                                        if INTERPOLATION_ORDER > 1
                                            c2_vdw14 = single(read_in_c2_vdw14{1}(lut_index));
                                        end
                                        if INTERPOLATION_ORDER > 2
                                            c3_vdw14 = single(read_in_c3_vdw14{1}(lut_index));
                                        end
                                        c0_vdw8 = single(read_in_c0_vdw8{1}(lut_index));
                                        c1_vdw8 = single(read_in_c1_vdw8{1}(lut_index));
                                        if INTERPOLATION_ORDER > 1
                                            c2_vdw8 = single(read_in_c2_vdw8{1}(lut_index));
                                        end
                                        if INTERPOLATION_ORDER > 2
                                            c3_vdw8 = single(read_in_c3_vdw8{1}(lut_index));
                                        end
                                        % Calculate the poly value
                                        switch(INTERPOLATION_ORDER)
                                            case 1
                                                vdw14 = polyval([c1_vdw14 c0_vdw14], r2);
                                                vdw8 = polyval([c1_vdw8 c0_vdw8], r2);
                                            case 2
                                                vdw14 = polyval([c2_vdw14 c1_vdw14 c0_vdw14], r2);
                                                vdw8 = polyval([c2_vdw8 c1_vdw8 c0_vdw8], r2);
                                            case 3
                                                vdw14 = polyval([c3_vdw14 c2_vdw14 c1_vdw14 c0_vdw14], r2);
                                                vdw8 = polyval([c3_vdw8 c2_vdw8 c1_vdw8 c0_vdw8], r2);
                                        end
                                    % Direct Evaluation
                                    else
                                        inv_r2 = 1 / r2;
                                        vdw14 = OUTPUT_SCALE_INDEX * 48 * EPS * SIGMA ^ 12 * inv_r2^7;
                                        vdw8  = OUTPUT_SCALE_INDEX * 24 * EPS * SIGMA ^ 6  * inv_r2^4;
                                    end
                                    % Calculate the total force
                                    F_LJ = single(vdw14) - single(vdw8);
                                    F_LJ_x = single(F_LJ * dx);
                                    F_LJ_y = single(F_LJ * dy);
                                    F_LJ_z = single(F_LJ * dz);

                                    % Accumulate force for reference particles
                                    tmp_force_acc_x = tmp_force_acc_x + F_LJ_x;
                                    tmp_force_acc_y = tmp_force_acc_y + F_LJ_y;
                                    tmp_force_acc_z = tmp_force_acc_z + F_LJ_z;

                                    %% Accumulate the particle force to neighbor particles
                                    neg_F_LJ_x = single(-F_LJ_x);
                                    neg_F_LJ_y = single(-F_LJ_y);
                                    neg_F_LJ_z = single(-F_LJ_z);
                                    % Don't accumulate for home cell
                                    if filter_id > 1
                                        neighbor_cell_x = filter_input_particle_reservoir(filter_id,neighbor_particle_ptr,4);
                                        neighbor_cell_y = filter_input_particle_reservoir(filter_id,neighbor_particle_ptr,5);
                                        neighbor_cell_z = filter_input_particle_reservoir(filter_id,neighbor_particle_ptr,6);
                                        neighbor_cell_ptr_tmp = filter_input_particle_reservoir(filter_id,neighbor_particle_ptr,7);
                                        % Get the neighbor cell id
                                        neighbor_cell_id = (neighbor_cell_x-1)*CELL_COUNT_Y*CELL_COUNT_Z + (neighbor_cell_y-1)*CELL_COUNT_Z + neighbor_cell_z;
                                        % Get current force value
                                        tmp_neighbor_force_x = cell_particle(neighbor_cell_id,neighbor_cell_ptr_tmp,4);
                                        tmp_neighbor_force_y = cell_particle(neighbor_cell_id,neighbor_cell_ptr_tmp,5);
                                        tmp_neighbor_force_z = cell_particle(neighbor_cell_id,neighbor_cell_ptr_tmp,6);
                                        % Accumulate force for neighbor particles
                                        tmp_neighbor_force_x = tmp_neighbor_force_x + neg_F_LJ_x;
                                        tmp_neighbor_force_y = tmp_neighbor_force_y + neg_F_LJ_y;
                                        tmp_neighbor_force_z = tmp_neighbor_force_z + neg_F_LJ_z;
                                        % Write back accumulated force
                                        cell_particle(neighbor_cell_id,neighbor_cell_ptr_tmp,4:6) = [tmp_neighbor_force_x, tmp_neighbor_force_y, tmp_neighbor_force_z];
                                        cell_particle(neighbor_cell_id,neighbor_cell_ptr_tmp,12) = cell_particle(neighbor_cell_id,neighbor_cell_ptr_tmp,12) + 1;                                
                                    % End of accumulating force to neighbor particles
                                    end

                                    %% Evaluate the LJ Potential when needed
                                    if ENABLE_ENERGY_EVALUATION
                                        % Use Interploation for energy evaluation
                                        if ENABLE_INTERPOLATION
                                            % Fetch the index for the polynomials
                                            c0_vdw12 = single(read_in_c0_vdw12{1}(lut_index));
                                            c1_vdw12 = single(read_in_c1_vdw12{1}(lut_index));
                                            if INTERPOLATION_ORDER > 1
                                                c2_vdw12 = single(read_in_c2_vdw12{1}(lut_index));
                                            end
                                            if INTERPOLATION_ORDER > 2
                                                c3_vdw12 = single(read_in_c3_vdw12{1}(lut_index));
                                            end
                                            c0_vdw6 = single(read_in_c0_vdw6{1}(lut_index));
                                            c1_vdw6 = single(read_in_c1_vdw6{1}(lut_index));
                                            if INTERPOLATION_ORDER > 1
                                                c2_vdw6 = single(read_in_c2_vdw6{1}(lut_index));
                                            end
                                            if INTERPOLATION_ORDER > 2
                                                c3_vdw6 = single(read_in_c3_vdw6{1}(lut_index));
                                            end
                                            % Calculate the poly value
                                            switch(INTERPOLATION_ORDER)
                                                case 1
                                                    vdw12 = polyval([c1_vdw12 c0_vdw12], r2);
                                                    vdw6 = polyval([c1_vdw6 c0_vdw6], r2);
                                                case 2
                                                    vdw12 = polyval([c2_vdw12 c1_vdw12 c0_vdw12], r2);
                                                    vdw6 = polyval([c2_vdw6 c1_vdw6 c0_vdw6], r2);
                                                case 3
                                                    vdw12 = polyval([c3_vdw12 c2_vdw12 c1_vdw12 c0_vdw12], r2);
                                                    vdw6 = polyval([c3_vdw6 c2_vdw6 c1_vdw6 c0_vdw6], r2);
                                            end
                                        % Use direct computation for energy evaluation
                                        else
                                            vdw12 = OUTPUT_SCALE_INDEX * 4 * EPS * SIGMA ^ 12 * inv_r2^6;
                                            vdw6 = OUTPUT_SCALE_INDEX * 4 * EPS * SIGMA ^ 6 * inv_r2^3;
                                        end
                                        % Calculate the LJ Potential
                                        E_LJ = single(vdw12) - single(vdw6);
                                        % Accumulate the LJ potential for reference particle
                                        tmp_potential_acc = tmp_potential_acc + E_LJ;

                                        % Accumulate the LJ potential to neighbor particles
                                        % Don't accumulate for home cell
                                        if filter_id > 1
                                            cell_particle(neighbor_cell_id,neighbor_cell_ptr_tmp,10) = cell_particle(neighbor_cell_id,neighbor_cell_ptr_tmp,10) + E_LJ;
                                        end
                                    % End of LJ potential evaluation
                                    end

                                % End of force & energy evaluation and accumulation
                                end
                            end
                        % End of current filter
                        end
                    % End of one round-robin process across all filters
                    end

                    % Write the accumulated reference force to array
                    tmp_force_acc_x = cell_particle(home_cell_id,ref_particle_ptr,4) + tmp_force_acc_x;
                    tmp_force_acc_y = cell_particle(home_cell_id,ref_particle_ptr,5) + tmp_force_acc_y;
                    tmp_force_acc_z = cell_particle(home_cell_id,ref_particle_ptr,6) + tmp_force_acc_z;
                    cell_particle(home_cell_id,ref_particle_ptr,4:6) = [tmp_force_acc_x, tmp_force_acc_y, tmp_force_acc_z];
                    % Write the accumulated energy to array
                    if ENABLE_ENERGY_EVALUATION
                        cell_particle(home_cell_id,ref_particle_ptr,10) = cell_particle(home_cell_id,ref_particle_ptr,10) + tmp_potential_acc;
                    end
                    % Write the particle pairs that lies within the cutoff radius with the reference particle
                    cell_particle(home_cell_id,ref_particle_ptr,12) = cell_particle(home_cell_id,ref_particle_ptr,12) + tmp_counter_particles_within_cutoff;

                % End of ref_particle_ptr
                end
                
                % Print out which homecell is done processing
                if ENABLE_PRINT_DETAIL_MESSAGE
                    fprintf('Homecell(%d,%d,%d): Force Evaluation done!\n', HOME_CELL_X, HOME_CELL_Y, HOME_CELL_Z);
                end
                
            % End of homecell on Z Dir
            end
        % End of homecell on Y Dir
        end
    % End of homecell on X Dir, all done   
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Energy Evaluation: Individual Kinetic Energy and System Total Energy
    %% The energy is evaluated based on the position and velocity at the beginning of the current iteration
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ENABLE_ENERGY_EVALUATION
        energy_evaluation_counter = energy_evaluation_counter + 1;
        potential_energy_acc = 0;
        kinetic_energy_acc = 0;
        for homecell_ptr_x = 1:length(HOME_CELL_X_RANGE)
            CUR_CELL_X = HOME_CELL_X_RANGE(homecell_ptr_x);
            for homecell_ptr_y = 1:length(HOME_CELL_Y_RANGE)
                CUR_CELL_Y = HOME_CELL_Y_RANGE(homecell_ptr_y);
                for homecell_ptr_z = 1:length(HOME_CELL_Z_RANGE)
                    CUR_CELL_Z = HOME_CELL_Z_RANGE(homecell_ptr_z);
                    cur_cell_id = (CUR_CELL_X-1)*CELL_COUNT_Y*CELL_COUNT_Z + (CUR_CELL_Y-1)*CELL_COUNT_Z + CUR_CELL_Z;
                    for particle_ptr = 1:particle_in_cell_counter(CUR_CELL_X,CUR_CELL_Y,CUR_CELL_Z)
                        %% Evaluate the individual Kinectic Energy First
                        v_x = cell_particle(cur_cell_id,particle_ptr,7);
                        v_y = cell_particle(cur_cell_id,particle_ptr,8);
                        v_z = cell_particle(cur_cell_id,particle_ptr,9);
                        v2 = v_x^2 + v_y^2 + v_z^2;
                        Ekinect = 0.5 * MASS * v2 * 10^-20;       % v unit is ang/s, MASS unit is kg, Ek unit supposed to be J(kg*m^2*s^-2);
                        cell_particle(cur_cell_id,particle_ptr,11) = Ekinect;
                        %% Evaluate the total energy
                        potential_energy_acc = cell_particle(cur_cell_id,particle_ptr,10) + potential_energy_acc;
                        kinetic_energy_acc = cell_particle(cur_cell_id,particle_ptr,11) + kinetic_energy_acc;
                    end
                end
            end
        end
        % Record the energy value
        energy_data_history(energy_evaluation_counter,1) = potential_energy_acc / 2;
        energy_data_history(energy_evaluation_counter,2) = kinetic_energy_acc;                                      % Unit: J
        energy_data_history(energy_evaluation_counter,3) = potential_energy_acc / 2 + kinetic_energy_acc * 10^-3;   % Unit: kJ
%        if ENABLE_PRINT_DETAIL_MESSAGE
            fprintf('Iteration %d, LJ energy %f, Kinectic energy %d, Total energy %f.\n', sim_iteration, energy_data_history(energy_evaluation_counter,1:3))
%        end

        % Write the energy result to output file
        if ENABLE_OUTPUT_ENERGY_FILE
            fprintf(OUTPUT_FILE_ID, '%d\t%e\t%e\t%e\n', sim_iteration, energy_data_history(energy_evaluation_counter,1:3));
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Motion Update Logic: Update location and Velocity
    %% The new data is write to an seprate array
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Clear the temp arrays
    tmp_particle_in_cell_counter = zeros(CELL_COUNT_X,CELL_COUNT_Y,CELL_COUNT_Z);
    tmp_cell_particle = single(zeros(CELL_COUNT_X*CELL_COUNT_Y*CELL_COUNT_Z,CELL_PARTICLE_MAX,12));
    % Traverse all cells
    for homecell_ptr_x = 1:length(HOME_CELL_X_RANGE)
        CUR_CELL_X = HOME_CELL_X_RANGE(homecell_ptr_x);
        min_x = (CUR_CELL_X - 1) * CUTOFF_RADIUS;
        max_x = CUR_CELL_X * CUTOFF_RADIUS;
        for homecell_ptr_y = 1:length(HOME_CELL_Y_RANGE)
            CUR_CELL_Y = HOME_CELL_Y_RANGE(homecell_ptr_y);
            min_y = (CUR_CELL_Y - 1) * CUTOFF_RADIUS;
            max_y = CUR_CELL_Y * CUTOFF_RADIUS;
            for homecell_ptr_z = 1:length(HOME_CELL_Z_RANGE)
                CUR_CELL_Z = HOME_CELL_Z_RANGE(homecell_ptr_z);
                min_z = (CUR_CELL_Z - 1) * CUTOFF_RADIUS;
                max_z = CUR_CELL_Z * CUTOFF_RADIUS;
                cur_cell_id = (CUR_CELL_X-1)*CELL_COUNT_Y*CELL_COUNT_Z + (CUR_CELL_Y-1)*CELL_COUNT_Z + CUR_CELL_Z;
                %particle_in_cell_counter = zeros(CELL_COUNT_X,CELL_COUNT_Y,CELL_COUNT_Z);
                %cell_particle = single(zeros(CELL_COUNT_X*CELL_COUNT_Y*CELL_COUNT_Z,CELL_PARTICLE_MAX,12));
                %tmp_particle_in_cell_counter = zeros(CELL_COUNT_X,CELL_COUNT_Y,CELL_COUNT_Z);
                %tmp_cell_particle = single(zeros(CELL_COUNT_X*CELL_COUNT_Y*CELL_COUNT_Z,CELL_PARTICLE_MAX,12));

                % Traverse each particle in the cell
                for particle_ptr = 1:particle_in_cell_counter(CUR_CELL_X,CUR_CELL_Y,CUR_CELL_Z)
                    % Fetch the current value
                    pos_x = cell_particle(cur_cell_id,particle_ptr,1);
                    pos_y = cell_particle(cur_cell_id,particle_ptr,2);
                    pos_z = cell_particle(cur_cell_id,particle_ptr,3);
                    force_x = cell_particle(cur_cell_id,particle_ptr,4);
                    force_y = cell_particle(cur_cell_id,particle_ptr,5);
                    force_z = cell_particle(cur_cell_id,particle_ptr,6);
                    v_x = cell_particle(cur_cell_id,particle_ptr,7);
                    v_y = cell_particle(cur_cell_id,particle_ptr,8);
                    v_z = cell_particle(cur_cell_id,particle_ptr,9);
                    % Update Velocity
                    v_x = v_x + (force_x / MASS) * SIMULATION_TIME_STEP;
                    v_y = v_y + (force_y / MASS) * SIMULATION_TIME_STEP;
                    v_z = v_z + (force_z / MASS) * SIMULATION_TIME_STEP;
                    % Update position
                    movement_x = v_x * SIMULATION_TIME_STEP;
                    movement_y = v_y * SIMULATION_TIME_STEP;
                    movement_z = v_z * SIMULATION_TIME_STEP;
                    pos_x = pos_x + movement_x;
                    pos_y = pos_y + movement_y;
                    pos_z = pos_z + movement_z;

                    % Apply boundary condition to the new position
                    pos_x = mod(pos_x, BOUNDING_BOX_SIZE_X);
                    pos_y = mod(pos_y, BOUNDING_BOX_SIZE_Y);
                    pos_z = mod(pos_z, BOUNDING_BOX_SIZE_Z);
                    % Correct the rare bug that when pos is a little bit smaller than BOUNDING_BOX_SIZE (say BOUNDING_BOX_SIZE-1.0e-10), it will return the value of BOUNDING_BOX_SIZE 
                    if pos_x == BOUNDING_BOX_SIZE_X
                        pos_x = 0;
                    end
                    if pos_y == BOUNDING_BOX_SIZE_Y
                        pos_y = 0;
                    end
                    if pos_z == BOUNDING_BOX_SIZE_Z
                        pos_z = 0;
                    end
                    % Update cell x
                    % use floor function to make sure when the coordinate is equal to the upper boundary, then move this particle to the next cell
                    target_cell_x = floor(pos_x/CUTOFF_RADIUS) + 1;
                    target_cell_y = floor(pos_y/CUTOFF_RADIUS) + 1;
                    target_cell_z = floor(pos_z/CUTOFF_RADIUS) + 1;
%{
                    % Determine the target cell
                    if pos_x >= min_x && pos_x < max_x
                        target_cell_x = CUR_CELL_X;
                    elseif pos_x >= max_x
                        % Boundary check
                        if CUR_CELL_X == CELL_COUNT_X
                            pos_x = pos_x - CELL_COUNT_X * CUTOFF_RADIUS;
                            target_cell_x = 1;
                        else
                            target_cell_x = CUR_CELL_X + 1;
                        end
                    else
                        if CUR_CELL_X == 1
                            pos_x = pos_x + CELL_COUNT_X * CUTOFF_RADIUS;
                            target_cell_x = CELL_COUNT_X;
                        else
                            target_cell_x = CELL_COUNT_X - 1;
                        end
                    end
                    % Update cell y
                    if pos_y >= min_y && pos_y < max_y
                        target_cell_y = CUR_CELL_Y;
                    elseif pos_y >= max_y
                        % Boundary check
                        if CUR_CELL_Y == CELL_COUNT_Y
                            pos_y = pos_y - CELL_COUNT_Y * CUTOFF_RADIUS;
                            target_cell_y = 1;
                        else
                            target_cell_y = CUR_CELL_Y + 1;
                        end
                    else
                        if CUR_CELL_Y == 1
                            pos_y = pos_y + CELL_COUNT_Y * CUTOFF_RADIUS;
                            target_cell_y = CELL_COUNT_Y;
                        else
                            target_cell_y = CELL_COUNT_Y - 1;
                        end
                    end
                    % Update cell z
                    if pos_z >= min_z && pos_z < max_z
                        target_cell_z = CUR_CELL_Z;
                    elseif pos_z >= max_z
                        % Boundary check
                        if CUR_CELL_Z == CELL_COUNT_Z
                            pos_z = pos_z - CELL_COUNT_Z * CUTOFF_RADIUS;
                            target_cell_z = 1;
                        else
                            target_cell_z = CUR_CELL_Z + 1;
                        end
                    else
                        if CUR_CELL_Z == 1
                            pos_z = pos_z + CELL_COUNT_Z * CUTOFF_RADIUS;
                            target_cell_z = CELL_COUNT_Z;
                        else
                            target_cell_z = CELL_COUNT_Z - 1;
                        end
                    end
%}
                    %% Assign the particle to new cells
                    new_particle_ptr = tmp_particle_in_cell_counter(target_cell_x, target_cell_y, target_cell_z) + 1;
                    target_cell_id = (target_cell_x-1)*CELL_COUNT_Y*CELL_COUNT_Z + (target_cell_y-1)*CELL_COUNT_Z + target_cell_z;
                    % Assign the position, force, velocity to temp array (clear the force value in this process)
                    tmp_cell_particle(target_cell_id,new_particle_ptr,1:9) = [pos_x,pos_y,pos_z,0,0,0,v_x,v_y,v_z];
                    % DO NOT!!! Assign the energy value to temp array, thus clear the energy value for the next iteration
                    %tmp_cell_particle(target_cell_id,new_particle_ptr,10) = cell_particle(cur_cell_id,particle_ptr,10);
                    %tmp_cell_particle(target_cell_id,new_particle_ptr,11) = cell_particle(cur_cell_id,particle_ptr,11);
                    % Assign the num of particles in the new cell
                    tmp_particle_in_cell_counter(target_cell_x, target_cell_y, target_cell_z) = new_particle_ptr;
                end
            end
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Force and Energy Verification logic
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ENABLE_VERIFICATION
        TARGET_HOME_CELL_X_POOL = 1:3;%1:1:5;
        TARGET_HOME_CELL_Y_POOL = 1:3;%1:1:5;
        TARGET_HOME_CELL_Z_POOL = 1:3;%1:1:5;
        TARGET_HOME_CELL_PARTICLE_ID_POOL = 1:3;%1:1:5;
        for testing_ptr = 1:length(TARGET_HOME_CELL_X_POOL)
            TARGET_HOME_CELL_X = TARGET_HOME_CELL_X_POOL(testing_ptr);
            TARGET_HOME_CELL_Y = TARGET_HOME_CELL_Y_POOL(testing_ptr);
            TARGET_HOME_CELL_Z = TARGET_HOME_CELL_Z_POOL(testing_ptr);
            TARGET_HOME_CELL_PARTICLE_ID = TARGET_HOME_CELL_PARTICLE_ID_POOL(testing_ptr);
            target_cell_id = (TARGET_HOME_CELL_X-1)*CELL_COUNT_Y*CELL_COUNT_Z + (TARGET_HOME_CELL_Y-1)*CELL_COUNT_Z + TARGET_HOME_CELL_Z;
            ref_pos_x = cell_particle(target_cell_id, TARGET_HOME_CELL_PARTICLE_ID,1);
            ref_pos_y = cell_particle(target_cell_id, TARGET_HOME_CELL_PARTICLE_ID,2);
            ref_pos_z = cell_particle(target_cell_id, TARGET_HOME_CELL_PARTICLE_ID,3);
            % Neighbor cell range
            % Apply periodic boundary condition
            if TARGET_HOME_CELL_X == 1
                VERIFICATION_CELL_X_RANGE = [CELL_COUNT_X TARGET_HOME_CELL_X TARGET_HOME_CELL_X+1];
            elseif TARGET_HOME_CELL_X == CELL_COUNT_X
                VERIFICATION_CELL_X_RANGE = [TARGET_HOME_CELL_X-1 TARGET_HOME_CELL_X 1];
            else
                VERIFICATION_CELL_X_RANGE = [TARGET_HOME_CELL_X-1 TARGET_HOME_CELL_X TARGET_HOME_CELL_X+1];
            end
            if TARGET_HOME_CELL_Y == 1
                VERIFICATION_CELL_Y_RANGE = [CELL_COUNT_Y TARGET_HOME_CELL_Y TARGET_HOME_CELL_Y+1];
            elseif TARGET_HOME_CELL_Y == CELL_COUNT_Y
                VERIFICATION_CELL_Y_RANGE = [TARGET_HOME_CELL_Y-1 TARGET_HOME_CELL_Y 1];
            else
                VERIFICATION_CELL_Y_RANGE = [TARGET_HOME_CELL_Y-1 TARGET_HOME_CELL_Y TARGET_HOME_CELL_Y+1];
            end
            if TARGET_HOME_CELL_Z == 1
                VERIFICATION_CELL_Z_RANGE = [CELL_COUNT_Z TARGET_HOME_CELL_Z TARGET_HOME_CELL_Z+1];
            elseif TARGET_HOME_CELL_Z == CELL_COUNT_Z
                VERIFICATION_CELL_Z_RANGE = [TARGET_HOME_CELL_Z-1 TARGET_HOME_CELL_Z 1];
            else
                VERIFICATION_CELL_Z_RANGE = [TARGET_HOME_CELL_Z-1 TARGET_HOME_CELL_Z TARGET_HOME_CELL_Z+1];
            end
            % Initialize the accumulator for verification
            Fvdw_verification_x = 0;
            Fvdw_verification_y = 0;
            Fvdw_verification_z = 0;
            Evdw_verification_acc = 0;
            % Initialize the counter for partner particles
            num_particle_within_cutoff = 0;
            %Traverse all the 27 neighbor cells (homecell + 26 neighbors)
            for verfication_cell_ptr_x = 1:3
                neighbor_cell_x = VERIFICATION_CELL_X_RANGE(verfication_cell_ptr_x);
                for verfication_cell_ptr_y = 1:3
                    neighbor_cell_y = VERIFICATION_CELL_Y_RANGE(verfication_cell_ptr_y);
                    for verfication_cell_ptr_z = 1:3
                        neighbor_cell_z = VERIFICATION_CELL_Z_RANGE(verfication_cell_ptr_z);
                        neighbor_cell_id = (neighbor_cell_x-1)*CELL_COUNT_Y*CELL_COUNT_Z + (neighbor_cell_y-1)*CELL_COUNT_Z + neighbor_cell_z;
                        % Traverse all the particles in those cells
                        for neighbor_particle_ptr = 1:particle_in_cell_counter(neighbor_cell_x,neighbor_cell_y,neighbor_cell_z)
                            % Fetch the neighbor particle position
                            neighbor_pos_x = cell_particle(neighbor_cell_id,neighbor_particle_ptr,1);
                            neighbor_pos_y = cell_particle(neighbor_cell_id,neighbor_particle_ptr,2);
                            neighbor_pos_z = cell_particle(neighbor_cell_id,neighbor_particle_ptr,3);
                            % Calculate r2
                            dx = ref_pos_x - neighbor_pos_x;
                            dy = ref_pos_y - neighbor_pos_y;
                            dz = ref_pos_z - neighbor_pos_z;
                            % Apply periodic boundary condition
                            dx = dx - BOUNDING_BOX_SIZE_X * round(dx/BOUNDING_BOX_SIZE_X);
                            dy = dy - BOUNDING_BOX_SIZE_Y * round(dy/BOUNDING_BOX_SIZE_Y);
                            dz = dz - BOUNDING_BOX_SIZE_Z * round(dz/BOUNDING_BOX_SIZE_Z);
                            % Calculate R2
                            r2 = dx^2 + dy^2 + dz^2;
                            % Filter
                            if r2 >= EXCLUSION_2 &&  r2 < CUTOFF_RADIUS_2 
                                num_particle_within_cutoff = num_particle_within_cutoff + 1;
                                % Evaluate LJ force
                                inv_r2 = 1 / r2;
                                vdw14_verification = OUTPUT_SCALE_INDEX * 48 * EPS * SIGMA ^ 12 * inv_r2^7;
                                vdw8_verification  = OUTPUT_SCALE_INDEX * 24 * EPS * SIGMA ^ 6  * inv_r2^4;
                                Fvdw_verification = vdw14_verification - vdw8_verification;
                                % Accumulation
                                Fvdw_verification_x = Fvdw_verification * dx + Fvdw_verification_x;
                                Fvdw_verification_y = Fvdw_verification * dy + Fvdw_verification_y;
                                Fvdw_verification_z = Fvdw_verification * dz + Fvdw_verification_z;
                                % Evaluate LJ potential
                                if ENABLE_ENERGY_EVALUATION
                                    vdw12_verification = OUTPUT_SCALE_INDEX * 4 * EPS * SIGMA ^ 12 * inv_r2^6;
                                    vdw6_verification = OUTPUT_SCALE_INDEX * 4 * EPS * SIGMA ^ 6 * inv_r2^3;
                                    Evdw_verification = vdw12_verification - vdw6_verification;
                                    % Accumulation
                                    Evdw_verification_acc = Evdw_verification_acc + Evdw_verification;
                                end
                            end
                        end
                    end
                end
            end
            % Fetch Evaluated result
            Fvdw_evaluated_x = cell_particle(target_cell_id,TARGET_HOME_CELL_PARTICLE_ID,4);
            Fvdw_evaluated_y = cell_particle(target_cell_id,TARGET_HOME_CELL_PARTICLE_ID,5);
            Fvdw_evaluated_z = cell_particle(target_cell_id,TARGET_HOME_CELL_PARTICLE_ID,6);
            % Print out verification result
            fprintf('The targeted verification particle is Cell(%d,%d,%d), particle ID %d, (%f,%f,%f)\n', TARGET_HOME_CELL_X, TARGET_HOME_CELL_Y, TARGET_HOME_CELL_Z,TARGET_HOME_CELL_PARTICLE_ID,ref_pos_x,ref_pos_y,ref_pos_z);
            fprintf('The Evaluated LJ force result is %e,%e,%e, num particle is %d\n',Fvdw_evaluated_x, Fvdw_evaluated_y, Fvdw_evaluated_z, cell_particle(target_cell_id,TARGET_HOME_CELL_PARTICLE_ID,12));
            fprintf('The Verification LJ force result is %e,%e,%e, num particle is %d\n',Fvdw_verification_x, Fvdw_verification_y, Fvdw_verification_z, num_particle_within_cutoff);
            fprintf('LJ Force Error rate is %f%%, %f%%, %f%%\n', abs((Fvdw_verification_x-Fvdw_evaluated_x)/Fvdw_verification_x)*100, abs((Fvdw_verification_y-Fvdw_evaluated_y)/Fvdw_verification_y)*100,abs((Fvdw_verification_z-Fvdw_evaluated_z)/Fvdw_verification_z)*100);
            if ENABLE_ENERGY_EVALUATION
                fprintf('The Evaluated LJ energy result is %e, num particle is %d\n',cell_particle(target_cell_id,TARGET_HOME_CELL_PARTICLE_ID,10), cell_particle(target_cell_id,TARGET_HOME_CELL_PARTICLE_ID,12));
                fprintf('The Verification LJ energy result is %e, num particle is %d\n',Evdw_verification_acc, num_particle_within_cutoff);
                fprintf('LJ Energy Error rate is %f%%\n', abs(cell_particle(target_cell_id,TARGET_HOME_CELL_PARTICLE_ID,10)-Evdw_verification_acc)/Evdw_verification_acc*100);
            end
        % End of evaluating the current particle
        end
    % End of testing phase
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Plot all particles out for fun
    %% The plot out position is based on the status at the beginning of the current iteration
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    tmp_position_data = single(zeros(TOTAL_PARTICLE,3));
    tmp_particle_counter = 0;
    % Traverse all the cells and generate the output plot array
    for homecell_ptr_x = 1:length(HOME_CELL_X_RANGE)
        CUR_CELL_X = HOME_CELL_X_RANGE(homecell_ptr_x);
        for homecell_ptr_y = 1:length(HOME_CELL_Y_RANGE)
            CUR_CELL_Y = HOME_CELL_Y_RANGE(homecell_ptr_y);
            for homecell_ptr_z = 1:length(HOME_CELL_Z_RANGE)
                CUR_CELL_Z = HOME_CELL_Z_RANGE(homecell_ptr_z);
                cur_cell_id = (CUR_CELL_X-1)*CELL_COUNT_Y*CELL_COUNT_Z + (CUR_CELL_Y-1)*CELL_COUNT_Z + CUR_CELL_Z;
                for particle_ptr = 1:particle_in_cell_counter(CUR_CELL_X,CUR_CELL_Y,CUR_CELL_Z)
                    tmp_particle_counter = tmp_particle_counter + 1;
                    tmp_position_data(tmp_particle_counter,1) = cell_particle(cur_cell_id,particle_ptr,1);
                    tmp_position_data(tmp_particle_counter,2) = cell_particle(cur_cell_id,particle_ptr,2);
                    tmp_position_data(tmp_particle_counter,3) = cell_particle(cur_cell_id,particle_ptr,3);
                    % Record history of position
                    position_data_history(sim_iteration,tmp_particle_counter,1) = cell_particle(cur_cell_id,particle_ptr,1);
                    position_data_history(sim_iteration,tmp_particle_counter,2) = cell_particle(cur_cell_id,particle_ptr,2);
                    position_data_history(sim_iteration,tmp_particle_counter,3) = cell_particle(cur_cell_id,particle_ptr,3);
                    % Record history of energy
                    position_data_history(sim_iteration,tmp_particle_counter,4) = cell_particle(cur_cell_id,particle_ptr,10);
                    position_data_history(sim_iteration,tmp_particle_counter,5) = cell_particle(cur_cell_id,particle_ptr,11);
                end
            end
        end
    end
    if ENABLE_SCATTER_PLOTTING
        clf;
        % 3D scatter plot all the particles position
        figure(1);
        scatter3(tmp_position_data(:,1),tmp_position_data(:,2),tmp_position_data(:,3));
        title_str = sprintf('Iteration %d', sim_iteration);
        title(title_str);
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Update the CELLLIST from the Motion Update Temp array
    %% The Force and Energy value is reset after this 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    particle_in_cell_counter = tmp_particle_in_cell_counter(:,:,:);
    cell_particle = tmp_cell_particle(:,:,:);

% End of current simulation iteration
end

%% Close the output file
if ENABLE_OUTPUT_ENERGY_FILE
    fclose(OUTPUT_FILE_ID);
end

%% Plot the energy waveform
figure(2);
subplot(3,1,1);
plot(1:ceil(SIMULATION_TIMESTEP/ENERGY_EVALUATION_STEPS), energy_data_history(1:ceil(SIMULATION_TIMESTEP/ENERGY_EVALUATION_STEPS),1));
title('System LJ Energy');
ylabel('kJ');
subplot(3,1,2);
plot(1:ceil(SIMULATION_TIMESTEP/ENERGY_EVALUATION_STEPS), energy_data_history(1:ceil(SIMULATION_TIMESTEP/ENERGY_EVALUATION_STEPS),2));
title('System Kinetic Energy')
ylabel('???');
subplot(3,1,3);
plot(1:ceil(SIMULATION_TIMESTEP/ENERGY_EVALUATION_STEPS), energy_data_history(1:ceil(SIMULATION_TIMESTEP/ENERGY_EVALUATION_STEPS),3));
title('System Total Energy')
ylabel('kJ');

%% Measure the total runtime
END_TIME = cputime;
fprintf('Total runtime is %d seconds.\n', END_TIME-START_TIME);



% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% Some real verification
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ref_x = single(18.775122);
% ref_y = single(16.947981);
% ref_z = single(15.622027);
% Fx_acc = single(0);
% Fy_acc = single(0);
% Fz_acc = single(0);
% counter = 0;
% for particle_ptr = 1:TOTAL_PARTICLE
%     neighbor_x = position_data(particle_ptr,1);
%     neighbor_y = position_data(particle_ptr,2);
%     neighbor_z = position_data(particle_ptr,3);
%     dx = ref_x - neighbor_x;
%     dy = ref_y - neighbor_y;
%     dz = ref_z - neighbor_z;
%     r2 = dx^2 + dy^2 + dz^2;
%     if r2 > 0 && r2 < CUTOFF_RADIUS_2
%         counter = counter + 1;
%         inv_r2 = 1/r2; 
%         vdw14_verification = OUTPUT_SCALE_INDEX * 48 * EPS * SIGMA ^ 12 * inv_r2^7;
%         vdw8_verification  = OUTPUT_SCALE_INDEX * 24 * EPS * SIGMA ^ 6  * inv_r2^4;
%         Fvdw_verification = vdw14_verification - vdw8_verification;
%         Fx_acc = Fx_acc + Fvdw_verification*dx;
%         Fy_acc = Fy_acc + Fvdw_verification*dy;
%         Fz_acc = Fz_acc + Fvdw_verification*dz;
%     end
% end
% fprintf('The Verification LJ force result is %e,%e,%e, num particle is %d\n',Fx_acc, Fy_acc, Fz_acc, counter);


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% Some other verification logic, evaluate the reference particle force from the 13 upper neighbors and the homecells
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NEIGHBOR_CELL_POOL_X = [3 3 3 3 3 4 4 4 4 4 4 4 4 4];
% NEIGHBOR_CELL_POOL_Y = [3 3 4 4 4 2 2 2 3 3 3 4 4 4];
% NEIGHBOR_CELL_POOL_Z = [3 4 2 3 4 2 3 4 2 3 4 2 3 4];
% ref_x = single(18.775122);
% ref_y = single(16.947981);
% ref_z = single(15.622027);
% Fx_acc = single(0);
% Fy_acc = single(0);
% Fz_acc = single(0);
% counter = 0;
% for cell_ptr = 1:length(NEIGHBOR_CELL_POOL_X)
%     neighbor_cell_x = NEIGHBOR_CELL_POOL_X(cell_ptr);
%     neighbor_cell_y = NEIGHBOR_CELL_POOL_Y(cell_ptr);
%     neighbor_cell_z = NEIGHBOR_CELL_POOL_Z(cell_ptr);
%     neighbor_cell_id = (neighbor_cell_x-1)*CELL_COUNT_Y*CELL_COUNT_Z + (neighbor_cell_y-1)*CELL_COUNT_Z + neighbor_cell_z;
%     neighbor_cell_particle_num = particle_in_cell_counter(neighbor_cell_x,neighbor_cell_y,neighbor_cell_z);
%     for particle_ptr = 1:neighbor_cell_particle_num
%         neighbor_x = cell_particle(neighbor_cell_id,particle_ptr,1);
%         neighbor_y = cell_particle(neighbor_cell_id,particle_ptr,2);
%         neighbor_z = cell_particle(neighbor_cell_id,particle_ptr,3);
%         dx = ref_x - neighbor_x;
%         dy = ref_y - neighbor_y;
%         dz = ref_z - neighbor_z;
%         r2 = dx^2 + dy^2 + dz^2;
%         if r2 > 0 && r2 < CUTOFF_RADIUS_2
%             counter = counter + 1;
%             inv_r2 = 1/r2; 
%             vdw14_verification = OUTPUT_SCALE_INDEX * 48 * EPS * SIGMA ^ 12 * inv_r2^7;
%             vdw8_verification  = OUTPUT_SCALE_INDEX * 24 * EPS * SIGMA ^ 6  * inv_r2^4;
%             Fvdw_verification = vdw14_verification - vdw8_verification;
%             Fx_acc = Fx_acc + Fvdw_verification*dx;
%             Fy_acc = Fy_acc + Fvdw_verification*dy;
%             Fz_acc = Fz_acc + Fvdw_verification*dz;
%         end
%     end
% end
% fprintf('When serve as ref particles, the Evaluated LJ force result is %e,%e,%e, num particle is %d\n',Fx_acc, Fy_acc, Fz_acc, counter);
