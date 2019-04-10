/**************************************
**************************************/
`timescale 1 ps/ 1 ps

module hardware_b_f_tb ();

reg clk;
reg rst;
wire [95:0] force_b;
wire [95:0] force_a;
wire [95:0] force_t;
//wire [31:0] energy_go;



hardware_b_f b1(clk, rst, force_b, force_a, force_t);//, energy_go);


always begin
#1 clk = ~clk;
end

initial begin
clk = 0;
rst = 1;
#2 rst = 0;
end

initial begin
#1000000 $stop;
end


initial begin 
$readmemb("C:/Users/qx/Desktop/bonded_force/hardware_b_f/bond_term.data",b1.bond_mem.ram);
$readmemb("C:/Users/qx/Desktop/bonded_force/hardware_b_f/angle_term.data",b1.angle_mem.ram);
$readmemb("C:/Users/qx/Desktop/bonded_force/hardware_b_f/dihedral_term.data",b1.torsion_mem.ram);

end

/*
initial begin 
$readmemh("angle_term.data",b1.angle_mem)

end
initial begin 
$readmemh("torsion_term.data",b1.torsion_mem)

end

*/
/***************************************for old top module*********************************************
initial begin

data_b[323:320] = 4'h1;
end 


initial begin 
data_b[319:128] = 192'h417e6666_417e6666_417e6666_41180000_41180000_41180000;

#2000 data_b[319:128] = 192'h420ccccd_420ccccd_420ccccd_41a0cccd_41a0cccd_41a0cccd;
#2000 data_b[319:128] = 192'h00ee0000_00ee0000_00ee0000_00ff0000_00ff0000_00ff0000;
#2000 data_b[319:128] = 192'h00ef0000_00ef0000_00ef0000_00fd0000_00fe0000_00feb000;
end

initial begin 
data_b[127:0] = 128'h00010000_00020000_3f07ae14_3f07ae14;
#2300 data_b[127:0] = 128'h00030000_00040000_3ef0a3d7_3ef0a3d7;
#2300 data_b[127:0] = 128'h00050000_00060000_00ef0000_00ff0000;
#2300 data_b[127:0] = 128'h00070000_00080000_00ed0000_00ab0000;
end

initial begin 
one_start = 1;
# 100 one_start = 0;
# 2200 one_start = 1;
#100 one_start = 0;
#2200 one_start = 1;
#100 one_start = 0;
#2200 one_start = 1;
#100 one_start = 0;
end
*/
endmodule 
