/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: force_cache_tb.v
//
//	Function: 
//				Testing the timing of the dual port ram
//
// Timing:
//				Read latency: (1 cycle)
//					If the output is registered, then Read latency is 3 cycles: 1 cycle for registering the input read address, 1 cycle to read out, 1 cycle to update the output register (the input read address is registered, which is required when implemented in M20K)
//					If the output is not registered, the read latency is 1 cycle after the address is assigned
//				Write latency: (2 cycle)
//					Since the input is registered, the latency is 2 cycles for write: 1 cycle for registering the input data, 1 cycle for updating the memeory content
//	
// Data Organization:
//				MSB -> LSB: {Force_Z, Force_Y, Force_X}
//
// Used by:
//				N/A
//
// Dependency:
//				force_cache.v
//
// Created by:
//				Chen Yang 11/26/2018
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ns

module force_cache_tb;
	
	parameter DATA_WIDTH = 32;
	parameter PARTICLE_NUM = 290;
	parameter ADDR_WIDTH = 9;
	
	reg clk, rst;
	reg [DATA_WIDTH-1:0] cache_write_data;
	reg [ADDR_WIDTH-1:0] cache_rd_address, cache_wr_address;
	reg cache_write_enable;
	wire [DATA_WIDTH-1:0] cache_readout_data;
	
	reg [3:0] tmp_counter;
	
	always #1 clk <= ~clk;
	
	always@(clk)
		begin
		if(rst)
			begin
			tmp_counter <= {4{1'b0}};
			cache_write_data <= {DATA_WIDTH{1'b0}};
			cache_rd_address <= {ADDR_WIDTH{1'b0}};
			cache_wr_address <= {ADDR_WIDTH{1'b0}};
			cache_write_enable <= 1'b0;
			end
		else
			begin
			tmp_counter <= tmp_counter + 1'b1;
			// Keep writing from address 0 to 10
			if(tmp_counter < 11)
				begin
				cache_write_enable <= 1'b1;
				cache_write_data <= cache_write_data + 1'b1;
				cache_wr_address <= {5'd0, tmp_counter};
				cache_rd_address <= 5;
				end
			// Measure the read latency
			else
				begin
				cache_write_enable <= 1'b0;
				cache_write_data <= cache_write_data;
				cache_wr_address <= {5'd0, tmp_counter};
				cache_rd_address <= 7;
				end
			end		
		end
	
	initial begin
		clk <= 1'b1;
		rst <= 1'b1;
		
		#10
		rst <= 1'b0;
	
		/*
		cache_write_data <= {DATA_WIDTH{1'b0}};
		cache_rd_address <= {ADDR_WIDTH{1'b0}};
		cache_wr_address <= {ADDR_WIDTH{1'b0}};
		cache_write_enable <= 1'b0;
		*/
	end
	
	// UUT
	force_cache
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_NUM(PARTICLE_NUM),
		.ADDR_WIDTH(ADDR_WIDTH)
	)
	force_cache
	(
		.clock(clk),
		.data(cache_write_data),
		.rdaddress(cache_rd_address),
		.wraddress(cache_wr_address),
		.wren(cache_write_enable),
		.q(cache_readout_data)
	);

endmodule