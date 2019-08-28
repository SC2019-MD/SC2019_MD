%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Analyzing the input file of ApoA1, find the max and min range of all the particle pairs
%%
%% By: Chen Yang
%% 07/25/2018
%% Boston University, CAAD Lab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;

% r2 range is 0.015793 ~ 29407.160915

%% Variables
EVALUATE_ALL = 1;
TOTAL_PARTICLE_NUM = 92224;
CUT_OFF = 14;
CUTOFF_2 = CUT_OFF * CUT_OFF;
DEPTH = 100;
% filepath = 'F:\Research_Files\MD\Ethan_MD_HDL\Ethan_Range_Limited_Pipeline\';
filename = 'input_positions_ApoA1.txt';
%filename = strcat(filepath, filename);
% Position data
pos = zeros(TOTAL_PARTICLE_NUM,3);


%% Read in ApoA1 data
% Open File
fp = fopen(filename);
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


%% Evaluate the distance of few particle pairs\
if EVALUATE_ALL == 0
    not_in_cutoff_counter = 0;
    for ref_counter = 1:DEPTH
        for neighbor_counter = 1:DEPTH
            dx = pos(ref_counter,1) - pos(neighbor_counter,1);
            dy = pos(ref_counter,2) - pos(neighbor_counter,2);
            dz = pos(ref_counter,3) - pos(neighbor_counter,3);
            r2 = dx*dx + dy*dy + dz*dz;
            if r2 > CUTOFF_2
                not_in_cutoff_counter = 1 + not_in_cutoff_counter;
                fprintf('%d: (%f,%f,%f), (%f,%f,%f) exceed cutoff radius! r2 = %f\n', not_in_cutoff_counter, pos(ref_counter,:), pos(neighbor_counter,:), r2);
            end
        end
    end
end

%% Evaluate the distance of all the particle pairs
if EVALUATE_ALL
    min_r2 = 100000000;
    max_r2 = 0;
    for ref_ptr = 1:TOTAL_PARTICLE_NUM
        for neighbor_ptr = 1:TOTAL_PARTICLE_NUM
            if ref_ptr ~= neighbor_ptr
                % calculate the distance
                dx = pos(ref_ptr,1) - pos(neighbor_ptr,1);
                dy = pos(ref_ptr,2) - pos(neighbor_ptr,2);
                dz = pos(ref_ptr,3) - pos(neighbor_ptr,3);
                r2 = dx*dx + dy*dy + dz*dz;

                % determine the max
                if r2 > max_r2
                    max_r2 = r2;
                end
                % determine the min
                if r2 < min_r2
                    min_r2 = r2;
                end            
            end
        end
    end

    fprintf('Max r2 is %f, Min r2 is %f\n', max_r2, min_r2);
end