assign cells_to_pipeline_1_1_1 = {
												Position_Cache_readout_position[22*3*DATA_WIDTH-1:21*3*DATA_WIDTH],
												Position_Cache_readout_position[21*3*DATA_WIDTH-1:20*3*DATA_WIDTH],
												Position_Cache_readout_position[24*3*DATA_WIDTH-1:23*3*DATA_WIDTH],
												Position_Cache_readout_position[18*3*DATA_WIDTH-1:17*3*DATA_WIDTH],
												Position_Cache_readout_position[17*3*DATA_WIDTH-1:16*3*DATA_WIDTH],
												Position_Cache_readout_position[20*3*DATA_WIDTH-1:19*3*DATA_WIDTH],
												Position_Cache_readout_position[30*3*DATA_WIDTH-1:29*3*DATA_WIDTH],
												Position_Cache_readout_position[29*3*DATA_WIDTH-1:28*3*DATA_WIDTH],
												Position_Cache_readout_position[32*3*DATA_WIDTH-1:31*3*DATA_WIDTH],
												Position_Cache_readout_position[6*3*DATA_WIDTH-1:5*3*DATA_WIDTH],
												Position_Cache_readout_position[5*3*DATA_WIDTH-1:4*3*DATA_WIDTH],
												Position_Cache_readout_position[8*3*DATA_WIDTH-1:7*3*DATA_WIDTH],
												Position_Cache_readout_position[2*3*DATA_WIDTH-1:1*3*DATA_WIDTH],
												Position_Cache_readout_position[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_1_1_2;
	assign cells_to_pipeline_1_1_2 = {
												Position_Cache_readout_position[23*3*DATA_WIDTH-1:22*3*DATA_WIDTH],
												Position_Cache_readout_position[22*3*DATA_WIDTH-1:21*3*DATA_WIDTH],
												Position_Cache_readout_position[21*3*DATA_WIDTH-1:20*3*DATA_WIDTH],
												Position_Cache_readout_position[19*3*DATA_WIDTH-1:18*3*DATA_WIDTH],
												Position_Cache_readout_position[18*3*DATA_WIDTH-1:17*3*DATA_WIDTH],
												Position_Cache_readout_position[17*3*DATA_WIDTH-1:16*3*DATA_WIDTH],
												Position_Cache_readout_position[31*3*DATA_WIDTH-1:30*3*DATA_WIDTH],
												Position_Cache_readout_position[30*3*DATA_WIDTH-1:29*3*DATA_WIDTH],
												Position_Cache_readout_position[29*3*DATA_WIDTH-1:28*3*DATA_WIDTH],
												Position_Cache_readout_position[7*3*DATA_WIDTH-1:6*3*DATA_WIDTH],
												Position_Cache_readout_position[6*3*DATA_WIDTH-1:5*3*DATA_WIDTH],
												Position_Cache_readout_position[5*3*DATA_WIDTH-1:4*3*DATA_WIDTH],
												Position_Cache_readout_position[3*3*DATA_WIDTH-1:2*3*DATA_WIDTH],
												Position_Cache_readout_position[2*3*DATA_WIDTH-1:1*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_1_1_3;
	assign cells_to_pipeline_1_1_3 = {
												Position_Cache_readout_position[24*3*DATA_WIDTH-1:23*3*DATA_WIDTH],
												Position_Cache_readout_position[23*3*DATA_WIDTH-1:22*3*DATA_WIDTH],
												Position_Cache_readout_position[22*3*DATA_WIDTH-1:21*3*DATA_WIDTH],
												Position_Cache_readout_position[20*3*DATA_WIDTH-1:19*3*DATA_WIDTH],
												Position_Cache_readout_position[19*3*DATA_WIDTH-1:18*3*DATA_WIDTH],
												Position_Cache_readout_position[18*3*DATA_WIDTH-1:17*3*DATA_WIDTH],
												Position_Cache_readout_position[32*3*DATA_WIDTH-1:31*3*DATA_WIDTH],
												Position_Cache_readout_position[31*3*DATA_WIDTH-1:30*3*DATA_WIDTH],
												Position_Cache_readout_position[30*3*DATA_WIDTH-1:29*3*DATA_WIDTH],
												Position_Cache_readout_position[8*3*DATA_WIDTH-1:7*3*DATA_WIDTH],
												Position_Cache_readout_position[7*3*DATA_WIDTH-1:6*3*DATA_WIDTH],
												Position_Cache_readout_position[6*3*DATA_WIDTH-1:5*3*DATA_WIDTH],
												Position_Cache_readout_position[4*3*DATA_WIDTH-1:3*3*DATA_WIDTH],
												Position_Cache_readout_position[3*3*DATA_WIDTH-1:2*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_1_1_4;
	assign cells_to_pipeline_1_1_4 = {
												Position_Cache_readout_position[21*3*DATA_WIDTH-1:20*3*DATA_WIDTH],
												Position_Cache_readout_position[24*3*DATA_WIDTH-1:23*3*DATA_WIDTH],
												Position_Cache_readout_position[23*3*DATA_WIDTH-1:22*3*DATA_WIDTH],
												Position_Cache_readout_position[17*3*DATA_WIDTH-1:16*3*DATA_WIDTH],
												Position_Cache_readout_position[20*3*DATA_WIDTH-1:19*3*DATA_WIDTH],
												Position_Cache_readout_position[19*3*DATA_WIDTH-1:18*3*DATA_WIDTH],
												Position_Cache_readout_position[29*3*DATA_WIDTH-1:28*3*DATA_WIDTH],
												Position_Cache_readout_position[32*3*DATA_WIDTH-1:31*3*DATA_WIDTH],
												Position_Cache_readout_position[31*3*DATA_WIDTH-1:30*3*DATA_WIDTH],
												Position_Cache_readout_position[5*3*DATA_WIDTH-1:4*3*DATA_WIDTH],
												Position_Cache_readout_position[8*3*DATA_WIDTH-1:7*3*DATA_WIDTH],
												Position_Cache_readout_position[7*3*DATA_WIDTH-1:6*3*DATA_WIDTH],
												Position_Cache_readout_position[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH],
												Position_Cache_readout_position[4*3*DATA_WIDTH-1:3*3*DATA_WIDTH]
												};
	always@(*)
		begin
		case(cell_set_select_1_1)
			1:
				begin
				cells_to_pipeline_1_1 <= cells_to_pipeline_1_1_1;
				Motion_Update_velocity_data_1_1 <= Motion_Update_velocity_data[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH];
				Motion_Update_velocity_read_addr[1*CELL_ADDR_WIDTH-1:0*CELL_ADDR_WIDTH] <= Motion_Update_velocity_read_addr_1_1;
				Motion_Update_out_velocity_data[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH] <= Motion_Update_out_velocity_data_1_1;
				reg_FSM_to_Cell_read_addr <= {
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[6*CELL_ADDR_WIDTH-1:5*CELL_ADDR_WIDTH],
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[8*CELL_ADDR_WIDTH-1:7*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[7*CELL_ADDR_WIDTH-1:6*CELL_ADDR_WIDTH],
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[12*CELL_ADDR_WIDTH-1:11*CELL_ADDR_WIDTH],
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[14*CELL_ADDR_WIDTH-1:13*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[13*CELL_ADDR_WIDTH-1:12*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[9*CELL_ADDR_WIDTH-1:8*CELL_ADDR_WIDTH],
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[11*CELL_ADDR_WIDTH-1:10*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[10*CELL_ADDR_WIDTH-1:9*CELL_ADDR_WIDTH],
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[3*CELL_ADDR_WIDTH-1:2*CELL_ADDR_WIDTH],
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[5*CELL_ADDR_WIDTH-1:4*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[4*CELL_ADDR_WIDTH-1:3*CELL_ADDR_WIDTH],
														dummy_zeros,
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[2*CELL_ADDR_WIDTH-1:1*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[1*CELL_ADDR_WIDTH-1:0*CELL_ADDR_WIDTH]
														};
				end
			2:
				begin
				cells_to_pipeline_1_1 <= cells_to_pipeline_1_1_2;
				Motion_Update_velocity_data_1_1 <= Motion_Update_velocity_data[2*3*DATA_WIDTH-1:1*3*DATA_WIDTH];
				Motion_Update_velocity_read_addr[2*CELL_ADDR_WIDTH-1:1*CELL_ADDR_WIDTH] <= Motion_Update_velocity_read_addr_1_1;
				Motion_Update_out_velocity_data[2*3*DATA_WIDTH-1:1*3*DATA_WIDTH] <= Motion_Update_out_velocity_data_1_1;
				reg_FSM_to_Cell_read_addr <= {
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[8*CELL_ADDR_WIDTH-1:7*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[7*CELL_ADDR_WIDTH-1:6*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[6*CELL_ADDR_WIDTH-1:5*CELL_ADDR_WIDTH],
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[14*CELL_ADDR_WIDTH-1:13*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[13*CELL_ADDR_WIDTH-1:12*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[12*CELL_ADDR_WIDTH-1:11*CELL_ADDR_WIDTH],
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[11*CELL_ADDR_WIDTH-1:10*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[10*CELL_ADDR_WIDTH-1:9*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[9*CELL_ADDR_WIDTH-1:8*CELL_ADDR_WIDTH],
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[5*CELL_ADDR_WIDTH-1:4*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[4*CELL_ADDR_WIDTH-1:3*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[3*CELL_ADDR_WIDTH-1:2*CELL_ADDR_WIDTH],
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[2*CELL_ADDR_WIDTH-1:1*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[1*CELL_ADDR_WIDTH-1:0*CELL_ADDR_WIDTH],
														dummy_zeros
														};
				end
			3:
				begin
				cells_to_pipeline_1_1 <= cells_to_pipeline_1_1_3;
				Motion_Update_velocity_data_1_1 <= Motion_Update_velocity_data[3*3*DATA_WIDTH-1:2*3*DATA_WIDTH];
				Motion_Update_velocity_read_addr[3*CELL_ADDR_WIDTH-1:2*CELL_ADDR_WIDTH] <= Motion_Update_velocity_read_addr_1_1;
				Motion_Update_out_velocity_data[3*3*DATA_WIDTH-1:2*3*DATA_WIDTH] <= Motion_Update_out_velocity_data_1_1;
				reg_FSM_to_Cell_read_addr <= {
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[8*CELL_ADDR_WIDTH-1:7*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[7*CELL_ADDR_WIDTH-1:6*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[6*CELL_ADDR_WIDTH-1:5*CELL_ADDR_WIDTH],
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[14*CELL_ADDR_WIDTH-1:13*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[13*CELL_ADDR_WIDTH-1:12*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[12*CELL_ADDR_WIDTH-1:11*CELL_ADDR_WIDTH],
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[11*CELL_ADDR_WIDTH-1:10*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[10*CELL_ADDR_WIDTH-1:9*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[9*CELL_ADDR_WIDTH-1:8*CELL_ADDR_WIDTH],
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[5*CELL_ADDR_WIDTH-1:4*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[4*CELL_ADDR_WIDTH-1:3*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[3*CELL_ADDR_WIDTH-1:2*CELL_ADDR_WIDTH],
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[2*CELL_ADDR_WIDTH-1:1*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[1*CELL_ADDR_WIDTH-1:0*CELL_ADDR_WIDTH],
														dummy_zeros,
														dummy_zeros
														};
				end
			4:
				begin
				cells_to_pipeline_1_1 <= cells_to_pipeline_1_1_4;
				Motion_Update_velocity_data_1_1 <= Motion_Update_velocity_data[4*3*DATA_WIDTH-1:3*3*DATA_WIDTH];
				Motion_Update_velocity_read_addr[4*CELL_ADDR_WIDTH-1:3*CELL_ADDR_WIDTH] <= Motion_Update_velocity_read_addr_1_1;
				Motion_Update_out_velocity_data[4*3*DATA_WIDTH-1:3*3*DATA_WIDTH] <= Motion_Update_out_velocity_data_1_1;
				reg_FSM_to_Cell_read_addr <= {
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[7*CELL_ADDR_WIDTH-1:6*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[6*CELL_ADDR_WIDTH-1:5*CELL_ADDR_WIDTH],
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[8*CELL_ADDR_WIDTH-1:7*CELL_ADDR_WIDTH],
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[13*CELL_ADDR_WIDTH-1:12*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[12*CELL_ADDR_WIDTH-1:11*CELL_ADDR_WIDTH],
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[14*CELL_ADDR_WIDTH-1:13*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[10*CELL_ADDR_WIDTH-1:9*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[9*CELL_ADDR_WIDTH-1:8*CELL_ADDR_WIDTH],
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[11*CELL_ADDR_WIDTH-1:10*CELL_ADDR_WIDTH],
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[4*CELL_ADDR_WIDTH-1:3*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[3*CELL_ADDR_WIDTH-1:2*CELL_ADDR_WIDTH],
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[5*CELL_ADDR_WIDTH-1:4*CELL_ADDR_WIDTH],
														FSM_to_Cell_read_addr_1_1[1*CELL_ADDR_WIDTH-1:0*CELL_ADDR_WIDTH],
														dummy_zeros,
														dummy_zeros,
														FSM_to_Cell_read_addr_1_1[2*CELL_ADDR_WIDTH-1:1*CELL_ADDR_WIDTH]
														};
				end
			default:
				begin
				cells_to_pipeline_1_1 <= cells_to_pipeline_1_1_1;
				Motion_Update_velocity_data_1_1 <= Motion_Update_velocity_data[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH];
				Motion_Update_velocity_read_addr[4*CELL_ADDR_WIDTH-1:0*CELL_ADDR_WIDTH] <= 0;
				Motion_Update_out_velocity_data[4*3*DATA_WIDTH-1:0*3*DATA_WIDTH] <= 0;
				reg_FSM_to_Cell_read_addr <= {
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros,
														dummy_zeros
														};
				end
		endcase
		end
	
	// Cell selection for pipeline 1-2
	wire [CELL_ID_WIDTH-1:0] cell_set_select_1_2;
	reg [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_1_2;
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_1_2_1;
	assign cells_to_pipeline_1_2_1 = {
												Position_Cache_readout_position[26*3*DATA_WIDTH-1:25*3*DATA_WIDTH],
												Position_Cache_readout_position[25*3*DATA_WIDTH-1:24*3*DATA_WIDTH],
												Position_Cache_readout_position[28*3*DATA_WIDTH-1:27*3*DATA_WIDTH],
												Position_Cache_readout_position[22*3*DATA_WIDTH-1:21*3*DATA_WIDTH],
												Position_Cache_readout_position[21*3*DATA_WIDTH-1:20*3*DATA_WIDTH],
												Position_Cache_readout_position[24*3*DATA_WIDTH-1:23*3*DATA_WIDTH],
												Position_Cache_readout_position[18*3*DATA_WIDTH-1:17*3*DATA_WIDTH],
												Position_Cache_readout_position[17*3*DATA_WIDTH-1:16*3*DATA_WIDTH],
												Position_Cache_readout_position[20*3*DATA_WIDTH-1:19*3*DATA_WIDTH],
												Position_Cache_readout_position[10*3*DATA_WIDTH-1:9*3*DATA_WIDTH],
												Position_Cache_readout_position[9*3*DATA_WIDTH-1:8*3*DATA_WIDTH],
												Position_Cache_readout_position[12*3*DATA_WIDTH-1:11*3*DATA_WIDTH],
												Position_Cache_readout_position[6*3*DATA_WIDTH-1:5*3*DATA_WIDTH],
												Position_Cache_readout_position[5*3*DATA_WIDTH-1:4*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_1_2_2;
	assign cells_to_pipeline_1_2_2 = {
												Position_Cache_readout_position[27*3*DATA_WIDTH-1:26*3*DATA_WIDTH],
												Position_Cache_readout_position[26*3*DATA_WIDTH-1:25*3*DATA_WIDTH],
												Position_Cache_readout_position[25*3*DATA_WIDTH-1:24*3*DATA_WIDTH],
												Position_Cache_readout_position[23*3*DATA_WIDTH-1:22*3*DATA_WIDTH],
												Position_Cache_readout_position[22*3*DATA_WIDTH-1:21*3*DATA_WIDTH],
												Position_Cache_readout_position[21*3*DATA_WIDTH-1:20*3*DATA_WIDTH],
												Position_Cache_readout_position[19*3*DATA_WIDTH-1:18*3*DATA_WIDTH],
												Position_Cache_readout_position[18*3*DATA_WIDTH-1:17*3*DATA_WIDTH],
												Position_Cache_readout_position[17*3*DATA_WIDTH-1:16*3*DATA_WIDTH],
												Position_Cache_readout_position[11*3*DATA_WIDTH-1:10*3*DATA_WIDTH],
												Position_Cache_readout_position[10*3*DATA_WIDTH-1:9*3*DATA_WIDTH],
												Position_Cache_readout_position[9*3*DATA_WIDTH-1:8*3*DATA_WIDTH],
												Position_Cache_readout_position[7*3*DATA_WIDTH-1:6*3*DATA_WIDTH],
												Position_Cache_readout_position[6*3*DATA_WIDTH-1:5*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_1_2_3;
	assign cells_to_pipeline_1_2_3 = {
												Position_Cache_readout_position[28*3*DATA_WIDTH-1:27*3*DATA_WIDTH],
												Position_Cache_readout_position[27*3*DATA_WIDTH-1:26*3*DATA_WIDTH],
												Position_Cache_readout_position[26*3*DATA_WIDTH-1:25*3*DATA_WIDTH],
												Position_Cache_readout_position[24*3*DATA_WIDTH-1:23*3*DATA_WIDTH],
												Position_Cache_readout_position[23*3*DATA_WIDTH-1:22*3*DATA_WIDTH],
												Position_Cache_readout_position[22*3*DATA_WIDTH-1:21*3*DATA_WIDTH],
												Position_Cache_readout_position[20*3*DATA_WIDTH-1:19*3*DATA_WIDTH],
												Position_Cache_readout_position[19*3*DATA_WIDTH-1:18*3*DATA_WIDTH],
												Position_Cache_readout_position[18*3*DATA_WIDTH-1:17*3*DATA_WIDTH],
												Position_Cache_readout_position[12*3*DATA_WIDTH-1:11*3*DATA_WIDTH],
												Position_Cache_readout_position[11*3*DATA_WIDTH-1:10*3*DATA_WIDTH],
												Position_Cache_readout_position[10*3*DATA_WIDTH-1:9*3*DATA_WIDTH],
												Position_Cache_readout_position[8*3*DATA_WIDTH-1:7*3*DATA_WIDTH],
												Position_Cache_readout_position[7*3*DATA_WIDTH-1:6*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_1_2_4;
	assign cells_to_pipeline_1_2_4 = {
												Position_Cache_readout_position[25*3*DATA_WIDTH-1:24*3*DATA_WIDTH],
												Position_Cache_readout_position[28*3*DATA_WIDTH-1:27*3*DATA_WIDTH],
												Position_Cache_readout_position[27*3*DATA_WIDTH-1:26*3*DATA_WIDTH],
												Position_Cache_readout_position[21*3*DATA_WIDTH-1:20*3*DATA_WIDTH],
												Position_Cache_readout_position[24*3*DATA_WIDTH-1:23*3*DATA_WIDTH],
												Position_Cache_readout_position[23*3*DATA_WIDTH-1:22*3*DATA_WIDTH],
												Position_Cache_readout_position[17*3*DATA_WIDTH-1:16*3*DATA_WIDTH],
												Position_Cache_readout_position[20*3*DATA_WIDTH-1:19*3*DATA_WIDTH],
												Position_Cache_readout_position[19*3*DATA_WIDTH-1:18*3*DATA_WIDTH],
												Position_Cache_readout_position[9*3*DATA_WIDTH-1:8*3*DATA_WIDTH],
												Position_Cache_readout_position[12*3*DATA_WIDTH-1:11*3*DATA_WIDTH],
												Position_Cache_readout_position[11*3*DATA_WIDTH-1:10*3*DATA_WIDTH],
												Position_Cache_readout_position[5*3*DATA_WIDTH-1:4*3*DATA_WIDTH],
												Position_Cache_readout_position[8*3*DATA_WIDTH-1:7*3*DATA_WIDTH]
												};
	always@(*)
		begin
		case(cell_set_select_1_2)
			1:
				begin
				cells_to_pipeline_1_2 <= cells_to_pipeline_1_2_1;
				end
			2:
				begin
				cells_to_pipeline_1_2 <= cells_to_pipeline_1_2_2;
				end
			3:
				begin
				cells_to_pipeline_1_2 <= cells_to_pipeline_1_2_3;
				end
			4:
				begin
				cells_to_pipeline_1_2 <= cells_to_pipeline_1_2_4;
				end
			default:
				begin
				cells_to_pipeline_1_2 <= cells_to_pipeline_1_2_1;
				end
		endcase
		end
	
	// Cell selection for pipeline 1-3
	wire [CELL_ID_WIDTH-1:0] cell_set_select_1_3;
	reg [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_1_3;
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_1_3_1;
	assign cells_to_pipeline_1_3_1 = {
												Position_Cache_readout_position[30*3*DATA_WIDTH-1:29*3*DATA_WIDTH],
												Position_Cache_readout_position[29*3*DATA_WIDTH-1:28*3*DATA_WIDTH],
												Position_Cache_readout_position[32*3*DATA_WIDTH-1:31*3*DATA_WIDTH],
												Position_Cache_readout_position[26*3*DATA_WIDTH-1:25*3*DATA_WIDTH],
												Position_Cache_readout_position[25*3*DATA_WIDTH-1:24*3*DATA_WIDTH],
												Position_Cache_readout_position[28*3*DATA_WIDTH-1:27*3*DATA_WIDTH],
												Position_Cache_readout_position[22*3*DATA_WIDTH-1:21*3*DATA_WIDTH],
												Position_Cache_readout_position[21*3*DATA_WIDTH-1:20*3*DATA_WIDTH],
												Position_Cache_readout_position[24*3*DATA_WIDTH-1:23*3*DATA_WIDTH],
												Position_Cache_readout_position[14*3*DATA_WIDTH-1:13*3*DATA_WIDTH],
												Position_Cache_readout_position[13*3*DATA_WIDTH-1:12*3*DATA_WIDTH],
												Position_Cache_readout_position[16*3*DATA_WIDTH-1:15*3*DATA_WIDTH],
												Position_Cache_readout_position[10*3*DATA_WIDTH-1:9*3*DATA_WIDTH],
												Position_Cache_readout_position[9*3*DATA_WIDTH-1:8*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_1_3_2;
	assign cells_to_pipeline_1_3_2 = {
												Position_Cache_readout_position[31*3*DATA_WIDTH-1:30*3*DATA_WIDTH],
												Position_Cache_readout_position[30*3*DATA_WIDTH-1:29*3*DATA_WIDTH],
												Position_Cache_readout_position[29*3*DATA_WIDTH-1:28*3*DATA_WIDTH],
												Position_Cache_readout_position[27*3*DATA_WIDTH-1:26*3*DATA_WIDTH],
												Position_Cache_readout_position[26*3*DATA_WIDTH-1:25*3*DATA_WIDTH],
												Position_Cache_readout_position[25*3*DATA_WIDTH-1:24*3*DATA_WIDTH],
												Position_Cache_readout_position[23*3*DATA_WIDTH-1:22*3*DATA_WIDTH],
												Position_Cache_readout_position[22*3*DATA_WIDTH-1:21*3*DATA_WIDTH],
												Position_Cache_readout_position[21*3*DATA_WIDTH-1:20*3*DATA_WIDTH],
												Position_Cache_readout_position[15*3*DATA_WIDTH-1:14*3*DATA_WIDTH],
												Position_Cache_readout_position[14*3*DATA_WIDTH-1:13*3*DATA_WIDTH],
												Position_Cache_readout_position[13*3*DATA_WIDTH-1:12*3*DATA_WIDTH],
												Position_Cache_readout_position[11*3*DATA_WIDTH-1:10*3*DATA_WIDTH],
												Position_Cache_readout_position[10*3*DATA_WIDTH-1:9*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_1_3_3;
	assign cells_to_pipeline_1_3_3 = {
												Position_Cache_readout_position[32*3*DATA_WIDTH-1:31*3*DATA_WIDTH],
												Position_Cache_readout_position[31*3*DATA_WIDTH-1:30*3*DATA_WIDTH],
												Position_Cache_readout_position[30*3*DATA_WIDTH-1:29*3*DATA_WIDTH],
												Position_Cache_readout_position[28*3*DATA_WIDTH-1:27*3*DATA_WIDTH],
												Position_Cache_readout_position[27*3*DATA_WIDTH-1:26*3*DATA_WIDTH],
												Position_Cache_readout_position[26*3*DATA_WIDTH-1:25*3*DATA_WIDTH],
												Position_Cache_readout_position[24*3*DATA_WIDTH-1:23*3*DATA_WIDTH],
												Position_Cache_readout_position[23*3*DATA_WIDTH-1:22*3*DATA_WIDTH],
												Position_Cache_readout_position[22*3*DATA_WIDTH-1:21*3*DATA_WIDTH],
												Position_Cache_readout_position[16*3*DATA_WIDTH-1:15*3*DATA_WIDTH],
												Position_Cache_readout_position[15*3*DATA_WIDTH-1:14*3*DATA_WIDTH],
												Position_Cache_readout_position[14*3*DATA_WIDTH-1:13*3*DATA_WIDTH],
												Position_Cache_readout_position[12*3*DATA_WIDTH-1:11*3*DATA_WIDTH],
												Position_Cache_readout_position[11*3*DATA_WIDTH-1:10*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_1_3_4;
	assign cells_to_pipeline_1_3_4 = {
												Position_Cache_readout_position[29*3*DATA_WIDTH-1:28*3*DATA_WIDTH],
												Position_Cache_readout_position[32*3*DATA_WIDTH-1:31*3*DATA_WIDTH],
												Position_Cache_readout_position[31*3*DATA_WIDTH-1:30*3*DATA_WIDTH],
												Position_Cache_readout_position[25*3*DATA_WIDTH-1:24*3*DATA_WIDTH],
												Position_Cache_readout_position[28*3*DATA_WIDTH-1:27*3*DATA_WIDTH],
												Position_Cache_readout_position[27*3*DATA_WIDTH-1:26*3*DATA_WIDTH],
												Position_Cache_readout_position[21*3*DATA_WIDTH-1:20*3*DATA_WIDTH],
												Position_Cache_readout_position[24*3*DATA_WIDTH-1:23*3*DATA_WIDTH],
												Position_Cache_readout_position[23*3*DATA_WIDTH-1:22*3*DATA_WIDTH],
												Position_Cache_readout_position[13*3*DATA_WIDTH-1:12*3*DATA_WIDTH],
												Position_Cache_readout_position[16*3*DATA_WIDTH-1:15*3*DATA_WIDTH],
												Position_Cache_readout_position[15*3*DATA_WIDTH-1:14*3*DATA_WIDTH],
												Position_Cache_readout_position[9*3*DATA_WIDTH-1:8*3*DATA_WIDTH],
												Position_Cache_readout_position[12*3*DATA_WIDTH-1:11*3*DATA_WIDTH]
												};
	always@(*)
		begin
		case(cell_set_select_1_3)
			1:
				begin
				cells_to_pipeline_1_3 <= cells_to_pipeline_1_3_1;
				end
			2:
				begin
				cells_to_pipeline_1_3 <= cells_to_pipeline_1_3_2;
				end
			3:
				begin
				cells_to_pipeline_1_3 <= cells_to_pipeline_1_3_3;
				end
			4:
				begin
				cells_to_pipeline_1_3 <= cells_to_pipeline_1_3_4;
				end
			default:
				begin
				cells_to_pipeline_1_3 <= cells_to_pipeline_1_3_1;
				end
		endcase
		end
	
	// Cell selection for pipeline 1-4
	wire [CELL_ID_WIDTH-1:0] cell_set_select_1_4;
	reg [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_1_4;
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_1_4_1;
	assign cells_to_pipeline_1_4_1 = {
												Position_Cache_readout_position[18*3*DATA_WIDTH-1:17*3*DATA_WIDTH],
												Position_Cache_readout_position[17*3*DATA_WIDTH-1:16*3*DATA_WIDTH],
												Position_Cache_readout_position[20*3*DATA_WIDTH-1:19*3*DATA_WIDTH],
												Position_Cache_readout_position[30*3*DATA_WIDTH-1:29*3*DATA_WIDTH],
												Position_Cache_readout_position[29*3*DATA_WIDTH-1:28*3*DATA_WIDTH],
												Position_Cache_readout_position[32*3*DATA_WIDTH-1:31*3*DATA_WIDTH],
												Position_Cache_readout_position[26*3*DATA_WIDTH-1:25*3*DATA_WIDTH],
												Position_Cache_readout_position[25*3*DATA_WIDTH-1:24*3*DATA_WIDTH],
												Position_Cache_readout_position[28*3*DATA_WIDTH-1:27*3*DATA_WIDTH],
												Position_Cache_readout_position[2*3*DATA_WIDTH-1:1*3*DATA_WIDTH],
												Position_Cache_readout_position[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH],
												Position_Cache_readout_position[4*3*DATA_WIDTH-1:3*3*DATA_WIDTH],
												Position_Cache_readout_position[14*3*DATA_WIDTH-1:13*3*DATA_WIDTH],
												Position_Cache_readout_position[13*3*DATA_WIDTH-1:12*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_1_4_2;
	assign cells_to_pipeline_1_4_2 = {
												Position_Cache_readout_position[19*3*DATA_WIDTH-1:18*3*DATA_WIDTH],
												Position_Cache_readout_position[18*3*DATA_WIDTH-1:17*3*DATA_WIDTH],
												Position_Cache_readout_position[17*3*DATA_WIDTH-1:16*3*DATA_WIDTH],
												Position_Cache_readout_position[31*3*DATA_WIDTH-1:30*3*DATA_WIDTH],
												Position_Cache_readout_position[30*3*DATA_WIDTH-1:29*3*DATA_WIDTH],
												Position_Cache_readout_position[29*3*DATA_WIDTH-1:28*3*DATA_WIDTH],
												Position_Cache_readout_position[27*3*DATA_WIDTH-1:26*3*DATA_WIDTH],
												Position_Cache_readout_position[26*3*DATA_WIDTH-1:25*3*DATA_WIDTH],
												Position_Cache_readout_position[25*3*DATA_WIDTH-1:24*3*DATA_WIDTH],
												Position_Cache_readout_position[3*3*DATA_WIDTH-1:2*3*DATA_WIDTH],
												Position_Cache_readout_position[2*3*DATA_WIDTH-1:1*3*DATA_WIDTH],
												Position_Cache_readout_position[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH],
												Position_Cache_readout_position[15*3*DATA_WIDTH-1:14*3*DATA_WIDTH],
												Position_Cache_readout_position[14*3*DATA_WIDTH-1:13*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_1_4_3;
	assign cells_to_pipeline_1_4_3 = {
												Position_Cache_readout_position[20*3*DATA_WIDTH-1:19*3*DATA_WIDTH],
												Position_Cache_readout_position[19*3*DATA_WIDTH-1:18*3*DATA_WIDTH],
												Position_Cache_readout_position[18*3*DATA_WIDTH-1:17*3*DATA_WIDTH],
												Position_Cache_readout_position[32*3*DATA_WIDTH-1:31*3*DATA_WIDTH],
												Position_Cache_readout_position[31*3*DATA_WIDTH-1:30*3*DATA_WIDTH],
												Position_Cache_readout_position[30*3*DATA_WIDTH-1:29*3*DATA_WIDTH],
												Position_Cache_readout_position[28*3*DATA_WIDTH-1:27*3*DATA_WIDTH],
												Position_Cache_readout_position[27*3*DATA_WIDTH-1:26*3*DATA_WIDTH],
												Position_Cache_readout_position[26*3*DATA_WIDTH-1:25*3*DATA_WIDTH],
												Position_Cache_readout_position[4*3*DATA_WIDTH-1:3*3*DATA_WIDTH],
												Position_Cache_readout_position[3*3*DATA_WIDTH-1:2*3*DATA_WIDTH],
												Position_Cache_readout_position[2*3*DATA_WIDTH-1:1*3*DATA_WIDTH],
												Position_Cache_readout_position[16*3*DATA_WIDTH-1:15*3*DATA_WIDTH],
												Position_Cache_readout_position[15*3*DATA_WIDTH-1:14*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_1_4_4;
	assign cells_to_pipeline_1_4_4 = {
												Position_Cache_readout_position[17*3*DATA_WIDTH-1:16*3*DATA_WIDTH],
												Position_Cache_readout_position[20*3*DATA_WIDTH-1:19*3*DATA_WIDTH],
												Position_Cache_readout_position[19*3*DATA_WIDTH-1:18*3*DATA_WIDTH],
												Position_Cache_readout_position[29*3*DATA_WIDTH-1:28*3*DATA_WIDTH],
												Position_Cache_readout_position[32*3*DATA_WIDTH-1:31*3*DATA_WIDTH],
												Position_Cache_readout_position[31*3*DATA_WIDTH-1:30*3*DATA_WIDTH],
												Position_Cache_readout_position[25*3*DATA_WIDTH-1:24*3*DATA_WIDTH],
												Position_Cache_readout_position[28*3*DATA_WIDTH-1:27*3*DATA_WIDTH],
												Position_Cache_readout_position[27*3*DATA_WIDTH-1:26*3*DATA_WIDTH],
												Position_Cache_readout_position[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH],
												Position_Cache_readout_position[4*3*DATA_WIDTH-1:3*3*DATA_WIDTH],
												Position_Cache_readout_position[3*3*DATA_WIDTH-1:2*3*DATA_WIDTH],
												Position_Cache_readout_position[13*3*DATA_WIDTH-1:12*3*DATA_WIDTH],
												Position_Cache_readout_position[16*3*DATA_WIDTH-1:15*3*DATA_WIDTH]
												};
	always@(*)
		begin
		case(cell_set_select_1_4)
			1:
				begin
				cells_to_pipeline_1_4 <= cells_to_pipeline_1_4_1;
				end
			2:
				begin
				cells_to_pipeline_1_4 <= cells_to_pipeline_1_4_2;
				end
			3:
				begin
				cells_to_pipeline_1_4 <= cells_to_pipeline_1_4_3;
				end
			4:
				begin
				cells_to_pipeline_1_4 <= cells_to_pipeline_1_4_4;
				end
			default:
				begin
				cells_to_pipeline_1_4 <= cells_to_pipeline_1_4_1;
				end
		endcase
		end
	
	// Cell selection for pipeline 2-1
	wire [CELL_ID_WIDTH-1:0] cell_set_select_2_1;
	reg [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_2_1;
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_2_1_1;
	assign cells_to_pipeline_2_1_1 = {
												Position_Cache_readout_position[38*3*DATA_WIDTH-1:37*3*DATA_WIDTH],
												Position_Cache_readout_position[37*3*DATA_WIDTH-1:36*3*DATA_WIDTH],
												Position_Cache_readout_position[40*3*DATA_WIDTH-1:39*3*DATA_WIDTH],
												Position_Cache_readout_position[34*3*DATA_WIDTH-1:33*3*DATA_WIDTH],
												Position_Cache_readout_position[33*3*DATA_WIDTH-1:32*3*DATA_WIDTH],
												Position_Cache_readout_position[36*3*DATA_WIDTH-1:35*3*DATA_WIDTH],
												Position_Cache_readout_position[46*3*DATA_WIDTH-1:45*3*DATA_WIDTH],
												Position_Cache_readout_position[45*3*DATA_WIDTH-1:44*3*DATA_WIDTH],
												Position_Cache_readout_position[48*3*DATA_WIDTH-1:47*3*DATA_WIDTH],
												Position_Cache_readout_position[22*3*DATA_WIDTH-1:21*3*DATA_WIDTH],
												Position_Cache_readout_position[21*3*DATA_WIDTH-1:20*3*DATA_WIDTH],
												Position_Cache_readout_position[24*3*DATA_WIDTH-1:23*3*DATA_WIDTH],
												Position_Cache_readout_position[18*3*DATA_WIDTH-1:17*3*DATA_WIDTH],
												Position_Cache_readout_position[17*3*DATA_WIDTH-1:16*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_2_1_2;
	assign cells_to_pipeline_2_1_2 = {
												Position_Cache_readout_position[39*3*DATA_WIDTH-1:38*3*DATA_WIDTH],
												Position_Cache_readout_position[38*3*DATA_WIDTH-1:37*3*DATA_WIDTH],
												Position_Cache_readout_position[37*3*DATA_WIDTH-1:36*3*DATA_WIDTH],
												Position_Cache_readout_position[35*3*DATA_WIDTH-1:34*3*DATA_WIDTH],
												Position_Cache_readout_position[34*3*DATA_WIDTH-1:33*3*DATA_WIDTH],
												Position_Cache_readout_position[33*3*DATA_WIDTH-1:32*3*DATA_WIDTH],
												Position_Cache_readout_position[47*3*DATA_WIDTH-1:46*3*DATA_WIDTH],
												Position_Cache_readout_position[46*3*DATA_WIDTH-1:45*3*DATA_WIDTH],
												Position_Cache_readout_position[45*3*DATA_WIDTH-1:44*3*DATA_WIDTH],
												Position_Cache_readout_position[23*3*DATA_WIDTH-1:22*3*DATA_WIDTH],
												Position_Cache_readout_position[22*3*DATA_WIDTH-1:21*3*DATA_WIDTH],
												Position_Cache_readout_position[21*3*DATA_WIDTH-1:20*3*DATA_WIDTH],
												Position_Cache_readout_position[19*3*DATA_WIDTH-1:18*3*DATA_WIDTH],
												Position_Cache_readout_position[18*3*DATA_WIDTH-1:17*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_2_1_3;
	assign cells_to_pipeline_2_1_3 = {
												Position_Cache_readout_position[40*3*DATA_WIDTH-1:39*3*DATA_WIDTH],
												Position_Cache_readout_position[39*3*DATA_WIDTH-1:38*3*DATA_WIDTH],
												Position_Cache_readout_position[38*3*DATA_WIDTH-1:37*3*DATA_WIDTH],
												Position_Cache_readout_position[36*3*DATA_WIDTH-1:35*3*DATA_WIDTH],
												Position_Cache_readout_position[35*3*DATA_WIDTH-1:34*3*DATA_WIDTH],
												Position_Cache_readout_position[34*3*DATA_WIDTH-1:33*3*DATA_WIDTH],
												Position_Cache_readout_position[48*3*DATA_WIDTH-1:47*3*DATA_WIDTH],
												Position_Cache_readout_position[47*3*DATA_WIDTH-1:46*3*DATA_WIDTH],
												Position_Cache_readout_position[46*3*DATA_WIDTH-1:45*3*DATA_WIDTH],
												Position_Cache_readout_position[24*3*DATA_WIDTH-1:23*3*DATA_WIDTH],
												Position_Cache_readout_position[23*3*DATA_WIDTH-1:22*3*DATA_WIDTH],
												Position_Cache_readout_position[22*3*DATA_WIDTH-1:21*3*DATA_WIDTH],
												Position_Cache_readout_position[20*3*DATA_WIDTH-1:19*3*DATA_WIDTH],
												Position_Cache_readout_position[19*3*DATA_WIDTH-1:18*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_2_1_4;
	assign cells_to_pipeline_2_1_4 = {
												Position_Cache_readout_position[37*3*DATA_WIDTH-1:36*3*DATA_WIDTH],
												Position_Cache_readout_position[40*3*DATA_WIDTH-1:39*3*DATA_WIDTH],
												Position_Cache_readout_position[39*3*DATA_WIDTH-1:38*3*DATA_WIDTH],
												Position_Cache_readout_position[33*3*DATA_WIDTH-1:32*3*DATA_WIDTH],
												Position_Cache_readout_position[36*3*DATA_WIDTH-1:35*3*DATA_WIDTH],
												Position_Cache_readout_position[35*3*DATA_WIDTH-1:34*3*DATA_WIDTH],
												Position_Cache_readout_position[45*3*DATA_WIDTH-1:44*3*DATA_WIDTH],
												Position_Cache_readout_position[48*3*DATA_WIDTH-1:47*3*DATA_WIDTH],
												Position_Cache_readout_position[47*3*DATA_WIDTH-1:46*3*DATA_WIDTH],
												Position_Cache_readout_position[21*3*DATA_WIDTH-1:20*3*DATA_WIDTH],
												Position_Cache_readout_position[24*3*DATA_WIDTH-1:23*3*DATA_WIDTH],
												Position_Cache_readout_position[23*3*DATA_WIDTH-1:22*3*DATA_WIDTH],
												Position_Cache_readout_position[17*3*DATA_WIDTH-1:16*3*DATA_WIDTH],
												Position_Cache_readout_position[20*3*DATA_WIDTH-1:19*3*DATA_WIDTH]
												};
	always@(*)
		begin
		case(cell_set_select_2_1)
			1:
				begin
				cells_to_pipeline_2_1 <= cells_to_pipeline_2_1_1;
				end
			2:
				begin
				cells_to_pipeline_2_1 <= cells_to_pipeline_2_1_2;
				end
			3:
				begin
				cells_to_pipeline_2_1 <= cells_to_pipeline_2_1_3;
				end
			4:
				begin
				cells_to_pipeline_2_1 <= cells_to_pipeline_2_1_4;
				end
			default:
				begin
				cells_to_pipeline_2_1 <= cells_to_pipeline_2_1_1;
				end
		endcase
		end
	
	// Cell selection for pipeline 2-2
	wire [CELL_ID_WIDTH-1:0] cell_set_select_2_2;
	reg [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_2_2;
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_2_2_1;
	assign cells_to_pipeline_2_2_1 = {
												Position_Cache_readout_position[42*3*DATA_WIDTH-1:41*3*DATA_WIDTH],
												Position_Cache_readout_position[41*3*DATA_WIDTH-1:40*3*DATA_WIDTH],
												Position_Cache_readout_position[44*3*DATA_WIDTH-1:43*3*DATA_WIDTH],
												Position_Cache_readout_position[38*3*DATA_WIDTH-1:37*3*DATA_WIDTH],
												Position_Cache_readout_position[37*3*DATA_WIDTH-1:36*3*DATA_WIDTH],
												Position_Cache_readout_position[40*3*DATA_WIDTH-1:39*3*DATA_WIDTH],
												Position_Cache_readout_position[34*3*DATA_WIDTH-1:33*3*DATA_WIDTH],
												Position_Cache_readout_position[33*3*DATA_WIDTH-1:32*3*DATA_WIDTH],
												Position_Cache_readout_position[36*3*DATA_WIDTH-1:35*3*DATA_WIDTH],
												Position_Cache_readout_position[26*3*DATA_WIDTH-1:25*3*DATA_WIDTH],
												Position_Cache_readout_position[25*3*DATA_WIDTH-1:24*3*DATA_WIDTH],
												Position_Cache_readout_position[28*3*DATA_WIDTH-1:27*3*DATA_WIDTH],
												Position_Cache_readout_position[22*3*DATA_WIDTH-1:21*3*DATA_WIDTH],
												Position_Cache_readout_position[21*3*DATA_WIDTH-1:20*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_2_2_2;
	assign cells_to_pipeline_2_2_2 = {
												Position_Cache_readout_position[43*3*DATA_WIDTH-1:42*3*DATA_WIDTH],
												Position_Cache_readout_position[42*3*DATA_WIDTH-1:41*3*DATA_WIDTH],
												Position_Cache_readout_position[41*3*DATA_WIDTH-1:40*3*DATA_WIDTH],
												Position_Cache_readout_position[39*3*DATA_WIDTH-1:38*3*DATA_WIDTH],
												Position_Cache_readout_position[38*3*DATA_WIDTH-1:37*3*DATA_WIDTH],
												Position_Cache_readout_position[37*3*DATA_WIDTH-1:36*3*DATA_WIDTH],
												Position_Cache_readout_position[35*3*DATA_WIDTH-1:34*3*DATA_WIDTH],
												Position_Cache_readout_position[34*3*DATA_WIDTH-1:33*3*DATA_WIDTH],
												Position_Cache_readout_position[33*3*DATA_WIDTH-1:32*3*DATA_WIDTH],
												Position_Cache_readout_position[27*3*DATA_WIDTH-1:26*3*DATA_WIDTH],
												Position_Cache_readout_position[26*3*DATA_WIDTH-1:25*3*DATA_WIDTH],
												Position_Cache_readout_position[25*3*DATA_WIDTH-1:24*3*DATA_WIDTH],
												Position_Cache_readout_position[23*3*DATA_WIDTH-1:22*3*DATA_WIDTH],
												Position_Cache_readout_position[22*3*DATA_WIDTH-1:21*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_2_2_3;
	assign cells_to_pipeline_2_2_3 = {
												Position_Cache_readout_position[44*3*DATA_WIDTH-1:43*3*DATA_WIDTH],
												Position_Cache_readout_position[43*3*DATA_WIDTH-1:42*3*DATA_WIDTH],
												Position_Cache_readout_position[42*3*DATA_WIDTH-1:41*3*DATA_WIDTH],
												Position_Cache_readout_position[40*3*DATA_WIDTH-1:39*3*DATA_WIDTH],
												Position_Cache_readout_position[39*3*DATA_WIDTH-1:38*3*DATA_WIDTH],
												Position_Cache_readout_position[38*3*DATA_WIDTH-1:37*3*DATA_WIDTH],
												Position_Cache_readout_position[36*3*DATA_WIDTH-1:35*3*DATA_WIDTH],
												Position_Cache_readout_position[35*3*DATA_WIDTH-1:34*3*DATA_WIDTH],
												Position_Cache_readout_position[34*3*DATA_WIDTH-1:33*3*DATA_WIDTH],
												Position_Cache_readout_position[28*3*DATA_WIDTH-1:27*3*DATA_WIDTH],
												Position_Cache_readout_position[27*3*DATA_WIDTH-1:26*3*DATA_WIDTH],
												Position_Cache_readout_position[26*3*DATA_WIDTH-1:25*3*DATA_WIDTH],
												Position_Cache_readout_position[24*3*DATA_WIDTH-1:23*3*DATA_WIDTH],
												Position_Cache_readout_position[23*3*DATA_WIDTH-1:22*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_2_2_4;
	assign cells_to_pipeline_2_2_4 = {
												Position_Cache_readout_position[41*3*DATA_WIDTH-1:40*3*DATA_WIDTH],
												Position_Cache_readout_position[44*3*DATA_WIDTH-1:43*3*DATA_WIDTH],
												Position_Cache_readout_position[43*3*DATA_WIDTH-1:42*3*DATA_WIDTH],
												Position_Cache_readout_position[37*3*DATA_WIDTH-1:36*3*DATA_WIDTH],
												Position_Cache_readout_position[40*3*DATA_WIDTH-1:39*3*DATA_WIDTH],
												Position_Cache_readout_position[39*3*DATA_WIDTH-1:38*3*DATA_WIDTH],
												Position_Cache_readout_position[33*3*DATA_WIDTH-1:32*3*DATA_WIDTH],
												Position_Cache_readout_position[36*3*DATA_WIDTH-1:35*3*DATA_WIDTH],
												Position_Cache_readout_position[35*3*DATA_WIDTH-1:34*3*DATA_WIDTH],
												Position_Cache_readout_position[25*3*DATA_WIDTH-1:24*3*DATA_WIDTH],
												Position_Cache_readout_position[28*3*DATA_WIDTH-1:27*3*DATA_WIDTH],
												Position_Cache_readout_position[27*3*DATA_WIDTH-1:26*3*DATA_WIDTH],
												Position_Cache_readout_position[21*3*DATA_WIDTH-1:20*3*DATA_WIDTH],
												Position_Cache_readout_position[24*3*DATA_WIDTH-1:23*3*DATA_WIDTH]
												};
	always@(*)
		begin
		case(cell_set_select_2_2)
			1:
				begin
				cells_to_pipeline_2_2 <= cells_to_pipeline_2_2_1;
				end
			2:
				begin
				cells_to_pipeline_2_2 <= cells_to_pipeline_2_2_2;
				end
			3:
				begin
				cells_to_pipeline_2_2 <= cells_to_pipeline_2_2_3;
				end
			4:
				begin
				cells_to_pipeline_2_2 <= cells_to_pipeline_2_2_4;
				end
			default:
				begin
				cells_to_pipeline_2_2 <= cells_to_pipeline_2_2_1;
				end
		endcase
		end
	
	// Cell selection for pipeline 2-3
	wire [CELL_ID_WIDTH-1:0] cell_set_select_2_3;
	reg [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_2_3;
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_2_3_1;
	assign cells_to_pipeline_2_3_1 = {
												Position_Cache_readout_position[46*3*DATA_WIDTH-1:45*3*DATA_WIDTH],
												Position_Cache_readout_position[45*3*DATA_WIDTH-1:44*3*DATA_WIDTH],
												Position_Cache_readout_position[48*3*DATA_WIDTH-1:47*3*DATA_WIDTH],
												Position_Cache_readout_position[42*3*DATA_WIDTH-1:41*3*DATA_WIDTH],
												Position_Cache_readout_position[41*3*DATA_WIDTH-1:40*3*DATA_WIDTH],
												Position_Cache_readout_position[44*3*DATA_WIDTH-1:43*3*DATA_WIDTH],
												Position_Cache_readout_position[38*3*DATA_WIDTH-1:37*3*DATA_WIDTH],
												Position_Cache_readout_position[37*3*DATA_WIDTH-1:36*3*DATA_WIDTH],
												Position_Cache_readout_position[40*3*DATA_WIDTH-1:39*3*DATA_WIDTH],
												Position_Cache_readout_position[30*3*DATA_WIDTH-1:29*3*DATA_WIDTH],
												Position_Cache_readout_position[29*3*DATA_WIDTH-1:28*3*DATA_WIDTH],
												Position_Cache_readout_position[32*3*DATA_WIDTH-1:31*3*DATA_WIDTH],
												Position_Cache_readout_position[26*3*DATA_WIDTH-1:25*3*DATA_WIDTH],
												Position_Cache_readout_position[25*3*DATA_WIDTH-1:24*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_2_3_2;
	assign cells_to_pipeline_2_3_2 = {
												Position_Cache_readout_position[47*3*DATA_WIDTH-1:46*3*DATA_WIDTH],
												Position_Cache_readout_position[46*3*DATA_WIDTH-1:45*3*DATA_WIDTH],
												Position_Cache_readout_position[45*3*DATA_WIDTH-1:44*3*DATA_WIDTH],
												Position_Cache_readout_position[43*3*DATA_WIDTH-1:42*3*DATA_WIDTH],
												Position_Cache_readout_position[42*3*DATA_WIDTH-1:41*3*DATA_WIDTH],
												Position_Cache_readout_position[41*3*DATA_WIDTH-1:40*3*DATA_WIDTH],
												Position_Cache_readout_position[39*3*DATA_WIDTH-1:38*3*DATA_WIDTH],
												Position_Cache_readout_position[38*3*DATA_WIDTH-1:37*3*DATA_WIDTH],
												Position_Cache_readout_position[37*3*DATA_WIDTH-1:36*3*DATA_WIDTH],
												Position_Cache_readout_position[31*3*DATA_WIDTH-1:30*3*DATA_WIDTH],
												Position_Cache_readout_position[30*3*DATA_WIDTH-1:29*3*DATA_WIDTH],
												Position_Cache_readout_position[29*3*DATA_WIDTH-1:28*3*DATA_WIDTH],
												Position_Cache_readout_position[27*3*DATA_WIDTH-1:26*3*DATA_WIDTH],
												Position_Cache_readout_position[26*3*DATA_WIDTH-1:25*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_2_3_3;
	assign cells_to_pipeline_2_3_3 = {
												Position_Cache_readout_position[48*3*DATA_WIDTH-1:47*3*DATA_WIDTH],
												Position_Cache_readout_position[47*3*DATA_WIDTH-1:46*3*DATA_WIDTH],
												Position_Cache_readout_position[46*3*DATA_WIDTH-1:45*3*DATA_WIDTH],
												Position_Cache_readout_position[44*3*DATA_WIDTH-1:43*3*DATA_WIDTH],
												Position_Cache_readout_position[43*3*DATA_WIDTH-1:42*3*DATA_WIDTH],
												Position_Cache_readout_position[42*3*DATA_WIDTH-1:41*3*DATA_WIDTH],
												Position_Cache_readout_position[40*3*DATA_WIDTH-1:39*3*DATA_WIDTH],
												Position_Cache_readout_position[39*3*DATA_WIDTH-1:38*3*DATA_WIDTH],
												Position_Cache_readout_position[38*3*DATA_WIDTH-1:37*3*DATA_WIDTH],
												Position_Cache_readout_position[32*3*DATA_WIDTH-1:31*3*DATA_WIDTH],
												Position_Cache_readout_position[31*3*DATA_WIDTH-1:30*3*DATA_WIDTH],
												Position_Cache_readout_position[30*3*DATA_WIDTH-1:29*3*DATA_WIDTH],
												Position_Cache_readout_position[28*3*DATA_WIDTH-1:27*3*DATA_WIDTH],
												Position_Cache_readout_position[27*3*DATA_WIDTH-1:26*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_2_3_4;
	assign cells_to_pipeline_2_3_4 = {
												Position_Cache_readout_position[45*3*DATA_WIDTH-1:44*3*DATA_WIDTH],
												Position_Cache_readout_position[48*3*DATA_WIDTH-1:47*3*DATA_WIDTH],
												Position_Cache_readout_position[47*3*DATA_WIDTH-1:46*3*DATA_WIDTH],
												Position_Cache_readout_position[41*3*DATA_WIDTH-1:40*3*DATA_WIDTH],
												Position_Cache_readout_position[44*3*DATA_WIDTH-1:43*3*DATA_WIDTH],
												Position_Cache_readout_position[43*3*DATA_WIDTH-1:42*3*DATA_WIDTH],
												Position_Cache_readout_position[37*3*DATA_WIDTH-1:36*3*DATA_WIDTH],
												Position_Cache_readout_position[40*3*DATA_WIDTH-1:39*3*DATA_WIDTH],
												Position_Cache_readout_position[39*3*DATA_WIDTH-1:38*3*DATA_WIDTH],
												Position_Cache_readout_position[29*3*DATA_WIDTH-1:28*3*DATA_WIDTH],
												Position_Cache_readout_position[32*3*DATA_WIDTH-1:31*3*DATA_WIDTH],
												Position_Cache_readout_position[31*3*DATA_WIDTH-1:30*3*DATA_WIDTH],
												Position_Cache_readout_position[25*3*DATA_WIDTH-1:24*3*DATA_WIDTH],
												Position_Cache_readout_position[28*3*DATA_WIDTH-1:27*3*DATA_WIDTH]
												};
	always@(*)
		begin
		case(cell_set_select_2_3)
			1:
				begin
				cells_to_pipeline_2_3 <= cells_to_pipeline_2_3_1;
				end
			2:
				begin
				cells_to_pipeline_2_3 <= cells_to_pipeline_2_3_2;
				end
			3:
				begin
				cells_to_pipeline_2_3 <= cells_to_pipeline_2_3_3;
				end
			4:
				begin
				cells_to_pipeline_2_3 <= cells_to_pipeline_2_3_4;
				end
			default:
				begin
				cells_to_pipeline_2_3 <= cells_to_pipeline_2_3_1;
				end
		endcase
		end
	
	// Cell selection for pipeline 2-4
	wire [CELL_ID_WIDTH-1:0] cell_set_select_2_4;
	reg [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_2_4;
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_2_4_1;
	assign cells_to_pipeline_2_4_1 = {
												Position_Cache_readout_position[34*3*DATA_WIDTH-1:33*3*DATA_WIDTH],
												Position_Cache_readout_position[33*3*DATA_WIDTH-1:32*3*DATA_WIDTH],
												Position_Cache_readout_position[36*3*DATA_WIDTH-1:35*3*DATA_WIDTH],
												Position_Cache_readout_position[46*3*DATA_WIDTH-1:45*3*DATA_WIDTH],
												Position_Cache_readout_position[45*3*DATA_WIDTH-1:44*3*DATA_WIDTH],
												Position_Cache_readout_position[48*3*DATA_WIDTH-1:47*3*DATA_WIDTH],
												Position_Cache_readout_position[42*3*DATA_WIDTH-1:41*3*DATA_WIDTH],
												Position_Cache_readout_position[41*3*DATA_WIDTH-1:40*3*DATA_WIDTH],
												Position_Cache_readout_position[44*3*DATA_WIDTH-1:43*3*DATA_WIDTH],
												Position_Cache_readout_position[18*3*DATA_WIDTH-1:17*3*DATA_WIDTH],
												Position_Cache_readout_position[17*3*DATA_WIDTH-1:16*3*DATA_WIDTH],
												Position_Cache_readout_position[20*3*DATA_WIDTH-1:19*3*DATA_WIDTH],
												Position_Cache_readout_position[30*3*DATA_WIDTH-1:29*3*DATA_WIDTH],
												Position_Cache_readout_position[29*3*DATA_WIDTH-1:28*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_2_4_2;
	assign cells_to_pipeline_2_4_2 = {
												Position_Cache_readout_position[35*3*DATA_WIDTH-1:34*3*DATA_WIDTH],
												Position_Cache_readout_position[34*3*DATA_WIDTH-1:33*3*DATA_WIDTH],
												Position_Cache_readout_position[33*3*DATA_WIDTH-1:32*3*DATA_WIDTH],
												Position_Cache_readout_position[47*3*DATA_WIDTH-1:46*3*DATA_WIDTH],
												Position_Cache_readout_position[46*3*DATA_WIDTH-1:45*3*DATA_WIDTH],
												Position_Cache_readout_position[45*3*DATA_WIDTH-1:44*3*DATA_WIDTH],
												Position_Cache_readout_position[43*3*DATA_WIDTH-1:42*3*DATA_WIDTH],
												Position_Cache_readout_position[42*3*DATA_WIDTH-1:41*3*DATA_WIDTH],
												Position_Cache_readout_position[41*3*DATA_WIDTH-1:40*3*DATA_WIDTH],
												Position_Cache_readout_position[19*3*DATA_WIDTH-1:18*3*DATA_WIDTH],
												Position_Cache_readout_position[18*3*DATA_WIDTH-1:17*3*DATA_WIDTH],
												Position_Cache_readout_position[17*3*DATA_WIDTH-1:16*3*DATA_WIDTH],
												Position_Cache_readout_position[31*3*DATA_WIDTH-1:30*3*DATA_WIDTH],
												Position_Cache_readout_position[30*3*DATA_WIDTH-1:29*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_2_4_3;
	assign cells_to_pipeline_2_4_3 = {
												Position_Cache_readout_position[36*3*DATA_WIDTH-1:35*3*DATA_WIDTH],
												Position_Cache_readout_position[35*3*DATA_WIDTH-1:34*3*DATA_WIDTH],
												Position_Cache_readout_position[34*3*DATA_WIDTH-1:33*3*DATA_WIDTH],
												Position_Cache_readout_position[48*3*DATA_WIDTH-1:47*3*DATA_WIDTH],
												Position_Cache_readout_position[47*3*DATA_WIDTH-1:46*3*DATA_WIDTH],
												Position_Cache_readout_position[46*3*DATA_WIDTH-1:45*3*DATA_WIDTH],
												Position_Cache_readout_position[44*3*DATA_WIDTH-1:43*3*DATA_WIDTH],
												Position_Cache_readout_position[43*3*DATA_WIDTH-1:42*3*DATA_WIDTH],
												Position_Cache_readout_position[42*3*DATA_WIDTH-1:41*3*DATA_WIDTH],
												Position_Cache_readout_position[20*3*DATA_WIDTH-1:19*3*DATA_WIDTH],
												Position_Cache_readout_position[19*3*DATA_WIDTH-1:18*3*DATA_WIDTH],
												Position_Cache_readout_position[18*3*DATA_WIDTH-1:17*3*DATA_WIDTH],
												Position_Cache_readout_position[32*3*DATA_WIDTH-1:31*3*DATA_WIDTH],
												Position_Cache_readout_position[31*3*DATA_WIDTH-1:30*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_2_4_4;
	assign cells_to_pipeline_2_4_4 = {
												Position_Cache_readout_position[33*3*DATA_WIDTH-1:32*3*DATA_WIDTH],
												Position_Cache_readout_position[36*3*DATA_WIDTH-1:35*3*DATA_WIDTH],
												Position_Cache_readout_position[35*3*DATA_WIDTH-1:34*3*DATA_WIDTH],
												Position_Cache_readout_position[45*3*DATA_WIDTH-1:44*3*DATA_WIDTH],
												Position_Cache_readout_position[48*3*DATA_WIDTH-1:47*3*DATA_WIDTH],
												Position_Cache_readout_position[47*3*DATA_WIDTH-1:46*3*DATA_WIDTH],
												Position_Cache_readout_position[41*3*DATA_WIDTH-1:40*3*DATA_WIDTH],
												Position_Cache_readout_position[44*3*DATA_WIDTH-1:43*3*DATA_WIDTH],
												Position_Cache_readout_position[43*3*DATA_WIDTH-1:42*3*DATA_WIDTH],
												Position_Cache_readout_position[17*3*DATA_WIDTH-1:16*3*DATA_WIDTH],
												Position_Cache_readout_position[20*3*DATA_WIDTH-1:19*3*DATA_WIDTH],
												Position_Cache_readout_position[19*3*DATA_WIDTH-1:18*3*DATA_WIDTH],
												Position_Cache_readout_position[29*3*DATA_WIDTH-1:28*3*DATA_WIDTH],
												Position_Cache_readout_position[32*3*DATA_WIDTH-1:31*3*DATA_WIDTH]
												};
	always@(*)
		begin
		case(cell_set_select_2_4)
			1:
				begin
				cells_to_pipeline_2_4 <= cells_to_pipeline_2_4_1;
				end
			2:
				begin
				cells_to_pipeline_2_4 <= cells_to_pipeline_2_4_2;
				end
			3:
				begin
				cells_to_pipeline_2_4 <= cells_to_pipeline_2_4_3;
				end
			4:
				begin
				cells_to_pipeline_2_4 <= cells_to_pipeline_2_4_4;
				end
			default:
				begin
				cells_to_pipeline_2_4 <= cells_to_pipeline_2_4_1;
				end
		endcase
		end
	
	// Cell selection for pipeline 3-1
	wire [CELL_ID_WIDTH-1:0] cell_set_select_3_1;
	reg [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_3_1;
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_3_1_1;
	assign cells_to_pipeline_3_1_1 = {
												Position_Cache_readout_position[54*3*DATA_WIDTH-1:53*3*DATA_WIDTH],
												Position_Cache_readout_position[53*3*DATA_WIDTH-1:52*3*DATA_WIDTH],
												Position_Cache_readout_position[56*3*DATA_WIDTH-1:55*3*DATA_WIDTH],
												Position_Cache_readout_position[50*3*DATA_WIDTH-1:49*3*DATA_WIDTH],
												Position_Cache_readout_position[49*3*DATA_WIDTH-1:48*3*DATA_WIDTH],
												Position_Cache_readout_position[52*3*DATA_WIDTH-1:51*3*DATA_WIDTH],
												Position_Cache_readout_position[62*3*DATA_WIDTH-1:61*3*DATA_WIDTH],
												Position_Cache_readout_position[61*3*DATA_WIDTH-1:60*3*DATA_WIDTH],
												Position_Cache_readout_position[64*3*DATA_WIDTH-1:63*3*DATA_WIDTH],
												Position_Cache_readout_position[38*3*DATA_WIDTH-1:37*3*DATA_WIDTH],
												Position_Cache_readout_position[37*3*DATA_WIDTH-1:36*3*DATA_WIDTH],
												Position_Cache_readout_position[40*3*DATA_WIDTH-1:39*3*DATA_WIDTH],
												Position_Cache_readout_position[34*3*DATA_WIDTH-1:33*3*DATA_WIDTH],
												Position_Cache_readout_position[33*3*DATA_WIDTH-1:32*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_3_1_2;
	assign cells_to_pipeline_3_1_2 = {
												Position_Cache_readout_position[55*3*DATA_WIDTH-1:54*3*DATA_WIDTH],
												Position_Cache_readout_position[54*3*DATA_WIDTH-1:53*3*DATA_WIDTH],
												Position_Cache_readout_position[53*3*DATA_WIDTH-1:52*3*DATA_WIDTH],
												Position_Cache_readout_position[51*3*DATA_WIDTH-1:50*3*DATA_WIDTH],
												Position_Cache_readout_position[50*3*DATA_WIDTH-1:49*3*DATA_WIDTH],
												Position_Cache_readout_position[49*3*DATA_WIDTH-1:48*3*DATA_WIDTH],
												Position_Cache_readout_position[63*3*DATA_WIDTH-1:62*3*DATA_WIDTH],
												Position_Cache_readout_position[62*3*DATA_WIDTH-1:61*3*DATA_WIDTH],
												Position_Cache_readout_position[61*3*DATA_WIDTH-1:60*3*DATA_WIDTH],
												Position_Cache_readout_position[39*3*DATA_WIDTH-1:38*3*DATA_WIDTH],
												Position_Cache_readout_position[38*3*DATA_WIDTH-1:37*3*DATA_WIDTH],
												Position_Cache_readout_position[37*3*DATA_WIDTH-1:36*3*DATA_WIDTH],
												Position_Cache_readout_position[35*3*DATA_WIDTH-1:34*3*DATA_WIDTH],
												Position_Cache_readout_position[34*3*DATA_WIDTH-1:33*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_3_1_3;
	assign cells_to_pipeline_3_1_3 = {
												Position_Cache_readout_position[56*3*DATA_WIDTH-1:55*3*DATA_WIDTH],
												Position_Cache_readout_position[55*3*DATA_WIDTH-1:54*3*DATA_WIDTH],
												Position_Cache_readout_position[54*3*DATA_WIDTH-1:53*3*DATA_WIDTH],
												Position_Cache_readout_position[52*3*DATA_WIDTH-1:51*3*DATA_WIDTH],
												Position_Cache_readout_position[51*3*DATA_WIDTH-1:50*3*DATA_WIDTH],
												Position_Cache_readout_position[50*3*DATA_WIDTH-1:49*3*DATA_WIDTH],
												Position_Cache_readout_position[64*3*DATA_WIDTH-1:63*3*DATA_WIDTH],
												Position_Cache_readout_position[63*3*DATA_WIDTH-1:62*3*DATA_WIDTH],
												Position_Cache_readout_position[62*3*DATA_WIDTH-1:61*3*DATA_WIDTH],
												Position_Cache_readout_position[40*3*DATA_WIDTH-1:39*3*DATA_WIDTH],
												Position_Cache_readout_position[39*3*DATA_WIDTH-1:38*3*DATA_WIDTH],
												Position_Cache_readout_position[38*3*DATA_WIDTH-1:37*3*DATA_WIDTH],
												Position_Cache_readout_position[36*3*DATA_WIDTH-1:35*3*DATA_WIDTH],
												Position_Cache_readout_position[35*3*DATA_WIDTH-1:34*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_3_1_4;
	assign cells_to_pipeline_3_1_4 = {
												Position_Cache_readout_position[53*3*DATA_WIDTH-1:52*3*DATA_WIDTH],
												Position_Cache_readout_position[56*3*DATA_WIDTH-1:55*3*DATA_WIDTH],
												Position_Cache_readout_position[55*3*DATA_WIDTH-1:54*3*DATA_WIDTH],
												Position_Cache_readout_position[49*3*DATA_WIDTH-1:48*3*DATA_WIDTH],
												Position_Cache_readout_position[52*3*DATA_WIDTH-1:51*3*DATA_WIDTH],
												Position_Cache_readout_position[51*3*DATA_WIDTH-1:50*3*DATA_WIDTH],
												Position_Cache_readout_position[61*3*DATA_WIDTH-1:60*3*DATA_WIDTH],
												Position_Cache_readout_position[64*3*DATA_WIDTH-1:63*3*DATA_WIDTH],
												Position_Cache_readout_position[63*3*DATA_WIDTH-1:62*3*DATA_WIDTH],
												Position_Cache_readout_position[37*3*DATA_WIDTH-1:36*3*DATA_WIDTH],
												Position_Cache_readout_position[40*3*DATA_WIDTH-1:39*3*DATA_WIDTH],
												Position_Cache_readout_position[39*3*DATA_WIDTH-1:38*3*DATA_WIDTH],
												Position_Cache_readout_position[33*3*DATA_WIDTH-1:32*3*DATA_WIDTH],
												Position_Cache_readout_position[36*3*DATA_WIDTH-1:35*3*DATA_WIDTH]
												};
	always@(*)
		begin
		case(cell_set_select_3_1)
			1:
				begin
				cells_to_pipeline_3_1 <= cells_to_pipeline_3_1_1;
				end
			2:
				begin
				cells_to_pipeline_3_1 <= cells_to_pipeline_3_1_2;
				end
			3:
				begin
				cells_to_pipeline_3_1 <= cells_to_pipeline_3_1_3;
				end
			4:
				begin
				cells_to_pipeline_3_1 <= cells_to_pipeline_3_1_4;
				end
			default:
				begin
				cells_to_pipeline_3_1 <= cells_to_pipeline_3_1_1;
				end
		endcase
		end
	
	// Cell selection for pipeline 3-2
	wire [CELL_ID_WIDTH-1:0] cell_set_select_3_2;
	reg [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_3_2;
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_3_2_1;
	assign cells_to_pipeline_3_2_1 = {
												Position_Cache_readout_position[58*3*DATA_WIDTH-1:57*3*DATA_WIDTH],
												Position_Cache_readout_position[57*3*DATA_WIDTH-1:56*3*DATA_WIDTH],
												Position_Cache_readout_position[60*3*DATA_WIDTH-1:59*3*DATA_WIDTH],
												Position_Cache_readout_position[54*3*DATA_WIDTH-1:53*3*DATA_WIDTH],
												Position_Cache_readout_position[53*3*DATA_WIDTH-1:52*3*DATA_WIDTH],
												Position_Cache_readout_position[56*3*DATA_WIDTH-1:55*3*DATA_WIDTH],
												Position_Cache_readout_position[50*3*DATA_WIDTH-1:49*3*DATA_WIDTH],
												Position_Cache_readout_position[49*3*DATA_WIDTH-1:48*3*DATA_WIDTH],
												Position_Cache_readout_position[52*3*DATA_WIDTH-1:51*3*DATA_WIDTH],
												Position_Cache_readout_position[42*3*DATA_WIDTH-1:41*3*DATA_WIDTH],
												Position_Cache_readout_position[41*3*DATA_WIDTH-1:40*3*DATA_WIDTH],
												Position_Cache_readout_position[44*3*DATA_WIDTH-1:43*3*DATA_WIDTH],
												Position_Cache_readout_position[38*3*DATA_WIDTH-1:37*3*DATA_WIDTH],
												Position_Cache_readout_position[37*3*DATA_WIDTH-1:36*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_3_2_2;
	assign cells_to_pipeline_3_2_2 = {
												Position_Cache_readout_position[59*3*DATA_WIDTH-1:58*3*DATA_WIDTH],
												Position_Cache_readout_position[58*3*DATA_WIDTH-1:57*3*DATA_WIDTH],
												Position_Cache_readout_position[57*3*DATA_WIDTH-1:56*3*DATA_WIDTH],
												Position_Cache_readout_position[55*3*DATA_WIDTH-1:54*3*DATA_WIDTH],
												Position_Cache_readout_position[54*3*DATA_WIDTH-1:53*3*DATA_WIDTH],
												Position_Cache_readout_position[53*3*DATA_WIDTH-1:52*3*DATA_WIDTH],
												Position_Cache_readout_position[51*3*DATA_WIDTH-1:50*3*DATA_WIDTH],
												Position_Cache_readout_position[50*3*DATA_WIDTH-1:49*3*DATA_WIDTH],
												Position_Cache_readout_position[49*3*DATA_WIDTH-1:48*3*DATA_WIDTH],
												Position_Cache_readout_position[43*3*DATA_WIDTH-1:42*3*DATA_WIDTH],
												Position_Cache_readout_position[42*3*DATA_WIDTH-1:41*3*DATA_WIDTH],
												Position_Cache_readout_position[41*3*DATA_WIDTH-1:40*3*DATA_WIDTH],
												Position_Cache_readout_position[39*3*DATA_WIDTH-1:38*3*DATA_WIDTH],
												Position_Cache_readout_position[38*3*DATA_WIDTH-1:37*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_3_2_3;
	assign cells_to_pipeline_3_2_3 = {
												Position_Cache_readout_position[60*3*DATA_WIDTH-1:59*3*DATA_WIDTH],
												Position_Cache_readout_position[59*3*DATA_WIDTH-1:58*3*DATA_WIDTH],
												Position_Cache_readout_position[58*3*DATA_WIDTH-1:57*3*DATA_WIDTH],
												Position_Cache_readout_position[56*3*DATA_WIDTH-1:55*3*DATA_WIDTH],
												Position_Cache_readout_position[55*3*DATA_WIDTH-1:54*3*DATA_WIDTH],
												Position_Cache_readout_position[54*3*DATA_WIDTH-1:53*3*DATA_WIDTH],
												Position_Cache_readout_position[52*3*DATA_WIDTH-1:51*3*DATA_WIDTH],
												Position_Cache_readout_position[51*3*DATA_WIDTH-1:50*3*DATA_WIDTH],
												Position_Cache_readout_position[50*3*DATA_WIDTH-1:49*3*DATA_WIDTH],
												Position_Cache_readout_position[44*3*DATA_WIDTH-1:43*3*DATA_WIDTH],
												Position_Cache_readout_position[43*3*DATA_WIDTH-1:42*3*DATA_WIDTH],
												Position_Cache_readout_position[42*3*DATA_WIDTH-1:41*3*DATA_WIDTH],
												Position_Cache_readout_position[40*3*DATA_WIDTH-1:39*3*DATA_WIDTH],
												Position_Cache_readout_position[39*3*DATA_WIDTH-1:38*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_3_2_4;
	assign cells_to_pipeline_3_2_4 = {
												Position_Cache_readout_position[57*3*DATA_WIDTH-1:56*3*DATA_WIDTH],
												Position_Cache_readout_position[60*3*DATA_WIDTH-1:59*3*DATA_WIDTH],
												Position_Cache_readout_position[59*3*DATA_WIDTH-1:58*3*DATA_WIDTH],
												Position_Cache_readout_position[53*3*DATA_WIDTH-1:52*3*DATA_WIDTH],
												Position_Cache_readout_position[56*3*DATA_WIDTH-1:55*3*DATA_WIDTH],
												Position_Cache_readout_position[55*3*DATA_WIDTH-1:54*3*DATA_WIDTH],
												Position_Cache_readout_position[49*3*DATA_WIDTH-1:48*3*DATA_WIDTH],
												Position_Cache_readout_position[52*3*DATA_WIDTH-1:51*3*DATA_WIDTH],
												Position_Cache_readout_position[51*3*DATA_WIDTH-1:50*3*DATA_WIDTH],
												Position_Cache_readout_position[41*3*DATA_WIDTH-1:40*3*DATA_WIDTH],
												Position_Cache_readout_position[44*3*DATA_WIDTH-1:43*3*DATA_WIDTH],
												Position_Cache_readout_position[43*3*DATA_WIDTH-1:42*3*DATA_WIDTH],
												Position_Cache_readout_position[37*3*DATA_WIDTH-1:36*3*DATA_WIDTH],
												Position_Cache_readout_position[40*3*DATA_WIDTH-1:39*3*DATA_WIDTH]
												};
	always@(*)
		begin
		case(cell_set_select_3_2)
			1:
				begin
				cells_to_pipeline_3_2 <= cells_to_pipeline_3_2_1;
				end
			2:
				begin
				cells_to_pipeline_3_2 <= cells_to_pipeline_3_2_2;
				end
			3:
				begin
				cells_to_pipeline_3_2 <= cells_to_pipeline_3_2_3;
				end
			4:
				begin
				cells_to_pipeline_3_2 <= cells_to_pipeline_3_2_4;
				end
			default:
				begin
				cells_to_pipeline_3_2 <= cells_to_pipeline_3_2_1;
				end
		endcase
		end
	
	// Cell selection for pipeline 3-3
	wire [CELL_ID_WIDTH-1:0] cell_set_select_3_3;
	reg [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_3_3;
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_3_3_1;
	assign cells_to_pipeline_3_3_1 = {
												Position_Cache_readout_position[62*3*DATA_WIDTH-1:61*3*DATA_WIDTH],
												Position_Cache_readout_position[61*3*DATA_WIDTH-1:60*3*DATA_WIDTH],
												Position_Cache_readout_position[64*3*DATA_WIDTH-1:63*3*DATA_WIDTH],
												Position_Cache_readout_position[58*3*DATA_WIDTH-1:57*3*DATA_WIDTH],
												Position_Cache_readout_position[57*3*DATA_WIDTH-1:56*3*DATA_WIDTH],
												Position_Cache_readout_position[60*3*DATA_WIDTH-1:59*3*DATA_WIDTH],
												Position_Cache_readout_position[54*3*DATA_WIDTH-1:53*3*DATA_WIDTH],
												Position_Cache_readout_position[53*3*DATA_WIDTH-1:52*3*DATA_WIDTH],
												Position_Cache_readout_position[56*3*DATA_WIDTH-1:55*3*DATA_WIDTH],
												Position_Cache_readout_position[46*3*DATA_WIDTH-1:45*3*DATA_WIDTH],
												Position_Cache_readout_position[45*3*DATA_WIDTH-1:44*3*DATA_WIDTH],
												Position_Cache_readout_position[48*3*DATA_WIDTH-1:47*3*DATA_WIDTH],
												Position_Cache_readout_position[42*3*DATA_WIDTH-1:41*3*DATA_WIDTH],
												Position_Cache_readout_position[41*3*DATA_WIDTH-1:40*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_3_3_2;
	assign cells_to_pipeline_3_3_2 = {
												Position_Cache_readout_position[63*3*DATA_WIDTH-1:62*3*DATA_WIDTH],
												Position_Cache_readout_position[62*3*DATA_WIDTH-1:61*3*DATA_WIDTH],
												Position_Cache_readout_position[61*3*DATA_WIDTH-1:60*3*DATA_WIDTH],
												Position_Cache_readout_position[59*3*DATA_WIDTH-1:58*3*DATA_WIDTH],
												Position_Cache_readout_position[58*3*DATA_WIDTH-1:57*3*DATA_WIDTH],
												Position_Cache_readout_position[57*3*DATA_WIDTH-1:56*3*DATA_WIDTH],
												Position_Cache_readout_position[55*3*DATA_WIDTH-1:54*3*DATA_WIDTH],
												Position_Cache_readout_position[54*3*DATA_WIDTH-1:53*3*DATA_WIDTH],
												Position_Cache_readout_position[53*3*DATA_WIDTH-1:52*3*DATA_WIDTH],
												Position_Cache_readout_position[47*3*DATA_WIDTH-1:46*3*DATA_WIDTH],
												Position_Cache_readout_position[46*3*DATA_WIDTH-1:45*3*DATA_WIDTH],
												Position_Cache_readout_position[45*3*DATA_WIDTH-1:44*3*DATA_WIDTH],
												Position_Cache_readout_position[43*3*DATA_WIDTH-1:42*3*DATA_WIDTH],
												Position_Cache_readout_position[42*3*DATA_WIDTH-1:41*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_3_3_3;
	assign cells_to_pipeline_3_3_3 = {
												Position_Cache_readout_position[64*3*DATA_WIDTH-1:63*3*DATA_WIDTH],
												Position_Cache_readout_position[63*3*DATA_WIDTH-1:62*3*DATA_WIDTH],
												Position_Cache_readout_position[62*3*DATA_WIDTH-1:61*3*DATA_WIDTH],
												Position_Cache_readout_position[60*3*DATA_WIDTH-1:59*3*DATA_WIDTH],
												Position_Cache_readout_position[59*3*DATA_WIDTH-1:58*3*DATA_WIDTH],
												Position_Cache_readout_position[58*3*DATA_WIDTH-1:57*3*DATA_WIDTH],
												Position_Cache_readout_position[56*3*DATA_WIDTH-1:55*3*DATA_WIDTH],
												Position_Cache_readout_position[55*3*DATA_WIDTH-1:54*3*DATA_WIDTH],
												Position_Cache_readout_position[54*3*DATA_WIDTH-1:53*3*DATA_WIDTH],
												Position_Cache_readout_position[48*3*DATA_WIDTH-1:47*3*DATA_WIDTH],
												Position_Cache_readout_position[47*3*DATA_WIDTH-1:46*3*DATA_WIDTH],
												Position_Cache_readout_position[46*3*DATA_WIDTH-1:45*3*DATA_WIDTH],
												Position_Cache_readout_position[44*3*DATA_WIDTH-1:43*3*DATA_WIDTH],
												Position_Cache_readout_position[43*3*DATA_WIDTH-1:42*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_3_3_4;
	assign cells_to_pipeline_3_3_4 = {
												Position_Cache_readout_position[61*3*DATA_WIDTH-1:60*3*DATA_WIDTH],
												Position_Cache_readout_position[64*3*DATA_WIDTH-1:63*3*DATA_WIDTH],
												Position_Cache_readout_position[63*3*DATA_WIDTH-1:62*3*DATA_WIDTH],
												Position_Cache_readout_position[57*3*DATA_WIDTH-1:56*3*DATA_WIDTH],
												Position_Cache_readout_position[60*3*DATA_WIDTH-1:59*3*DATA_WIDTH],
												Position_Cache_readout_position[59*3*DATA_WIDTH-1:58*3*DATA_WIDTH],
												Position_Cache_readout_position[53*3*DATA_WIDTH-1:52*3*DATA_WIDTH],
												Position_Cache_readout_position[56*3*DATA_WIDTH-1:55*3*DATA_WIDTH],
												Position_Cache_readout_position[55*3*DATA_WIDTH-1:54*3*DATA_WIDTH],
												Position_Cache_readout_position[45*3*DATA_WIDTH-1:44*3*DATA_WIDTH],
												Position_Cache_readout_position[48*3*DATA_WIDTH-1:47*3*DATA_WIDTH],
												Position_Cache_readout_position[47*3*DATA_WIDTH-1:46*3*DATA_WIDTH],
												Position_Cache_readout_position[41*3*DATA_WIDTH-1:40*3*DATA_WIDTH],
												Position_Cache_readout_position[44*3*DATA_WIDTH-1:43*3*DATA_WIDTH]
												};
	always@(*)
		begin
		case(cell_set_select_3_3)
			1:
				begin
				cells_to_pipeline_3_3 <= cells_to_pipeline_3_3_1;
				end
			2:
				begin
				cells_to_pipeline_3_3 <= cells_to_pipeline_3_3_2;
				end
			3:
				begin
				cells_to_pipeline_3_3 <= cells_to_pipeline_3_3_3;
				end
			4:
				begin
				cells_to_pipeline_3_3 <= cells_to_pipeline_3_3_4;
				end
			default:
				begin
				cells_to_pipeline_3_3 <= cells_to_pipeline_3_3_1;
				end
		endcase
		end
	
	// Cell selection for pipeline 3-4
	wire [CELL_ID_WIDTH-1:0] cell_set_select_3_4;
	reg [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_3_4;
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_3_4_1;
	assign cells_to_pipeline_3_4_1 = {
												Position_Cache_readout_position[50*3*DATA_WIDTH-1:49*3*DATA_WIDTH],
												Position_Cache_readout_position[49*3*DATA_WIDTH-1:48*3*DATA_WIDTH],
												Position_Cache_readout_position[52*3*DATA_WIDTH-1:51*3*DATA_WIDTH],
												Position_Cache_readout_position[62*3*DATA_WIDTH-1:61*3*DATA_WIDTH],
												Position_Cache_readout_position[61*3*DATA_WIDTH-1:60*3*DATA_WIDTH],
												Position_Cache_readout_position[64*3*DATA_WIDTH-1:63*3*DATA_WIDTH],
												Position_Cache_readout_position[58*3*DATA_WIDTH-1:57*3*DATA_WIDTH],
												Position_Cache_readout_position[57*3*DATA_WIDTH-1:56*3*DATA_WIDTH],
												Position_Cache_readout_position[60*3*DATA_WIDTH-1:59*3*DATA_WIDTH],
												Position_Cache_readout_position[34*3*DATA_WIDTH-1:33*3*DATA_WIDTH],
												Position_Cache_readout_position[33*3*DATA_WIDTH-1:32*3*DATA_WIDTH],
												Position_Cache_readout_position[36*3*DATA_WIDTH-1:35*3*DATA_WIDTH],
												Position_Cache_readout_position[46*3*DATA_WIDTH-1:45*3*DATA_WIDTH],
												Position_Cache_readout_position[45*3*DATA_WIDTH-1:44*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_3_4_2;
	assign cells_to_pipeline_3_4_2 = {
												Position_Cache_readout_position[51*3*DATA_WIDTH-1:50*3*DATA_WIDTH],
												Position_Cache_readout_position[50*3*DATA_WIDTH-1:49*3*DATA_WIDTH],
												Position_Cache_readout_position[49*3*DATA_WIDTH-1:48*3*DATA_WIDTH],
												Position_Cache_readout_position[63*3*DATA_WIDTH-1:62*3*DATA_WIDTH],
												Position_Cache_readout_position[62*3*DATA_WIDTH-1:61*3*DATA_WIDTH],
												Position_Cache_readout_position[61*3*DATA_WIDTH-1:60*3*DATA_WIDTH],
												Position_Cache_readout_position[59*3*DATA_WIDTH-1:58*3*DATA_WIDTH],
												Position_Cache_readout_position[58*3*DATA_WIDTH-1:57*3*DATA_WIDTH],
												Position_Cache_readout_position[57*3*DATA_WIDTH-1:56*3*DATA_WIDTH],
												Position_Cache_readout_position[35*3*DATA_WIDTH-1:34*3*DATA_WIDTH],
												Position_Cache_readout_position[34*3*DATA_WIDTH-1:33*3*DATA_WIDTH],
												Position_Cache_readout_position[33*3*DATA_WIDTH-1:32*3*DATA_WIDTH],
												Position_Cache_readout_position[47*3*DATA_WIDTH-1:46*3*DATA_WIDTH],
												Position_Cache_readout_position[46*3*DATA_WIDTH-1:45*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_3_4_3;
	assign cells_to_pipeline_3_4_3 = {
												Position_Cache_readout_position[52*3*DATA_WIDTH-1:51*3*DATA_WIDTH],
												Position_Cache_readout_position[51*3*DATA_WIDTH-1:50*3*DATA_WIDTH],
												Position_Cache_readout_position[50*3*DATA_WIDTH-1:49*3*DATA_WIDTH],
												Position_Cache_readout_position[64*3*DATA_WIDTH-1:63*3*DATA_WIDTH],
												Position_Cache_readout_position[63*3*DATA_WIDTH-1:62*3*DATA_WIDTH],
												Position_Cache_readout_position[62*3*DATA_WIDTH-1:61*3*DATA_WIDTH],
												Position_Cache_readout_position[60*3*DATA_WIDTH-1:59*3*DATA_WIDTH],
												Position_Cache_readout_position[59*3*DATA_WIDTH-1:58*3*DATA_WIDTH],
												Position_Cache_readout_position[58*3*DATA_WIDTH-1:57*3*DATA_WIDTH],
												Position_Cache_readout_position[36*3*DATA_WIDTH-1:35*3*DATA_WIDTH],
												Position_Cache_readout_position[35*3*DATA_WIDTH-1:34*3*DATA_WIDTH],
												Position_Cache_readout_position[34*3*DATA_WIDTH-1:33*3*DATA_WIDTH],
												Position_Cache_readout_position[48*3*DATA_WIDTH-1:47*3*DATA_WIDTH],
												Position_Cache_readout_position[47*3*DATA_WIDTH-1:46*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_3_4_4;
	assign cells_to_pipeline_3_4_4 = {
												Position_Cache_readout_position[49*3*DATA_WIDTH-1:48*3*DATA_WIDTH],
												Position_Cache_readout_position[52*3*DATA_WIDTH-1:51*3*DATA_WIDTH],
												Position_Cache_readout_position[51*3*DATA_WIDTH-1:50*3*DATA_WIDTH],
												Position_Cache_readout_position[61*3*DATA_WIDTH-1:60*3*DATA_WIDTH],
												Position_Cache_readout_position[64*3*DATA_WIDTH-1:63*3*DATA_WIDTH],
												Position_Cache_readout_position[63*3*DATA_WIDTH-1:62*3*DATA_WIDTH],
												Position_Cache_readout_position[57*3*DATA_WIDTH-1:56*3*DATA_WIDTH],
												Position_Cache_readout_position[60*3*DATA_WIDTH-1:59*3*DATA_WIDTH],
												Position_Cache_readout_position[59*3*DATA_WIDTH-1:58*3*DATA_WIDTH],
												Position_Cache_readout_position[33*3*DATA_WIDTH-1:32*3*DATA_WIDTH],
												Position_Cache_readout_position[36*3*DATA_WIDTH-1:35*3*DATA_WIDTH],
												Position_Cache_readout_position[35*3*DATA_WIDTH-1:34*3*DATA_WIDTH],
												Position_Cache_readout_position[45*3*DATA_WIDTH-1:44*3*DATA_WIDTH],
												Position_Cache_readout_position[48*3*DATA_WIDTH-1:47*3*DATA_WIDTH]
												};
	always@(*)
		begin
		case(cell_set_select_3_4)
			1:
				begin
				cells_to_pipeline_3_4 <= cells_to_pipeline_3_4_1;
				end
			2:
				begin
				cells_to_pipeline_3_4 <= cells_to_pipeline_3_4_2;
				end
			3:
				begin
				cells_to_pipeline_3_4 <= cells_to_pipeline_3_4_3;
				end
			4:
				begin
				cells_to_pipeline_3_4 <= cells_to_pipeline_3_4_4;
				end
			default:
				begin
				cells_to_pipeline_3_4 <= cells_to_pipeline_3_4_1;
				end
		endcase
		end
	
	// Cell selection for pipeline 4-1
	wire [CELL_ID_WIDTH-1:0] cell_set_select_4_1;
	reg [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_4_1;
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_4_1_1;
	assign cells_to_pipeline_4_1_1 = {
												Position_Cache_readout_position[6*3*DATA_WIDTH-1:5*3*DATA_WIDTH],
												Position_Cache_readout_position[5*3*DATA_WIDTH-1:4*3*DATA_WIDTH],
												Position_Cache_readout_position[8*3*DATA_WIDTH-1:7*3*DATA_WIDTH],
												Position_Cache_readout_position[2*3*DATA_WIDTH-1:1*3*DATA_WIDTH],
												Position_Cache_readout_position[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH],
												Position_Cache_readout_position[4*3*DATA_WIDTH-1:3*3*DATA_WIDTH],
												Position_Cache_readout_position[14*3*DATA_WIDTH-1:13*3*DATA_WIDTH],
												Position_Cache_readout_position[13*3*DATA_WIDTH-1:12*3*DATA_WIDTH],
												Position_Cache_readout_position[16*3*DATA_WIDTH-1:15*3*DATA_WIDTH],
												Position_Cache_readout_position[54*3*DATA_WIDTH-1:53*3*DATA_WIDTH],
												Position_Cache_readout_position[53*3*DATA_WIDTH-1:52*3*DATA_WIDTH],
												Position_Cache_readout_position[56*3*DATA_WIDTH-1:55*3*DATA_WIDTH],
												Position_Cache_readout_position[50*3*DATA_WIDTH-1:49*3*DATA_WIDTH],
												Position_Cache_readout_position[49*3*DATA_WIDTH-1:48*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_4_1_2;
	assign cells_to_pipeline_4_1_2 = {
												Position_Cache_readout_position[7*3*DATA_WIDTH-1:6*3*DATA_WIDTH],
												Position_Cache_readout_position[6*3*DATA_WIDTH-1:5*3*DATA_WIDTH],
												Position_Cache_readout_position[5*3*DATA_WIDTH-1:4*3*DATA_WIDTH],
												Position_Cache_readout_position[3*3*DATA_WIDTH-1:2*3*DATA_WIDTH],
												Position_Cache_readout_position[2*3*DATA_WIDTH-1:1*3*DATA_WIDTH],
												Position_Cache_readout_position[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH],
												Position_Cache_readout_position[15*3*DATA_WIDTH-1:14*3*DATA_WIDTH],
												Position_Cache_readout_position[14*3*DATA_WIDTH-1:13*3*DATA_WIDTH],
												Position_Cache_readout_position[13*3*DATA_WIDTH-1:12*3*DATA_WIDTH],
												Position_Cache_readout_position[55*3*DATA_WIDTH-1:54*3*DATA_WIDTH],
												Position_Cache_readout_position[54*3*DATA_WIDTH-1:53*3*DATA_WIDTH],
												Position_Cache_readout_position[53*3*DATA_WIDTH-1:52*3*DATA_WIDTH],
												Position_Cache_readout_position[51*3*DATA_WIDTH-1:50*3*DATA_WIDTH],
												Position_Cache_readout_position[50*3*DATA_WIDTH-1:49*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_4_1_3;
	assign cells_to_pipeline_4_1_3 = {
												Position_Cache_readout_position[8*3*DATA_WIDTH-1:7*3*DATA_WIDTH],
												Position_Cache_readout_position[7*3*DATA_WIDTH-1:6*3*DATA_WIDTH],
												Position_Cache_readout_position[6*3*DATA_WIDTH-1:5*3*DATA_WIDTH],
												Position_Cache_readout_position[4*3*DATA_WIDTH-1:3*3*DATA_WIDTH],
												Position_Cache_readout_position[3*3*DATA_WIDTH-1:2*3*DATA_WIDTH],
												Position_Cache_readout_position[2*3*DATA_WIDTH-1:1*3*DATA_WIDTH],
												Position_Cache_readout_position[16*3*DATA_WIDTH-1:15*3*DATA_WIDTH],
												Position_Cache_readout_position[15*3*DATA_WIDTH-1:14*3*DATA_WIDTH],
												Position_Cache_readout_position[14*3*DATA_WIDTH-1:13*3*DATA_WIDTH],
												Position_Cache_readout_position[56*3*DATA_WIDTH-1:55*3*DATA_WIDTH],
												Position_Cache_readout_position[55*3*DATA_WIDTH-1:54*3*DATA_WIDTH],
												Position_Cache_readout_position[54*3*DATA_WIDTH-1:53*3*DATA_WIDTH],
												Position_Cache_readout_position[52*3*DATA_WIDTH-1:51*3*DATA_WIDTH],
												Position_Cache_readout_position[51*3*DATA_WIDTH-1:50*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_4_1_4;
	assign cells_to_pipeline_4_1_4 = {
												Position_Cache_readout_position[5*3*DATA_WIDTH-1:4*3*DATA_WIDTH],
												Position_Cache_readout_position[8*3*DATA_WIDTH-1:7*3*DATA_WIDTH],
												Position_Cache_readout_position[7*3*DATA_WIDTH-1:6*3*DATA_WIDTH],
												Position_Cache_readout_position[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH],
												Position_Cache_readout_position[4*3*DATA_WIDTH-1:3*3*DATA_WIDTH],
												Position_Cache_readout_position[3*3*DATA_WIDTH-1:2*3*DATA_WIDTH],
												Position_Cache_readout_position[13*3*DATA_WIDTH-1:12*3*DATA_WIDTH],
												Position_Cache_readout_position[16*3*DATA_WIDTH-1:15*3*DATA_WIDTH],
												Position_Cache_readout_position[15*3*DATA_WIDTH-1:14*3*DATA_WIDTH],
												Position_Cache_readout_position[53*3*DATA_WIDTH-1:52*3*DATA_WIDTH],
												Position_Cache_readout_position[56*3*DATA_WIDTH-1:55*3*DATA_WIDTH],
												Position_Cache_readout_position[55*3*DATA_WIDTH-1:54*3*DATA_WIDTH],
												Position_Cache_readout_position[49*3*DATA_WIDTH-1:48*3*DATA_WIDTH],
												Position_Cache_readout_position[52*3*DATA_WIDTH-1:51*3*DATA_WIDTH]
												};
	always@(*)
		begin
		case(cell_set_select_4_1)
			1:
				begin
				cells_to_pipeline_4_1 <= cells_to_pipeline_4_1_1;
				end
			2:
				begin
				cells_to_pipeline_4_1 <= cells_to_pipeline_4_1_2;
				end
			3:
				begin
				cells_to_pipeline_4_1 <= cells_to_pipeline_4_1_3;
				end
			4:
				begin
				cells_to_pipeline_4_1 <= cells_to_pipeline_4_1_4;
				end
			default:
				begin
				cells_to_pipeline_4_1 <= cells_to_pipeline_4_1_1;
				end
		endcase
		end
	
	// Cell selection for pipeline 4-2
	wire [CELL_ID_WIDTH-1:0] cell_set_select_4_2;
	reg [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_4_2;
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_4_2_1;
	assign cells_to_pipeline_4_2_1 = {
												Position_Cache_readout_position[10*3*DATA_WIDTH-1:9*3*DATA_WIDTH],
												Position_Cache_readout_position[9*3*DATA_WIDTH-1:8*3*DATA_WIDTH],
												Position_Cache_readout_position[12*3*DATA_WIDTH-1:11*3*DATA_WIDTH],
												Position_Cache_readout_position[6*3*DATA_WIDTH-1:5*3*DATA_WIDTH],
												Position_Cache_readout_position[5*3*DATA_WIDTH-1:4*3*DATA_WIDTH],
												Position_Cache_readout_position[8*3*DATA_WIDTH-1:7*3*DATA_WIDTH],
												Position_Cache_readout_position[2*3*DATA_WIDTH-1:1*3*DATA_WIDTH],
												Position_Cache_readout_position[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH],
												Position_Cache_readout_position[4*3*DATA_WIDTH-1:3*3*DATA_WIDTH],
												Position_Cache_readout_position[58*3*DATA_WIDTH-1:57*3*DATA_WIDTH],
												Position_Cache_readout_position[57*3*DATA_WIDTH-1:56*3*DATA_WIDTH],
												Position_Cache_readout_position[60*3*DATA_WIDTH-1:59*3*DATA_WIDTH],
												Position_Cache_readout_position[54*3*DATA_WIDTH-1:53*3*DATA_WIDTH],
												Position_Cache_readout_position[53*3*DATA_WIDTH-1:52*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_4_2_2;
	assign cells_to_pipeline_4_2_2 = {
												Position_Cache_readout_position[11*3*DATA_WIDTH-1:10*3*DATA_WIDTH],
												Position_Cache_readout_position[10*3*DATA_WIDTH-1:9*3*DATA_WIDTH],
												Position_Cache_readout_position[9*3*DATA_WIDTH-1:8*3*DATA_WIDTH],
												Position_Cache_readout_position[7*3*DATA_WIDTH-1:6*3*DATA_WIDTH],
												Position_Cache_readout_position[6*3*DATA_WIDTH-1:5*3*DATA_WIDTH],
												Position_Cache_readout_position[5*3*DATA_WIDTH-1:4*3*DATA_WIDTH],
												Position_Cache_readout_position[3*3*DATA_WIDTH-1:2*3*DATA_WIDTH],
												Position_Cache_readout_position[2*3*DATA_WIDTH-1:1*3*DATA_WIDTH],
												Position_Cache_readout_position[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH],
												Position_Cache_readout_position[59*3*DATA_WIDTH-1:58*3*DATA_WIDTH],
												Position_Cache_readout_position[58*3*DATA_WIDTH-1:57*3*DATA_WIDTH],
												Position_Cache_readout_position[57*3*DATA_WIDTH-1:56*3*DATA_WIDTH],
												Position_Cache_readout_position[55*3*DATA_WIDTH-1:54*3*DATA_WIDTH],
												Position_Cache_readout_position[54*3*DATA_WIDTH-1:53*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_4_2_3;
	assign cells_to_pipeline_4_2_3 = {
												Position_Cache_readout_position[12*3*DATA_WIDTH-1:11*3*DATA_WIDTH],
												Position_Cache_readout_position[11*3*DATA_WIDTH-1:10*3*DATA_WIDTH],
												Position_Cache_readout_position[10*3*DATA_WIDTH-1:9*3*DATA_WIDTH],
												Position_Cache_readout_position[8*3*DATA_WIDTH-1:7*3*DATA_WIDTH],
												Position_Cache_readout_position[7*3*DATA_WIDTH-1:6*3*DATA_WIDTH],
												Position_Cache_readout_position[6*3*DATA_WIDTH-1:5*3*DATA_WIDTH],
												Position_Cache_readout_position[4*3*DATA_WIDTH-1:3*3*DATA_WIDTH],
												Position_Cache_readout_position[3*3*DATA_WIDTH-1:2*3*DATA_WIDTH],
												Position_Cache_readout_position[2*3*DATA_WIDTH-1:1*3*DATA_WIDTH],
												Position_Cache_readout_position[60*3*DATA_WIDTH-1:59*3*DATA_WIDTH],
												Position_Cache_readout_position[59*3*DATA_WIDTH-1:58*3*DATA_WIDTH],
												Position_Cache_readout_position[58*3*DATA_WIDTH-1:57*3*DATA_WIDTH],
												Position_Cache_readout_position[56*3*DATA_WIDTH-1:55*3*DATA_WIDTH],
												Position_Cache_readout_position[55*3*DATA_WIDTH-1:54*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_4_2_4;
	assign cells_to_pipeline_4_2_4 = {
												Position_Cache_readout_position[9*3*DATA_WIDTH-1:8*3*DATA_WIDTH],
												Position_Cache_readout_position[12*3*DATA_WIDTH-1:11*3*DATA_WIDTH],
												Position_Cache_readout_position[11*3*DATA_WIDTH-1:10*3*DATA_WIDTH],
												Position_Cache_readout_position[5*3*DATA_WIDTH-1:4*3*DATA_WIDTH],
												Position_Cache_readout_position[8*3*DATA_WIDTH-1:7*3*DATA_WIDTH],
												Position_Cache_readout_position[7*3*DATA_WIDTH-1:6*3*DATA_WIDTH],
												Position_Cache_readout_position[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH],
												Position_Cache_readout_position[4*3*DATA_WIDTH-1:3*3*DATA_WIDTH],
												Position_Cache_readout_position[3*3*DATA_WIDTH-1:2*3*DATA_WIDTH],
												Position_Cache_readout_position[57*3*DATA_WIDTH-1:56*3*DATA_WIDTH],
												Position_Cache_readout_position[60*3*DATA_WIDTH-1:59*3*DATA_WIDTH],
												Position_Cache_readout_position[59*3*DATA_WIDTH-1:58*3*DATA_WIDTH],
												Position_Cache_readout_position[53*3*DATA_WIDTH-1:52*3*DATA_WIDTH],
												Position_Cache_readout_position[56*3*DATA_WIDTH-1:55*3*DATA_WIDTH]
												};
	always@(*)
		begin
		case(cell_set_select_4_2)
			1:
				begin
				cells_to_pipeline_4_2 <= cells_to_pipeline_4_2_1;
				end
			2:
				begin
				cells_to_pipeline_4_2 <= cells_to_pipeline_4_2_2;
				end
			3:
				begin
				cells_to_pipeline_4_2 <= cells_to_pipeline_4_2_3;
				end
			4:
				begin
				cells_to_pipeline_4_2 <= cells_to_pipeline_4_2_4;
				end
			default:
				begin
				cells_to_pipeline_4_2 <= cells_to_pipeline_4_2_1;
				end
		endcase
		end
	
	// Cell selection for pipeline 4-3
	wire [CELL_ID_WIDTH-1:0] cell_set_select_4_3;
	reg [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_4_3;
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_4_3_1;
	assign cells_to_pipeline_4_3_1 = {
												Position_Cache_readout_position[14*3*DATA_WIDTH-1:13*3*DATA_WIDTH],
												Position_Cache_readout_position[13*3*DATA_WIDTH-1:12*3*DATA_WIDTH],
												Position_Cache_readout_position[16*3*DATA_WIDTH-1:15*3*DATA_WIDTH],
												Position_Cache_readout_position[10*3*DATA_WIDTH-1:9*3*DATA_WIDTH],
												Position_Cache_readout_position[9*3*DATA_WIDTH-1:8*3*DATA_WIDTH],
												Position_Cache_readout_position[12*3*DATA_WIDTH-1:11*3*DATA_WIDTH],
												Position_Cache_readout_position[6*3*DATA_WIDTH-1:5*3*DATA_WIDTH],
												Position_Cache_readout_position[5*3*DATA_WIDTH-1:4*3*DATA_WIDTH],
												Position_Cache_readout_position[8*3*DATA_WIDTH-1:7*3*DATA_WIDTH],
												Position_Cache_readout_position[62*3*DATA_WIDTH-1:61*3*DATA_WIDTH],
												Position_Cache_readout_position[61*3*DATA_WIDTH-1:60*3*DATA_WIDTH],
												Position_Cache_readout_position[64*3*DATA_WIDTH-1:63*3*DATA_WIDTH],
												Position_Cache_readout_position[58*3*DATA_WIDTH-1:57*3*DATA_WIDTH],
												Position_Cache_readout_position[57*3*DATA_WIDTH-1:56*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_4_3_2;
	assign cells_to_pipeline_4_3_2 = {
												Position_Cache_readout_position[15*3*DATA_WIDTH-1:14*3*DATA_WIDTH],
												Position_Cache_readout_position[14*3*DATA_WIDTH-1:13*3*DATA_WIDTH],
												Position_Cache_readout_position[13*3*DATA_WIDTH-1:12*3*DATA_WIDTH],
												Position_Cache_readout_position[11*3*DATA_WIDTH-1:10*3*DATA_WIDTH],
												Position_Cache_readout_position[10*3*DATA_WIDTH-1:9*3*DATA_WIDTH],
												Position_Cache_readout_position[9*3*DATA_WIDTH-1:8*3*DATA_WIDTH],
												Position_Cache_readout_position[7*3*DATA_WIDTH-1:6*3*DATA_WIDTH],
												Position_Cache_readout_position[6*3*DATA_WIDTH-1:5*3*DATA_WIDTH],
												Position_Cache_readout_position[5*3*DATA_WIDTH-1:4*3*DATA_WIDTH],
												Position_Cache_readout_position[63*3*DATA_WIDTH-1:62*3*DATA_WIDTH],
												Position_Cache_readout_position[62*3*DATA_WIDTH-1:61*3*DATA_WIDTH],
												Position_Cache_readout_position[61*3*DATA_WIDTH-1:60*3*DATA_WIDTH],
												Position_Cache_readout_position[59*3*DATA_WIDTH-1:58*3*DATA_WIDTH],
												Position_Cache_readout_position[58*3*DATA_WIDTH-1:57*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_4_3_3;
	assign cells_to_pipeline_4_3_3 = {
												Position_Cache_readout_position[16*3*DATA_WIDTH-1:15*3*DATA_WIDTH],
												Position_Cache_readout_position[15*3*DATA_WIDTH-1:14*3*DATA_WIDTH],
												Position_Cache_readout_position[14*3*DATA_WIDTH-1:13*3*DATA_WIDTH],
												Position_Cache_readout_position[12*3*DATA_WIDTH-1:11*3*DATA_WIDTH],
												Position_Cache_readout_position[11*3*DATA_WIDTH-1:10*3*DATA_WIDTH],
												Position_Cache_readout_position[10*3*DATA_WIDTH-1:9*3*DATA_WIDTH],
												Position_Cache_readout_position[8*3*DATA_WIDTH-1:7*3*DATA_WIDTH],
												Position_Cache_readout_position[7*3*DATA_WIDTH-1:6*3*DATA_WIDTH],
												Position_Cache_readout_position[6*3*DATA_WIDTH-1:5*3*DATA_WIDTH],
												Position_Cache_readout_position[64*3*DATA_WIDTH-1:63*3*DATA_WIDTH],
												Position_Cache_readout_position[63*3*DATA_WIDTH-1:62*3*DATA_WIDTH],
												Position_Cache_readout_position[62*3*DATA_WIDTH-1:61*3*DATA_WIDTH],
												Position_Cache_readout_position[60*3*DATA_WIDTH-1:59*3*DATA_WIDTH],
												Position_Cache_readout_position[59*3*DATA_WIDTH-1:58*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_4_3_4;
	assign cells_to_pipeline_4_3_4 = {
												Position_Cache_readout_position[13*3*DATA_WIDTH-1:12*3*DATA_WIDTH],
												Position_Cache_readout_position[16*3*DATA_WIDTH-1:15*3*DATA_WIDTH],
												Position_Cache_readout_position[15*3*DATA_WIDTH-1:14*3*DATA_WIDTH],
												Position_Cache_readout_position[9*3*DATA_WIDTH-1:8*3*DATA_WIDTH],
												Position_Cache_readout_position[12*3*DATA_WIDTH-1:11*3*DATA_WIDTH],
												Position_Cache_readout_position[11*3*DATA_WIDTH-1:10*3*DATA_WIDTH],
												Position_Cache_readout_position[5*3*DATA_WIDTH-1:4*3*DATA_WIDTH],
												Position_Cache_readout_position[8*3*DATA_WIDTH-1:7*3*DATA_WIDTH],
												Position_Cache_readout_position[7*3*DATA_WIDTH-1:6*3*DATA_WIDTH],
												Position_Cache_readout_position[61*3*DATA_WIDTH-1:60*3*DATA_WIDTH],
												Position_Cache_readout_position[64*3*DATA_WIDTH-1:63*3*DATA_WIDTH],
												Position_Cache_readout_position[63*3*DATA_WIDTH-1:62*3*DATA_WIDTH],
												Position_Cache_readout_position[57*3*DATA_WIDTH-1:56*3*DATA_WIDTH],
												Position_Cache_readout_position[60*3*DATA_WIDTH-1:59*3*DATA_WIDTH]
												};
	always@(*)
		begin
		case(cell_set_select_4_3)
			1:
				begin
				cells_to_pipeline_4_3 <= cells_to_pipeline_4_3_1;
				end
			2:
				begin
				cells_to_pipeline_4_3 <= cells_to_pipeline_4_3_2;
				end
			3:
				begin
				cells_to_pipeline_4_3 <= cells_to_pipeline_4_3_3;
				end
			4:
				begin
				cells_to_pipeline_4_3 <= cells_to_pipeline_4_3_4;
				end
			default:
				begin
				cells_to_pipeline_4_3 <= cells_to_pipeline_4_3_1;
				end
		endcase
		end
	
	// Cell selection for pipeline 4-4
	wire [CELL_ID_WIDTH-1:0] cell_set_select_4_4;
	reg [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_4_4;
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_4_4_1;
	assign cells_to_pipeline_4_4_1 = {
												Position_Cache_readout_position[2*3*DATA_WIDTH-1:1*3*DATA_WIDTH],
												Position_Cache_readout_position[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH],
												Position_Cache_readout_position[4*3*DATA_WIDTH-1:3*3*DATA_WIDTH],
												Position_Cache_readout_position[14*3*DATA_WIDTH-1:13*3*DATA_WIDTH],
												Position_Cache_readout_position[13*3*DATA_WIDTH-1:12*3*DATA_WIDTH],
												Position_Cache_readout_position[16*3*DATA_WIDTH-1:15*3*DATA_WIDTH],
												Position_Cache_readout_position[10*3*DATA_WIDTH-1:9*3*DATA_WIDTH],
												Position_Cache_readout_position[9*3*DATA_WIDTH-1:8*3*DATA_WIDTH],
												Position_Cache_readout_position[12*3*DATA_WIDTH-1:11*3*DATA_WIDTH],
												Position_Cache_readout_position[50*3*DATA_WIDTH-1:49*3*DATA_WIDTH],
												Position_Cache_readout_position[49*3*DATA_WIDTH-1:48*3*DATA_WIDTH],
												Position_Cache_readout_position[52*3*DATA_WIDTH-1:51*3*DATA_WIDTH],
												Position_Cache_readout_position[62*3*DATA_WIDTH-1:61*3*DATA_WIDTH],
												Position_Cache_readout_position[61*3*DATA_WIDTH-1:60*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_4_4_2;
	assign cells_to_pipeline_4_4_2 = {
												Position_Cache_readout_position[3*3*DATA_WIDTH-1:2*3*DATA_WIDTH],
												Position_Cache_readout_position[2*3*DATA_WIDTH-1:1*3*DATA_WIDTH],
												Position_Cache_readout_position[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH],
												Position_Cache_readout_position[15*3*DATA_WIDTH-1:14*3*DATA_WIDTH],
												Position_Cache_readout_position[14*3*DATA_WIDTH-1:13*3*DATA_WIDTH],
												Position_Cache_readout_position[13*3*DATA_WIDTH-1:12*3*DATA_WIDTH],
												Position_Cache_readout_position[11*3*DATA_WIDTH-1:10*3*DATA_WIDTH],
												Position_Cache_readout_position[10*3*DATA_WIDTH-1:9*3*DATA_WIDTH],
												Position_Cache_readout_position[9*3*DATA_WIDTH-1:8*3*DATA_WIDTH],
												Position_Cache_readout_position[51*3*DATA_WIDTH-1:50*3*DATA_WIDTH],
												Position_Cache_readout_position[50*3*DATA_WIDTH-1:49*3*DATA_WIDTH],
												Position_Cache_readout_position[49*3*DATA_WIDTH-1:48*3*DATA_WIDTH],
												Position_Cache_readout_position[63*3*DATA_WIDTH-1:62*3*DATA_WIDTH],
												Position_Cache_readout_position[62*3*DATA_WIDTH-1:61*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_4_4_3;
	assign cells_to_pipeline_4_4_3 = {
												Position_Cache_readout_position[4*3*DATA_WIDTH-1:3*3*DATA_WIDTH],
												Position_Cache_readout_position[3*3*DATA_WIDTH-1:2*3*DATA_WIDTH],
												Position_Cache_readout_position[2*3*DATA_WIDTH-1:1*3*DATA_WIDTH],
												Position_Cache_readout_position[16*3*DATA_WIDTH-1:15*3*DATA_WIDTH],
												Position_Cache_readout_position[15*3*DATA_WIDTH-1:14*3*DATA_WIDTH],
												Position_Cache_readout_position[14*3*DATA_WIDTH-1:13*3*DATA_WIDTH],
												Position_Cache_readout_position[12*3*DATA_WIDTH-1:11*3*DATA_WIDTH],
												Position_Cache_readout_position[11*3*DATA_WIDTH-1:10*3*DATA_WIDTH],
												Position_Cache_readout_position[10*3*DATA_WIDTH-1:9*3*DATA_WIDTH],
												Position_Cache_readout_position[52*3*DATA_WIDTH-1:51*3*DATA_WIDTH],
												Position_Cache_readout_position[51*3*DATA_WIDTH-1:50*3*DATA_WIDTH],
												Position_Cache_readout_position[50*3*DATA_WIDTH-1:49*3*DATA_WIDTH],
												Position_Cache_readout_position[64*3*DATA_WIDTH-1:63*3*DATA_WIDTH],
												Position_Cache_readout_position[63*3*DATA_WIDTH-1:62*3*DATA_WIDTH]
												};
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_4_4_4;
	assign cells_to_pipeline_4_4_4 = {
												Position_Cache_readout_position[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH],
												Position_Cache_readout_position[4*3*DATA_WIDTH-1:3*3*DATA_WIDTH],
												Position_Cache_readout_position[3*3*DATA_WIDTH-1:2*3*DATA_WIDTH],
												Position_Cache_readout_position[13*3*DATA_WIDTH-1:12*3*DATA_WIDTH],
												Position_Cache_readout_position[16*3*DATA_WIDTH-1:15*3*DATA_WIDTH],
												Position_Cache_readout_position[15*3*DATA_WIDTH-1:14*3*DATA_WIDTH],
												Position_Cache_readout_position[9*3*DATA_WIDTH-1:8*3*DATA_WIDTH],
												Position_Cache_readout_position[12*3*DATA_WIDTH-1:11*3*DATA_WIDTH],
												Position_Cache_readout_position[11*3*DATA_WIDTH-1:10*3*DATA_WIDTH],
												Position_Cache_readout_position[49*3*DATA_WIDTH-1:48*3*DATA_WIDTH],
												Position_Cache_readout_position[52*3*DATA_WIDTH-1:51*3*DATA_WIDTH],
												Position_Cache_readout_position[51*3*DATA_WIDTH-1:50*3*DATA_WIDTH],
												Position_Cache_readout_position[61*3*DATA_WIDTH-1:60*3*DATA_WIDTH],
												Position_Cache_readout_position[64*3*DATA_WIDTH-1:63*3*DATA_WIDTH]
												};
	always@(*)
		begin
		case(cell_set_select_4_4)
			1:
				begin
				cells_to_pipeline_4_4 <= cells_to_pipeline_4_4_1;
				end
			2:
				begin
				cells_to_pipeline_4_4 <= cells_to_pipeline_4_4_2;
				end
			3:
				begin
				cells_to_pipeline_4_4 <= cells_to_pipeline_4_4_3;
				end
			4:
				begin
				cells_to_pipeline_4_4 <= cells_to_pipeline_4_4_4;
				end
			default:
				begin
				cells_to_pipeline_4_4 <= cells_to_pipeline_4_4_1;
				end
		endcase
		end