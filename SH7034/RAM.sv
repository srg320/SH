module SH7034_RAM 
(
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	
	input      [27:0] IBUS_A,
	input      [31:0] IBUS_DI,
	output     [31:0] IBUS_DO,
	input       [3:0] IBUS_BA,
	input             IBUS_WE,
	input             IBUS_REQ,
	output            IBUS_BUSY,
	output            IBUS_ACT
);
	
	wire RAM_SEL = (IBUS_A[27:24] == 4'hF);
	
	bit  [31:0] RAM_Q;
	wire [31:0] RAM_D = {IBUS_BA[3] ? IBUS_DI[31:24] : RAM_Q[31:24],
	                     IBUS_BA[2] ? IBUS_DI[23:16] : RAM_Q[23:16],
								IBUS_BA[1] ? IBUS_DI[15: 8] : RAM_Q[15: 8],
								IBUS_BA[0] ? IBUS_DI[ 7: 0] : RAM_Q[ 7: 0]};
	CPU_RAM cpu_ram
	(
		.clock(CLK),
		.wraddress(IBUS_A[11:2]),
		.data(RAM_D),
		.wren(IBUS_WE & RAM_SEL & CE_R),
		.rdaddress(IBUS_A[11:2]),
		.q(RAM_Q)
	);
	
	assign IBUS_DO = RAM_Q;
	assign IBUS_BUSY = 0;
	assign IBUS_ACT = RAM_SEL;
	
endmodule
