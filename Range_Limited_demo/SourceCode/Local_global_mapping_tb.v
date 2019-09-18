`timescale 1ns/1ns

module Local_global_mapping_tb;

	parameter NUM_NEIGHBOR_CELLS		= 13;
	parameter NUM_PIPELINES				= 16;
	parameter CELL_ADDR_WIDTH			= 4;
	parameter CELL_ID_WIDTH				= 3;
	parameter NUM_FILTER					= 8;
	parameter TOTAL_CELL_NUM			= 64;
	parameter RDADDR_ARBITER_SIZE		= 5;
	parameter RDADDR_ARBITER_MSB		= 16;
	parameter PARTICLE_ID_WIDTH		= CELL_ID_WIDTH*3+CELL_ADDR_WIDTH;
	parameter DATA_WIDTH					= 32;
	
	
	reg clk, rst;
	reg [CELL_ID_WIDTH-1:0] cellz;
	
	reg [NUM_PIPELINES*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] Local_FSM_to_Cell_read_addr;
	reg [NUM_PIPELINES*(NUM_NEIGHBOR_CELLS+1)-1:0] Local_enable_reading;
	reg [TOTAL_CELL_NUM*3*DATA_WIDTH-1:0] Position_Cache_readout_position;
	
	wire [TOTAL_CELL_NUM-1:0] enable_reading;
	wire [TOTAL_CELL_NUM*CELL_ADDR_WIDTH-1:0] FSM_to_Cell_read_addr;
	wire [NUM_PIPELINES*(NUM_NEIGHBOR_CELLS+1)-1:0] Cell_to_FSM_read_success_bit;
	wire [NUM_PIPELINES*(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline;
	
	wire [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] read_addr_1_1;
	wire [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] read_addr_1_2;
	wire [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] read_addr_1_3;
	wire [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] read_addr_1_4;
	wire [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] read_addr_2_1;
	wire [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] read_addr_2_2;
	wire [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] read_addr_2_3;
	wire [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] read_addr_2_4;
	wire [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] read_addr_3_1;
	wire [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] read_addr_3_2;
	wire [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] read_addr_3_3;
	wire [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] read_addr_3_4;
	wire [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] read_addr_4_1;
	wire [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] read_addr_4_2;
	wire [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] read_addr_4_3;
	wire [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] read_addr_4_4;
	
	assign read_addr_1_1 = Local_FSM_to_Cell_read_addr[1*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0];
	assign read_addr_1_2 = Local_FSM_to_Cell_read_addr[2*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:1*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH];
	assign read_addr_1_3 = Local_FSM_to_Cell_read_addr[3*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:2*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH];
	assign read_addr_1_4 = Local_FSM_to_Cell_read_addr[4*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:3*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH];
	assign read_addr_2_1 = Local_FSM_to_Cell_read_addr[5*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:4*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH];
	assign read_addr_2_2 = Local_FSM_to_Cell_read_addr[6*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:5*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH];
	assign read_addr_2_3 = Local_FSM_to_Cell_read_addr[7*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:6*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH];
	assign read_addr_2_4 = Local_FSM_to_Cell_read_addr[8*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:7*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH];
	assign read_addr_3_1 = Local_FSM_to_Cell_read_addr[9*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:8*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH];
	assign read_addr_3_2 = Local_FSM_to_Cell_read_addr[10*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:9*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH];
	assign read_addr_3_3 = Local_FSM_to_Cell_read_addr[11*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:10*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH];
	assign read_addr_3_4 = Local_FSM_to_Cell_read_addr[12*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:11*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH];
	assign read_addr_4_1 = Local_FSM_to_Cell_read_addr[13*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:12*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH];
	assign read_addr_4_2 = Local_FSM_to_Cell_read_addr[14*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:13*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH];
	assign read_addr_4_3 = Local_FSM_to_Cell_read_addr[15*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:14*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH];
	assign read_addr_4_4 = Local_FSM_to_Cell_read_addr[16*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:15*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH];
	
	always #1 clk <= ~clk;
	
	initial
		begin
		clk <= 1'b1;
		rst <= 1'b1;
		Local_FSM_to_Cell_read_addr <= 0;
		Local_enable_reading <= 0;
		Position_Cache_readout_position <= 0;
		cellz <= 1;
		
		// Check enable = 0 for all cellz's
		#10
		rst <= 1'b0;
		// Each pipeline requests a fixed address, in order to separate pipelines. 
		Local_FSM_to_Cell_read_addr <= { {(NUM_NEIGHBOR_CELLS+1){4'hF}}, 
													{(NUM_NEIGHBOR_CELLS+1){4'hE}},
													{(NUM_NEIGHBOR_CELLS+1){4'hD}},
													{(NUM_NEIGHBOR_CELLS+1){4'hC}},
													{(NUM_NEIGHBOR_CELLS+1){4'hB}},
													{(NUM_NEIGHBOR_CELLS+1){4'hA}},
													{(NUM_NEIGHBOR_CELLS+1){4'h9}},
													{(NUM_NEIGHBOR_CELLS+1){4'h8}},
													{(NUM_NEIGHBOR_CELLS+1){4'h7}},
													{(NUM_NEIGHBOR_CELLS+1){4'h6}},
													{(NUM_NEIGHBOR_CELLS+1){4'h5}},
													{(NUM_NEIGHBOR_CELLS+1){4'h4}},
													{(NUM_NEIGHBOR_CELLS+1){4'h3}},
													{(NUM_NEIGHBOR_CELLS+1){4'h2}},
													{(NUM_NEIGHBOR_CELLS+1){4'h1}},
													{(NUM_NEIGHBOR_CELLS+1){4'h0}}};
		cellz <= 1;
		Local_enable_reading <= 0;
		Position_Cache_readout_position <= 0;
		
		#10
		cellz <= 2;
		
		#10
		cellz <= 3;
		
		#10
		cellz <= 4;
		
		// Check all enable
		#10
		cellz <= 1;
		Local_enable_reading <= {(NUM_PIPELINES*(NUM_NEIGHBOR_CELLS+1)){1'b1}};
		
		#20
		cellz <= 2;
		
		#20
		cellz <= 3;
		
		#20
		cellz <= 4;
		
		#10
		$stop;
		end
	
	
	Local_global_mapping
	#(
		.NUM_NEIGHBOR_CELLS(NUM_NEIGHBOR_CELLS),
		.NUM_PIPELINES(NUM_PIPELINES),
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.NUM_FILTER(NUM_FILTER),
		.TOTAL_CELL_NUM(TOTAL_CELL_NUM),
		.RDADDR_ARBITER_SIZE(RDADDR_ARBITER_SIZE),
		.RDADDR_ARBITER_MSB(RDADDR_ARBITER_MSB),
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	)
	Local_global_mapping
	(
		.clk(clk),
		.rst(rst),
		.cellz(cellz),
		.Local_FSM_to_Cell_read_addr(Local_FSM_to_Cell_read_addr),
		.Local_enable_reading(Local_enable_reading),
		.Position_Cache_readout_position(Position_Cache_readout_position),
		
		.enable_reading(enable_reading),
		.FSM_to_Cell_read_addr(FSM_to_Cell_read_addr),
		.Cell_to_FSM_read_success_bit(Cell_to_FSM_read_success_bit),
		.cells_to_pipeline(cells_to_pipeline)
	);
	
endmodule