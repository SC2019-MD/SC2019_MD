`timescale 1ns/1ns
module tbmemoryCtrl();

    parameter DIMENSION = 16;
    parameter NUM_FFTS = 4;
    parameter DATA_REAL_WIDTH = 32;
    parameter DATA_IMAG_WIDTH = 32;

    typedef struct packed
    {
        logic [DATA_REAL_WIDTH : 0] FFT_real;
        logic [DATA_IMAG_WIDTH : 0] FFT_imag;
    } FFT_input;

    logic clk, rst;
    logic [2:0] FFT_dim;

    FFT_input DATABASE_dataOut [0 : DIMENSION-1][0 : DIMENSION-1];
    FFT_input FFTData_out[0 : NUM_FFTS-1];

    integer count;

    memoryCtrl uut
    (
        .clk(clk),
        .rst(rst),
        .DATABASE_wren(), 
        .DATABASE_dataIn(), 
        .DATABASE_dataOut(DATABASE_dataOut), 
        .DATABASE_readAddress(), 
        .DATABASE_writeAddress(),

        .CMwen(), 
        .FFTwen(), 
        .selx(), 
        .sely(), 
        .selz(), 
        .mem_sel_4(), 
        .FFT_iteration(count[10:0]), 
        .FFT_dim(FFT_dim), 
        .coeff_in(), 
        .Force_out(), 
        .FFTData_in(), 
        .FFTData_out(FFTData_out)
    );

    always
    begin
        #5 clk <= ~clk;
    end


    integer i, j;
    initial 
    begin
        clk = 0;
        rst = 0;    
        count = 0;
        FFT_dim = 0;

        for (i = 0; i < DIMENSION; i = i + 1)
        begin
            for (j = 0; j < DIMENSION; j = j + 1)
            begin
                DATABASE_dataOut[i][j].FFT_real = i*DIMENSION + j;
                DATABASE_dataOut[i][j].FFT_imag = '0;
            end
        end

        #10;
        FFT_dim = 1;
        for (count = 0; count < 256+16; count = count + 1)
        begin
            #10;
        end
        FFT_dim = 0;

		#10;
		FFT_dim = 2;
		for (count = 0; count < 256+16; count = count + 1)
		begin
			#10;
		end
		FFT_dim = 0;

		#10;
		FFT_dim = 4;
		for (count = 0; count < 256+16; count = count + 1)
		begin
			#10;
		end
		FFT_dim = 0;

        #100;
        $stop;
        
    end

endmodule