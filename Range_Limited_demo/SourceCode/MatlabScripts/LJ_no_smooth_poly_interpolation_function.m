%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function: LJ_no_smooth_poly_interpolation_function
% Generate the interpolation table
% Currently only evaluate the LJ force, equation refer to 'Efficient Calculation of Pairwise Nonbonded Forces', M. Chiu, A. Khan, M. Herbordt, FCCM2011
%
% Final result:
%       The interpolation tables
%
% By: Chen Yang
% Boston University, CAAD Lab
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
function  LJ_no_smooth_poly_interpolation_function(interpolation_order,segment_num,bin_num,precision,min,max,cutoff,switchon,output_scale_index,eps,sigma)
% interpolation_order is the order of interpolation. i.e, interpolation_order=1 produces ax+b
% the results are from lower order to higher order, i.e coef(0,0) is the coefficient of constant term for first bin.
	
    % Paraemeters
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
	fileID_0  = fopen('c0_14.txt', 'wt');
    fileID_1  = fopen('c1_14.txt', 'wt');
    fileID_mif_0 = fopen('c0_14.mif', 'wt');
    fileID_mif_1 = fopen('c1_14.mif', 'wt');
    if(interpolation_order > 1)
        fileID_2  = fopen('c2_14.txt', 'wt');
        fileID_mif_2 = fopen('c2_14.mif', 'wt');
    end
    if(interpolation_order > 2)
        fileID_3  = fopen('c3_14.txt', 'wt');
        fileID_mif_3 = fopen('c3_14.mif', 'wt');
    end
    
    fileID_4  = fopen('c0_8.txt', 'wt');
    fileID_5  = fopen('c1_8.txt', 'wt');
    fileID_mif_4 = fopen('c0_8.mif', 'wt');
    fileID_mif_5 = fopen('c1_8.mif', 'wt');
    if(interpolation_order > 1)
        fileID_6  = fopen('c2_8.txt', 'wt');
        fileID_mif_6 = fopen('c2_8.mif', 'wt');
    end
    if(interpolation_order > 2)
        fileID_7  = fopen('c3_8.txt', 'wt');
        fileID_mif_7 = fopen('c3_8.mif', 'wt');
    end
    
    fileID_8  = fopen('c0_12.txt', 'wt');
    fileID_9  = fopen('c1_12.txt', 'wt');
    fileID_mif_8 = fopen('c0_12.mif', 'wt');
    fileID_mif_9 = fopen('c1_12.mif', 'wt');
    if(interpolation_order > 1)
        fileID_10 = fopen('c2_12.txt', 'wt');
        fileID_mif_10 = fopen('c2_12.mif', 'wt');
    end
    if(interpolation_order > 2)
        fileID_11 = fopen('c3_12.txt', 'wt');
        fileID_mif_11 = fopen('c3_12.mif', 'wt');
    end
    
    fileID_12 = fopen('c0_6.txt', 'wt');
    fileID_13 = fopen('c1_6.txt', 'wt');
    fileID_mif_12 = fopen('c0_6.mif', 'wt');
    fileID_mif_13 = fopen('c1_6.mif', 'wt');
    if(interpolation_order > 1)
        fileID_14 = fopen('c2_6.txt', 'wt');
        fileID_mif_14 = fopen('c2_6.mif', 'wt');
    end
    if(interpolation_order > 2)
        fileID_15 = fopen('c3_6.txt', 'wt');
        fileID_mif_15 = fopen('c3_6.mif', 'wt');
    end
    
    count = 0;
    
    cutoff2 = single(cutoff * cutoff);
    switchon2 = single(switchon * switchon);
    inv_denom = single((cutoff2 - switchon2)^3);
    denom = 1/inv_denom;
    
    range_min = min;
    range_max = 2*min;
    
    %% Write the mif file header
    fprintf(fileID_mif_0,'DEPTH = %d;\n',segment_num*bin_num);
    fprintf(fileID_mif_0,'WIDTH = 32;\n');
    fprintf(fileID_mif_0,'ADDRESS_RADIX = DEC;\n');
    fprintf(fileID_mif_0,'DATA_RADIX = HEX;\n');
    fprintf(fileID_mif_0,'CONTENT\n');
    fprintf(fileID_mif_0,'BEGIN\n');
    
    fprintf(fileID_mif_1,'DEPTH = %d;\n',segment_num*bin_num);
    fprintf(fileID_mif_1,'WIDTH = 32;\n');
    fprintf(fileID_mif_1,'ADDRESS_RADIX = DEC;\n');
    fprintf(fileID_mif_1,'DATA_RADIX = HEX;\n');
    fprintf(fileID_mif_1,'CONTENT\n');
    fprintf(fileID_mif_1,'BEGIN\n');
    
    fprintf(fileID_mif_4,'DEPTH = %d;\n',segment_num*bin_num);
    fprintf(fileID_mif_4,'WIDTH = 32;\n');
    fprintf(fileID_mif_4,'ADDRESS_RADIX = DEC;\n');
    fprintf(fileID_mif_4,'DATA_RADIX = HEX;\n');
    fprintf(fileID_mif_4,'CONTENT\n');
    fprintf(fileID_mif_4,'BEGIN\n');
    
    fprintf(fileID_mif_5,'DEPTH = %d;\n',segment_num*bin_num);
    fprintf(fileID_mif_5,'WIDTH = 32;\n');
    fprintf(fileID_mif_5,'ADDRESS_RADIX = DEC;\n');
    fprintf(fileID_mif_5,'DATA_RADIX = HEX;\n');
    fprintf(fileID_mif_5,'CONTENT\n');
    fprintf(fileID_mif_5,'BEGIN\n');
    
    if interpolation_order > 1
        fprintf(fileID_mif_2,'DEPTH = %d;\n',segment_num*bin_num);
        fprintf(fileID_mif_2,'WIDTH = 32;\n');
        fprintf(fileID_mif_2,'ADDRESS_RADIX = DEC;\n');
        fprintf(fileID_mif_2,'DATA_RADIX = HEX;\n');
        fprintf(fileID_mif_2,'CONTENT\n');
        fprintf(fileID_mif_2,'BEGIN\n');

        fprintf(fileID_mif_6,'DEPTH = %d;\n',segment_num*bin_num);
        fprintf(fileID_mif_6,'WIDTH = 32;\n');
        fprintf(fileID_mif_6,'ADDRESS_RADIX = DEC;\n');
        fprintf(fileID_mif_6,'DATA_RADIX = HEX;\n');
        fprintf(fileID_mif_6,'CONTENT\n');
        fprintf(fileID_mif_6,'BEGIN\n');
    end
    
    if interpolation_order > 2
        fprintf(fileID_mif_3,'DEPTH = %d;\n',segment_num*bin_num);
        fprintf(fileID_mif_3,'WIDTH = 32;\n');
        fprintf(fileID_mif_3,'ADDRESS_RADIX = DEC;\n');
        fprintf(fileID_mif_3,'DATA_RADIX = HEX;\n');
        fprintf(fileID_mif_3,'CONTENT\n');
        fprintf(fileID_mif_3,'BEGIN\n');

        fprintf(fileID_mif_7,'DEPTH = %d;\n',segment_num*bin_num);
        fprintf(fileID_mif_7,'WIDTH = 32;\n');
        fprintf(fileID_mif_7,'ADDRESS_RADIX = DEC;\n');
        fprintf(fileID_mif_7,'DATA_RADIX = HEX;\n');
        fprintf(fileID_mif_7,'CONTENT\n');
        fprintf(fileID_mif_7,'BEGIN\n');
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
                
                inv_r6(i)  = inv_r2 * inv_r4;
                inv_r12(i) = inv_r6(i) * inv_r6(i);
                
                inv_r14(i) = output_scale_index * 48 * eps * sigma ^ 12 * inv_r12(i) * inv_r2;
                inv_r8(i)  = output_scale_index * 24 * eps * sigma ^ 6  * inv_r6(i)  * inv_r2;
                
                inv_r12(i) = output_scale_index * 4 * eps * sigma ^ 12 * inv_r12(i);
                inv_r6(i)  = output_scale_index * 4 * eps * sigma ^ 6  * inv_r6(i);
                
                %inv_r14(i) = output_scale_index * inv_r12(i) * inv_r2;
                %inv_r8(i)  = output_scale_index * inv_r6(i)  * inv_r2;
                
                %inv_r12(i) = output_scale_index * inv_r12(i) * inv_r2;
                %inv_r6(i)  = output_scale_index * inv_r6(i)  * inv_r2;
            end

            r14_func = polyfit(x,inv_r14,interpolation_order);
            r8_func  = polyfit(x,inv_r8,interpolation_order);
            r12_func = polyfit(x,inv_r12,interpolation_order);
            r6_func  = polyfit(x,inv_r6,interpolation_order);
            
            ncoef=length(r14_func);
            
            switch(interpolation_order)
                case 1
                    % write to file for verification
                    fprintf(fileID_0,'%15.25f\n',r14_func(2));
                    fprintf(fileID_1,'%15.25f\n',r14_func(1));

                    fprintf(fileID_4,'%15.25f\n',r8_func(2));
                    fprintf(fileID_5,'%15.25f\n',r8_func(1));

                    fprintf(fileID_8, '%15.25f\n',r12_func(2));
                    fprintf(fileID_9, '%15.25f\n',r12_func(1));

                    fprintf(fileID_12,'%15.25f\n',r6_func(2));
                    fprintf(fileID_13,'%15.25f\n',r6_func(1));
                    
                    % write to file for mif
                    fprintf(fileID_mif_0,'%d : %tX;\n',count, r14_func(2));
                    fprintf(fileID_mif_1,'%d : %tX;\n',count, r14_func(1));

                    fprintf(fileID_mif_4,'%d : %tX;\n',count, r8_func(2));
                    fprintf(fileID_mif_5,'%d : %tX;\n',count, r8_func(1));

                    fprintf(fileID_mif_8,'%d : %tX;\n',count, r12_func(2));
                    fprintf(fileID_mif_9,'%d : %tX;\n',count, r12_func(1));

                    fprintf(fileID_mif_12,'%d : %tX;\n',count, r6_func(2));
                    fprintf(fileID_mif_13,'%d : %tX;\n',count, r6_func(1));
                    
                case 2
                    % write to file for verification
                    fprintf(fileID_0,'%15.25f\n',r14_func(3));
                    fprintf(fileID_1,'%15.25f\n',r14_func(2));
                    fprintf(fileID_2,'%15.25f\n',r14_func(1)); 

                    fprintf(fileID_4,'%15.25f\n',r8_func(3));
                    fprintf(fileID_5,'%15.25f\n',r8_func(2));
                    fprintf(fileID_6,'%15.25f\n',r8_func(1));

                    fprintf(fileID_8, '%15.25f\n',r12_func(3));
                    fprintf(fileID_9, '%15.25f\n',r12_func(2));
                    fprintf(fileID_10,'%15.25f\n',r12_func(1)); 

                    fprintf(fileID_12,'%15.25f\n',r6_func(3));
                    fprintf(fileID_13,'%15.25f\n',r6_func(2));
                    fprintf(fileID_14,'%15.25f\n',r6_func(1));
                    
                    % write to file for mif
                    fprintf(fileID_mif_0,'%d : %tX;\n',count, r14_func(3));
                    fprintf(fileID_mif_1,'%d : %tX;\n',count, r14_func(2));
                    fprintf(fileID_mif_2,'%d : %tX;\n',count, r14_func(1));

                    fprintf(fileID_mif_4,'%d : %tX;\n',count, r8_func(3));
                    fprintf(fileID_mif_5,'%d : %tX;\n',count, r8_func(2));
                    fprintf(fileID_mif_6,'%d : %tX;\n',count, r8_func(1));

                    fprintf(fileID_mif_8,'%d : %tX;\n',count, r12_func(3));
                    fprintf(fileID_mif_9,'%d : %tX;\n',count, r12_func(2));
                    fprintf(fileID_mif_10,'%d : %tX;\n',count, r12_func(1));

                    fprintf(fileID_mif_12,'%d : %tX;\n',count, r6_func(3));
                    fprintf(fileID_mif_13,'%d : %tX;\n',count, r6_func(2));
                    fprintf(fileID_mif_14,'%d : %tX;\n',count, r6_func(1));
                    
                case 3
                    % write to file for verification
                    fprintf(fileID_0,'%15.25f\n',r14_func(4));
                    fprintf(fileID_1,'%15.25f\n',r14_func(3));
                    fprintf(fileID_2,'%15.25f\n',r14_func(2)); 
                    fprintf(fileID_3,'%15.25f\n',r14_func(1)); 

                    fprintf(fileID_4,'%15.25f\n',r8_func(4));
                    fprintf(fileID_5,'%15.25f\n',r8_func(3));
                    fprintf(fileID_6,'%15.25f\n',r8_func(2));
                    fprintf(fileID_7,'%15.25f\n',r8_func(1));

                    fprintf(fileID_8, '%15.25f\n',r12_func(4));
                    fprintf(fileID_9, '%15.25f\n',r12_func(3));
                    fprintf(fileID_10,'%15.25f\n',r12_func(2)); 
                    fprintf(fileID_11,'%15.25f\n',r12_func(1));

                    fprintf(fileID_12,'%15.25f\n',r6_func(4));
                    fprintf(fileID_13,'%15.25f\n',r6_func(3));
                    fprintf(fileID_14,'%15.25f\n',r6_func(2));
                    fprintf(fileID_15,'%15.25f\n',r6_func(1));
                    
                    % write to file for mif
                    fprintf(fileID_mif_0,'%d : %tX;\n',count, r14_func(4));
                    fprintf(fileID_mif_1,'%d : %tX;\n',count, r14_func(3));
                    fprintf(fileID_mif_2,'%d : %tX;\n',count, r14_func(2));
                    fprintf(fileID_mif_3,'%d : %tX;\n',count, r14_func(1));

                    fprintf(fileID_mif_4,'%d : %tX;\n',count, r8_func(4));
                    fprintf(fileID_mif_5,'%d : %tX;\n',count, r8_func(3));
                    fprintf(fileID_mif_6,'%d : %tX;\n',count, r8_func(2));
                    fprintf(fileID_mif_7,'%d : %tX;\n',count, r8_func(1));

                    fprintf(fileID_mif_8,'%d : %tX;\n',count, r12_func(4));
                    fprintf(fileID_mif_9,'%d : %tX;\n',count, r12_func(3));
                    fprintf(fileID_mif_10,'%d : %tX;\n',count, r12_func(2));
                    fprintf(fileID_mif_11,'%d : %tX;\n',count, r12_func(1));

                    fprintf(fileID_mif_12,'%d : %tX;\n',count, r6_func(4));
                    fprintf(fileID_mif_13,'%d : %tX;\n',count, r6_func(3));
                    fprintf(fileID_mif_14,'%d : %tX;\n',count, r6_func(2));
                    fprintf(fileID_mif_15,'%d : %tX;\n',count, r6_func(1));
            end
            
            %fprintf(fileID_0,'%d\t:\t%tx;\n', count, r14_func(4));
            %fprintf(fileID_1,'%d\t:\t%tx;\n', count, r14_func(3));
            %fprintf(fileID_2,'%d\t:\t%tx;\n', count, r14_func(2));
            %fprintf(fileID_3,'%d\t:\t%tx;\n', count, r14_func(1));
            
            %fprintf(fileID_4,'%d\t:\t%tx;\n', count, r8_func(4));
            %fprintf(fileID_5,'%d\t:\t%tx;\n', count, r8_func(3));
            %fprintf(fileID_6,'%d\t:\t%tx;\n', count, r8_func(2));
            %fprintf(fileID_7,'%d\t:\t%tx;\n', count, r8_func(1));
            
            %fprintf(fileID_8,'%d\t:\t%tx;\n',  count, r12_func(4));
            %fprintf(fileID_9,'%d\t:\t%tx;\n',  count, r12_func(3));
            %fprintf(fileID_10,'%d\t:\t%tx;\n', count, r12_func(2));
            %fprintf(fileID_11,'%d\t:\t%tx;\n', count, r12_func(1));
            
            %fprintf(fileID_12,'%d\t:\t%tx;\n', count, r6_func(4));
            %fprintf(fileID_13,'%d\t:\t%tx;\n', count, r6_func(3));
            %fprintf(fileID_14,'%d\t:\t%tx;\n', count, r6_func(2));
            %fprintf(fileID_15,'%d\t:\t%tx;\n', count, r6_func(1));
           
            count = count + 1;
            ca = ca + step;
        end
        
        range_min = range_min * 2;
        range_max = range_max * 2;
    end
    
    %% Write the end of mif file
    fprintf(fileID_mif_0,'END;\n');
    fprintf(fileID_mif_1,'END;\n');
    fprintf(fileID_mif_4,'END;\n');
    fprintf(fileID_mif_5,'END;\n');
    if interpolation_order > 1
        fprintf(fileID_mif_2,'END;\n');
        fprintf(fileID_mif_6,'END;\n');
    end
    if interpolation_order > 2
        fprintf(fileID_mif_3,'END;\n');
        fprintf(fileID_mif_7,'END;\n');
    end
    
    
    %% Close the files
    fclose(fileID_0);
    fclose(fileID_1);
    fclose(fileID_4);
    fclose(fileID_5);
    fclose(fileID_8);
    fclose(fileID_9);
    fclose(fileID_12);
    fclose(fileID_13);
    
    fclose(fileID_mif_0);
    fclose(fileID_mif_1);
    fclose(fileID_mif_4);
    fclose(fileID_mif_5);
    fclose(fileID_mif_8);
    fclose(fileID_mif_9);
    fclose(fileID_mif_12);
    fclose(fileID_mif_13);

    if interpolation_order > 1
        fclose(fileID_2);
        fclose(fileID_6);
        fclose(fileID_10);
        fclose(fileID_14);
        
        fclose(fileID_mif_2);
        fclose(fileID_mif_6);
        fclose(fileID_mif_10);
        fclose(fileID_mif_14);
    end
    
    if interpolation_order > 2
        fclose(fileID_3);
        fclose(fileID_7);
        fclose(fileID_11);
        fclose(fileID_15);
        
        fclose(fileID_mif_3);
        fclose(fileID_mif_7);
        fclose(fileID_mif_11);
        fclose(fileID_mif_15);
    end
    