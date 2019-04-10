`timescale 1ns/1ns

module memoryCtrl
    (clk, rst, 
    DATABASE_wren, DATABASE_dataIn, DATABASE_dataOut, DATABASE_readAddress, DATABASE_writeAddress, 
    CMwen, FFTwen, selx, sely, selz, mem_sel_4, FFT_iteration, FFT_dim, coeff_in, Force_out, FFTData_in, FFTData_out);

    parameter NUMEQU = 4;
    parameter NUMCOEFF = 64;
    parameter DIMENSION = 16;
    parameter DIMENSION_LOG = 4;
    parameter DATA_REAL_WIDTH = 32;
    parameter DATA_IMAG_WIDTH = 32;
    parameter GRID_ADDRESS_WIDTH = 4;
    parameter NUM_FFTS = 4;

    typedef struct packed
    {
        logic [DATA_REAL_WIDTH : 0] FFT_real;
        logic [DATA_IMAG_WIDTH : 0] FFT_imag;
    } FFT_input;

    input logic clk, rst;

    input  logic DATABASE_wren [0 : DIMENSION-1][0 : DIMENSION-1];
    output FFT_input DATABASE_dataIn  [0 : DIMENSION-1][0 : DIMENSION-1];
    input  FFT_input DATABASE_dataOut [0 : DIMENSION-1][0 : DIMENSION-1];
    output logic [GRID_ADDRESS_WIDTH-1 : 0] DATABASE_readAddress [0 : DIMENSION-1][0 : DIMENSION-1];
    input  logic [GRID_ADDRESS_WIDTH-1 : 0] DATABASE_writeAddress [0 : DIMENSION-1][0 : DIMENSION-1];

    input logic CMwen;
    input logic [DIMENSION-1 : 0] FFTwren;

    input logic [DIMENSION_LOG-1 : 0] selx, sely, selz;

    input logic [1:0] mem_sel_4;

    input logic [10:0] FFT_iteration;
    input logic [2:0] FFT_dim;

    input logic [DATA_REAL_WIDTH-1 : 0] coeff_in [0:NUMEQU-1][0:NUMEQU-1][0:NUMEQU-1];
    input FFT_input FFTData_in [0 : NUM_FFTS-1];

    output FFT_input FFTData_out [0 : NUM_FFTS-1];
    output logic [DATA_REAL_WIDTH-1 : 0] Force_out [0:NUMEQU-1][0:NUMEQU-1][0:NUMEQU-1];

    // memory locations can only be up to 32. Thus 5'b.
    // Any coefficients that lie outside of the simulation box are ignored.
    // This means:
    //		Xlo: (selx % 32) == 0  then ignore x=0
    //		Xhi: (selx % 32) == 30 then ignore x=3
    //		Xhi: (selx % 32) == 31 then ignore x=3 & x=2

    //		Ylo: (sely % 32) == 0  then ignore y=0
    //		Yhi: (sely % 32) == 30 then ignore y=3
    //		Yhi: (sely % 32) == 31 then ignore y=3 & y=2

    //		Zlo: (selz % 32) == 0  then ignore z=0
    //		Zhi: (selz % 32) == 30 then ignore z=3
    //		Zhi: (selz % 32) == 31 then ignore z=3 & z=2

    assign new_selx = selx + (mem_sel_4 - 1);

    FFT_input FFT_DataOut_reorder [0 : 2][0 : DIMENSION-1][0 : DIMENSION-1][0 : DIMENSION-1];

    genvar m, n, p;
    generate 
        for (m = 0; m < DIMENSION; m = m + 1)
        begin: rearrange_per_fft
            for (n = 0; n < DIMENSION; n = n + 1)
            begin: rearrange_per_fft_iteration
                for (p = 0; p < DIMENSION; p = p + 1)
                begin: rearrage_per_fft_index
                    assign FFT_DataOut_reorder[0][n][p][m] = DATABASE_dataOut[m][n];
                    assign FFT_DataOut_reorder[1][n][p][m] = DATABASE_dataOut[p][m];
                    assign FFT_DataOut_reorder[2][n][p][m] = DATABASE_dataOut[m][p];

                    //assign FFT_wren_reorder[0][n][p][m] = FFTwren[m];
                    //assign FFT_wren_reorder[1][n][p][m] = FFTwren[m];
                    //assign FFT_wren_reorder[2][n][p][m] = FFTwren[m];
                end
            end
        end
    endgenerate

    always_comb
    begin
        case(FFT_dim)
            0:
            begin
                FFTData_out <= '{NUM_FFTS{'0}};
                DATABASE_readAddress <= '{DIMENSION{'{DIMENSION{'0}}}};
                //DATABASE_readAddress <= '{DIMENSION{'{DIMENSION{FFT_iteration[DIMENSION_LOG-1:0]}}}};
                DATABASE_writeAddress <= '{DIMENSION{'{DIMENSION{'0}}}};
                //DATABASE_wren <= '{DIMENSION{'{DIMENSION{'CMwen}}}};
            end
            1:
            begin
                FFTData_out <= FFT_DataOut_reorder[0][FFT_iteration[DIMENSION_LOG+(DIMENSION_LOG-1):DIMENSION_LOG]][FFT_iteration[DIMENSION_LOG-1:0]][0 : NUM_FFTS-1];
                DATABASE_readAddress <= '{DIMENSION{'{DIMENSION{FFT_iteration[DIMENSION_LOG-1:0]}}}};
                DATABASE_writeAddress <= '{DIMENSION{'{DIMENSION{FFT_iteration[DIMENSION_LOG-1:0]}}}};
            end
            2:
            begin
                FFTData_out <= FFT_DataOut_reorder[1][FFT_iteration[DIMENSION_LOG+DIMENSION_LOG-1:DIMENSION_LOG]][FFT_iteration[DIMENSION_LOG-1:0]][0 : NUM_FFTS-1];
                DATABASE_readAddress <= '{DIMENSION{'{DIMENSION{FFT_iteration[DIMENSION_LOG+DIMENSION_LOG-1:DIMENSION_LOG]}}}};
                DATABASE_writeAddress <= '{DIMENSION{'{DIMENSION{FFT_iteration[DIMENSION_LOG+DIMENSION_LOG-1:DIMENSION_LOG]-1}}}};
            end
            4:
            begin
                FFTData_out <= FFT_DataOut_reorder[2][FFT_iteration[DIMENSION_LOG+DIMENSION_LOG-1:DIMENSION_LOG]][FFT_iteration[DIMENSION_LOG-1:0]][0 : NUM_FFTS-1];
                DATABASE_readAddress <= '{DIMENSION{'{DIMENSION{FFT_iteration[DIMENSION_LOG+DIMENSION_LOG-1:DIMENSION_LOG]}}}};
                DATABASE_writeAddress <= '{DIMENSION{'{DIMENSION{FFT_iteration[DIMENSION_LOG+DIMENSION_LOG-1:DIMENSION_LOG]-1}}}};
            end
            default:
            begin
                FFTData_out <= '{NUM_FFTS{'0}};
                DATABASE_readAddress <= '{DIMENSION{'{DIMENSION{'0}}}};
            end
        endcase
    end

    /*integer i2;
    assign i2 = mem_sel_4 - 1;

    always_ff @ (posedge clk)
    begin

        integer m;
        
        integer j,j2;
        integer k,k2;

        integer x, y, z;
        
        for (m = 0; m < DIMENSION*DIMENSION; m = m + 1)
        begin
            writeAddress[m] <= 0;
            wren[m] <= 0;
            memInReal[m] <= 0;
            memInImg[m] <= 0;
        end

        if (FFT_dim == 3'd0)
        begin
            for (k = 0; k < NUMEQU; k = k + 1)
            begin
                k2 = k - 1;

                for (j = 0; j < NUMEQU; j = j + 1)
                begin
                    j2 = j - 1;

                    x = selx + i2;
                    y = sely + j2;
                    z = selz + k2;
                    if (x != -1 && x < 32 &&
                        y != -1 && y < 32 &&
                        z != -1 && z < 32) 
                    begin
                        memInReal[y + z*32] <= coeff_in[k][j][mem_sel_4];
                        memInImg[y + z*32] <= 0;
                        writeAddress[y + z*32] <= x[4:0];
                        wren[y + z*32] <= CMwen;
                    end
                end
            end
        end
        if (FFT_dim == 3'd1)
        begin
            
            integer addr;
            addr = (FFT_iteration[10:5] - 1)*32;
            if (addr >= 0 && addr < 1024)
            begin
                integer i;
                for (i = 0; i < DIMENSION; i = i + 1)
                begin
                    writeAddress [addr + i] <= FFT_iteration[4:0];
                    wren		 [addr + i] <= FFTwen[i];
                    memInReal    [addr + i] <= FFTData_in[addr + i][63:32];
                    memInImg     [addr + i] <= FFTData_in[addr + i][31:0];
                end
            end
        end
        if (FFT_dim == 3'd2)
        begin

            integer addr;
            integer i;

            addr = FFT_iteration[5:0] - 6'd1;

            for (i = 0; i < DIMENSION; i = i + 1)
            begin
                writeAddress [addr + i*DIMENSION] <= FFT_iteration[9:5];
                wren		 [addr + i*DIMENSION] <= FFTwen[i];
                memInReal    [addr + i*DIMENSION] <= FFTData_in[addr + i*DIMENSION][63:32];
                memInImg     [addr + i*DIMENSION] <= FFTData_in[addr + i*DIMENSION][31:0];
            end
        end
        if (FFT_dim == 3'd4)
        begin

            integer addr;
            integer i;

            addr = FFT_iteration[5:0] - 6'd1;

            for (i = 0; i < DIMENSION; i = i + 1)
            begin
                writeAddress [addr*DIMENSION + i] <= FFT_iteration[9:5];
                wren		 [addr*DIMENSION + i] <= FFTwen[i];
                memInReal    [addr*DIMENSION + i] <= FFTData_in[addr*DIMENSION + i][63:32];
                memInImg     [addr*DIMENSION + i] <= FFTData_in[addr*DIMENSION + i][31:0];
            end
        end
    end

    always_ff @ (posedge clk)
    begin

        // set readAddress
        //    using FFT_iteration and FFT_dim
        integer i;
        integer addr;
        for (i = 0; i < DIMENSION*DIMENSION; i = i + 1)
        begin
            readAddress[i] = 0;
        end

        if (FFT_dim == 3'd0)
        begin
            integer j,j2;
            integer k,k2;
            
            integer x, y, z;
        
            for (k = 0; k < NUMEQU; k = k + 1)
            begin
                k2 = k - 1;

                for (j = 0; j < NUMEQU; j = j + 1)
                begin
                    j2 = j - 1;

                    x = selx + i2;
                    y = sely + j2;
                    z = selz + k2;
                    if (x != -1 && x < 32 &&
                        y != -1 && y < 32 &&
                        z != -1 && z < 32) 
                    begin
                        Force_out[k][j][mem_sel_4] <= memOutReal[y + z*32];
                        readAddress[y + z*32] <= x[4:0];
                    end
                end
            end

        end


            addr = FFT_iteration[9:5]*32;

            if (addr >= 0 && addr < 1024)
            begin
                for (i = 0; i < DIMENSION; i = i + 1)
                begin
                    readAddress[addr + i] <= FFT_iteration[4:0];
                    FFTData_out[i] <= dataOut[addr + i];
                end
            end
        end

        if (FFT_dim == 3'd2)
        begin
            
            addr = FFT_iteration[4:0];
            
            for (i = 0; i < DIMENSION; i = i + 1)
            begin
                readAddress[addr + i*DIMENSION] <= FFT_iteration[9:5];
                FFTData_out[i] <= dataOut[addr + i*DIMENSION];
            end
        end
        if (FFT_dim == 3'd4)
        begin
            
            addr = FFT_iteration[4:0];
            
            for (i = 0; i < DIMENSION; i = i + 1)
            begin
                readAddress[addr*DIMENSION + i] <= FFT_iteration[9:5];
                FFTData_out[i] <= dataOut[addr*DIMENSION + i];
            end
        end

    end
    */

endmodule