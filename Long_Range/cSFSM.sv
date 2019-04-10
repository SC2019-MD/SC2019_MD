module cSFSM(
	clk, 
	rst, 
	start_sig, 
	
	CMAPwen,
	Forcewen,
	CA_BI,	
	memSel,
	memAddr,	
	selD,		
	dim,	
	particleCacheAddr,

	// signals for reading nios memory
	user_data_available,

	// FFT signals
	FFTsop,
	FFTeop,
	FFTsinkValid,
	FFTsourceValid,
	FFTdirection
);

//parameter MEMORY_MAX = 65535*4;
parameter MEMORY_MAX = 4096*4;
parameter FFTCALC = 1024;
localparam DELAY_50 = 50;
localparam DELAY_128 = 128;


input clk;
input rst;
input start_sig;

output logic CMAPwen;							// wen for charge mapping with a once cycles delay
output logic Forcewen;							// wen for charge mapping with a once cycles delay
output logic [1:0] CA_BI;						// select coefficients between charge mapping 00 and back interpolation 01, 10, 11
output logic [1:0] memSel;						// select between idle, cMAP, FFT, FFT+greens
output logic [10:0] memAddr;					// FFT and BI read Address 
output logic [1:0] selD;							// FFT mux sel. 
output logic [2:0] dim;							// FFT Dimension Select
output logic [14:0] particleCacheAddr;

/*        FFT signals          */
output logic FFTsop;							// start frame signal for FFT modules - generate after 1 cycle delay
output logic FFTeop; 							// end frame signal for FFT modules - generate after 1 cycles delay
output logic FFTsinkValid;						// start FFT operation - generate when generating the first sop
output logic FFTsourceValid;					// set to 1 when setting resetn to 1
output logic FFTdirection;						// 0 for FFT, 1 for iFFT. used to reverse real img parts and add divider to path

input user_data_available;

integer count;

enum {IDLE, 
		READ_DB_START, READ_WAIT_DB, READING_DB, DELAY_DB,
		FFTX, DELAY_FFTX,
		FFTY, DELAY_FFTY,
		FFTZ, DELAY_FFTZ,
		IFFTX, DELAY_IFFTX,
		IFFTY, DELAY_IFFTY,
		IFFTZ, DELAY_IFFTZ,
		BIX_START, BIX, DELAY_BIX,
		BIY_START, BIY, DELAY_BIY,
		BIZ_START, BIZ, DELAY_BIZ,
		WRITE_BACK
} state, next_state;


assign control_base = 0;

always_ff @ (posedge clk)
begin
	if (rst)
	begin
		state <= IDLE;
	end
	else
	begin
		state <= next_state;
	end
end

always_ff @ (posedge clk)
begin
	if (rst)
		count <= 0;
	else
	begin
		case (state)
		IDLE, READ_DB_START, READ_WAIT_DB:
			count <= 0;

		READING_DB:
			count <= count + 1;

		DELAY_DB:
		begin
			if (count >= MEMORY_MAX+DELAY_50)
				count <= 0;
			else
				count <= count + 1;

		end
		FFTX: 
		begin
				count <= count + 1;
		end
		DELAY_FFTX: 
		begin
			if (count >= FFTCALC+DELAY_128)
				count <= 0;
			else
				count <= count + 1;
		end
		FFTY:
		begin
				count <= count + 1;
		end
		DELAY_FFTY:
		begin
			if (count >= FFTCALC+DELAY_128)
				count <= 0;
			else
				count <= count + 1;
		end
		FFTZ:
		begin
				count <= count + 1;
		end
		DELAY_FFTZ:
		begin
			if (count >= FFTCALC+DELAY_128)
				count <= 0;
			else
				count <= count + 1;
		end
		IFFTX:
		begin
				count <= count + 1;
		end
		DELAY_IFFTX:
		begin
			if (count >= FFTCALC+DELAY_128)
				count <= 0;
			else
				count <= count + 1;
		end
		IFFTY:
		begin
				count <= count + 1;
		end
		DELAY_IFFTY:
		begin
			if (count >= FFTCALC+DELAY_128)
				count <= 0;
			else
				count <= count + 1;
		end
		IFFTZ:
		begin
				count <= count + 1;
		end
		DELAY_IFFTZ:
		begin
			if (count >= FFTCALC+DELAY_128)
				count <= 0;
			else
				count <= count + 1;
		end
		BIX_START:
		begin
				count <= 0;
		end
		BIX:
		begin
				count <= count + 1;
		end
		DELAY_BIX:
		begin
			if (count >= MEMORY_MAX+DELAY_50)
				count <= 0;
			else
				count <= count + 1;
		end
		endcase
	end	
end

