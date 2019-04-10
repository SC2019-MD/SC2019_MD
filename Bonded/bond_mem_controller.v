/**************************************

***********************************/

module bond_mem_controller
(
	input clk,
	input rst,
	output [13:0] addr_b
);


// Quartus Prime Verilog Template
// Binary counter

reg [7:0] count;

reg send_b;
reg [13:0] addr;
	// rst if needed, or increment if counting is enabled
/*	
always @ (posedge clk or posedge rst)
begin
	if (rst) begin
		count <= 0;
		send_b <= 0;
	end
	else if (count == 8'hC8) begin
		count <= 0;
		send_b <= 1; // signal to send one bond term
	end
	else if (count != 8'hC8) begin
		count <= count + 1;
		send_b <= 0;
	end
end
*/
always @ (posedge clk or posedge rst) //or posedge send_b) 
begin
	if (rst) begin
		addr <= 14'b0;
	end
	//else if (send_b) begin
	else begin
		addr <= addr + 1'b1;
	end 
end 

assign addr_b = addr;

endmodule
