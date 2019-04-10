NUM_ITERATION = 10000;
ENABLE_PBC = 1;                               % Enable periodic boundary condition
USING_INTERPOLATION = 1;
% Ar
DATASET_NAME = "LiquidArgon";
kb = 1.380e-23;                               % Boltzmann constant (J/K)S
Nav = 6.022e23;                               % Avogadro constant, # of atoms per mol
Ar_weight = 39.95;                            % g/mol value of Argon atom
EPS = 1.995996 * 1.995996;                    % Extracted from OpenMM, unit kJ      %0.996;% Unit: kJ	%0.238;% Unit kcal/mol	%kb * 120;% Unit J
SIGMA = 2.1;%3.4;%0.8;%0.1675*2;                   % Extracted from LJArgon, unit Angstrom        %3.35;%3.4;% Unit Angstrom    %3.4e-10;% Unit meter, the unit should be in consistant with position value
MASS = Ar_weight / Nav / 10^3;                % Unit kg
SIMULATION_TIME_STEP = 2E-15;                 % 2 femtosecond
CUTOFF_RADIUS = single(8.5);%single(SIGMA*2.5);%single(8);%single(7.65);      % Unit Angstrom, Cutoff Radius
CUTOFF_RADIUS_2 = CUTOFF_RADIUS^2;            % Cutoff distance square
CELL_COUNT_X = 7;%5;%3;
CELL_COUNT_Y = 6;%5;%3;
CELL_COUNT_Z = 6;%5;%3;
BOUNDING_BOX_SIZE_X = single(CELL_COUNT_X * CUTOFF_RADIUS);
BOUNDING_BOX_SIZE_Y = single(CELL_COUNT_Y * CUTOFF_RADIUS);
BOUNDING_BOX_SIZE_Z = single(CELL_COUNT_Z * CUTOFF_RADIUS);
% Dataset parameters
INPUT_SCALE_INDEX = 1;%1.0E10;                      % Set this as 10^10 if the input unit is in meters, or set as 1 when input unit is Angstrom
TOTAL_PARTICLE_NUM = 20000;%10000;%864;%500;
COMMON_PATH = "";
INPUT_FILE_FORMAT = "txt";%"pdb";                   % The input file format, can be "txt" or "pdb"
INPUT_FILE_NAME = "input_positions_ljargon_20000_box_58_49_49.txt";%"input_positions_ljargon_10000_40box.txt";%"ar_gas.pdb";%"input_positions_ljargon.txt";
% Interpolation Parameters
EXCLUSION = single(2^-1);                     % Unit Angstrom, If the particle pairs has closers distance than this value, then don't evaluate
EXCLUSION_2 = EXCLUSION ^ 2;                  % Exclusion distance square
RAW_R2_MIN = 2^-12;%2.242475;                 % Currently this value is not used
MIN_LOG_INDEX = floor(log(EXCLUSION_2)/log(2));
MIN_RANGE = 2^MIN_LOG_INDEX;                  % minimal range for the evaluation
MAX_LOG_INDEX = ceil(log(CUTOFF_RADIUS_2)/log(2));
MAX_RANGE = 2^MAX_LOG_INDEX;                  % maximum range for the evaluation (currently this is the cutoff radius)
INTERPOLATION_ORDER = 1;
SEGMENT_NUM = MAX_LOG_INDEX-MIN_LOG_INDEX;    % # of segment
BIN_NUM = 256;                                % # of bins per segment

% Position data array
% 1~3: posx, posy, posz; 4~6: vx, vy, vz; 8~10: Fx, Fy, Fz; 11: LJ Energy; 12: Kinetic Energy, 13: Neighbor particles within cutoff
position_data = single(zeros(TOTAL_PARTICLE_NUM,9));
energy_history = single(zeros(NUM_ITERATION,3));
position_data_history = single(zeros(NUM_ITERATION,TOTAL_PARTICLE_NUM,5));  % 1~3: posx, posy, posz; 4: LJ Energy; 5: Kinetic Energy;
% Output result file
OUTPUT_FILE_NAME = strcat('Output_Energy_Simplified_Model_',DATASET_NAME,'_',num2str(TOTAL_PARTICLE_NUM),'_iter_',num2str(NUM_ITERATION),'.txt');
OUTPUT_FILE_ID = fopen(OUTPUT_FILE_NAME,'w');

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
    while line_counter <= TOTAL_PARTICLE_NUM
        tline = fgets(fp);
        line_elements = textscan(tline,'%s %f64 %f64 %f64');
        position_data(line_counter,1) = line_elements{2}*INPUT_SCALE_INDEX;
        position_data(line_counter,2) = line_elements{3}*INPUT_SCALE_INDEX;
        position_data(line_counter,3) = line_elements{4}*INPUT_SCALE_INDEX;
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
    while line_counter <= TOTAL_PARTICLE_NUM
        tline = fgets(fp);
        line_elements = textscan(tline,'%s %s %s %s %s %s %f64 %f64 %f64 %s %s %s');
        position_data(line_counter,1) = line_elements{7};
        position_data(line_counter,2) = line_elements{8};
        position_data(line_counter,3) = line_elements{9};
        line_counter = line_counter + 1;
    end
