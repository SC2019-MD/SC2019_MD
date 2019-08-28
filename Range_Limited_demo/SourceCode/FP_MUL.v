/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: FP_MUL.v
//
//	Function:
//				Floating Point MUL on hard DSP unit
//
// Latency: 4 cycles
//
// Created by: Chen Yang 10/24/18
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module FP_MUL  (
    input  wire                          clk,
    input  wire                          ena,
    input  wire                          clr,
    input  wire [31:0]                   ay,
    input  wire [31:0]                   az,
    output wire [31:0]                   result
	);
    wire [1-1:0] clk_vec;
    wire [1-1:0] ena_vec;
    wire [1:0]                   clr_vec;
    assign clk_vec[0] = clk;
    assign ena_vec[0] = ena;
    assign clr_vec[1] = clr;
    assign clr_vec[0] = clr;
fourteennm_fp_mac  #(
    .accumulate_clock("NONE"),
    .ax_clock("NONE"),
    .ay_clock("0"),
    .az_clock("0"),
    .accum_pipeline_clock("NONE"),
    .ax_chainin_pl_clock("NONE"),
    .mult_pipeline_clock("0"),
    .accum_2nd_pipeline_clock("NONE"),
    .ax_chainin_2nd_pl_clock("NONE"),
    .mult_2nd_pipeline_clock("0"),
    .accum_adder_clock("NONE"),
    .adder_input_clock("NONE"),
    .output_clock("0"),
    .clear_type("sclr"),
    .use_chainin("false"),
    .operation_mode("sp_mult"),
    .adder_subtract("false")
) sp_mult (
    .clk({1'b0,1'b0,clk_vec[0]}),
    .ena({1'b0,1'b0,ena_vec[0]}),
    .clr(clr_vec),
    .ay(ay),
    .az(az),

    .chainin(32'b0),
    .resulta(result),
    .mult_overflow (open),
    .mult_underflow(open),
    .mult_invalid  (open),
    .mult_inexact  (open),
    .adder_overflow (open),
    .adder_underflow(open),
    .adder_invalid  (open),
    .adder_inexact  (open),
    .chainout()
);
endmodule
