%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Analyzing the input file of ApoA1, find the max and min range of all the particle pairs
%%
%% By: Chen Yang
%% 07/25/2018
%% Boston University, CAAD Lab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;

% raw r2 range is 2.272326e-27 ~ 3.401961e-17 (unit meter)
% If scaled by 100 times, the range is 2.272326e-03 ~ 34019614.734912 (unit A)
% The read in data unit is angstrom (A), but when data are in that range, it turns out that the minimum r2 value can be too small, lead to the overflow when calculating the r^-14
% Thus here we are going to scale up the position data along with the cutoff value, to avoid overflow

%% Variables
EVALUATE_ALL = 1;
SCALE_INDEX = 1;%10^10;%100 * 10^10;                              % the readin position data suppose to in the unit of A, but it turns out that the minimum r2 value can be too small, lead to the overflow when calculating the r^-14
TOTAL_PARTICLE_NUM = 20000;%10000;%864;%19008;
CUT_OFF = 8.5;%7.65;
CUTOFF_2 = CUT_OFF * CUT_OFF;
DEPTH = 100;
% filepath = 'F:\Research_Files\MD\Ethan_MD_HDL\Ethan_Range_Limited_Pipeline\';
%filename = 'input_positions_ljargon_10000_40box.txt';
filename = 'input_positions_ljargon_20000_box_58_49_49.txt';
%filename = strcat(filepath, filename);
% Position data
pos = zeros(TOTAL_PARTICLE_NUM,3);
% r2 results
r2_result = zeros(1,TOTAL_PARTICLE_NUM^2);


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
    line_elements = textscan(tline,'%s %f64 %f64 %f64');
    pos(line_counter,1) = line_elements{2} * SCALE_INDEX;
    pos(line_counter,2) = line_elements{3} * SCALE_INDEX;
    pos(line_counter,3) = line_elements{4} * SCALE_INDEX;
    line_counter = line_counter + 1;
end
% Close File
fclose(fp);


%% Evaluate the distance of few particle pairs
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
    filter_counter = 0;
    min_r2 = 100000000;
    max_r2 = 0;
    for ref_ptr = 1:TOTAL_PARTICLE_NUM
        for neighbor_ptr = ref_ptr+1:TOTAL_PARTICLE_NUM
            % calculate the distance
            dx = pos(ref_ptr,1) - pos(neighbor_ptr,1);
            dy = pos(ref_ptr,2) - pos(neighbor_ptr,2);
            dz = pos(ref_ptr,3) - pos(neighbor_ptr,3);
            r2 = dx*dx + dy*dy + dz*dz;
            
            % Record the filtered results
            if(r2 <= CUTOFF_2)
                filter_counter = filter_counter + 1;
                r2_result(filter_counter) = r2;
            end

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

    fprintf('Max r2 is %e, Min r2 is %e\n', max_r2, min_r2);
end

% Plot distribution of filtered r2
histogram(r2_result(1:nnz(r2_result)));
