ENABLE_PBC = 1;
CELL_COUNT_X = 7;%5;%3;
CELL_COUNT_Y = 6;%5;%3;
CELL_COUNT_Z = 6;%5;%3;
CUTOFF_RADIUS = single(8.5);
BOUNDING_BOX_SIZE_X = single(CELL_COUNT_X * CUTOFF_RADIUS);
BOUNDING_BOX_SIZE_Y = single(CELL_COUNT_Y * CUTOFF_RADIUS);
BOUNDING_BOX_SIZE_Z = single(CELL_COUNT_Z * CUTOFF_RADIUS);

TOTAL_PAIRS = 20000;
Amber_results = single(zeros(20000,8));

EPS = single(1.995996 * 1.995996);                    % Extracted from OpenMM, unit kJ      %0.996;% Unit: kJ	%0.238;% Unit kcal/mol	%kb * 120;% Unit J
SIGMA = single(2.1);%3.4;%0.8;%0.1675*2;                   % Extracted from LJArgon, unit Angstrom        %3.35;%3.4;% Unit Angstrom    %3.4e-10;% Unit meter, the unit should be in consistant with position value


%% Read in Amber results
filename = 'Amber_Output_with_coordinates.txt';
% Open File
fp = fopen(filename);
if fp == -1
        fprintf('failed to open %s\n',filename);
end
% Read in line by line
line_counter = 1;
while line_counter < TOTAL_PAIRS
    tline = fgets(fp);
    line_elements = textscan(tline,'%s %s %s %s %s %s %s %s %f64 %f64 %f64 %f64 %f64 %f64 %f64 %f64');
    Amber_results(line_counter,1) = line_elements{9};
    Amber_results(line_counter,2) = line_elements{10};
    Amber_results(line_counter,3) = line_elements{11};
    Amber_results(line_counter,4) = line_elements{12};
    Amber_results(line_counter,5) = line_elements{13};
    Amber_results(line_counter,6) = line_elements{14};
    Amber_results(line_counter,7) = line_elements{15};
    Amber_results(line_counter,8) = line_elements{16};
    line_counter = line_counter + 1;
end
% Close File
fclose(fp);

for i = 1:20
    dx = Amber_results(i,1) - Amber_results(i,4);
    dy = Amber_results(i,2) - Amber_results(i,5);
    dz = Amber_results(i,3) - Amber_results(i,6);
    % Apply periodic boundary
    if ENABLE_PBC
        dx = dx - BOUNDING_BOX_SIZE_X * round(dx/BOUNDING_BOX_SIZE_X);
        dy = dy - BOUNDING_BOX_SIZE_Y * round(dy/BOUNDING_BOX_SIZE_Y);
        dz = dz - BOUNDING_BOX_SIZE_Z * round(dz/BOUNDING_BOX_SIZE_Z);
    end
    
    r2 = dx^2 + dy^2 + dz^2;
    inv_r2 = 1 / r2;
    Evdw = 4 * EPS * SIGMA ^ 12 * inv_r2^6 - 4 * EPS * SIGMA ^ 6 * inv_r2^3;
    if abs(r2 - Amber_results(i,7)) > 0.01
        fprintf("Pair %d: r2 not matching! %f <---> %f\n", i, r2, Amber_results(i,7));
        %break;
    end
    if abs(Evdw - Amber_results(i,8)) > 0.01
        fprintf("Pair %d: Evdw not matching! %f <---> %f\n", i, Evdw, Amber_results(i,8));
    end
end
% Amber_results(1,1) = 4.2590000000000057;
% Amber_results(1,2) = 5.0469999999999988;
% Amber_results(1,3) = 4.1359999999999992;
% Amber_results(1,4) = 59.539999999999999;
% Amber_results(1,5) = 3.8180000000000018;
% Amber_results(1,6) = 48.999999999999993;
% i=1;
% dx = Amber_results(i,1) - Amber_results(i,4);
% dy = Amber_results(i,2) - Amber_results(i,5);
% dz = Amber_results(i,3) - Amber_results(i,6);
% % Apply periodic boundary
% if ENABLE_PBC
%     dx = dx - BOUNDING_BOX_SIZE_X * round(dx/BOUNDING_BOX_SIZE_X);
%     dy = dy - BOUNDING_BOX_SIZE_Y * round(dy/BOUNDING_BOX_SIZE_Y);
%     dz = dz - BOUNDING_BOX_SIZE_Z * round(dz/BOUNDING_BOX_SIZE_Z);
% end
% 
% r2 = dx^2 + dy^2 + dz^2;
% inv_r2 = 1 / r2;
% Evdw = 4 * EPS * SIGMA ^ 12 * inv_r2^6 - 4 * EPS * SIGMA ^ 6 * inv_r2^3;
