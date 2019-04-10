`timescale 1ns/1ns
//Top module to connect others together
module Top_Electro(clk, rst, start_sig, user_buffer_data, user_data_available, forcedb_user_buffer_input_data);
    
    //------------------------------------------------------
    parameter DATA_REAL_WIDTH = 32;
    parameter DATA_IMAG_WIDTH = 32;
    parameter GRID_ADDRESS_WIDTH = 4;
    parameter DIMENSION = 16;
    parameter DIMENSION_LOG = 4;
    parameter COEFF_BOX_WIDTH = 4;
    parameter NUM_FFTS = 4;
    //------------------------------------------------------

    input clk, rst;
    input [1:0] start_sig;
    input [4*DATA_REAL_WIDTH-1:0] user_buffer_data; 
    input user_data_available;
    
    output [4*DATA_REAL_WIDTH-1:0] forcedb_user_buffer_input_data;
    
    //------------------------------------------------------
    typedef struct packed
    {
        logic [DATA_REAL_WIDTH : 0] FFT_real;
        logic [DATA_IMAG_WIDTH : 0] FFT_imag;
    } FFT_input;
    //------------------------------------------------------
    
    wire CMAPwenD;
    wire [18:0] Pdb_Address;
    wire CMAPwen_in;
    wire CMAPwen_out;
    wire Forcewen_in;
    wire forceValid_out;
    //wire [8:0] MemAddress;
    wire [DIMENSION_LOG-1 : 0] selx, sely, selz;
    wire [DATA_REAL_WIDTH-1 : 0] coeff     [0 : COEFF_BOX_WIDTH-1] [0 : COEFF_BOX_WIDTH-1] [0 : COEFF_BOX_WIDTH-1];
    wire [DATA_REAL_WIDTH-1 : 0] Force_out [0 : COEFF_BOX_WIDTH-1] [0 : COEFF_BOX_WIDTH-1] [0 : COEFF_BOX_WIDTH-1];
    wire [DATA_REAL_WIDTH-1 : 0] forcex    [0 : COEFF_BOX_WIDTH-1] [0 : COEFF_BOX_WIDTH-1] [0 : COEFF_BOX_WIDTH-1];
    wire [DATA_REAL_WIDTH-1 : 0] forcey    [0 : COEFF_BOX_WIDTH-1] [0 : COEFF_BOX_WIDTH-1] [0 : COEFF_BOX_WIDTH-1];
    wire [DATA_REAL_WIDTH-1 : 0] forcez    [0 : COEFF_BOX_WIDTH-1] [0 : COEFF_BOX_WIDTH-1] [0 : COEFF_BOX_WIDTH-1];
    
    wire [1:0] coeff_memSel;
    logic [1:0] mem_sel_4;
    
    wire [31:0] coeff_inter [0:63];
    
    wire [63:0] mem_inter_wen_out;
    wire [575:0] coeff_memAddr;
    
    wire stageCompletion;
    
    wire control_fixed_location;
    wire [31:0] control_base;
    wire [31:0] control_length;
    wire control_go;
    wire control_done;
    wire control_early_done;
    wire user_read_buffer;
    
    logic [2:0] FFT_dim;
    logic [10:0] FFT_iteration;
    
    logic [DIMENSION-1:0] FFTwen_writeback;
    
    
    logic FFTsop;
    logic FFTeop;
    logic FFTsinkValid;
    logic FFTsourceValid;
    logic FFTdirection;
    logic [31:0] source_valid;

    logic [14:0] particleCacheAddr;

    logic [127:0] force_buffer_data; 
    
    // INPUTS TO GRID MEMORY DATABASE
    logic DATABASE_wren [DIMENSION*DIMENSION-1 : 0];
    logic FFT_input DATABASE_dataIn  [DIMENSION*DIMENSION-1 : 0];
    logic FFT_input DATABASE_dataOut [DIMENSION*DIMENSION-1 : 0];
    logic [GRID_ADDRESS_WIDTH-1 : 0] DATABASE_readAddress [DIMENSION*DIMENSION-1 : 0];
    logic [GRID_ADDRESS_WIDTH-1 : 0] DATABASE_writeAddress [DIMENSION*DIMENSION-1 : 0];

    FFT_input FFTData_out [0 : NUM_FFTS - 1];
    FFT_input FFTData_in  [0 : NUM_FFTS - 1];
    
    cSFSM control_SM(
        .clk(clk),
        .rst(rst),
        .start_sig(start_sig[0]), 
        .CMAPwen(CMAPwen_in),				// wen for charge mapping with a once cycles delay
        .Forcewen(Forcewen_in),				// wen for charge mapping with a once cycles delay
        .CA_BI(),
        .memSel(coeff_memSel),			// select between idle(), cMAP(), FFT(), FFT+greens
        .memAddr(FFT_iteration),			// FFT and BI read Address 
        .selD(mem_sel_4),				// FFT mux sel. 
        .dim(FFT_dim),				// FFT Dimension Select
        .particleCacheAddr(particleCacheAddr),

        .user_data_available(user_data_available),
    
        .FFTsop(FFTsop),							// start frame signal for FFT modules - generate after 1 cycle delay
        .FFTeop(FFTeop), 							// end frame signal for FFT modules - generate after 1 cycles delay
        .FFTsinkValid(FFTsinkValid),						// start FFT operation - generate when generating the first sop
        .FFTsourceValid(FFTsourceValid),					// set to 1 when setting resetn to 1
        .FFTdirection(FFTdirection)						// 0 for FFT, 1 for iFFT. used to reverse real img parts and add divider to path
    
    );
    
    Particle_Mem position_data(
        .clock(clk),
        .data(user_buffer_data),      // Data [128]
        .q(force_buffer_data),         // Q [128]
        .wraddress(particleCacheAddr), // WRaddr [15]
        .rdaddress(particleCacheAddr), // RDaddr [15]
        .wren(CMAPwen_in)      
    );

    coeff64 CM_func(
        .clk(clk),
        .rst(rst),
        .wen_in(CMAPwen_in),
        .forceValid_in(Forcewen_in), // after cycle delay like wen_in
        .CA_BI(2'b00),
        .wen_out(CMAPwen_out),
        .forceValid_out(), //
        .selx(selx),
        .sely(sely),
        .selz(selz),
        .user_buffer_data(user_buffer_data),
        .coeff ( coeff )
    );
    
    coeff64 ForceX_func(
        .clk(clk),
        .rst(rst),
        .wen_in(CMAPwen_in),
        .forceValid_in(Forcewen_in), // after cycle delay like wen_in
        .CA_BI(2'b01),
        .wen_out(),
        .forceValid_out(), //
        .selx(),
        .sely(),
        .selz(),
        .user_buffer_data(force_buffer_data),
        .coeff ( forcex )
    );

    coeff64 ForceY_func(
        .clk(clk),
        .rst(rst),
        .wen_in(CMAPwen_in),
        .forceValid_in(Forcewen_in), // after cycle delay like wen_in
        .CA_BI(2'b10),
        .wen_out(),
        .forceValid_out(), //
        .selx(),
        .sely(),
        .selz(),
        .user_buffer_data(force_buffer_data),
        .coeff ( forcey )
    );

    coeff64 ForceZ_func(
        .clk(clk),
        .rst(rst),
        .wen_in(CMAPwen_in),
        .forceValid_in(Forcewen_in), // after cycle delay like wen_in
        .CA_BI(2'b11),
        .wen_out(),
        .forceValid_out(), //
        .selx(),
        .sely(),
        .selz(),
        .user_buffer_data(force_buffer_data),
        .coeff ( forcez )
    );

    blockMem database (
        .clk(clk),
        .rst(rst),

        .wren(DATABASE_wren), 
        .dataIn(DATABASE_dataIn), 
        .dataOut(DATABASE_dataOut), 
        .readAddress(DATABASE_readAddress), 
        .writeAddress(DATABASE_writeAddress)
    );

    
    memoryCtrl databaseCtrl(
        .clk(clk),
        .rst(rst),

        .DATABASE_wren(DATABASE_wren),
        .DATABASE_dataIn(DATABASE_dataIn), 
        .DATABASE_dataOut(DATABASE_dataOut), 
        .DATABASE_readAddress(DATABASE_readAddress),
        .DATABASE_writeAddress(DATABASE_writeAddress),

        .CMwen(CMAPwen_out),
        .FFTwen(FFTwen_writeback),
        
        .selx(selx),
        .sely(sely),
        .selz(selz),
        .mem_sel_4(mem_sel_4),
        
        .FFT_iteration(FFT_iteration),
        .FFT_dim(FFT_dim),
        
        .coeff_in( coeff ),
        .Force_out( Force_out ),
        .FFTData_in( FFTData_in ),
        .FFTData_out( FFTData_out )

    );
    
    Reduction_Tree ForceXtree(
        .clk(clk), 
        .rst(rst), 
        .out_port(forcedb_user_buffer_input_data[31:0]), 
        .in_port1(forcex),
        .in_port2(Force_out)
    );
    
    Reduction_Tree ForceYtree(
        .clk(clk), 
        .rst(rst), 
        .out_port(forcedb_user_buffer_input_data[63:32]), 
        .in_port1(forcey),
        .in_port2(Force_out)
    );
    
    Reduction_Tree ForceZtree(
        .clk(clk), 
        .rst(rst), 
        .out_port(forcedb_user_buffer_input_data[95:64]), 
        .in_port1(forcez),
        .in_port2(Force_out)
    );
    
    assign forcedb_user_buffer_input_data[127:96] = 0;
    
    assign FFTwen_writeback  = {NUM_FFTS{source_valid[0]}};
    
    genvar fft_index;
    generate
        for (fft_index = 0; fft_index < 04; fft_index = fft_index + 1)
        begin: create_fft
            fftIP FFT_modules(
                .clk          (clk),
                .reset_n      (~rst),
                .sink_valid   (FFTsinkValid),
                .sink_ready   (),
                .sink_error   (2'd0),
                .sink_sop     (FFTsop),
                .sink_eop     (FFTeop),
                .sink_real    (FFTData_out[fft_index].FFT_real),
                .sink_imag    (FFTData_out[fft_index].FFT_imag),
                .fftpts_in    (6'd32),
                .inverse      (FFTdirection),
                .source_valid (source_valid[fft_index]),
                .source_ready (FFTsourceValid),
                .source_error (),
                .source_sop   (),
                .source_eop   (),
                .source_real  (FFTData_in[fft_index].FFT_real),
                .source_imag  (FFTData_in[fft_index].FFT_imag),
                .fftpts_out   ()
            );
        end
    endgenerate
    
endmodule
