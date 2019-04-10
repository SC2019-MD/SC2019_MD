%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function: LJ_Coulomb_no_smooth_poly_interpolation_function
% Generate the interpolation table
% Generate the interpolation table for both LJ force and Coulomb force, equation refer to 'Efficient Calculation of Pairwise Nonbonded Forces', M. Chiu, A. Khan, M. Herbordt, FCCM2011
%
% Final result:
%       The interpolation tables
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Example:
% Compute coefficients for target function f=x^-7 on range from 2^0 to 2^8 for a 2nd or 3rd order approximate polynomial with logirithmic szie intervals,
% every section is of 128 or 256 intervals, and output results to a.txt.
% 2^0 is becuase r2 > exclude_r2_min
% 2^8 is becuase r2 < cutoff2
%
% Command line:
% syms x
% f=x^-7
% poly_interpolation_coef_real(3,16,2^-4,2^-3,'a.txt')

% output_scale_index: the output value can be out the scope of single-precision floating point, thus use this value to scale the output result back
% eps: eps of the particles, Unit J
% sigma: sigma value of the particles, Unit meter
% interpolation_order: interpolation order
% bin_num: # of bins per segment
% precision: # of datapoints for each interpolation
% min, max: range of distance
% cutoff: cut-off radius
% switchon: switch on distance
function  LJ_Coulomb_no_smooth_poly_interpolation_function(interpolation_order,segment_num,bin_num,precision,min,max,cutoff,switchon,output_scale_index,eps,sigma)
% interpolation_order is the order of interpolation. i.e, interpolation_order=1 produces ax+b
% the results are from lower order to higher order, i.e coef(0,0) is the coefficient of constant term for first bin.
	
    % Control Parameters
    GEN_ENERGY_FILE = 1;
    
    % Parameters
    pi = 3.14;
    q0 = 1;
    q1 = 1;
    % Ar
