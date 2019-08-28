/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: FP_ACC.v
//
//	Function:
//				FP_ADD with 1 cycle of latency
//				No input register
//				Connect the output to one of the inputs, then form an accumulator
//				Fmax ~ 360MHz
//
// Used by:
//				Partial_Force_Acc.v
//
// Latency: 1 cycle
//
// Created by: Chen Yang 10/24/18
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module FP_ACC 
#(parameter DATA_WIDTH = 32)
(
    input  wire                          clk,
    input  wire                          ena,
    input  wire                          clr,
    input  wire [DATA_WIDTH-1:0]         ax,
    input  wire [DATA_WIDTH-1:0]         ay,
    output wire [DATA_WIDTH-1:0]         result
);
    wire clk_vec;
    wire ena_vec;
    wire [1:0]                   clr_vec;
    assign clk_vec = clk;
    assign ena_vec = ena;
    assign clr_vec[1] = clr;
    assign clr_vec[0] = clr;
fourteennm_fp_mac  #(
    .accumulate_clock("NONE"),
    .ax_clock("NONE"),
    .ay_clock("NONE"),
    .az_clock("NONE"),
    .accum_pipeline_clock("NONE"),
    .ax_chainin_pl_clock("NONE"),
    .mult_pipeline_clock("NONE"),
    .accum_2nd_pipeline_clock("NONE"),
    .ax_chainin_2nd_pl_clock("NONE"),
    .mult_2nd_pipeline_clock("NONE"),
    .accum_adder_clock("NONE"),
    .adder_input_clock("NONE"),
    .output_clock("0"),
    .clear_type("sclr"),
    .use_chainin("false"),
    .operation_mode("sp_add"),
    .adder_subtract("false")
) sp_add (
    .clk({1'b0,1'b0,clk_vec}),
    .ena({1'b0,1'b0,ena_vec}),
    .clr(clr_vec),
    .ax(ax),
    .ay(ay),

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