always_comb
begin
		next_state <= state;
		
		case (state)
		IDLE:
			if (start_sig) next_state <= READ_DB_START;

		READ_DB_START:
			next_state <= READ_WAIT_DB;

		READ_WAIT_DB:
			if (user_data_available) next_state <= READING_DB;

		READING_DB:
			if (count >= MEMORY_MAX) next_state <= DELAY_DB;

		DELAY_DB:
			if (count >= MEMORY_MAX+DELAY_50) next_state <= FFTX;

		FFTX:
			if (count >= FFTCALC) next_state <= DELAY_FFTX;

		DELAY_FFTX:
			if (count >= FFTCALC+DELAY_128) next_state <= FFTY;

		FFTY:
			if (count >= FFTCALC) next_state <= DELAY_FFTY;

		DELAY_FFTY:
			if (count >= FFTCALC+DELAY_128) next_state <= FFTZ;

		FFTZ:
			if (count >= FFTCALC) next_state <= DELAY_FFTZ;

		DELAY_FFTZ:
			if (count >= FFTCALC+DELAY_128) next_state <= IFFTX;

		IFFTX:
			if (count >= FFTCALC) next_state <= DELAY_IFFTX;

		DELAY_IFFTX:
			if (count >= FFTCALC+DELAY_128) next_state <= IFFTY;

		IFFTY:
			if (count >= FFTCALC) next_state <= DELAY_IFFTY;

		DELAY_IFFTY:
			if (count >= FFTCALC+DELAY_128) next_state <= IFFTZ;

		IFFTZ:
			if (count >= FFTCALC) next_state <= DELAY_IFFTZ;

		DELAY_IFFTZ:
			if (count >= FFTCALC+DELAY_128) next_state <= BIX_START;

		BIX_START:
			if (user_data_available) next_state <= BIX;

		BIX:
			if (count >= MEMORY_MAX) next_state <= DELAY_BIX;

		DELAY_BIX:
			if (count >= MEMORY_MAX+DELAY_50) next_state <= IDLE;

		endcase
end


