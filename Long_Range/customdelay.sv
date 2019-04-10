module customdelay(
	clk,
	rst,
	x,
	y
);

parameter WIDTH = 32;
parameter DELAY = 3;

input  logic clk;
input  logic rst;
input  logic [WIDTH-1 : 0] x;
output logic [WIDTH-1 : 0] y;

logic [WIDTH-1 : 0] current [0 : DELAY - 1];

integer i;
always_ff @ (posedge clk)
begin
	if (rst)
		y <= 0;
	else
	begin
		current[0] <= x;
		for (i = 1; i < DELAY; i = i + 1)
		begin
			current[i] <= current[i-1];
		end
		y <= current[DELAY-1];
	end

end

endmodule