%    kb = 1.380e-23;         % Boltzmann constant (J/K)
%    eps = kb * 120;         % Unit J
%    sigma = 3.4e-10;        % Unit meter


    if nargin < 6 
        error('LJ_poly_interpolation_function(interpolation_order,segment_num,bin_num,precision,min,max,cutoff,switchon)');
    end
    
	if min < 0
		error('min must be greater than 0.');
    end
    
	if interpolation_order > 3 || interpolation_order <= 0
        error('The supported interpolation order is 1, 2, 3 ....\n');
	end

    %% Create output files
    % R14 term for LJ force
	fileID_c0_14  = fopen('c0_14.txt', 'wt');
    fileID_c1_14  = fopen('c1_14.txt', 'wt');
    fileID_mif_c0_14 = fopen('c0_14.mif', 'wt');
    fileID_mif_c1_14 = fopen('c1_14.mif', 'wt');
    if(interpolation_order > 1)
        fileID_c2_14  = fopen('c2_14.txt', 'wt');
        fileID_mif_c2_14 = fopen('c2_14.mif', 'wt');
    end
    if(interpolation_order > 2)
        fileID_c3_14  = fopen('c3_14.txt', 'wt');
        fileID_mif_c3_14 = fopen('c3_14.mif', 'wt');
    end
    % R8 term for LJ force
    fileID_c0_8  = fopen('c0_8.txt', 'wt');
    fileID_c1_8  = fopen('c1_8.txt', 'wt');
    fileID_mif_c0_8 = fopen('c0_8.mif', 'wt');
    fileID_mif_c1_8 = fopen('c1_8.mif', 'wt');
    if(interpolation_order > 1)
        fileID_c2_8  = fopen('c2_8.txt', 'wt');
        fileID_mif_c2_8 = fopen('c2_8.mif', 'wt');
    end
    if(interpolation_order > 2)
        fileID_c3_8  = fopen('c3_8.txt', 'wt');
        fileID_mif_c3_8 = fopen('c3_8.mif', 'wt');
    end
    % R3 term for Coulomb force
    fileID_c0_3 = fopen('c0_3.txt', 'wt');
    fileID_c1_3 = fopen('c1_3.txt', 'wt');
    fileID_mif_c0_3 = fopen('c0_3.mif', 'wt');
    fileID_mif_c1_3 = fopen('c1_3.mif', 'wt');
    if(interpolation_order > 1)
        fileID_c2_3 = fopen('c2_3.txt', 'wt');
        fileID_mif_c2_3 = fopen('c2_3.mif', 'wt');
    end
    if(interpolation_order > 2)
        fileID_c3_3 = fopen('c3_3.txt', 'wt');
        fileID_mif_c3_3 = fopen('c3_3.mif', 'wt');
    end
   
    if GEN_ENERGY_FILE
        % R12 term for LJ potential
        fileID_c0_12  = fopen('c0_12.txt', 'wt');
        fileID_c1_12  = fopen('c1_12.txt', 'wt');
        fileID_mif_c0_12 = fopen('c0_12.mif', 'wt');
        fileID_mif_c1_12 = fopen('c1_12.mif', 'wt');
        if(interpolation_order > 1)
            fileID_c2_12 = fopen('c2_12.txt', 'wt');
            fileID_mif_c2_12 = fopen('c2_12.mif', 'wt');
        end
        if(interpolation_order > 2)
            fileID_c3_12 = fopen('c3_12.txt', 'wt');
            fileID_mif_c3_12 = fopen('c3_12.mif', 'wt');
        end
        % R6 term for LJ potential
        fileID_c0_6 = fopen('c0_6.txt', 'wt');
        fileID_c1_6 = fopen('c1_6.txt', 'wt');
        fileID_mif_c0_6 = fopen('c0_6.mif', 'wt');
        fileID_mif_c1_6 = fopen('c1_6.mif', 'wt');
        if(interpolation_order > 1)
            fileID_c2_6 = fopen('c2_6.txt', 'wt');
            fileID_mif_c2_6 = fopen('c2_6.mif', 'wt');
        end
        if(interpolation_order > 2)
            fileID_c3_6 = fopen('c3_6.txt', 'wt');
            fileID_mif_c3_6 = fopen('c3_6.mif', 'wt');
        end
        % R1 term for Coulomb potential
        fileID_c0_1 = fopen('c0_1.txt', 'wt');
        fileID_c1_1 = fopen('c1_1.txt', 'wt');
        fileID_mif_c0_1 = fopen('c0_1.mif', 'wt');
        fileID_mif_c1_1 = fopen('c1_1.mif', 'wt');
        if(interpolation_order > 1)
            fileID_c2_1 = fopen('c2_1.txt', 'wt');
            fileID_mif_c2_1 = fopen('c2_1.mif', 'wt');
        end
        if(interpolation_order > 2)
            fileID_c3_1 = fopen('c3_1.txt', 'wt');
            fileID_mif_c3_1 = fopen('c3_1.mif', 'wt');
        end
    end
    
    count = 0;
    
    cutoff2 = single(cutoff * cutoff);
    switchon2 = single(switchon * switchon);
    inv_denom = single((cutoff2 - switchon2)^3);
    denom = 1/inv_denom;
    
    range_min = min;
    range_max = 2*min;
    
    %% Write the mif file header
    fprintf(fileID_mif_c0_14,'DEPTH = %d;\n',segment_num*bin_num);
    fprintf(fileID_mif_c0_14,'WIDTH = 32;\n');
    fprintf(fileID_mif_c0_14,'ADDRESS_RADIX = DEC;\n');
    fprintf(fileID_mif_c0_14,'DATA_RADIX = HEX;\n');
    fprintf(fileID_mif_c0_14,'CONTENT\n');
    fprintf(fileID_mif_c0_14,'BEGIN\n');
    
    fprintf(fileID_mif_c1_14,'DEPTH = %d;\n',segment_num*bin_num);
    fprintf(fileID_mif_c1_14,'WIDTH = 32;\n');
    fprintf(fileID_mif_c1_14,'ADDRESS_RADIX = DEC;\n');
    fprintf(fileID_mif_c1_14,'DATA_RADIX = HEX;\n');
    fprintf(fileID_mif_c1_14,'CONTENT\n');
    fprintf(fileID_mif_c1_14,'BEGIN\n');
    
    fprintf(fileID_mif_c0_8,'DEPTH = %d;\n',segment_num*bin_num);
    fprintf(fileID_mif_c0_8,'WIDTH = 32;\n');
    fprintf(fileID_mif_c0_8,'ADDRESS_RADIX = DEC;\n');
    fprintf(fileID_mif_c0_8,'DATA_RADIX = HEX;\n');
    fprintf(fileID_mif_c0_8,'CONTENT\n');
    fprintf(fileID_mif_c0_8,'BEGIN\n');
    
    fprintf(fileID_mif_c1_8,'DEPTH = %d;\n',segment_num*bin_num);
    fprintf(fileID_mif_c1_8,'WIDTH = 32;\n');
    fprintf(fileID_mif_c1_8,'ADDRESS_RADIX = DEC;\n');
    fprintf(fileID_mif_c1_8,'DATA_RADIX = HEX;\n');
    fprintf(fileID_mif_c1_8,'CONTENT\n');
    fprintf(fileID_mif_c1_8,'BEGIN\n');
    
    fprintf(fileID_mif_c0_3,'DEPTH = %d;\n',segment_num*bin_num);
    fprintf(fileID_mif_c0_3,'WIDTH = 32;\n');
    fprintf(fileID_mif_c0_3,'ADDRESS_RADIX = DEC;\n');
    fprintf(fileID_mif_c0_3,'DATA_RADIX = HEX;\n');
    fprintf(fileID_mif_c0_3,'CONTENT\n');
    fprintf(fileID_mif_c0_3,'BEGIN\n');
    
    fprintf(fileID_mif_c1_3,'DEPTH = %d;\n',segment_num*bin_num);
    fprintf(fileID_mif_c1_3,'WIDTH = 32;\n');
    fprintf(fileID_mif_c1_3,'ADDRESS_RADIX = DEC;\n');
    fprintf(fileID_mif_c1_3,'DATA_RADIX = HEX;\n');
    fprintf(fileID_mif_c1_3,'CONTENT\n');
    fprintf(fileID_mif_c1_3,'BEGIN\n');
    
    if GEN_ENERGY_FILE
        fprintf(fileID_mif_c0_12,'DEPTH = %d;\n',segment_num*bin_num);
        fprintf(fileID_mif_c0_12,'WIDTH = 32;\n');
        fprintf(fileID_mif_c0_12,'ADDRESS_RADIX = DEC;\n');
        fprintf(fileID_mif_c0_12,'DATA_RADIX = HEX;\n');
        fprintf(fileID_mif_c0_12,'CONTENT\n');
        fprintf(fileID_mif_c0_12,'BEGIN\n');

        fprintf(fileID_mif_c1_12,'DEPTH = %d;\n',segment_num*bin_num);
        fprintf(fileID_mif_c1_12,'WIDTH = 32;\n');
        fprintf(fileID_mif_c1_12,'ADDRESS_RADIX = DEC;\n');
        fprintf(fileID_mif_c1_12,'DATA_RADIX = HEX;\n');
        fprintf(fileID_mif_c1_12,'CONTENT\n');
        fprintf(fileID_mif_c1_12,'BEGIN\n');

        fprintf(fileID_mif_c0_6,'DEPTH = %d;\n',segment_num*bin_num);
        fprintf(fileID_mif_c0_6,'WIDTH = 32;\n');
        fprintf(fileID_mif_c0_6,'ADDRESS_RADIX = DEC;\n');
        fprintf(fileID_mif_c0_6,'DATA_RADIX = HEX;\n');
        fprintf(fileID_mif_c0_6,'CONTENT\n');
        fprintf(fileID_mif_c0_6,'BEGIN\n');

        fprintf(fileID_mif_c1_6,'DEPTH = %d;\n',segment_num*bin_num);
        fprintf(fileID_mif_c1_6,'WIDTH = 32;\n');
        fprintf(fileID_mif_c1_6,'ADDRESS_RADIX = DEC;\n');
        fprintf(fileID_mif_c1_6,'DATA_RADIX = HEX;\n');
        fprintf(fileID_mif_c1_6,'CONTENT\n');
        fprintf(fileID_mif_c1_6,'BEGIN\n');

        fprintf(fileID_mif_c0_1,'DEPTH = %d;\n',segment_num*bin_num);
        fprintf(fileID_mif_c0_1,'WIDTH = 32;\n');
        fprintf(fileID_mif_c0_1,'ADDRESS_RADIX = DEC;\n');
        fprintf(fileID_mif_c0_1,'DATA_RADIX = HEX;\n');
        fprintf(fileID_mif_c0_1,'CONTENT\n');
        fprintf(fileID_mif_c0_1,'BEGIN\n');

        fprintf(fileID_mif_c1_1,'DEPTH = %d;\n',segment_num*bin_num);
        fprintf(fileID_mif_c1_1,'WIDTH = 32;\n');
        fprintf(fileID_mif_c1_1,'ADDRESS_RADIX = DEC;\n');
        fprintf(fileID_mif_c1_1,'DATA_RADIX = HEX;\n');
        fprintf(fileID_mif_c1_1,'CONTENT\n');
        fprintf(fileID_mif_c1_1,'BEGIN\n');
    end
    
    if interpolation_order > 1
        fprintf(fileID_mif_c2_14,'DEPTH = %d;\n',segment_num*bin_num);
        fprintf(fileID_mif_c2_14,'WIDTH = 32;\n');
        fprintf(fileID_mif_c2_14,'ADDRESS_RADIX = DEC;\n');
        fprintf(fileID_mif_c2_14,'DATA_RADIX = HEX;\n');
        fprintf(fileID_mif_c2_14,'CONTENT\n');
        fprintf(fileID_mif_c2_14,'BEGIN\n');

        fprintf(fileID_mif_c2_8,'DEPTH = %d;\n',segment_num*bin_num);
        fprintf(fileID_mif_c2_8,'WIDTH = 32;\n');
        fprintf(fileID_mif_c2_8,'ADDRESS_RADIX = DEC;\n');
        fprintf(fileID_mif_c2_8,'DATA_RADIX = HEX;\n');
        fprintf(fileID_mif_c2_8,'CONTENT\n');
        fprintf(fileID_mif_c2_8,'BEGIN\n');
        
        fprintf(fileID_mif_c2_3,'DEPTH = %d;\n',segment_num*bin_num);
        fprintf(fileID_mif_c2_3,'WIDTH = 32;\n');
        fprintf(fileID_mif_c2_3,'ADDRESS_RADIX = DEC;\n');
        fprintf(fileID_mif_c2_3,'DATA_RADIX = HEX;\n');
        fprintf(fileID_mif_c2_3,'CONTENT\n');
        fprintf(fileID_mif_c2_3,'BEGIN\n');
        
        if GEN_ENERGY_FILE
            fprintf(fileID_mif_c2_12,'DEPTH = %d;\n',segment_num*bin_num);
            fprintf(fileID_mif_c2_12,'WIDTH = 32;\n');
            fprintf(fileID_mif_c2_12,'ADDRESS_RADIX = DEC;\n');
            fprintf(fileID_mif_c2_12,'DATA_RADIX = HEX;\n');
            fprintf(fileID_mif_c2_12,'CONTENT\n');
            fprintf(fileID_mif_c2_12,'BEGIN\n');

            fprintf(fileID_mif_c2_6,'DEPTH = %d;\n',segment_num*bin_num);
            fprintf(fileID_mif_c2_6,'WIDTH = 32;\n');
            fprintf(fileID_mif_c2_6,'ADDRESS_RADIX = DEC;\n');
            fprintf(fileID_mif_c2_6,'DATA_RADIX = HEX;\n');
            fprintf(fileID_mif_c2_6,'CONTENT\n');
            fprintf(fileID_mif_c2_6,'BEGIN\n');

            fprintf(fileID_mif_c2_1,'DEPTH = %d;\n',segment_num*bin_num);
            fprintf(fileID_mif_c2_1,'WIDTH = 32;\n');
            fprintf(fileID_mif_c2_1,'ADDRESS_RADIX = DEC;\n');
            fprintf(fileID_mif_c2_1,'DATA_RADIX = HEX;\n');
            fprintf(fileID_mif_c2_1,'CONTENT\n');
            fprintf(fileID_mif_c2_1,'BEGIN\n');
        end
    end
    
    if interpolation_order > 2
        fprintf(fileID_mif_c3_14,'DEPTH = %d;\n',segment_num*bin_num);
        fprintf(fileID_mif_c3_14,'WIDTH = 32;\n');
        fprintf(fileID_mif_c3_14,'ADDRESS_RADIX = DEC;\n');
        fprintf(fileID_mif_c3_14,'DATA_RADIX = HEX;\n');
        fprintf(fileID_mif_c3_14,'CONTENT\n');
        fprintf(fileID_mif_c3_14,'BEGIN\n');

        fprintf(fileID_mif_c3_8,'DEPTH = %d;\n',segment_num*bin_num);
        fprintf(fileID_mif_c3_8,'WIDTH = 32;\n');
        fprintf(fileID_mif_c3_8,'ADDRESS_RADIX = DEC;\n');
        fprintf(fileID_mif_c3_8,'DATA_RADIX = HEX;\n');
        fprintf(fileID_mif_c3_8,'CONTENT\n');
        fprintf(fileID_mif_c3_8,'BEGIN\n');
        
        fprintf(fileID_mif_c3_3,'DEPTH = %d;\n',segment_num*bin_num);
        fprintf(fileID_mif_c3_3,'WIDTH = 32;\n');
        fprintf(fileID_mif_c3_3,'ADDRESS_RADIX = DEC;\n');
        fprintf(fileID_mif_c3_3,'DATA_RADIX = HEX;\n');
        fprintf(fileID_mif_c3_3,'CONTENT\n');
        fprintf(fileID_mif_c3_3,'BEGIN\n');
        
        if GEN_ENERGY_FILE
            fprintf(fileID_mif_c3_12,'DEPTH = %d;\n',segment_num*bin_num);
            fprintf(fileID_mif_c3_12,'WIDTH = 32;\n');
            fprintf(fileID_mif_c3_12,'ADDRESS_RADIX = DEC;\n');
            fprintf(fileID_mif_c3_12,'DATA_RADIX = HEX;\n');
            fprintf(fileID_mif_c3_12,'CONTENT\n');
            fprintf(fileID_mif_c3_12,'BEGIN\n');

            fprintf(fileID_mif_c3_6,'DEPTH = %d;\n',segment_num*bin_num);
            fprintf(fileID_mif_c3_6,'WIDTH = 32;\n');
            fprintf(fileID_mif_c3_6,'ADDRESS_RADIX = DEC;\n');
            fprintf(fileID_mif_c3_6,'DATA_RADIX = HEX;\n');
            fprintf(fileID_mif_c3_6,'CONTENT\n');
            fprintf(fileID_mif_c3_6,'BEGIN\n');

            fprintf(fileID_mif_c3_1,'DEPTH = %d;\n',segment_num*bin_num);
            fprintf(fileID_mif_c3_1,'WIDTH = 32;\n');
            fprintf(fileID_mif_c3_1,'ADDRESS_RADIX = DEC;\n');
            fprintf(fileID_mif_c3_1,'DATA_RADIX = HEX;\n');
            fprintf(fileID_mif_c3_1,'CONTENT\n');
            fprintf(fileID_mif_c3_1,'BEGIN\n');
        end
    end
    
    
    %% Start evaluation
    while(range_min < max)          % EACH SEGMENT
    
        step = single((range_max-range_min)/bin_num);
        ca = single(range_min);
        cb = range_min + step;
    
        for j=1:bin_num                   % EACH BIN
            x = zeros(precision,1);

            % for L-J Potential/Force
            inv_r12 = single(zeros(precision,1));
            inv_r6  = single(zeros(precision,1));
            
            inv_r14 = single(zeros(precision,1));
            inv_r8  = single(zeros(precision,1));
            
            inv_r3  = single(zeros(precision,1));
            inv_r1  = single(zeros(precision,1));
            
            delta = step/precision;
    
            for i=1:precision
                x(i) = ca + (i-1) * delta;
                r2 = x(i);
                
