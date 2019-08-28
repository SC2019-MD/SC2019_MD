%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function: LJ_no_smooth_poly_interpolation_accuracy
% Evaluate the accuracy for interpolation
% Currently only evaluate the LJ force, equation refer to 'Efficient Calculation of Pairwise Nonbonded Forces', M. Chiu, A. Khan, M. Herbordt, FCCM2011
% The evaluation of the force and potential is also based on the LJ-Argon benchmark (https://github.com/KenNewcomb/LJ-Argon/blob/master/classes/simulation.py)
% Dependency: LJ_poly_interpolation_function.m (Generating the interpolation index and stored in txt file)
% Final result:
%       Fvdw_real: real result in single precision
%       Fvdw_poly: result evaluated using polynomial
%       average_error_rate: the average error rate for all the evaluated input r2
%
% Units of the input:
%       The ideal unit for position should be meter. 
%       For the LJArgon dataset, the real evaluated force is in range of (4.7371e-5,6.6029e+54), which exceed the range that can be coverd by single floating point
%
% By: Chen Yang
% 07/18/2018
% Boston University, CAAD Lab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all;

% output_scale_index: the output value can be out the scope of single-precision floating point, thus use this value to scale the output result back
% eps: eps of the particles, Unit J
% sigma: sigma value of the particles, Unit meter
% interpolation_order: interpolation order
% segment_num: # of large sections we have
% bin_num: # of bins per segment
% precision: # of datapoints for each interpolation
% min, max : range of distance

% Input & Output Scale Parameters
INPUT_SCALE_INDEX = 1;                     % the readin position data is in the unit of angstrom
OUTPUT_SCALE_INDEX = 1;                    % The scale value for the results of r14 & r8 term

% Dataset Paraemeters
DATASET_NAME = 'LJArgon';
% Ar
kb = 1.380e-23;                            % Boltzmann constant (J/K)
eps = 1.995996 * 1.995996;                 % Extracted from OpenMM, unit kJ      %0.996;% Unit: kJ	%0.238;% Unit kcal/mol	%kb * 120;% Unit J
sigma = 2.1;%3.4;%0.1675*2;                     % Extracted from LJArgon Dataset, unit Angstrom        %3.35;%3.4;% Unit Angstrom    %3.4e-10;% Unit meter, the unit should be in consistant with position value
cutoff = single(8.5);%single(sigma*2.5 * INPUT_SCALE_INDEX);%single(7.65 * INPUT_SCALE_INDEX);             % Cut-off radius, unit Angstrom
cutoff2 = cutoff * cutoff;
EXCLUSION = single(2^-1);
EXCLUSION_2 = EXCLUSION ^ 2;
switchon = single(0.1);

% LJArgon min r2 is 2.242475 ang^2
% Here we keep in consistant with ApoA1
raw_r2_min = 2^-12;%2.242475;
scaled_r2_min = raw_r2_min * INPUT_SCALE_INDEX^2;
min_log_index = floor(log(EXCLUSION_2)/log(2));
% Choose a min_range of 2^-15
min_range = 2^min_log_index;    % minimal range for the evaluation
max_log_index = ceil(log(cutoff2)/log(2));
% Based on cutoff and min_range to determine the # of segments
% Max range of cutoff is 
max_range = 2^max_log_index;  % maximum range for the evaluation (currently this is the cutoff radius)

% Interpolation parameters
interpolation_order = 1;                % interpolation order, no larger than 3
segment_num = max_log_index-min_log_index;                       % # of segment
bin_num = 256;                          % # of bins per segment
precision = 8;                          % # of datepoints when generating the polynomial index 

verification_datapoints = 10000;
verification_step_width = (max_range-min_range)/verification_datapoints;
r2 = single(min_range:verification_step_width:cutoff2-verification_step_width);
%r2 = [min_range cutoff cutoff2];
% initialize variables (in double precision)
inv_r2 = zeros(length(r2),1);
inv_r4 = zeros(length(r2),1);
inv_r6 = zeros(length(r2),1);
inv_r12 = zeros(length(r2),1);
inv_r8 = zeros(length(r2),1);
inv_r14 = zeros(length(r2),1);
% The golden result for LJ term
vdw14_real = zeros(length(r2),1);
vdw8_real = zeros(length(r2),1);
vdw6_real = zeros(length(r2),1);
vdw12_real = zeros(length(r2),1);
% The interpolated result for LJ term
vdw14_poly = zeros(length(r2),1);
vdw8_poly = zeros(length(r2),1);
vdw6_poly = zeros(length(r2),1);
vdw12_poly = zeros(length(r2),1);

s = zeros(length(r2),1);
ds = zeros(length(r2),1);
Fvdw_real = zeros(length(r2),1);
Fvdw_poly = zeros(size(r2,2),1);
Evdw_real = zeros(length(r2),1);
Evdw_poly = zeros(length(r2),1);

% Coefficient gen (random number), independent of r
%A_energy = OUTPUT_SCALE_INDEX * 4 * eps * sigma ^ 12;             % Multiply with the r12 term
%B_energy = OUTPUT_SCALE_INDEX * 4 * eps * sigma ^ 6;              % Multiply with the r6 term
%A_force  = OUTPUT_SCALE_INDEX * 48 * eps * sigma ^ 12;            % Multiply with the r14 term
%B_force  = OUTPUT_SCALE_INDEX * 24 * eps * sigma ^ 6;             % Multiply with the r8 term
A_energy = 4 * eps * sigma ^ 12;             % Multiply with the r12 term
B_energy = 4 * eps * sigma ^ 6;              % Multiply with the r6 term
A_force  = 48 * eps * sigma ^ 12;            % Multiply with the r14 term
B_force  = 24 * eps * sigma ^ 6;             % Multiply with the r8 term
%% Evaluate the real result in single precision (in double precision)
for i = 1:size(r2,2)
    % calculate the real value
    inv_r2(i) = 1 / r2(i);
    inv_r4(i) = inv_r2(i) * inv_r2(i);

    inv_r6(i)  = inv_r2(i) * inv_r4(i);
    inv_r12(i) = inv_r6(i) * inv_r6(i);

    inv_r14(i) = inv_r12(i) * inv_r2(i);
    inv_r8(i)  = inv_r6(i)  * inv_r2(i);
    
    vdw14_real(i) = OUTPUT_SCALE_INDEX * 48 * eps * sigma ^ 12 * inv_r14(i);
    vdw8_real(i)  = OUTPUT_SCALE_INDEX * 24 * eps * sigma ^ 6  * inv_r8(i);
   
    vdw6_real(i)  = OUTPUT_SCALE_INDEX * 4 * eps * sigma ^ 6  * inv_r6(i);
    vdw12_real(i) = OUTPUT_SCALE_INDEX * 4 * eps * sigma ^ 12  * inv_r12(i);
    
    % Calculate the VDW force
    Fvdw_real(i) = vdw14_real(i) - vdw8_real(i);
    % Calculate the VDW energy
    Evdw_real(i) = vdw12_real(i) - vdw6_real(i);
end

%% Generate the interpolation table (only need to run this once if the interpolation parameter remains)
LJ_no_smooth_poly_interpolation_function(interpolation_order,segment_num, bin_num,precision,min_range,max_range,cutoff,switchon,OUTPUT_SCALE_INDEX,eps,sigma);

%% Evaluate the interpolation result
% Load in the index data
fileID_0  = fopen('c0_14.txt', 'r');
fileID_1  = fopen('c1_14.txt', 'r');
if interpolation_order > 1
    fileID_2  = fopen('c2_14.txt', 'r');
end
if interpolation_order > 2
    fileID_3  = fopen('c3_14.txt', 'r');
end

fileID_4  = fopen('c0_8.txt', 'r');
fileID_5  = fopen('c1_8.txt', 'r');
if interpolation_order > 1
    fileID_6  = fopen('c2_8.txt', 'r');
end
if interpolation_order > 2
    fileID_7  = fopen('c3_8.txt', 'r');
end

fileID_8  = fopen('c0_12.txt', 'r');
fileID_9  = fopen('c1_12.txt', 'r');
if interpolation_order > 1
    fileID_10  = fopen('c2_12.txt', 'r');
end
if interpolation_order > 2
    fileID_11  = fopen('c3_12.txt', 'r');
end

fileID_12  = fopen('c0_6.txt', 'r');
fileID_13  = fopen('c1_6.txt', 'r');
if interpolation_order > 1
    fileID_14  = fopen('c2_6.txt', 'r');
end
if interpolation_order > 2
    fileID_15  = fopen('c3_6.txt', 'r');
end

% Fetch the index for the polynomials
read_in_c0_vdw14 = textscan(fileID_0, '%f');
read_in_c1_vdw14 = textscan(fileID_1, '%f');
if interpolation_order > 1
    read_in_c2_vdw14 = textscan(fileID_2, '%f');
end
if interpolation_order > 2
    read_in_c3_vdw14 = textscan(fileID_3, '%f');
end
read_in_c0_vdw8 = textscan(fileID_4, '%f');
read_in_c1_vdw8 = textscan(fileID_5, '%f');
if interpolation_order > 1
    read_in_c2_vdw8 = textscan(fileID_6, '%f');
end
if interpolation_order > 2
    read_in_c3_vdw8 = textscan(fileID_7, '%f');
end
read_in_c0_vdw12 = textscan(fileID_8, '%f');
read_in_c1_vdw12 = textscan(fileID_9, '%f');
if interpolation_order > 1
    read_in_c2_vdw12 = textscan(fileID_10, '%f');
end
if interpolation_order > 2
    read_in_c3_vdw12 = textscan(fileID_11, '%f');
end
read_in_c0_vdw6 = textscan(fileID_12, '%f');
read_in_c1_vdw6 = textscan(fileID_13, '%f');
if interpolation_order > 1
    read_in_c2_vdw6 = textscan(fileID_14, '%f');
end
if interpolation_order > 2
    read_in_c3_vdw6 = textscan(fileID_15, '%f');
end

% close file
fclose(fileID_0);
fclose(fileID_1);
if interpolation_order > 1
    fclose(fileID_2);
end
if interpolation_order > 2
    fclose(fileID_3);
end
fclose(fileID_4);
fclose(fileID_5);
if interpolation_order > 1
    fclose(fileID_6);
end
if interpolation_order > 2
    fclose(fileID_7);
end
fclose(fileID_8);
fclose(fileID_9);
if interpolation_order > 1
    fclose(fileID_10);
end
if interpolation_order > 2
    fclose(fileID_11);
end
fclose(fileID_12);
fclose(fileID_13);
if interpolation_order > 1
    fclose(fileID_14);
end
if interpolation_order > 2
    fclose(fileID_15);
end

% Start evaluation
for i = 1:size(r2,2)
    % Locate the segment of the current r2
    seg_ptr = 0;        % The first segment will be #0, second will be #1, etc....
    while(r2(i) >= min_range * 2^(seg_ptr+1))
        seg_ptr = seg_ptr + 1;
    end
    if(seg_ptr >= segment_num)      % if the segment pointer is larger than the maximum number of segment, then error out
        disp('Error occur: could not locate the segment for the input r2');
        exit;
    end
    
    % Locate the bin in the current segment
    segment_min = single(min_range * 2^seg_ptr);
    segment_max = segment_min * 2;
    segment_step = (segment_max - segment_min) / bin_num;
    bin_ptr = floor((r2(i) - segment_min)/segment_step) + 1;            % the bin_ptr will give which bin it locate
    
    % Calculate the index for table lookup
    lut_index = seg_ptr * bin_num + bin_ptr;
    
    % Fetch the index for the polynomials
    c0_vdw14 = single(read_in_c0_vdw14{1}(lut_index));
    c1_vdw14 = single(read_in_c1_vdw14{1}(lut_index));
    if interpolation_order > 1
        c2_vdw14 = single(read_in_c2_vdw14{1}(lut_index));
    end
    if interpolation_order > 2
        c3_vdw14 = single(read_in_c3_vdw14{1}(lut_index));
    end
    c0_vdw8 = single(read_in_c0_vdw8{1}(lut_index));
    c1_vdw8 = single(read_in_c1_vdw8{1}(lut_index));
    if interpolation_order > 1
        c2_vdw8 = single(read_in_c2_vdw8{1}(lut_index));
    end
    if interpolation_order > 2
        c3_vdw8 = single(read_in_c3_vdw8{1}(lut_index));
    end
    c0_vdw12 = single(read_in_c0_vdw12{1}(lut_index));
    c1_vdw12 = single(read_in_c1_vdw12{1}(lut_index));
    if interpolation_order > 1
        c2_vdw12 = single(read_in_c2_vdw12{1}(lut_index));
    end
    if interpolation_order > 2
        c3_vdw12 = single(read_in_c3_vdw12{1}(lut_index));
    end
    c0_vdw6 = single(read_in_c0_vdw6{1}(lut_index));
    c1_vdw6 = single(read_in_c1_vdw6{1}(lut_index));
    if interpolation_order > 1
        c2_vdw6 = single(read_in_c2_vdw6{1}(lut_index));
    end
    if interpolation_order > 2
        c3_vdw6 = single(read_in_c3_vdw6{1}(lut_index));
    end
    
    % Calculate the poly value
    switch(interpolation_order)
        case 1
            vdw14 = polyval([c1_vdw14 c0_vdw14], r2(i));
            vdw8 = polyval([c1_vdw8 c0_vdw8], r2(i));
            vdw12 = polyval([c1_vdw12 c0_vdw12], r2(i));
            vdw6 = polyval([c1_vdw6 c0_vdw6], r2(i));
        case 2
            vdw14 = polyval([c2_vdw14 c1_vdw14 c0_vdw14], r2(i));
            vdw8 = polyval([c2_vdw8 c1_vdw8 c0_vdw8], r2(i));
            vdw12 = polyval([c2_vdw12 c1_vdw12 c0_vdw12], r2(i));
            vdw6 = polyval([c2_vdw6 c1_vdw6 c0_vdw6], r2(i));
        case 3
            vdw14 = polyval([c3_vdw14 c2_vdw14 c1_vdw14 c0_vdw14], r2(i));
            vdw8 = polyval([c3_vdw8 c2_vdw8 c1_vdw8 c0_vdw8], r2(i));
            vdw12 = polyval([c3_vdw12 c2_vdw12 c1_vdw12 c0_vdw12], r2(i));
            vdw6 = polyval([c3_vdw6 c2_vdw6 c1_vdw6 c0_vdw6], r2(i));
    end
    
    %vdw14_poly(i) = A_force * vdw14;
    %vdw8_poly(i) = B_force * vdw8;
    %vdw12_poly(i) = A_energy * vdw12;
    %vdw6_poly(i) = B_energy * vdw6;
    vdw14_poly(i) = vdw14;
    vdw8_poly(i) = vdw8;
    vdw12_poly(i) = vdw12;
    vdw6_poly(i) = vdw6;
    
    % Calculate the force
    Fvdw_poly(i) = vdw14_poly(i) - vdw8_poly(i);
    % Calculate the energy
    Evdw_poly(i) = vdw12_poly(i) - vdw6_poly(i);
end

%% Plot the Evaw value
clf;
figure(1);
plot(r2, Evdw_poly);
title('Evdw poly value');

%% Evaluate the Error rate
f_diff_rate = zeros(size(r2,2),1);
e_diff_rate = zeros(size(r2,2),1);
for i = 1:size(r2,2)
    difference = Fvdw_poly(i) - Fvdw_real(i);
    f_diff_rate(i) = abs(difference / Fvdw_real(i));
    difference = Evdw_poly(i) - Evdw_real(i);
    e_diff_rate(i) = abs(difference / Evdw_real(i));
end

f_average_error_rate = sum(f_diff_rate) / size(r2,2);
e_average_error_rate = sum(e_diff_rate) / size(r2,2);
fprintf('The average error rate is: force %f, energy %f\n', f_average_error_rate, e_average_error_rate);


%% Profiling
profiling_output_file_name = strcat(DATASET_NAME,'_PreEvaluation_Profiling_Data.txt');
fileID = fopen(profiling_output_file_name, 'wt');
fprintf(fileID, 'Dataset: %s\n', DATASET_NAME);
fprintf(fileID, '\tr2 range is: (%e, %e)\n', min(r2), max(r2));
fprintf(fileID, '\tvdw14_real range is: (%e, %e)\n', min(abs(vdw14_real)), max(vdw14_real));
fprintf(fileID, '\tvdw14_poly range is: (%e, %e)\n', min(abs(vdw14_poly)), max(vdw14_poly));
fprintf(fileID, '\tvdw8_real range is: (%e, %e)\n', min(abs(vdw8_real)), max(vdw8_real));
fprintf(fileID, '\tvdw8_poly range is: (%e, %e)\n', min(abs(vdw8_poly)), max(vdw8_poly));
fprintf(fileID, '\tvdw12_real range is: (%e, %e)\n', min(abs(vdw12_real)), max(vdw12_real));
fprintf(fileID, '\tvdw12_poly range is: (%e, %e)\n', min(abs(vdw12_poly)), max(vdw12_poly));
fprintf(fileID, '\tvdw6_real range is: (%e, %e)\n', min(abs(vdw6_real)), max(vdw6_real));
fprintf(fileID, '\tvdw6_poly range is: (%e, %e)\n', min(abs(vdw6_poly)), max(vdw6_poly));
fprintf(fileID, '\tFvdw_real range is: (%e, %e)\n', min(Fvdw_real), max(Fvdw_real));
fprintf(fileID, '\tFvdw_poly range is: (%e, %e)\n', min(Fvdw_poly), max(Fvdw_poly));
fprintf(fileID, '\tEvdw_real range is: (%e, %e)\n', min(Evdw_real), max(Evdw_real));
fprintf(fileID, '\tEvdw_poly range is: (%e, %e)\n', min(Evdw_poly), max(Evdw_poly));
fprintf(fileID, '\tAverage error rate is: Force %f%%, Energy %f%%\n', f_average_error_rate * 100, e_average_error_rate * 100);
fclose(fileID);

plot(Fvdw_poly);
hold on;
plot(Fvdw_real);
%ylim([0.1E5 0.2E5]);