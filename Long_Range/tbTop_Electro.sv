`timescale 1ns/1ns
module tbMDTest();

logic clk;
logic rst;
logic [1:0] start_sig;

logic [127:0] user_buffer_data;
logic user_data_available;
logic [127:0] force_data;

integer               data_file    ; // file handler
integer               scan_file    ; // file handler
`define NULL 0    

Top_Electro uut(
	.clk(clk),
	.rst(rst),
	.start_sig(start_sig),
	.user_buffer_data(user_buffer_data), 
	.user_data_available(user_data_available),
    .forcedb_user_buffer_input_data(force_data)
	);

integer i;
always
	#5 clk <= ~clk;

initial
begin

    data_file = $fopen("list_mem.lst", "r");
    if (data_file == `NULL) 
	begin
		$display("data_file handle was NULL");
		$finish;
	end

	clk <= 0;
	rst <= 0;
	start_sig <= 0;
	i = 0;
	user_data_available = 0;
	user_buffer_data <= 'b0;

	#10;
	rst <= 1;
	#10;
	rst <= 0;
	#500;
	start_sig <= 1;
	#50;
	user_data_available = 1;
	for(i = 0; i < 2048; i=i+1)
	begin
		//user_buffer_data <= {i,i,i,0};
		scan_file = $fscanf(data_file, "%x;\n", user_buffer_data); 
	#40;
	end
	user_data_available = 0;
	#131000;
	user_data_available = 1;
	for(i = 0; i < 2048; i=i+1)
	begin
		user_buffer_data <= {i,i,i,0};
	#40;
	end
	user_data_available = 0;
	#100;
	//$stop;

end
endmodule

