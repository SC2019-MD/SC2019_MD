/**************************************

***********************************/

module angle_mem_controller
(
input clk,
input rst,
output [13:0] addr_a
);


// Quartus Prime Verilog Template
// Binary counter

reg [11:0] count;

reg send_a;
reg [13:0] addr;
	// rst if needed, or increment if counting is enabled
/*	
always @ (posedge clk or posedge rst)
begin
	if (rst) begin
		count <= 0;
		send_a<= 0;
	end
	else if (count == 12'h1F4) begin
		count <= 0;
		send_a <= 1; // signal to send one bond term
	end
	else if (count != 12'h1F4) begin
		count <= count + 1;
		send_a <= 0;
	end
end
*/
always @ (posedge rst or posedge clk)//send_a) 
begin
	if (rst) begin
		addr <= 14'b0;
	end
	//else if (send_a) begin
	else begin	
		addr <= addr + 1'b1;
	end 
end 

assign addr_a = addr;

endmodule