end
% Close File
fclose(fp);
fprintf('Particle data loading finished!\n');

%% Find the min, max of raw data in each dimension
min_x  = min(position_data(1:TOTAL_PARTICLE_NUM,1));
max_x  = max(position_data(1:TOTAL_PARTICLE_NUM,1));
min_y  = min(position_data(1:TOTAL_PARTICLE_NUM,2));
max_y  = max(position_data(1:TOTAL_PARTICLE_NUM,2));
min_z  = min(position_data(1:TOTAL_PARTICLE_NUM,3));
max_z  = max(position_data(1:TOTAL_PARTICLE_NUM,3));
% shift all the data to positive
position_data(1:TOTAL_PARTICLE_NUM,1) = position_data(1:TOTAL_PARTICLE_NUM,1)-min_x;          % range: 0 ~ 347.7847
position_data(1:TOTAL_PARTICLE_NUM,2) = position_data(1:TOTAL_PARTICLE_NUM,2)-min_y;          % range: 0 ~ 347.7851
position_data(1:TOTAL_PARTICLE_NUM,3) = position_data(1:TOTAL_PARTICLE_NUM,3)-min_z;          % range: 0 ~ 347.7838
fprintf('All particles shifted to align on (0,0,0)\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Load in interpolation index data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if USING_INTERPOLATION
    fileID_0  = fopen('c0_14.txt', 'r');
    fileID_1  = fopen('c1_14.txt', 'r');
    fileID_4  = fopen('c0_8.txt', 'r');
    fileID_5  = fopen('c1_8.txt', 'r');
    fileID_8  = fopen('c0_12.txt', 'r');
    fileID_9  = fopen('c1_12.txt', 'r');
    fileID_12  = fopen('c0_6.txt', 'r');
    fileID_13  = fopen('c1_6.txt', 'r');
    % Fetch the index for the polynomials
    read_in_c0_vdw14 = textscan(fileID_0, '%f');
    read_in_c1_vdw14 = textscan(fileID_1, '%f');
    read_in_c0_vdw8 = textscan(fileID_4, '%f');
    read_in_c1_vdw8 = textscan(fileID_5, '%f');
    read_in_c0_vdw12 = textscan(fileID_8, '%f');
    read_in_c1_vdw12 = textscan(fileID_9, '%f');
    read_in_c0_vdw6 = textscan(fileID_12, '%f');
    read_in_c1_vdw6 = textscan(fileID_13, '%f');
    % close file
    fclose(fileID_0);
    fclose(fileID_1);
    fclose(fileID_4);
    fclose(fileID_5);
    fclose(fileID_8);
    fclose(fileID_9);
    fclose(fileID_12);
    fclose(fileID_13);
end

%% Start Evaluation
for iteration = 1:NUM_ITERATION
    % Traverse all the particles in the simulation space
    System_LJ_Energy = 0;
    Pairs_Evaluated_Counter = 0;
    for ref_ptr = 1:TOTAL_PARTICLE_NUM
        Evdw_acc = 0;
        Fx_acc = 0;
        Fy_acc = 0;
        Fz_acc = 0;
        ref_x = position_data(ref_ptr,1);
        ref_y = position_data(ref_ptr,2);
        ref_z = position_data(ref_ptr,3);
        particle_within_cutoff_counter = 0;
        for neighbor_ptr = 1:TOTAL_PARTICLE_NUM
            neighbor_x = position_data(neighbor_ptr,1);
            neighbor_y = position_data(neighbor_ptr,2);
            neighbor_z = position_data(neighbor_ptr,3);
            % Get dx
            dx = ref_x - neighbor_x;
            dy = ref_y - neighbor_y;
            dz = ref_z - neighbor_z;
            % Apply periodic boundary
            if ENABLE_PBC
                dx = dx - BOUNDING_BOX_SIZE_X * round(dx/BOUNDING_BOX_SIZE_X);
                dy = dy - BOUNDING_BOX_SIZE_Y * round(dy/BOUNDING_BOX_SIZE_Y);
                dz = dz - BOUNDING_BOX_SIZE_Z * round(dz/BOUNDING_BOX_SIZE_Z);
            end
            % Get dx
            r2 = dx*dx + dy*dy + dz*dz;
            % Apply cutoff
            if r2 > 0 && r2 <= CUTOFF_RADIUS_2
                Pairs_Evaluated_Counter = Pairs_Evaluated_Counter + 1;
                particle_within_cutoff_counter = particle_within_cutoff_counter + 1;
                
                % Using Table lookup for evaluation
                if USING_INTERPOLATION
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
                    c0_vdw8 = single(read_in_c0_vdw8{1}(lut_index));
                    c1_vdw8 = single(read_in_c1_vdw8{1}(lut_index));
                    c0_vdw12 = single(read_in_c0_vdw12{1}(lut_index));
                    c1_vdw12 = single(read_in_c1_vdw12{1}(lut_index));
                    c0_vdw6 = single(read_in_c0_vdw6{1}(lut_index));
                    c1_vdw6 = single(read_in_c1_vdw6{1}(lut_index));
                    % Calculate the poly value
                    vdw14 = polyval([c1_vdw14 c0_vdw14], r2);
                    vdw8 = polyval([c1_vdw8 c0_vdw8], r2);
                    vdw12 = polyval([c1_vdw12 c0_vdw12], r2);
                    vdw6 = polyval([c1_vdw6 c0_vdw6], r2);
                % Direct Evaluation
                else
                    inv_r2 = 1 / r2;
                    vdw14 = 48 * EPS * SIGMA ^ 12 * inv_r2^7;
                    vdw8  = 24 * EPS * SIGMA ^ 6  * inv_r2^4;
                    vdw12 = 4 * EPS * SIGMA ^ 12 * inv_r2^6;
                    vdw6 = 4 * EPS * SIGMA ^ 6 * inv_r2^3;
                end

                %% LJ Force and Energy
                Fvdw = vdw14 - vdw8;
                Evdw = vdw12 - vdw6;
                
                % Accumulate force
                Fx_acc = Fx_acc + Fvdw * dx;
                Fy_acc = Fy_acc + Fvdw * dy;
                Fz_acc = Fz_acc + Fvdw * dz;
                % Accumulate Energy
                Evdw_acc = Evdw_acc + Evdw;
            end
        end
        % Write back force
        position_data(ref_ptr,7) = Fx_acc;
        position_data(ref_ptr,8) = Fy_acc;
        position_data(ref_ptr,9) = Fz_acc;
        % Write back energy
        position_data(ref_ptr,10) = Evdw_acc;
        position_data(ref_ptr,12) = particle_within_cutoff_counter;

        %% Update Velocity
        acceleration_x = Fx_acc / MASS;
        acceleration_y = Fy_acc / MASS;
        acceleration_z = Fz_acc / MASS;
        % Velocity
        vx = position_data(ref_ptr,4);
        vy = position_data(ref_ptr,5);
        vz = position_data(ref_ptr,6);
        vx = vx + acceleration_x * SIMULATION_TIME_STEP;
        vy = vy + acceleration_y * SIMULATION_TIME_STEP;
        vz = vz + acceleration_z * SIMULATION_TIME_STEP;
        % Write back velocity
        position_data(ref_ptr,4) = vx;
        position_data(ref_ptr,5) = vy;
        position_data(ref_ptr,6) = vz;
%         % Kinetic energy
%         Ek = 0.5 * MASS * (vx*vx + vy*vy +vz*vz);
%         % Write back Ek
%         position_data(ref_ptr,11) = Ek;

        %% Accumualte System energy
        %System_LJ_Energy = System_LJ_Energy + Ek + Evdw_acc;
        System_LJ_Energy = System_LJ_Energy + Evdw_acc;
%         System_Ek = System_Ek + Ek;
    end

    %% Record history data
    for i=1:TOTAL_PARTICLE_NUM
        position_data_history(iteration,i,1) = position_data(i,1);
        position_data_history(iteration,i,2) = position_data(i,2);
        position_data_history(iteration,i,3) = position_data(i,3);
        position_data_history(iteration,i,4) = position_data(i,10);
        position_data_history(iteration,i,5) = position_data(i,11);
    end
    
    %% Correct momenta
    vx_avg = sum(position_data(:,4)) / TOTAL_PARTICLE_NUM;
    vy_avg = sum(position_data(:,5)) / TOTAL_PARTICLE_NUM;
    vz_avg = sum(position_data(:,6)) / TOTAL_PARTICLE_NUM;
    

    %% Motion Update & System Ek evaluation
    System_Ek = 0;
    for ptr = 1:TOTAL_PARTICLE_NUM
        posx = position_data(ptr, 1);
        posy = position_data(ptr, 2);
        posz = position_data(ptr, 3);
%        vx = position_data(ptr, 4) - vx_avg;
%        vy = position_data(ptr, 5) - vy_avg;
%        vz = position_data(ptr, 6) - vz_avg;
        vx = position_data(ptr, 4);
        vy = position_data(ptr, 5);
        vz = position_data(ptr, 6);
        posx = posx + vx*SIMULATION_TIME_STEP;
        posy = posy + vy*SIMULATION_TIME_STEP;
        posz = posz + vz*SIMULATION_TIME_STEP;
        % Periodic boundary
        if posx < 0
            posx = posx + BOUNDING_BOX_SIZE_X;
        elseif posx >= BOUNDING_BOX_SIZE_X
            posx = posx - BOUNDING_BOX_SIZE_X;
        end
        if posy < 0
            posy = posy + BOUNDING_BOX_SIZE_Y;
        elseif posy >= BOUNDING_BOX_SIZE_Y
            posy = posy - BOUNDING_BOX_SIZE_Y;
        end
        if posz < 0
            posz = posz + BOUNDING_BOX_SIZE_Z;
        elseif posz >= BOUNDING_BOX_SIZE_Z
            posz = posz - BOUNDING_BOX_SIZE_Z;
        end
        
        % Evaluate Ek
        % Kinetic energy
        Ek = 0.5 * MASS * (vx*vx + vy*vy +vz*vz) * 10^-20;       % v unit is ang/s, MASS unit is kg, Ek unit supposed to be J(kg*m^2*s^-2)
        % Write back Ek
        position_data(ref_ptr,11) = Ek;
        % Accumualte to system Ek
        System_Ek = System_Ek + Ek;
        
        % Write back position and velocity
        position_data(ptr, 1) = posx;
        position_data(ptr, 2) = posy;
        position_data(ptr, 3) = posz;
        position_data(ptr, 4) = vx;
        position_data(ptr, 5) = vy;
        position_data(ptr, 6) = vz;
        % Clear force
        position_data(ptr, 7) = 0;
        position_data(ptr, 8) = 0;
        position_data(ptr, 9) = 0;
    end
    
    %% Print out system energy infomation
    % LJ potential should only count once towards both particles
    System_LJ_Energy = System_LJ_Energy / 2;
    System_Total_Energy = System_LJ_Energy+System_Ek*10^-3;
    energy_history(iteration,1:3) = [System_LJ_Energy,System_Ek,System_Total_Energy];
    fprintf("Iteration %d, System energy is %f, Kinetic energy is %f\n", iteration, System_LJ_Energy, System_Ek);
    
    % Write the energy result to output file
    fprintf(OUTPUT_FILE_ID, '%d\t%e\t%e\t%e\n', iteration, System_LJ_Energy,System_Ek,System_Total_Energy);
end

% Close the output file
fclose(OUTPUT_FILE_ID);

% Plot the energy waveform
clf;
figure(3);
subplot(3,1,1);
plot(1:NUM_ITERATION, energy_history(1:NUM_ITERATION,1));
title('System LJ Energy');
ylabel('kJ');
subplot(3,1,2);
plot(1:NUM_ITERATION, energy_history(1:NUM_ITERATION,2));
title('System Kinetic Energy')
ylabel('J');
subplot(3,1,3);
plot(1:NUM_ITERATION, energy_history(1:NUM_ITERATION,3));
title('System Total Energy')
ylabel('kJ');
