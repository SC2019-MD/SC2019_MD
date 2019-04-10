/**************************************
counters counting numbers of cycles  
***********************************/

module torsion_mem_controller
(
	input clk,
	input rst,
	output [13:0] addr_t
);


// Quartus Prime Verilog Template
// Binary counter

reg [11:0] count;

reg send_t;
reg [13:0] addr;
	// rst if needed, or increment if counting is enabled
	
always @ (posedge clk or posedge rst)
begin
	if (rst) begin
		count <= 0;
		send_t <= 0;
	end
	else if (count == 12'h320) begin
		count <= 0;
		send_t <= 1; // signal to send one bond term
	end
	else if (count != 12'h320) begin
		count <= count + 1'b1;
		send_t <= 0;
	end
end

reg prev_send_t;
always @ (posedge clk) 
begin
	prev_send_t <= send_t;
	if (rst) begin
		addr <= 14'b0;
	end
	else if (~prev_send_t && send_t) begin
		addr <= addr + 1'b1;
	end
	else begin
		addr <= addr;
	end
end 

assign addr_t = addr;
endmodule