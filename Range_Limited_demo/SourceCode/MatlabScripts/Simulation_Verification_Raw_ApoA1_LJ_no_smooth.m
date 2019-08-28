%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Using ApoA1 input postion data, to evaluate the LJ force using the generated Lookup table
% The output of this script can be used to verify the HDL simulation result
% 
% Run the following scripts before run this:
%                   LJ_no_smooth_poly_interpolation_accuracy.m          % This one generate the lookup table entries
%
% Output:
%       VERIFICATION_REFERENCE_OUTPUT.txt
%
% By: Chen Yang
% 10/02/2018
% Boston University, CAAD Lab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;

%% Variables
INTERPOLATION_ORDER = 1;                % interpolation order, no larger than 3
CUTOFF = 14;
CUTOFF_2 = CUTOFF*CUTOFF;
SEGMENT_NUM = 14;                       % # of segment
BIN_NUM = 256;                          % # of bins per segment
% Range starting from 2^-6 (ApoA1 min r2 is 0.015793)
MIN_RANGE = 0.015625;                  % minimal range for the evaluation
% ApoA1 cutoff is 12~13 Ang, thus set the bin as 14 to cover the range
MAX_RANGE = MIN_RANGE * 2^SEGMENT_NUM;  % maximum range for the evaluation (currently this is the cutoff radius)
EVALUATION_REF_NUM = 100;                % Reference Particle numbers
EVALUATION_NEIGHBOR_NUM = 100;           % Neighbor Particle numbers

filepath = '';
filename = 'input_positions_ApoA1.txt';
filename = strcat(filepath, filename);
% Position data
pos = zeros(92224,3);


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


%% Evaluate the LJ force using the generated lookup table
%% Load in the index data
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

% Prepare the output file
fresult = fopen('VERIFICATION_REFERENCE_OUTPUT.txt', 'wt');
fprintf(fresult,'ParticlePairs:\t\t\t\t\t\tTotal LJ\tX_Comp\t\tY_Comp\t\tZ_Comp\n');
fprintf(fresult,'\t\tDistance info: r2\tdx\tdy\tdz\t\n');


%% Start Evaluation using interpolation
% Evalute the first EVALUATION_NUM^2 particle pairs
for ref_ptr = 1:EVALUATION_REF_NUM
    % Get the reference particle coordinate
    refx = single(pos(ref_ptr,1));
    refy = single(pos(ref_ptr,2));
    refz = single(pos(ref_ptr,3));
    for neighbor_ptr = 1:EVALUATION_NEIGHBOR_NUM
        % Get the neighbor particle coordinate
        neighbor_x = single(pos(neighbor_ptr,1));
        neighbor_y = single(pos(neighbor_ptr,2));
        neighbor_z = single(pos(neighbor_ptr,3));

        % Calcualte r2
        dx = single(refx - neighbor_x);
        dy = single(refy - neighbor_y);
        dz = single(refz - neighbor_z);
        r2 = dx*dx + dy*dy+ dz*dz;
        % Table lookup
        % Locate the segment of the current r2
        if r2 < CUTOFF_2 && r2 > 0
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
            % Calculate the total force
            F_LJ = single(vdw14) - single(vdw8);
            F_LJ_x = single(F_LJ * dx);
            F_LJ_y = single(F_LJ * dy);
            F_LJ_z = single(F_LJ * dz);
            
            
        % Set the force value as 0 if exceed cutoff radius
        else
            F_LJ = 0;
            F_LJ_x = 0;
            F_LJ_y = 0;
            F_LJ_z = 0;
        end
        fprintf(fresult,'(%tX,%tX,%tX),(%tX,%tX,%tX): %tX\t%tX\t%tX\t%tX\n',pos(ref_ptr,:),pos(neighbor_ptr,:),F_LJ,F_LJ_x,F_LJ_y,F_LJ_z);
        fprintf(fresult,'\t\tDistance info: %tX, %tX, %tX, %tX\n', r2, dx, dy, dz);
    end
end
fclose(fresult);