always_comb 
begin
	CMAPwen <= 1'b0;						// wen for charge mapping
	Forcewen<= 1'b0;						// wen for force
	CA_BI <= 2'b00;						// select coefficients between charge mapping and back interpolation
	memSel <= 2'b00;					// select between idle, cMAP, FFT, FFT+greens
	dim <= 3'b000;						// FFT Dimension Select
	memAddr <= 0;
	particleCacheAddr <= 0;

	FFTsop <= 1'b0;						// start frame signal for FFT modules - generate after 1 cycle delay
	FFTeop <= 1'b0;						// end frame signal for FFT modules - generate after 1 cycles delay
	FFTsinkValid <= 1'b0;				// start FFT operation - generate when generating the first sop
	FFTsourceValid <= 1'b0;				// set to 1 when setting resetn to 1
	FFTdirection <= 1'b0;				// 0 for FFT, 1 for iFFT. used to reverse real img parts and add divider to path

	selD <= count[1:0];

		case (state)
		READ_DB_START:
		begin
		end

		READING_DB:
		begin
			CMAPwen <= 1'b1;					// wen for charge mapping
			memSel <= 2'b01;					// select between idle, cMAP, FFT, FFT+greens
			particleCacheAddr <= count[14:0];
		end

		DELAY_DB:
		begin
			memSel <= 2'b01;						// select between idle, cMAP, FFT, FFT+greens
		end

		FFTX:
		begin
			memSel <= 2'b10;						// select between idle, cMAP, FFT, FFT+greens

			dim <= 3'b001;							// FFT Dimension Select

			memAddr <= count[10:0];

			// FFT Signals
			FFTsinkValid <= 1;
			FFTsourceValid <= 1'b1;					// set to 1 when setting resetn to 1
			if (count[4:0] == 5'b00000)
				FFTsop <= 1'b1;								// start frame signal for FFT modules - generate after 1 cycle delay
			else
				FFTsop <= 1'b0;

			if (count[4:0] == 5'b11111)
				FFTeop <= 1'b1; 							// end frame signal for FFT modules - generate after 1 cycles delay
			else
				FFTeop <= 1'b0;


		end

		DELAY_FFTX:
		begin
			memSel <= 2'b10;						// select between idle, cMAP, FFT, FFT+greens
			dim <= 3'b001;							// FFT Dimension Select

			memAddr <= 0;
			
			// FFT Signals
			FFTsourceValid <= 1'b1;					// set to 1 when setting resetn to 1
		end

		FFTY:
		begin
			memSel <= 2'b10;						// select between idle, cMAP, FFT, FFT+greens

			dim <= 3'b010;							// FFT Dimension Select

			memAddr <= count[10:0];

			// FFT Signals
			FFTsinkValid <= 1;
			FFTsourceValid <= 1'b1;					// set to 1 when setting resetn to 1
			if (count[4:0] == 5'b00000)
				FFTsop <= 1'b1;								// start frame signal for FFT modules - generate after 1 cycle delay
			else
				FFTsop <= 1'b0;

			if (count[4:0] == 5'b11111)
				FFTeop <= 1'b1; 							// end frame signal for FFT modules - generate after 1 cycles delay
			else
				FFTeop <= 1'b0;

		end

		DELAY_FFTY:
		begin
			memSel <= 2'b10;						// select between idle, cMAP, FFT, FFT+greens
			dim <= 3'b010;							// FFT Dimension Select

			memAddr <= 0;

			// FFT Signals
			FFTsourceValid <= 1'b1;					// set to 1 when setting resetn to 1
		end

		FFTZ:
		begin
			memSel <= 2'b11;						// select between idle, cMAP, FFT, FFT+greens

			dim <= 3'b100;							// FFT Dimension Select

			memAddr <= count[10:0];

			// FFT Signals
			FFTsinkValid <= 1;
			FFTsourceValid <= 1'b1;					// set to 1 when setting resetn to 1
			if (count[4:0] == 5'b00000)
				FFTsop <= 1'b1;								// start frame signal for FFT modules - generate after 1 cycle delay
			else
				FFTsop <= 1'b0;

			if (count[4:0] == 5'b11111)
				FFTeop <= 1'b1; 							// end frame signal for FFT modules - generate after 1 cycles delay
			else
				FFTeop <= 1'b0;

		end

		DELAY_FFTZ:
		begin
			memSel <= 2'b11;						// select between idle, cMAP, FFT, FFT+greens
			dim <= 3'b100;							// FFT Dimension Select

			memAddr <= count[10:0];

			// FFT Signals
			FFTsourceValid <= 1'b1;					// set to 1 when setting resetn to 1
		end

		IFFTX:
		begin
			memSel <= 2'b10;						// select between idle, cMAP, FFT, FFT+greens

			dim <= 3'b001;							// FFT Dimension Select

			memAddr <= count[10:0];
			
			// FFT Signals
			FFTsinkValid <= 1;
			FFTsourceValid <= 1'b1;					// set to 1 when setting resetn to 1
			FFTdirection <= 1'b1;
			if (count[4:0] == 5'b00000)
				FFTsop <= 1'b1;								// start frame signal for FFT modules - generate after 1 cycle delay
			else
				FFTsop <= 1'b0;

			if (count[4:0] == 5'b11111)
				FFTeop <= 1'b1; 							// end frame signal for FFT modules - generate after 1 cycles delay
			else
				FFTeop <= 1'b0;
		end

		DELAY_IFFTX:
		begin
			memSel <= 2'b10;						// select between idle, cMAP, FFT, FFT+greens
			dim <= 3'b001;							// FFT Dimension Select

			memAddr <= count[10:0];

			// FFT Signals
			FFTsourceValid <= 1'b1;					// set to 1 when setting resetn to 1
		end

		IFFTY:
		begin
			memSel <= 2'b10;						// select between idle, cMAP, FFT, FFT+greens

			dim <= 3'b010;							// FFT Dimension Select

			memAddr <= count[10:0];

			// FFT Signals
			FFTsinkValid <= 1;
			FFTsourceValid <= 1'b1;					// set to 1 when setting resetn to 1
			FFTdirection <= 1'b1;
			if (count[4:0] == 5'b00000)
				FFTsop <= 1'b1;								// start frame signal for FFT modules - generate after 1 cycle delay
			else
				FFTsop <= 1'b0;

			if (count[4:0] == 5'b11111)
				FFTeop <= 1'b1; 							// end frame signal for FFT modules - generate after 1 cycles delay
			else
				FFTeop <= 1'b0;
		end

		DELAY_IFFTY:
		begin
			memSel <= 2'b10;						// select between idle, cMAP, FFT, FFT+greens
			dim <= 3'b010;							// FFT Dimension Select

			memAddr <= count[10:0];

			// FFT Signals
			FFTsourceValid <= 1'b1;					// set to 1 when setting resetn to 1
		end

		IFFTZ:
		begin
			memSel <= 2'b10;						// select between idle, cMAP, FFT, FFT+greens

			dim <= 3'b100;							// FFT Dimension Select

			memAddr <= count[10:0];

			// FFT Signals
			FFTsinkValid <= 1;
			FFTsourceValid <= 1'b1;					// set to 1 when setting resetn to 1
			FFTdirection <= 1'b1;
			if (count[4:0] == 5'b00000)
				FFTsop <= 1'b1;								// start frame signal for FFT modules - generate after 1 cycle delay
			else
				FFTsop <= 1'b0;

			if (count[4:0] == 5'b11111)
				FFTeop <= 1'b1; 							// end frame signal for FFT modules - generate after 1 cycles delay
			else
				FFTeop <= 1'b0;
		end

		DELAY_IFFTZ:
		begin
			memSel <= 2'b10;						// select between idle, cMAP, FFT, FFT+greens
			dim <= 3'b100;							// FFT Dimension Select

			memAddr <= count[10:0];

			// FFT Signals
			FFTsourceValid <= 1'b1;					// set to 1 when setting resetn to 1
		end

		BIX_START:
		begin
		end

		BIX:
		begin
			//CMAPwen <= 1'b1;					// wen for charge mapping
			memSel <= 2'b01;						// select between idle, cMAP, FFT, FFT+greens
			particleCacheAddr <= count[14:0];
		end

		DELAY_BIX:
		begin
			memSel <= 2'b01;						// select between idle, cMAP, FFT, FFT+greens

		end
		endcase
end


endmodule
