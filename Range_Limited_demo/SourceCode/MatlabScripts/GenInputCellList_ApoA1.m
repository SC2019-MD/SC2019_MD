%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generating the input mif file for each cells to initializing the cell memory in design Ethan_RL_Pipeline_1st_Order_SingleFloat
% Output data in IEEE floating point format  
%
% Data Organization:
%       Address 0: Number of particles in the cell
%       Address 1~...: {position_z, position_y, position_x}
%
% Output file:
%       cell_ini_file_idx_idy_idz.mif
%       cell_ini_file_idx_idy_idz.txt
%
% Attention:
%		* If the # of particles per cell change, special care need to take when generate the first element (# of particles in the cell) in the mif file
%			~ take care of how many 0s need to be patched
%       * cell_id = (cell_x-1)*CELL_COUNT_Y*CELL_COUNT_Z + (cell_y-1)*CELL_COUNT_Z + cell_z;
%
% Key variables:
%       position_data(particle_id, position)                    ---- the aligned position data for all the read in particles (algined to (0,0,0))
%       particle_in_cell_counter(cell_x, cell_y, cell_z)        ---- recording how many particles in each cell
%       cell_particle(cell_id, particle_id, position_data)      ---- recording the position information of each particles in each cell
%       out_range_particle_counter      
%
% By: Chen Yang
% 10/29/2018
% Boston University, CAAD Lab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Simulation Parameters
CUTOFF_RADIUS = single(12);                         % Cutoff Radius
CUTOFF_RADIUS_2 = CUTOFF_RADIUS * CUTOFF_RADIUS;    % Cutoff distance square
%% Benmarck Related Parameters (related with CUTOFF_RADIUS)
CELL_COUNT_X = 9;
CELL_COUNT_Y = 9;
CELL_COUNT_Z = 7;
CELL_PARTICLE_MAX = 290;                            % The maximum possible particle count in each cell
TOTAL_PARTICLE = 92224;                             % particle count in ApoA1 benchmark
MEM_DATA_WIDTH = 32*3;                              % Memory Data Width (3*32 for position)
COMMON_PATH = '';
INPUT_FILE_NAME = 'input_positions_ApoA1.txt';
%% Data Arraies for processing
% Bounding box of 12A, total of 9*9*7 cells, organized in a 4D array
raw_position_data = zeros(TOTAL_PARTICLE,3);                % The raw input data
position_data = single(zeros(TOTAL_PARTICLE,3));            % The shifted input data
particle_in_cell_counter = single(zeros(CELL_COUNT_X,CELL_COUNT_Y,CELL_COUNT_Z));               % counters tracking the # of particles in each cell
cell_particle = single(zeros(CELL_COUNT_X*CELL_COUNT_Y*CELL_COUNT_Z,CELL_PARTICLE_MAX,8));      % 3D array holding sorted cell particles(cell_id, particle_id, particle_info), cell_id = (cell_x-1)*9*7+(cell_y-1)*7+cell_z
                                                                                        % Particle info: 1~3:position(x,y,z), 4~6:force component in each direction, 7: energy, 8:# of partner particles
%% Simulation Control Parameters
% The subset of cell initalization file need to generate (the cell number starting from 1)
% Cell numbering mechanism: cell_id = (cell_x-1)*CELL_COUNT_Y*CELL_COUNT_Z + (cell_y-1)*CELL_COUNT_Z + cell_z;
GEN_CELL_RANGE_X = [1 2 3];
GEN_CELL_RANGE_Y = [1 2 3];
GEN_CELL_RANGE_Z = [1 2 3];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Preprocessing the Raw Input data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Load the data from input file
input_file_path = strcat(COMMON_PATH, INPUT_FILE_NAME);
fprintf('*** Start reading data from input file %s ***\n', input_file_path);
% Open File
fp = fopen(input_file_path);
if fp == -1
        fprintf('failed to open %s\n',filename);
end
% Read in line by line
line_counter = 1;
while ~feof(fp)
    tline = fgets(fp);
    line_elements = textscan(tline,'%f');
    raw_position_data(line_counter,:) = line_elements{1}; 
    line_counter = line_counter + 1;
end
% Close File
fclose(fp);
fprintf('Particle data loading finished!\n');

