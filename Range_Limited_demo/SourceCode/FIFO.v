/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: FIFO.v
//
//	Function:
//				You know, a FIFO......
//
// Timing:
//				When the first write data is issued: after one cycle, empty falling down
//				When the last data is read out, empty rise one cycle after the rdreq's arrival, along with the last data
//				Data_out port remain as the last readout data if empty or rdreq is low
//				When the rdreq is assigned, the next cycle data is readout. If the rdreq drop, the output will hold the previous readout value.
//				When the FIFO is empty, the output remains as the last valid readout data.
//				Buffer_Full is only set after one cycle of overflow occurs......
// 
// Used by:
// 			A lot of stuff.......
//
// Testbench:
//				Check the testbench for Filter_buffer....
//
// Created by:
//				Chen Yang 12/10/18
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// (C) 2001-2018 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module  FIFO
#(
	parameter DATA_WIDTH = 32,
	parameter FIFO_DEPTH = 32,
	parameter FIFO_ADDR_WIDTH = 5,				// log(FILTER_BUFFER_DEPTH) / log 2
	parameter ALMOST_FULL_THRESHOLD = 3			// If there's less than this value available in the FIFO, set the almost_full flag
)
(
    clock,
    data,
    rdreq,
    wrreq,
	 almost_full,
    empty,
    full,
    q,
    usedw
);

    input    clock;
    input  [DATA_WIDTH-1:0]  data;
    input    rdreq;
    input    wrreq;
	 output   almost_full;
    output   empty;
    output   full;
    output [DATA_WIDTH-1:0]  q;
    output [FIFO_ADDR_WIDTH-1:0]  usedw;

    wire  sub_wire0;
    wire  sub_wire1;
	 wire  sub_wire4;
    wire [DATA_WIDTH-1:0] sub_wire2;
    wire [FIFO_ADDR_WIDTH-1:0] sub_wire3;
    wire  empty = sub_wire0;
    wire  full = sub_wire1;
	 wire  almost_full = sub_wire4;
    wire [DATA_WIDTH-1:0] q = sub_wire2[DATA_WIDTH-1:0];
    wire [FIFO_ADDR_WIDTH-1:0] usedw = sub_wire3[FIFO_ADDR_WIDTH-1:0];

    scfifo  scfifo_component (
                .clock (clock),
                .data (data),
                .rdreq (rdreq),
                .wrreq (wrreq),
                .empty (sub_wire0),
                .full (sub_wire1),
                .q (sub_wire2),
                .usedw (sub_wire3),
                .aclr (),
                .almost_empty (),
                .almost_full (sub_wire4),
                .eccstatus (),
                .sclr ());
    defparam
        scfifo_component.add_ram_output_register  = "OFF",
		  scfifo_component.almost_full_value  = FIFO_DEPTH - ALMOST_FULL_THRESHOLD,
        scfifo_component.enable_ecc  = "FALSE",
        scfifo_component.intended_device_family  = "Stratix 10",
        scfifo_component.lpm_numwords  = FIFO_DEPTH,
        scfifo_component.lpm_showahead  = "OFF",
        scfifo_component.lpm_type  = "scfifo",
        scfifo_component.lpm_width  = DATA_WIDTH,
        scfifo_component.lpm_widthu  = FIFO_ADDR_WIDTH,
        scfifo_component.overflow_checking  = "ON",
        scfifo_component.underflow_checking  = "ON",
        scfifo_component.use_eab  = "ON";


endmodule