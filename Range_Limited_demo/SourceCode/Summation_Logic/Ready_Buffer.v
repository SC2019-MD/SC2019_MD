/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: Ready_Buffer.v
//
// Function: 
//				Buffering the incoming cell evaluation status
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
//
// Created by: 
//				Tong Geng 03/26/2019
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module Ready_Buffer
#(
	parameter NUM_TOTAL_CELL 				= 125
)
(
	input clk,
	input rst,
	input [NUM_TOTAL_CELL-1:0] ready_to_sum,
	output reg [NUM_TOTAL_CELL-1:0] cell_id_to_sum,
	output reg valid_out,
	input resume
);
    
    reg [7:0] addr;
    reg [NUM_TOTAL_CELL-1:0] cell_status;
    reg [1:0] state;
    
    parameter IDLE = 2'b00; 
    parameter SCAN = 2'b01;
    parameter WAIT = 2'b10;
    
    always @(posedge clk)
    begin 
        if (rst) 
        begin
            addr <= 0;
            cell_id_to_sum <= 0;
            cell_status <= 0;
            state <= IDLE;
            valid_out <= 0;
        end
        else begin
        if (valid_out == 1)
            cell_status <= cell_status | ready_to_sum & (~cell_id_to_sum);
        else 
            cell_status <= cell_status | ready_to_sum;
            case (state)
            IDLE: 
            begin 
                addr <= 0;
                cell_id_to_sum <= {1'b1,251'b0};
                //cell_status <= cell_status | ready_to_sum;
                state <= SCAN;
                valid_out <= 0;
            end
            SCAN: 
            begin 
                if (cell_status[addr] == 0) 
                begin
                    cell_id_to_sum <= {cell_id_to_sum[0],cell_id_to_sum[NUM_TOTAL_CELL-1:1]};
                    //cell_status <= cell_status | ready_to_sum;
                    state <= SCAN;
                    valid_out <= 0;
                    if (cell_id_to_sum[0] == 1)
                        addr <= 0;
                    else
                        addr <= addr + 1;
                end
                else 
                begin
                    cell_id_to_sum <= cell_id_to_sum;
                    addr <= addr;
                    state <= WAIT;
                    valid_out <= 1;
                end
            end
            WAIT: 
            begin 
                if (resume == 1) 
                begin
                    state <= SCAN;
                    cell_id_to_sum <= {cell_id_to_sum[0],cell_id_to_sum[NUM_TOTAL_CELL-1:1]};
                    valid_out <= 0; 
                    if (cell_id_to_sum[0] == 1)
                        addr <= 0;
                    else
                        addr <= addr + 1;
                end
                else
                begin
                    state <= WAIT;
                    addr <= addr;
                    cell_id_to_sum <= cell_id_to_sum;
                    valid_out <= 0; 
                end
            end
            default: 
            begin 
                state <= state;
                addr <= addr;
                cell_id_to_sum <= cell_id_to_sum;
                valid_out <= valid_out; 
            end
            endcase
        end
    end
    
endmodule