%% Find the min, max of raw data in each dimension
min_x  = (min(raw_position_data(:,1)));
max_x  = (max(raw_position_data(:,1)));
min_y  = (min(raw_position_data(:,2)));
max_y  = (max(raw_position_data(:,2)));
min_z  = (min(raw_position_data(:,3)));
max_z  = (max(raw_position_data(:,3)));
% Original range is (-56.296,56.237), (-57.123,56.259), (-40.611,40.878)
% shift all the data to positive
position_data(:,1) = raw_position_data(:,1)-min_x;          % range: 0 ~ 112.533
position_data(:,2) = raw_position_data(:,2)-min_y;          % range: 0 ~ 113.382
position_data(:,3) = raw_position_data(:,3)-min_z;          % range: 0 ~ 81.489
fprintf('All particles shifted to align on (0,0,0)\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Mapping the particles to cell list
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('*** Start mapping paricles to cells! ***\n');
out_range_particle_counter = 0;
for i = 1:TOTAL_PARTICLE
    % determine the cell each particle belongs to
    if position_data(i,1) ~= 0
        cell_x = ceil(position_data(i,1) / CUTOFF_RADIUS);
    else
        cell_x = 1;
    end
    if position_data(i,2) ~= 0
        cell_y = ceil(position_data(i,2) / CUTOFF_RADIUS);
    else
        cell_y = 1;
    end
    if position_data(i,3) ~= 0
        cell_z = ceil(position_data(i,3) / CUTOFF_RADIUS);
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
        fprintf('Out of range partcile is (%f,%f,%f)\n', position_data(i,1:3));
    end
end
fprintf('Particles mapping to cells finished! Total of %d particles falling out of the range.\n', out_range_particle_counter);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Write the ApoA1 data to Memeory initialization file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('Starting write Mem init file...\n');
tmp_pos_x = single(0);
tmp_pos_y = single(0);
tmp_pos_z = single(0);
for x_ptr = 1:size(GEN_CELL_RANGE_X,2)
    cell_id_x = GEN_CELL_RANGE_X(x_ptr);
    for y_ptr = 1:size(GEN_CELL_RANGE_Y,2)
        cell_id_y = GEN_CELL_RANGE_Y(y_ptr);
        for z_ptr = 1:size(GEN_CELL_RANGE_Z,2)
            cell_id_z = GEN_CELL_RANGE_Z(z_ptr);
            % Get the cell id
            cell_id = (cell_id_x-1)*CELL_COUNT_Y*CELL_COUNT_Z + (cell_id_y-1)*CELL_COUNT_Z + cell_id_z;
            % Get the number of particles in the cell
            cell_particle_num = particle_in_cell_counter(cell_id_x, cell_id_y, cell_id_z);
            % Generate the initialization file name (cell_ini_file_1_2_3.mif)
            cell_ini_file_name = strcat('cell_ini_file_',num2str(cell_id_x),'_',num2str(cell_id_y),'_',num2str(cell_id_z),'.mif');
            % Generate the decimal reference file name (cell_ini_file_1_2_3.txt)
            cell_ref_file_name = strcat('cell_ini_file_',num2str(cell_id_x),'_',num2str(cell_id_y),'_',num2str(cell_id_z),'.txt');
            % Create the mif file
            fileID = fopen(cell_ini_file_name, 'wt');
            % Create the reference file
            ref_fileID = fopen(cell_ref_file_name, 'wt');

            % Write mif file header
            fprintf(fileID,'DEPTH = %d;\n', CELL_PARTICLE_MAX);
            fprintf(fileID,'WIDTH = %d;\n', MEM_DATA_WIDTH);
            fprintf(fileID,'ADDRESS_RADIX = DEC;\n');
            fprintf(fileID,'DATA_RADIX = HEX;\n');
            fprintf(fileID,'CONTENT\n');
            fprintf(fileID,'BEGIN\n');
            % Write the reference file headline
            fprintf(ref_fileID,'Memory Address: PosZ\tPosY\tPosX\n');

            % Write the first data in the ram: The number of particles in the current cell (in decimal format)
            % Format: {32'd0, 32'd0, 24'd0, NUM_PARTICLE}
            fprintf(fileID,'0 : %tX%tX000000%X;\n', single(0),single(0),uint32(cell_particle_num));
            fprintf(ref_fileID,'Num Particles In the Cell : %d\n', uint32(cell_particle_num));
            % Write the position data (in IEEE format)
            for entry_num = 1:cell_particle_num
                tmp_pos_x = single(cell_particle(cell_id,entry_num,1));
                tmp_pos_y = single(cell_particle(cell_id,entry_num,2));
                tmp_pos_z = single(cell_particle(cell_id,entry_num,3));
                fprintf(fileID,'%d : %tX%tX%tX;\n',entry_num, tmp_pos_z, tmp_pos_y, tmp_pos_x);
                fprintf(ref_fileID,'HEX %d : %tX\t%tX\t%tX\t\n',entry_num, tmp_pos_z, tmp_pos_y, tmp_pos_x);
                fprintf(ref_fileID,'DEC %d : %f\t%f\t%f\t\n',entry_num, tmp_pos_z, tmp_pos_y, tmp_pos_x);
            end
            % Fill the rest memory data with 0
            if cell_particle_num+1 < CELL_PARTICLE_MAX
                for entry_num = (cell_particle_num+1):(CELL_PARTICLE_MAX-1)
                    fprintf(fileID,'%d : %tX%tX%tX;\n',entry_num, single(0), single(0), single(0));
                    fprintf(ref_fileID,'%d : %f\t%f\t%f\t\n',entry_num, single(0), single(0), single(0));
                end
            end
            
            % Write the end of mif file
            fprintf(fileID,'END;\n');

            % Close file
            fclose(fileID);
            fclose(ref_fileID);
        end
    end
end
fprintf('Mem init file generation finished!\n');