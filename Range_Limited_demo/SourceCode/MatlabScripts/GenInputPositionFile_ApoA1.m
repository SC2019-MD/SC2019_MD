%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generating the input mif file for initializing the position memory in design Ethan_RL_Pipeline_1st_Order_SingleFloat
% Output data in IEEE floating point format  
%
% By: Chen Yang
% 05/29/2018
% Boston University, CAAD Lab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;

% Variables
depth = 100;                        % memory depth
width = 32;                         % memory data width
filename_list = {'particle_ref_x.mif', 'particle_ref_y.mif', 'particle_ref_z.mif', 'particle_neighbor_x.mif', 'particle_neighbor_y.mif', 'particle_neighbor_z.mif'};
file_count = 6;                     % total number of files


%% Read in ApoA1 data
% Position data
pos = zeros(92224,3);
input_file_name = 'input_positions_ApoA1.txt';
% Open File
fp = fopen(input_file_name);
if fp == -1
        fprintf('failed to open %s\n',filename);
end
% Read in line by line
line_counter = 1;
while ~feof(fp)
    tline = fgets(fp);
    line_elements = textscan(tline,'%f');
    pos(line_counter,:) = line_elements{1}; 
    line_counter = line_counter + 1;
end
% Close File
fclose(fp);

%% Write the ApoA1 data to Memeory initialization file
for i = 1:file_count

    % Create the mif file
    fileID{i} = fopen(filename_list{i}, 'wt');

    % Write mif file header
    fprintf(fileID{i},'DEPTH = %d;\n',depth);
    fprintf(fileID{i},'WIDTH = %d;\n', width);
    fprintf(fileID{i},'ADDRESS_RADIX = DEC;\n');
    fprintf(fileID{i},'DATA_RADIX = HEX;\n');
    fprintf(fileID{i},'CONTENT\n');
    fprintf(fileID{i},'BEGIN\n');

    % Write the position data
    if mod(i,3)~= 0
        index = mod(i,3);
    else
        index = 3;
    end
    for entry_num = 1:depth
        tmp = single(pos(entry_num,index));
        fprintf(fileID{i},'%d : %tX;\n',entry_num-1, tmp);
    end

    % Write the end of mif file
    fprintf(fileID{i},'END;\n');

    % Close file
    fclose(fileID{i});
end