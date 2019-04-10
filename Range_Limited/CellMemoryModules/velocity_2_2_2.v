/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: velocity_2_2_2.v
//
//	Function:
//				Memory modules holding the initial velocity information of each cells
//
//	Purpose:
//				Providing particle position data for force evaluation and motion update
//
// Data Organization:
//				Address 0 for each cell module: # of particles in the cell.
//				MSB-LSB: {vz, vy, vx}
//
// Used by:
//				Velocity_Cache_2_2_2.v
//
// Dependency:
//				velocity_ini_file_2_2_2.hex / velocity_ini_file_2_2_2.mif
//
// Testbench:
//				RL_LJ_Top_tb.v
//
// Timing:
//				1 cycle reading delay from input address and output data.
//
// Created by:
//				Chen Yang's Script (Gen_Velocity_Cell.cpp), based on Single Port RAM IP core
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`include "../define.v"

`timescale 1 ps / 1 ps

module velocity_2_2_2
#(
	parameter DATA_WIDTH = 32*3,
	parameter PARTICLE_NUM = 220,
	parameter ADDR_WIDTH = 8
)
(
	address,
	clock,
	data,
	rden,
	wren,
	q
);

	input  [ADDR_WIDTH-1:0]  address;
	input    clock;
	input  [DATA_WIDTH-1:0]  data;
	input    rden;
	input    wren;
	output [DATA_WIDTH-1:0]  q;

	tri1     clock;
	tri1     rden;

	wire [DATA_WIDTH-1:0] sub_wire0;
	wire [DATA_WIDTH-1:0] q = sub_wire0[DATA_WIDTH-1:0];

	altera_syncram  altera_syncram_component (
		.address_a (address),
		.clock0 (clock),
		.data_a (data),
		.rden_a (rden),
		.wren_a (wren),
		.q_a (sub_wire0),
		.aclr0 (1'b0),
		.aclr1 (1'b0),
		.address2_a (1'b1),
		.address2_b (1'b1),
		.address_b (1'b1),
		.addressstall_a (1'b0),
		.addressstall_b (1'b0),
		.byteena_a (1'b1),
		.byteena_b (1'b1),
		.clock1 (1'b1),
		.clocken0 (1'b1),
		.clocken1 (1'b1),
		.clocken2 (1'b1),
		.clocken3 (1'b1),
		.data_b (1'b1),
		.eccencbypass (1'b0),
		.eccencparity (8'b0),
		.eccstatus ( ),
		.q_b ( ),
		.rden_b (1'b1),
		.sclr (1'b0),
		.wren_b (1'b0));
	defparam
		altera_syncram_component.width_byteena_a  = 1,
		altera_syncram_component.clock_enable_input_a  = "BYPASS",
		altera_syncram_component.clock_enable_output_a  = "BYPASS",
/*
`ifdef WINDOWS_PATH
		altera_syncram_component.init_file = "F:/Dropbox/CAAD_Server/MD_RL_Pipeline/Ethan_RL_Pipeline_1st_Order_SingleFloat_18.0/SourceCode/cell_ini_file_2_2_2.hex"
`elsif STX_PATH
		altera_syncram_component.init_file = "/home/vsachde/Dropbox/CAAD_Server/MD_RL_Pipeline/Ethan_RL_Pipeline_1st_Order_SingleFloat_18.0/SourceCode/cell_ini_file_2_2_2.hex"
`elsif STX_2ND_PATH
		altera_syncram_component.init_file = "/home/vsachde/Dropbox/CAAD_Server/MD_RL_Pipeline/MD_HDL_STX/SourceCode/cell_ini_file_2_2_2.hex"
`else
		altera_syncram_component.init_file = "F:/Dropbox/CAAD_Server/MD_RL_Pipeline/Ethan_RL_Pipeline_1st_Order_SingleFloat_18.0/SourceCode/cell_ini_file_2_2_2.hex"
`endif
,
*/
		altera_syncram_component.intended_device_family  = "Stratix 10",
		altera_syncram_component.lpm_hint  = "ENABLE_RUNTIME_MOD=NO",
		altera_syncram_component.lpm_type  = "altera_syncram",
		altera_syncram_component.numwords_a  = PARTICLE_NUM,
		altera_syncram_component.operation_mode  = "SINGLE_PORT",
		altera_syncram_component.outdata_aclr_a  = "NONE",
		altera_syncram_component.outdata_sclr_a  = "NONE",
		altera_syncram_component.outdata_reg_a  = "CLOCK0",
		altera_syncram_component.enable_force_to_zero  = "TRUE",
		altera_syncram_component.power_up_uninitialized  = "FALSE",
		altera_syncram_component.ram_block_type  = "M20K",
		altera_syncram_component.read_during_write_mode_port_a  = "DONT_CARE",
		altera_syncram_component.widthad_a  = ADDR_WIDTH,
		altera_syncram_component.width_a  = DATA_WIDTH;


endmodule
