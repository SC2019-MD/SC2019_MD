//-----------------------------------------------------
// Design Name : syn_fifo
// File Name   : syn_fifo.v
// Function    : Synchronous (single clock) FIFO
// Coder       : Deepak Kumar Tala
//-----------------------------------------------------
module syn_fifo (
clk      , // Clock input
rst      , // Active high reset
//wr_cs    , // Write chip select
//rd_cs    , // Read chipe select
data_in  , // Data input
//rd_en    , // Read enable
//wr_en    , // Write Enable
data_out  // Data Output
//empty    , // FIFO empty
//full       // FIFO full
);    
 
// FIFO constants
parameter DATA_WIDTH = 32;
parameter RAM_DEPTH = 14;

// Port Declarations
input clk;
input rst;

input [DATA_WIDTH-1:0] data_in;

output [DATA_WIDTH-1:0] data_out;

//-----------Internal variables-------------------

//wire [DATA_WIDTH-1:0] data_out;


//-----------Variable assignments---------------
reg [DATA_WIDTH-1:0] ram [0:RAM_DEPTH-1];

//-----------Code Start---------------------------


integer i, j;
always @ (posedge clk or posedge rst) begin
	if (rst) begin
     for(i = 0; i < RAM_DEPTH; i= i+1) begin
		ram[i] <= 0;
	 end 
	 end else begin 
		ram[0] <= data_in;
		for(j = 0; j < RAM_DEPTH -1; j = j + 1) begin
			ram[j + 1] <= ram[j];
		end
	 end 
end

assign data_out = ram[RAM_DEPTH -1];


   

endmodule
