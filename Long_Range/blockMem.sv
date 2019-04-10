`timescale 1ns/1ns
//Testing memory system with 32x32 or 1024 brams

module blockMem(clk, rst, wren, dataIn, dataOut, readAddress, writeAddress);

parameter DATA_REAL_WIDTH = 32;
parameter DATA_IMAG_WIDTH = 32;
parameter GRID_ADDRESS_WIDTH = 4;
parameter DIMENSION = 16;

input logic clk, rst;
input logic wren [0 : DIMENSION-1][0 : DIMENSION-1];

input logic  [DATA_REAL_WIDTH + DATA_IMAG_WIDTH - 1 : 0] dataIn  [0 : DIMENSION-1][0 : DIMENSION-1];
output logic [DATA_REAL_WIDTH + DATA_IMAG_WIDTH - 1 : 0] dataOut [0 : DIMENSION-1][0 : DIMENSION-1];

input logic  [GRID_ADDRESS_WIDTH-1 : 0] readAddress [0 : DIMENSION-1][0 : DIMENSION-1];
output logic [GRID_ADDRESS_WIDTH-1 : 0] writeAddress [0 : DIMENSION-1][0 : DIMENSION-1];


// Grid is made of 1024 memory blocks each 32 wide.
// Addresses are incremented in X direction
// Memory blocks are assigned y,z

gridMem Grid [DIMENSION*DIMENSION -1 : 0](
    .clock(clk),
    .data(dataIn),
    .rdaddress(readAddress),
    .wraddress(writeAddress),
    .wren(wren),
    .q(dataOut)
);

endmodule