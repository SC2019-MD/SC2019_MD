module Read_Addr_Arbiter_Bottom
#(
	parameter CELL_ADDR_WIDTH		= 7,
	parameter RDADDR_ARBITER_SIZE	= 4, 
	parameter RDADDR_ARBITER_MSB	= 16
)
(
	input clk, 
	input rst, 
	input [CELL_ADDR_WIDTH-1:0] addr1,
	input [CELL_ADDR_WIDTH-1:0] addr2,
	input [CELL_ADDR_WIDTH-1:0] addr3,
	input [CELL_ADDR_WIDTH-1:0] addr4,
	
	input enable1,
	input enable2,
	input enable3,
	input enable4,
	
	output [RDADDR_ARBITER_SIZE-1:0] Arbitration_Result
);

wire [RDADDR_ARBITER_SIZE-1:0] enable;
assign enable = {enable4, enable3, enable2, enable1};

reg [RDADDR_ARBITER_SIZE-1:0] prev_arbitration_result;
wire [RDADDR_ARBITER_SIZE-1:0] arbitration_step1;
wire [RDADDR_ARBITER_SIZE-1:0] arbitration_step2;
wire [RDADDR_ARBITER_SIZE-1:0] arbitration_step3;
wire [RDADDR_ARBITER_SIZE-1:0] arbitration_step4;
wire [RDADDR_ARBITER_SIZE-1:0] arbitration_step5;
wire [RDADDR_ARBITER_SIZE-1:0] arbitration_result_tmp;
wire [RDADDR_ARBITER_SIZE-1:0] round_robin_result;
assign arbitration_step1 = (prev_arbitration_result << 1) - 1'b1;
assign arbitration_step2 = ~arbitration_step1;
assign arbitration_step3 = (prev_arbitration_result == 0 || ((prev_arbitration_result << 1) > enable) || prev_arbitration_result == RDADDR_ARBITER_MSB) ? enable : (arbitration_step2 & enable);
assign arbitration_step4 = ~arbitration_step3 + 1'b1;

// step5 is just the temp result in Fitter_Arbiter
assign arbitration_step5 = arbitration_step3 & arbitration_step4;
assign round_robin_result = (enable == prev_arbitration_result) ? prev_arbitration_result : arbitration_step5;

// If all addresses are the same, everyone is happy
assign Arbitration_Result = (addr1 == addr2 && addr2 == addr3 && addr3 == addr4) ? 4'b1111 : round_robin_result;

always@(posedge clk)
	if (rst)
		begin
		prev_arbitration_result <= 0;
		end
	else
		begin
		prev_arbitration_result <= round_robin_result;
		end
endmodule