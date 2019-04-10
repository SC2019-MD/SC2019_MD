/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: force_cache.v
//
//	Function: 
//				Force cache need to be dual port RAM, one port for reading out particle force, the other used for write back accumulated force
//				Serve as the actual buffer that holds evaluated force values during evaluation
//				The initial force value is 0
//				When new force value arrives, it will accumulate to the current stored value
//				Read while writing: output is the old value
//				Implementation: M20K
//
// Data Organization:
//				MSB -> LSB: {Force_Z, Force_Y, Force_X}
//
// Timing:
//				Read latency: (1 cycle)
//					If the output is registered, then Read latency is 3 cycles: 1 cycle for registering the input read address, 1 cycle to read out, 1 cycle to update the output register (the input read address is registered, which is required when implemented in M20K)
//					If the output is not registered, the read latency is 1 cycle after the address is assigned
//				Write latency: (2 cycle)
//					Since the input is registered, the latency is 2 cycles for write: 1 cycle for registering the input data, 1 cycle for updating the memeory content
//				
// Used by:
//				Force_Write_Back_Controller.v
//
// Dependency:
//				N/A
//
// Testbench:
//				force_cache_tb.v
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

`include "define.v"

// synopsys translate_off
`timescale 1 ns / 1 ns
// synopsys translate_on
module  force_cache
#(
	parameter DATA_WIDTH = 32*3,//32*3,
	parameter PARTICLE_NUM = 290,
	parameter ADDR_WIDTH = 9
)
(
    clock,
    data,															// Write data into Port A
    rdaddress,														// Read address for Port B
    wraddress,														// Write address for Port A
    wren,															// Write enable for Port A
    q																	// Data readout from Port B, when data is writing from Port A while being read from Port B at the same time, it will readout the old data
);

	 input  clock;
    input  [DATA_WIDTH-1:0]  data;
    input  [ADDR_WIDTH-1:0]  rdaddress;
    input  [ADDR_WIDTH-1:0]  wraddress;
    input  wren;
    output [DATA_WIDTH-1:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
    tri1     clock;
    tri0     wren;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

    wire [DATA_WIDTH-1:0] sub_wire0;
    wire [DATA_WIDTH-1:0] q = sub_wire0[DATA_WIDTH-1:0];

    altera_syncram  altera_syncram_component (
                .address_a (wraddress),
                .address_b (rdaddress),
                .clock0 (clock),
                .data_a (data),
                .wren_a (wren),
                .q_b (sub_wire0),
                .aclr0 (1'b0),
                .aclr1 (1'b0),
                .address2_a (1'b1),
                .address2_b (1'b1),
                .addressstall_a (1'b0),
                .addressstall_b (1'b0),
                .byteena_a (1'b1),
                .byteena_b (1'b1),
                .clock1 (1'b1),
                .clocken0 (1'b1),
                .clocken1 (1'b1),
                .clocken2 (1'b1),
                .clocken3 (1'b1),
                .data_b ({(DATA_WIDTH-1){1'b1}}),
                .eccencbypass (1'b0),
                .eccencparity (8'b0),
                .eccstatus (),
                .q_a (),
                .rden_a (1'b1),
                .rden_b (1'b1),
                .sclr (1'b0),
                .wren_b (1'b0));
    defparam
        altera_syncram_component.address_aclr_b  = "NONE",
        altera_syncram_component.address_reg_b  = "CLOCK0",
        altera_syncram_component.clock_enable_input_a  = "BYPASS",
        altera_syncram_component.clock_enable_input_b  = "BYPASS",
        altera_syncram_component.clock_enable_output_b  = "BYPASS",
        altera_syncram_component.intended_device_family  = "Stratix 10",
        altera_syncram_component.lpm_type  = "altera_syncram",
        altera_syncram_component.numwords_a  = PARTICLE_NUM,
        altera_syncram_component.numwords_b  = PARTICLE_NUM,
        altera_syncram_component.operation_mode  = "DUAL_PORT",
        altera_syncram_component.outdata_aclr_b  = "NONE",
        altera_syncram_component.outdata_sclr_b  = "NONE",
//        altera_syncram_component.outdata_reg_b  = "CLOCK0",					// Register the port B output, if this one is selected, the latency for read is 3 cycles
		  altera_syncram_component.outdata_reg_b  = "UNREGISTERED",				// Unregister the port B output, if this one is selected, the latency for read is 1 cycle
        altera_syncram_component.power_up_uninitialized  = "FALSE",
		  altera_syncram_component.ram_block_type  = "M20K",
        altera_syncram_component.read_during_write_mode_mixed_ports  = "OLD_DATA",
        altera_syncram_component.widthad_a  = ADDR_WIDTH,
        altera_syncram_component.widthad_b  = ADDR_WIDTH,
        altera_syncram_component.width_a  = DATA_WIDTH,
        altera_syncram_component.width_b  = DATA_WIDTH,
        altera_syncram_component.width_byteena_a  = 1;

endmodule
