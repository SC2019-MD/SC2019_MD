/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: ROM.v
//
// Function:
//				Read only memory used for holding fixed data from input dataset
//
// Data Organization:
//				Address 0 for each cell module: # of valid data in the memory
//
// Used by:
//				
//
// Dependency:
//				mif file extracted from input dataset
//
// Testbench:
//				N/A
//
// Timing:
//				2 cycles reading delay from input address and output data.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1 ps / 1 ps

module ROM
#(
	parameter DATA_WIDTH = 32,
	parameter PARTICLE_NUM = 16384,
	parameter ADDR_WIDTH = 14
)
(
	address,
	clock,
	q
);

    input  [ADDR_WIDTH-1:0]  address;
    input    clock;
    output [DATA_WIDTH-1:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
    tri1     clock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

    wire [DATA_WIDTH-1:0] sub_wire0;
    wire [DATA_WIDTH-1:0] q = sub_wire0[DATA_WIDTH-1:0];

    altera_syncram  altera_syncram_component (
                .address_a (address),
                .clock0 (clock),
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
                .data_a ({DATA_WIDTH{1'b1}}),
                .data_b (1'b1),
                .eccencbypass (1'b0),
                .eccencparity (8'b0),
                .eccstatus ( ),
                .q_b ( ),
                .rden_a (1'b1),
                .rden_b (1'b1),
                .sclr (1'b0),
                .wren_a (1'b0),
                .wren_b (1'b0));
    defparam
        altera_syncram_component.address_aclr_a  = "NONE",
        altera_syncram_component.clock_enable_input_a  = "BYPASS",
        altera_syncram_component.clock_enable_output_a  = "BYPASS",
/**/
        altera_syncram_component.intended_device_family  = "Stratix 10",
        altera_syncram_component.lpm_hint  = "ENABLE_RUNTIME_MOD=NO",
        altera_syncram_component.lpm_type  = "altera_syncram",
        altera_syncram_component.numwords_a  = PARTICLE_NUM,
        altera_syncram_component.operation_mode  = "ROM",
        altera_syncram_component.outdata_aclr_a  = "NONE",
        altera_syncram_component.outdata_sclr_a  = "NONE",
        altera_syncram_component.outdata_reg_a  = "CLOCK0",
        altera_syncram_component.enable_force_to_zero  = "FALSE",
        altera_syncram_component.widthad_a  = ADDR_WIDTH,
        altera_syncram_component.width_a  = DATA_WIDTH,
        altera_syncram_component.width_byteena_a  = 1;

endmodule
