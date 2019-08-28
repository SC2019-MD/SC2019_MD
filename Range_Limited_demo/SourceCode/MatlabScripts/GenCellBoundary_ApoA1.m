%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generating the input mif file for cell boundary memory used by motion update units
% Output data in IEEE floating point format  
%
% Data Organization:
%       Cell id starts from 1, but memory address starts from 0
%       For example, for cell id = 1, the low boundary is at address 0, upper boundary is at address 1
%
% Output file:
%       cell_ini_boundary_value.mif
%
% Attention:
%
% Key variables:    
%
% By: Chen Yang
% 12/29/2018
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
MEMORY_DEPTH = max([CELL_COUNT_X CELL_COUNT_Y CELL_COUNT_Z])+1;   % The maximum possible cell count + 1
MEM_DATA_WIDTH = 32;                                                % Memory Data Width (32 bit for boundary information)
COMMON_PATH = '';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Write the ApoA1 cell boundary information to Memeory initialization file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate the initialization file name
cell_ini_file_name = strcat('cell_ini_boundary_value.mif');
% Create the mif file
fileID = fopen(cell_ini_file_name, 'wt');

fprintf('Starting write Cell boundary mem init file...\n');

% Write mif file header
fprintf(fileID,'DEPTH = %d;\n', MEMORY_DEPTH);
fprintf(fileID,'WIDTH = %d;\n', MEM_DATA_WIDTH);
fprintf(fileID,'ADDRESS_RADIX = DEC;\n');
fprintf(fileID,'DATA_RADIX = HEX;\n');
fprintf(fileID,'CONTENT\n');
fprintf(fileID,'BEGIN\n');

for i = 0:MEMORY_DEPTH-1
    fprintf(fileID,'%d : %tX;\n',i, i*CUTOFF_RADIUS);
end

% Write the end of mif file
fprintf(fileID,'END;\n');

% Close file
fclose(fileID);
fprintf('Cell boundary mem init file generation finished!\n');