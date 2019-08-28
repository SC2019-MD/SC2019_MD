/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: Filter_Arbiter.v
//
//	Function: Make arbitration decisions among multiple available filters
//					Take filter availability as input, output selection signal (only 1 bit is high)
//					0 latency between input available and output selection
//
// Policy: Round-Robin
// Algorithm:
//		Rule out the previous selected channels 
// 		Step 0: Prev arbitration result: 0010
// 		Step 1: Shift left 1 bit, then -1 => 0100 - 1 = 0011
// 		Step 2: Not Step 1 => 1100
// 		Step 3: And with current mask 0110 => 0100 (all the previous arbitrated bits are removed)
//			* if the previous arbitration result is 0, means no channel selected, then avoid Step 1-3
//			** if the previous arbitration result is MSB, means one iteration is finished, then avoid Step 1-3
//			*** if the available channels only in the lower bits, but the previous selected channel is on the higher bit, then avoid Step 1-3
// 	Below is how to find the least significant 1 bit (2's complement & original value)
// 		Step 4: 2's complement of Step 3 => 1100
// 		Step 5: And Step 3, Step 4 => 0100 (This is the new result)
// 		Step 6: When the current mask is 1000, then omit step 1, so the lower bit mask will not be cleared
//			Step 7: When there's only one input source has valid data, then keeps selecting that only one
//			Step 8: When previous arbitration result is 0, then skip Step 1-3
//
// Used by:
//				Filter_Bank.v
//
// Dependency:
// 			None
//
// Testbench:
//				Filter_Arbiter_tb.v
//
//	Latency:	0 cycle
//
// Created by:
//				Chen Yang 10/12/18
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module Filter_Arbiter
#(
	parameter NUM_FILTER = 8,
	parameter ARBITER_MSB = 128					// 2^(NUM_FILTER-1)
)
(
	input clk,
	input rst,
	input [NUM_FILTER-1:0] Filter_Available_Flag,
	output [NUM_FILTER-1:0] Arbitration_Result
);

	reg [NUM_FILTER-1:0] prev_arbitration_result;
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Arbitration logic
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	wire [NUM_FILTER-1:0] arbitration_step1;
	wire [NUM_FILTER-1:0] arbitration_step2;
	wire [NUM_FILTER-1:0] arbitration_step3;
	wire [NUM_FILTER-1:0] arbitration_step4;
	wire [NUM_FILTER-1:0] arbitration_result_tmp;
	assign arbitration_step1 = (prev_arbitration_result << 1) - 1'b1;
	assign arbitration_step2 = ~arbitration_step1;
	// If the prev_arbitration_result is 0, then keep the original input flag
	// If the prev_arbitration_result is MSB, then keep the origianl input flag
	// If the available flag is only on the lower bit than the previous selected channel, then start over from the LSB 
	// If not, then remove the previous selected channels to achieve round-robin
	assign arbitration_step3 = (prev_arbitration_result == 0 || ((prev_arbitration_result << 1) > Filter_Available_Flag) || prev_arbitration_result == ARBITER_MSB) ? Filter_Available_Flag : (arbitration_step2 & Filter_Available_Flag);
	// 2's complement
	assign arbitration_step4 = ~arbitration_step3 + 1'b1;
	assign arbitration_result_tmp = arbitration_step3 & arbitration_step4;
	// If only a single filter has data, then keep reading from that one
	// If not, then performing arbitration execution
	assign Arbitration_Result = (Filter_Available_Flag == prev_arbitration_result) ? prev_arbitration_result : arbitration_result_tmp;
	
	// Assign previous results
	always@(posedge clk)
		begin
		if(rst)
			begin
			prev_arbitration_result <= 0;
/*			
			arbitration_step1 <= 0;
			arbitration_step2 <= 0;
			arbitration_step3 <= 0;
			arbitration_step4 <= 0;
			arbitration_result_tmp <= 0;
			Arbitration_Result <= 0;
*/
			end
		else
			begin
			prev_arbitration_result <= Arbitration_Result;
/*			
			arbitration_step1 <= (prev_arbitration_result << 1) - 1'b1;
			arbitration_step2 <= (prev_arbitration_result != 2^(NUM_FILTER-1))? ~arbitration_step1 : ~prev_arbitration_result;
			arbitration_step3 <= arbitration_step2 & Filter_Available_Flag;
			arbitration_step4 <= ~arbitration_step3 + 1'b1;							// 2's complement
			arbitration_result_tmp <= arbitration_step3 & arbitration_step4;
			Arbitration_Result <= (Filter_Available_Flag == prev_arbitration_result) ? prev_arbitration_result : arbitration_result_tmp;
*/
			end
		end

endmodule