%                 if(r2 <= switchon2)
%                     s = 1;
%                     ds = 0;
%                 end
%         
%                 if(r2 > switchon2 && r2 <= cutoff2)
%                     s = (cutoff2 - r2) * (cutoff2 - r2) * (cutoff2 + 2*r2 - 3 * switchon2) * denom;
%                     ds = 12 * (cutoff2 - r2) * (switchon2 - r2) * denom;
%                 end
%         
%                 if(r2 > cutoff2)
%                     s = 0;
%                     ds = 0;
%                 end
                
                inv_r2 = 1/r2;
                inv_r4 = inv_r2 * inv_r2;
                inv_r1_raw = sqrt(inv_r2);
                
                inv_r6(i)  = inv_r2 * inv_r4;
                inv_r12(i) = inv_r6(i) * inv_r6(i);
                
                inv_r14(i) = output_scale_index * 48 * eps * sigma ^ 12 * inv_r12(i) * inv_r2;
                inv_r8(i)  = output_scale_index * 24 * eps * sigma ^ 6  * inv_r6(i)  * inv_r2;
                
                inv_r12(i) = output_scale_index * 4 * eps * sigma ^ 12 * inv_r12(i);
                inv_r6(i)  = output_scale_index * 4 * eps * sigma ^ 6  * inv_r6(i);
                
                inv_r1(i)  = output_scale_index * (q0*q1) / (4*pi*eps) * inv_r1_raw;
                inv_r3(i)  = output_scale_index * (q0*q1) / (4*pi*eps) * inv_r2 * inv_r1_raw;
                
                %inv_r14(i) = output_scale_index * inv_r12(i) * inv_r2;
                %inv_r8(i)  = output_scale_index * inv_r6(i)  * inv_r2;
                
                %inv_r12(i) = output_scale_index * inv_r12(i) * inv_r2;
                %inv_r6(i)  = output_scale_index * inv_r6(i)  * inv_r2;
            end

            r14_func = polyfit(x,inv_r14,interpolation_order);
            r8_func  = polyfit(x,inv_r8,interpolation_order);
            r12_func = polyfit(x,inv_r12,interpolation_order);
            r6_func  = polyfit(x,inv_r6,interpolation_order);
            r3_func  = polyfit(x,inv_r3,interpolation_order);
            r1_func  = polyfit(x,inv_r1,interpolation_order);
            
            ncoef=length(r14_func);
            
            switch(interpolation_order)
                case 1
                    % write to file for verification
                    fprintf(fileID_c0_14,'%15.25f\n',r14_func(2));
                    fprintf(fileID_c1_14,'%15.25f\n',r14_func(1));
                    fprintf(fileID_c0_8,'%15.25f\n',r8_func(2));
                    fprintf(fileID_c1_8,'%15.25f\n',r8_func(1));
                    fprintf(fileID_c0_3,'%15.25f\n',r3_func(2));
                    fprintf(fileID_c1_3,'%15.25f\n',r3_func(1));
                    % write to file for mif
                    fprintf(fileID_mif_c0_14,'%d : %tX;\n',count, r14_func(2));
                    fprintf(fileID_mif_c1_14,'%d : %tX;\n',count, r14_func(1));
                    fprintf(fileID_mif_c0_8,'%d : %tX;\n',count, r8_func(2));
                    fprintf(fileID_mif_c1_8,'%d : %tX;\n',count, r8_func(1));
                    fprintf(fileID_mif_c0_3,'%d : %tX;\n',count, r3_func(2));
                    fprintf(fileID_mif_c1_3,'%d : %tX;\n',count, r3_func(1));
                    % Gen energy file
                    if GEN_ENERGY_FILE
                        fprintf(fileID_c0_12, '%15.25f\n',r12_func(2));
                        fprintf(fileID_c1_12, '%15.25f\n',r12_func(1));
                        fprintf(fileID_c0_6,'%15.25f\n',r6_func(2));
                        fprintf(fileID_c1_6,'%15.25f\n',r6_func(1));
                        fprintf(fileID_c0_1,'%15.25f\n',r1_func(2));
                        fprintf(fileID_c1_1,'%15.25f\n',r1_func(1));
                        fprintf(fileID_mif_c0_12,'%d : %tX;\n',count, r12_func(2));
                        fprintf(fileID_mif_c1_12,'%d : %tX;\n',count, r12_func(1));
                        fprintf(fileID_mif_c0_6,'%d : %tX;\n',count, r6_func(2));
                        fprintf(fileID_mif_c1_6,'%d : %tX;\n',count, r6_func(1));
                        fprintf(fileID_mif_c0_1,'%d : %tX;\n',count, r1_func(2));
                        fprintf(fileID_mif_c1_1,'%d : %tX;\n',count, r1_func(1));
                    end
                case 2
                    % write to file for verification
                    fprintf(fileID_c0_14,'%15.25f\n',r14_func(3));
                    fprintf(fileID_c1_14,'%15.25f\n',r14_func(2));
                    fprintf(fileID_c2_14,'%15.25f\n',r14_func(1)); 
                    fprintf(fileID_c0_8,'%15.25f\n',r8_func(3));
                    fprintf(fileID_c1_8,'%15.25f\n',r8_func(2));
                    fprintf(fileID_c2_8,'%15.25f\n',r8_func(1));
                    fprintf(fileID_c0_3,'%15.25f\n',r3_func(3));
                    fprintf(fileID_c1_3,'%15.25f\n',r3_func(2));
                    fprintf(fileID_c2_3,'%15.25f\n',r3_func(1));
                    % write to file for mif
                    fprintf(fileID_mif_c0_14,'%d : %tX;\n',count, r14_func(3));
                    fprintf(fileID_mif_c1_14,'%d : %tX;\n',count, r14_func(2));
                    fprintf(fileID_mif_c2_14,'%d : %tX;\n',count, r14_func(1));
                    fprintf(fileID_mif_c0_8,'%d : %tX;\n',count, r8_func(3));
                    fprintf(fileID_mif_c1_8,'%d : %tX;\n',count, r8_func(2));
                    fprintf(fileID_mif_c2_8,'%d : %tX;\n',count, r8_func(1));
                    fprintf(fileID_mif_c0_3,'%d : %tX;\n',count, r3_func(3));
                    fprintf(fileID_mif_c1_3,'%d : %tX;\n',count, r3_func(2));
                    fprintf(fileID_mif_c2_3,'%d : %tX;\n',count, r3_func(1));
                    % Gen energy file
                    if GEN_ENERGY_FILE
                        fprintf(fileID_c0_12, '%15.25f\n',r12_func(3));
                        fprintf(fileID_c1_12, '%15.25f\n',r12_func(2));
                        fprintf(fileID_c2_12,'%15.25f\n',r12_func(1)); 
                        fprintf(fileID_c0_6,'%15.25f\n',r6_func(3));
                        fprintf(fileID_c1_6,'%15.25f\n',r6_func(2));
                        fprintf(fileID_c2_6,'%15.25f\n',r6_func(1));
                        fprintf(fileID_c0_1,'%15.25f\n',r1_func(3));
                        fprintf(fileID_c1_1,'%15.25f\n',r1_func(2));
                        fprintf(fileID_c2_1,'%15.25f\n',r1_func(1));
                        fprintf(fileID_mif_c0_12,'%d : %tX;\n',count, r12_func(3));
                        fprintf(fileID_mif_c1_12,'%d : %tX;\n',count, r12_func(2));
                        fprintf(fileID_mif_c2_12,'%d : %tX;\n',count, r12_func(1));
                        fprintf(fileID_mif_c0_6,'%d : %tX;\n',count, r6_func(3));
                        fprintf(fileID_mif_c1_6,'%d : %tX;\n',count, r6_func(2));
                        fprintf(fileID_mif_c2_6,'%d : %tX;\n',count, r6_func(1));
                        fprintf(fileID_mif_c0_1,'%d : %tX;\n',count, r1_func(3));
                        fprintf(fileID_mif_c1_1,'%d : %tX;\n',count, r1_func(2));
                        fprintf(fileID_mif_c2_1,'%d : %tX;\n',count, r1_func(1));
                    end
                    
                case 3
                    % write to file for verification
                    fprintf(fileID_c0_14,'%15.25f\n',r14_func(4));
                    fprintf(fileID_c1_14,'%15.25f\n',r14_func(3));
                    fprintf(fileID_c2_14,'%15.25f\n',r14_func(2)); 
                    fprintf(fileID_c3_14,'%15.25f\n',r14_func(1)); 
                    fprintf(fileID_c0_8,'%15.25f\n',r8_func(4));
                    fprintf(fileID_c1_8,'%15.25f\n',r8_func(3));
                    fprintf(fileID_c2_8,'%15.25f\n',r8_func(2));
                    fprintf(fileID_c3_8,'%15.25f\n',r8_func(1));
                    fprintf(fileID_c0_3,'%15.25f\n',r3_func(4));
                    fprintf(fileID_c1_3,'%15.25f\n',r3_func(3));
                    fprintf(fileID_c2_3,'%15.25f\n',r3_func(2));
                    fprintf(fileID_c3_3,'%15.25f\n',r3_func(1));
                    % write to file for mif
                    fprintf(fileID_mif_c0_14,'%d : %tX;\n',count, r14_func(4));
                    fprintf(fileID_mif_c1_14,'%d : %tX;\n',count, r14_func(3));
                    fprintf(fileID_mif_c2_14,'%d : %tX;\n',count, r14_func(2));
                    fprintf(fileID_mif_c3_14,'%d : %tX;\n',count, r14_func(1));
                    fprintf(fileID_mif_c0_8,'%d : %tX;\n',count, r8_func(4));
                    fprintf(fileID_mif_c1_8,'%d : %tX;\n',count, r8_func(3));
                    fprintf(fileID_mif_c2_8,'%d : %tX;\n',count, r8_func(2));
                    fprintf(fileID_mif_c3_8,'%d : %tX;\n',count, r8_func(1));
                    fprintf(fileID_mif_c0_3,'%d : %tX;\n',count, r3_func(4));
                    fprintf(fileID_mif_c1_3,'%d : %tX;\n',count, r3_func(3));
                    fprintf(fileID_mif_c2_3,'%d : %tX;\n',count, r3_func(2));
                    fprintf(fileID_mif_c3_3,'%d : %tX;\n',count, r3_func(1));
                    % Gen energy file
                    if GEN_ENERGY_FILE
                        fprintf(fileID_c0_12, '%15.25f\n',r12_func(4));
                        fprintf(fileID_c1_12, '%15.25f\n',r12_func(3));
                        fprintf(fileID_c2_12,'%15.25f\n',r12_func(2)); 
                        fprintf(fileID_c3_12,'%15.25f\n',r12_func(1));
                        fprintf(fileID_c0_6,'%15.25f\n',r6_func(4));
                        fprintf(fileID_c1_6,'%15.25f\n',r6_func(3));
                        fprintf(fileID_c2_6,'%15.25f\n',r6_func(2));
                        fprintf(fileID_c3_6,'%15.25f\n',r6_func(1));
                        fprintf(fileID_c0_1,'%15.25f\n',r1_func(4));
                        fprintf(fileID_c1_1,'%15.25f\n',r1_func(3));
                        fprintf(fileID_c2_1,'%15.25f\n',r1_func(2));
                        fprintf(fileID_c3_1,'%15.25f\n',r1_func(1));
                        fprintf(fileID_mif_c0_12,'%d : %tX;\n',count, r12_func(4));
                        fprintf(fileID_mif_c1_12,'%d : %tX;\n',count, r12_func(3));
                        fprintf(fileID_mif_c2_12,'%d : %tX;\n',count, r12_func(2));
                        fprintf(fileID_mif_c3_12,'%d : %tX;\n',count, r12_func(1));
                        fprintf(fileID_mif_c0_6,'%d : %tX;\n',count, r6_func(4));
                        fprintf(fileID_mif_c1_6,'%d : %tX;\n',count, r6_func(3));
                        fprintf(fileID_mif_c2_6,'%d : %tX;\n',count, r6_func(2));
                        fprintf(fileID_mif_c3_6,'%d : %tX;\n',count, r6_func(1));
                        fprintf(fileID_mif_c0_1,'%d : %tX;\n',count, r1_func(4));
                        fprintf(fileID_mif_c1_1,'%d : %tX;\n',count, r1_func(3));
                        fprintf(fileID_mif_c2_1,'%d : %tX;\n',count, r1_func(2));
                        fprintf(fileID_mif_c3_1,'%d : %tX;\n',count, r1_func(1));
                    end
            end
            
            %fprintf(fileID_c0_14,'%d\t:\t%tx;\n', count, r14_func(4));
            %fprintf(fileID_c1_14,'%d\t:\t%tx;\n', count, r14_func(3));
            %fprintf(fileID_c2_14,'%d\t:\t%tx;\n', count, r14_func(2));
            %fprintf(fileID_c3_14,'%d\t:\t%tx;\n', count, r14_func(1));
            
            %fprintf(fileID_c0_8,'%d\t:\t%tx;\n', count, r8_func(4));
            %fprintf(fileID_c1_8,'%d\t:\t%tx;\n', count, r8_func(3));
            %fprintf(fileID_c2_8,'%d\t:\t%tx;\n', count, r8_func(2));
            %fprintf(fileID_c3_8,'%d\t:\t%tx;\n', count, r8_func(1));
            
            %fprintf(fileID_c0_12,'%d\t:\t%tx;\n',  count, r12_func(4));
            %fprintf(fileID_c1_12,'%d\t:\t%tx;\n',  count, r12_func(3));
            %fprintf(fileID_c2_12,'%d\t:\t%tx;\n', count, r12_func(2));
            %fprintf(fileID_c3_12,'%d\t:\t%tx;\n', count, r12_func(1));
            
            %fprintf(fileID_c0_6,'%d\t:\t%tx;\n', count, r6_func(4));
            %fprintf(fileID_c1_6,'%d\t:\t%tx;\n', count, r6_func(3));
            %fprintf(fileID_c2_6,'%d\t:\t%tx;\n', count, r6_func(2));
            %fprintf(fileID_c3_6,'%d\t:\t%tx;\n', count, r6_func(1));
           
            count = count + 1;
            ca = ca + step;
        end
        
        range_min = range_min * 2;
        range_max = range_max * 2;
    end
    
    %% Write the end of mif file
    fprintf(fileID_mif_c0_14,'END;\n');
    fprintf(fileID_mif_c1_14,'END;\n');
    fprintf(fileID_mif_c0_8,'END;\n');
    fprintf(fileID_mif_c1_8,'END;\n');
    fprintf(fileID_mif_c0_3,'END;\n');
    fprintf(fileID_mif_c1_3,'END;\n');
    if interpolation_order > 1
        fprintf(fileID_mif_c2_14,'END;\n');
        fprintf(fileID_mif_c2_8,'END;\n');
        fprintf(fileID_mif_c2_3,'END;\n');
    end
    if interpolation_order > 2
        fprintf(fileID_mif_c3_14,'END;\n');
        fprintf(fileID_mif_c3_8,'END;\n');
        fprintf(fileID_mif_c3_3,'END;\n');
    end
    
    if GEN_ENERGY_FILE
        fprintf(fileID_mif_c0_12,'END;\n');
        fprintf(fileID_mif_c1_12,'END;\n');
        fprintf(fileID_mif_c0_6,'END;\n');
        fprintf(fileID_mif_c1_6,'END;\n');
        fprintf(fileID_mif_c0_1,'END;\n');
        fprintf(fileID_mif_c1_1,'END;\n');
        if interpolation_order > 1
            fprintf(fileID_mif_c2_12,'END;\n');
            fprintf(fileID_mif_c2_6,'END;\n');
            fprintf(fileID_mif_c2_1,'END;\n');
        end
        if interpolation_order > 2
            fprintf(fileID_mif_c3_12,'END;\n');
            fprintf(fileID_mif_c3_6,'END;\n');
            fprintf(fileID_mif_c3_1,'END;\n');
        end
    end
    
    
    %% Close the files
    fclose(fileID_c0_14);
    fclose(fileID_c1_14);
    fclose(fileID_c0_8);
    fclose(fileID_c1_8);
    fclose(fileID_c0_3);
    fclose(fileID_c1_3);
    
    fclose(fileID_mif_c0_14);
    fclose(fileID_mif_c1_14);
    fclose(fileID_mif_c0_8);
    fclose(fileID_mif_c1_8);
    fclose(fileID_mif_c0_3);
    fclose(fileID_mif_c1_3);

    if interpolation_order > 1
        fclose(fileID_c2_14);
        fclose(fileID_c2_8);
        fclose(fileID_c2_3);
        
        fclose(fileID_mif_c2_14);
        fclose(fileID_mif_c2_8);
        fclose(fileID_mif_c2_3);
    end
    
    if interpolation_order > 2
        fclose(fileID_c3_14);
        fclose(fileID_c3_8);
        fclose(fileID_c3_3);
        
        fclose(fileID_mif_c3_14);
        fclose(fileID_mif_c3_8);
        fclose(fileID_mif_c3_3);
    end
    
    if GEN_ENERGY_FILE
        fclose(fileID_c0_12);
        fclose(fileID_c1_12);
        fclose(fileID_c0_6);
        fclose(fileID_c1_6);
        fclose(fileID_c0_1);
        fclose(fileID_c1_1);
        fclose(fileID_mif_c0_12);
        fclose(fileID_mif_c1_12);
        fclose(fileID_mif_c0_6);
        fclose(fileID_mif_c1_6);
        fclose(fileID_mif_c0_1);
        fclose(fileID_mif_c1_1);
        
        if interpolation_order > 1
            fclose(fileID_c2_12);
            fclose(fileID_c2_6);
            fclose(fileID_c2_1);
            fclose(fileID_mif_c2_12);
            fclose(fileID_mif_c2_6);
            fclose(fileID_mif_c2_1);
        end
        if interpolation_order > 2
            fclose(fileID_c3_12);
            fclose(fileID_c3_6);
            fclose(fileID_c3_1);
            fclose(fileID_mif_c3_12);
            fclose(fileID_mif_c3_6);
            fclose(fileID_mif_c3_1)
        end
    end