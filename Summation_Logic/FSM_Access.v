/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: FSM_Access.v
//
// Function: 
//				Summation Control logic
//
// Data Organization:
//				
//
// Used by:
//				Summation_Logic.v
//
// Dependency:
//				N/A
//
// Testbench:
//				_tb.v
//
// Timing:
//				TBD
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module FSM_Access
#(
	parameter DATA_WIDTH 					= 32,
	parameter TOTAL_PARTICLE_NUM 			= 20000,
	parameter PARTICLE_GLOBAL_ID_WIDTH 	= 15,											// log(TOTAL_PARTICLE_NUM)/log(2)
	parameter NUM_CELL_X 					= 5,
	parameter NUM_CELL_Y 					= 5,
	parameter NUM_CELL_Z 					= 5,
	parameter NUM_TOTAL_CELL 				= NUM_CELL_X * NUM_CELL_Y * NUM_CELL_Z
)
(
    input clk,
    input rst,
    input [NUM_TOTAL_CELL-1:0] cell_id_to_sum,
    input cell_id_access_valid,
    input [3*DATA_WIDTH-1:0] number_of_partical,
    output reg [PARTICLE_GLOBAL_ID_WIDTH-1:0] access_address,
    output reg [NUM_TOTAL_CELL-1:0] cell_id,
    output reg rd_en,
    output reg resume,
    output reg valid_out_to_adder,
    input valid_in
    );
    
    reg [1:0] state;
    reg [7:0] number_of_partical_r;
    
    parameter IDLE = 2'b00; 
    parameter CHECK = 2'b01;
    parameter ACCESS = 2'b10;
    
    always @(posedge clk)
    begin 
        if (rst) 
        begin
            access_address <= 0;
            cell_id <= 0;
            rd_en <= 0;
            resume <= 0;
            state <= IDLE;
            number_of_partical_r <= 0;
            valid_out_to_adder <= 0;
        end
        else begin
            case (state)
            IDLE: 
            begin 
                access_address <= 0;
                rd_en <= 0;
                resume <= 0;
                number_of_partical_r <= 0;
                valid_out_to_adder <= 0;
                if (cell_id_access_valid == 1)
                begin
                    state <= CHECK;
                    cell_id <= cell_id_to_sum;
                end
                else
                begin
                    state <= IDLE;
                    cell_id <= 0;
                end
            end
            CHECK: 
            begin 
                valid_out_to_adder <= 0;
                cell_id <= cell_id;
                rd_en <= 1;
                resume <= 0;
                if (valid_in == 1) 
                begin
                    number_of_partical_r <= number_of_partical[7:0];
                    state <= ACCESS;
                    access_address <= 1;
                end
                else
                begin
                    number_of_partical_r <= 0;
                    state <= CHECK;
                    access_address <= 0;
                end
            end
            ACCESS: 
            begin 
                cell_id <= cell_id;
                number_of_partical_r <= number_of_partical_r;
                if (access_address == number_of_partical_r)
                begin
                    access_address <= 0;
                    state <= IDLE;
                    rd_en <= 0;
                    valid_out_to_adder <= 0;
                    resume <= 1;
                end  
                else
                begin
                    valid_out_to_adder <= 1;
                    rd_en <= 1;
                    access_address <= access_address + 1;
                    resume <= 0;
                    state <= ACCESS;
                end
            end
            default: 
            begin 
                access_address <= access_address;
                cell_id <= cell_id;
                rd_en <= rd_en;
                resume <= resume;
                state <= state;
                number_of_partical_r <= number_of_partical_r;
                valid_out_to_adder <= valid_out_to_adder;
            end
            endcase
        end
    end
    
endmodule
