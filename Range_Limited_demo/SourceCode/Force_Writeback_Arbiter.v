module Force_Writeback_Arbiter
#(
	parameter FORCE_WTADDR_ARBITER_SIZE		= 6,
	parameter FORCE_WTADDR_ARBITER_MSB		= 32
)
(
	input clk, 
	input rst, 
	input ref_force_valid,
	input force_valid_1,
	input force_valid_2,
	input force_valid_3,
	input force_valid_4,
	input force_valid_5,
	
	output [FORCE_WTADDR_ARBITER_SIZE-1:0] Arbitration_Result
);

wire [FORCE_WTADDR_ARBITER_SIZE-1:0] enable;


assign enable = {force_valid_5, force_valid_4, force_valid_3, force_valid_2, force_valid_1, ref_force_valid};

reg [FORCE_WTADDR_ARBITER_SIZE-1:0] prev_arbitration_result;
wire [FORCE_WTADDR_ARBITER_SIZE-1:0] arbitration_step1;
wire [FORCE_WTADDR_ARBITER_SIZE-1:0] arbitration_step2;
wire [FORCE_WTADDR_ARBITER_SIZE-1:0] arbitration_step3;
wire [FORCE_WTADDR_ARBITER_SIZE-1:0] arbitration_step4;
wire [FORCE_WTADDR_ARBITER_SIZE-1:0] arbitration_result_tmp;
assign arbitration_step1 = (prev_arbitration_result << 1) - 1'b1;
assign arbitration_step2 = ~arbitration_step1;
assign arbitration_step3 = (prev_arbitration_result == 0 || ((prev_arbitration_result << 1) > enable) || prev_arbitration_result == FORCE_WTADDR_ARBITER_MSB) ? enable : (arbitration_step2 & enable);
assign arbitration_step4 = ~arbitration_step3 + 1'b1;

// step5 is just the temp result in Fitter_Arbiter
assign arbitration_result_tmp = arbitration_step3 & arbitration_step4;

// If all addresses are the same, everyone is happy
assign Arbitration_Result = (enable == prev_arbitration_result) ? prev_arbitration_result : arbitration_result_tmp;

always@(posedge clk)
	if (rst)
		begin
		prev_arbitration_result <= 0;
		end
	else
		begin
		prev_arbitration_result <= Arbitration_Result;
		end
		
endmodule