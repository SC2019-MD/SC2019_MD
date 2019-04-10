/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: Filter_Buffer_tb.v
//
//	Function:
//				Testbench for Filter_Buffer.v
//				Checking when will the data show on the output port (if the rdreq is not assigned, will the data already be in there?)
// 
// Dependency:
// 			Filter_Buffer.v
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ns

module Filter_Buffer_tb;

	parameter DATA_WIDTH = 32;
	parameter FILTER_BUFFER_DEPTH = 32;
	parameter FILTER_BUFFER_ADDR_WIDTH = 5;					// log(FILTER_BUFFER_DEPTH) / log 2
	
	reg clk;
	reg [DATA_WIDTH-1:0] data_in;
	reg rdreq, wrreq;
	wire empty, full;
	wire [DATA_WIDTH-1:0] data_out;
	wire [FILTER_BUFFER_ADDR_WIDTH-1:0] usedw;
	
	reg [4:0] counter;
	reg rst;
	
	always #1 clk <= ~clk;
	
	always@(posedge clk)
		begin
		if(rst)
			begin
			counter <= 0;
			data_in <= 32'hDEADBEEF;
			rdreq <= 1'b0;
			wrreq <= 1'b0;
			end
		else
			begin
			counter <= counter + 1'b1;
			data_in <= data_in + 1'b1;
			if(counter <= 5)
				begin
				rdreq <= 1'b0;
				wrreq <= 1'b1;
				end
			else if (counter <= 10)
				begin
				rdreq <= 1'b1;
				wrreq <= 1'b1;
				end
			// read out one data from buffer when counter is even numver
			else if (counter[0] == 0)
				begin
				rdreq <= 1'b1;
				wrreq <= 1'b0;
				end
			else
				begin
				rdreq <= 1'b0;
				wrreq <= 1'b0;
				end
			end
		end
	
	initial begin
		clk <= 1'b1;
		rst <= 1'b1;
		
		#10
		rst <= 1'b0;
		
	end
	

	Filter_Buffer
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.FILTER_BUFFER_DEPTH(FILTER_BUFFER_DEPTH),
		.FILTER_BUFFER_ADDR_WIDTH(FILTER_BUFFER_ADDR_WIDTH)
	)
	Filter_Buffer
	(
		 .clock(clk),
		 .data(data_in),
		 .rdreq(rdreq),
		 .wrreq(wrreq),
		 .empty(empty),
		 .full(full),
		 .q(data_out),
		 .usedw(usedw)
	);


endmodule