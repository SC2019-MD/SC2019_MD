/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: RL_Pipeline_Direct_Comp.v
//
//	Function: Evaluate the piarwise non-bonded force between particle pairs using direct computation
// 			1 tile of force pipeline, without filter
//
// Dependency:
// 			RL_Evaluate_Pairs_Direct.v
//				r2_compute.v
//
// Created by:
//				Chen Yang 09/06/18
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module RL_Pipeline_Direct_Comp
#(
	parameter DATA_WIDTH 				= 32,
	parameter INTERPOLATION_ORDER		= 1,
	parameter SEGMENT_NUM				= 12,
	parameter SEGMENT_WIDTH				= 4,
	parameter BIN_WIDTH					= 8,
	parameter BIN_NUM						= 256,
	parameter LOOKUP_NUM					= SEGMENT_NUM * BIN_NUM,			// SEGMENT_NUM * BIN_NUM
	parameter LOOKUP_ADDR_WIDTH		= SEGMENT_WIDTH + BIN_WIDTH		// log LOOKUP_NUM / log 2
)
(
	input  clk,
	input  rst,
	input  start,
	output [DATA_WIDTH-1:0] forceoutput,
	output forceoutput_valid,
	output reg done
);
	
	// rst & start signal is given by in-memory content editor
//	wire rst;
//	wire start;
	
	wire [DATA_WIDTH-1:0] p_a;
	wire [DATA_WIDTH-1:0] p_b;
	wire [DATA_WIDTH-1:0] p_qq;
	wire [DATA_WIDTH-1:0] p_G0;
	wire [DATA_WIDTH-1:0] p_G1;
	wire [DATA_WIDTH-1:0] p_G2;
	
	assign p_a  = 32'h40000000;				// p_a = 2, in IEEE floating point format
	assign p_b  = 32'h40800000;				// p_b = 4, in IEEE floating point format
	assign p_qq = 32'h41000000;				// p_qq = 8, in IEEE floating point format
	
	assign p_G0 = 32'h40000000;				// p_a = 2, in IEEE floating point format
	assign p_G1 = 32'h40800000;				// p_b = 4, in IEEE floating point format
	assign p_G2 = 32'h41000000;				// p_qq = 8, in IEEE floating point format
	
	wire [DATA_WIDTH-1:0] refx;
	wire [DATA_WIDTH-1:0] posx;
	wire [DATA_WIDTH-1:0] refy;
	wire [DATA_WIDTH-1:0] posy;
	wire [DATA_WIDTH-1:0] refz;
	wire [DATA_WIDTH-1:0] posz;

	reg rden;
	reg wren;

	reg [8:0] wraddr;
	reg [8:0] neighbor_rdaddr;
	reg [8:0] home_rdaddr;

	reg r2_enable;									// control signal that enables R2 calculation, this signal should have 1 cycle delay of the rden signal, thus wait for the data read out from BRAM
	wire [DATA_WIDTH-1:0] r2;
	wire r2_valid;
	
	parameter WAIT_FOR_START = 2'b00;
	parameter START 			 = 2'b01;
	parameter EVALUATION 	 = 2'b10;
	parameter DONE 			 = 2'b11;
	reg [1:0] state;
	
	always@(posedge clk)
		if(rst)
			begin
			neighbor_rdaddr <= 9'd0;
			home_rdaddr <= 9'd0;
			wraddr <= 9'd0;
			wren <= 1'b0;
			rden <= 1'b0;
			r2_enable <= 1'b0;
			
			state <= WAIT_FOR_START;
			end
		else if(start)
			begin
			r2_enable <= rden;				// Assign the r2_enable signal, one cycle delay from the rden signal
			
			wren <= 1'b0;						// temporarily disable write back to position ram
			wraddr <= 9'd0;
			case(state)
				WAIT_FOR_START:				// Wait for the input start signal from outside
					begin
					neighbor_rdaddr <= 9'd0;
					home_rdaddr <= 9'd0;
					rden <= 1'b0;
					done <= 1'b0;
					if(start)
						state <= START;
					else
						state <= WAIT_FOR_START;
					end
					
				START:							// Evaluate the first pair (start from addr = 0)
					begin
					neighbor_rdaddr <= 9'd0;
					home_rdaddr <= 9'd0;
					
					done <= 1'b0;
					rden <= 1'b1;
					state <= EVALUATION;
					end
					
				EVALUATION:						// Evaluating all the particle pairs
					begin
					done <= 1'b0;
					
					neighbor_rdaddr <= neighbor_rdaddr + 1'b1;
					rden <= 1'b1;
					if(neighbor_rdaddr == 9'b111111111)
						home_rdaddr <= home_rdaddr + 1'b1;

					if(home_rdaddr < 9'b111111111)
						state <= EVALUATION;
					else
						state <= DONE;
					end
					
				DONE:								// Output a done signal
					begin
					done <= 1'b1;
					neighbor_rdaddr <= 9'd0;
					home_rdaddr <= 9'd0;
					rden <= 1'b0;
					
					state <= WAIT_FOR_START;
					end
			endcase
			end
			
//	CTRL_RAM Rst_RAM(
//		.data(),    //  ram_input.datain
//		.address(1'b0), //           .address
//		.wren(1'b0),    //           .wren
//		.clock(clk),   //           .clk
//		.q(rst)        // ram_output.dataout
//		);

		
//	Start_Ctrl_RAM Start_Ctrl_RAM(
//		.data(),    //  ram_input.datain
//		.address(1'b0), //           .address
//		.wren(1'b0),    //           .wren
//		.clock(clk),   //           .clk
//		.q(start)        // ram_output.dataout
//	);

	r2_compute #(DATA_WIDTH) r2_evaluate(
		.clk(clk),
		.rst(rst),
		.enable(r2_enable),
		.refx(refx),
		.refy(refy),
		.refz(refz),
		.posx(posx),
		.posy(posy),
		.posz(posz),
		.r2(r2),
		.r2_valid(r2_valid)
		);

	RL_Evaluate_Pairs_Direct #(
		.DATA_WIDTH(DATA_WIDTH)
	)
	RL_Evaluate_Pairs(
		.clk(clk),
		.rst(rst),
		.r2_valid(r2_valid),
		.r2(r2),
		.p_a(p_a),
		.p_b(p_b),
		.p_qq(p_qq),
		.p_G0(p_G0),
		.p_G1(p_G1),
		.p_G2(p_G2),
		.RL_force(forceoutput),
		.RL_force_valid(forceoutput_valid)
		);

	refx refx_bram (
		.data(),
		.wraddress(wraddr),
		.rdaddress(home_rdaddr),
		.wren(wren),
		.clock(clk),
		.rden(rden),
		.q(refx)
		);

	refy refy_bram (
		.data(),
		.wraddress(wraddr),
		.rdaddress(home_rdaddr),
		.wren(wren),
		.clock(clk),
		.rden(rden),
		.q(refy)
		);

	refz refz_bram (
		.data(),
		.wraddress(wraddr),
		.rdaddress(home_rdaddr),
		.wren(wren),
		.clock(clk),
		.rden(rden),
		.q(refz)
		);


	posx posx_bram (
		.data(),
		.wraddress(wraddr),
		.rdaddress(neighbor_rdaddr),
		.wren(wren),
		.clock(clk),
		.rden(rden),
		.q(posx)
		);

	posy posy_bram (
		.data(),
		.wraddress(wraddr),
		.rdaddress(neighbor_rdaddr),
		.wren(wren),
		.clock(clk),
		.rden(rden),
		.q(posy)
		);

	posz posz_bram (
		.data(),
		.wraddress(wraddr),
		.rdaddress(neighbor_rdaddr),
		.wren(wren),
		.clock(clk),
		.rden(rden),
		.q(posz)
		);

endmodule


