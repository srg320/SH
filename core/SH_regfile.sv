module SH2_regfile (
	input             CLK,
	input             RST_N,
	input             CE,
	
	input       [4:0] WA_ADDR,
	input      [31:0] WA_D,
	input             WAE,
	input       [4:0] WB_ADDR,
	input      [31:0] WB_D,
	input             WBE,
	
	input       [4:0] RA_ADDR,
	output     [31:0] RA_Q,
	input       [4:0] RB_ADDR,
	output     [31:0] RB_Q,
	output     [31:0] R0_Q
	
);
	
	// synopsys translate_off
	`define SIM
	// synopsys translate_on
	
`ifdef SIM

	reg [31:0]  GR[16+1];
	
	bit  [4:0] WB_ADDR_SAVE;
	bit [31:0] WB_D_SAVE;
	bit        WBE_SAVE;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			WB_ADDR_SAVE <= '0;
			WB_D_SAVE <= '0;
			WBE_SAVE <= 0;
		end
		else begin
			WBE_SAVE <= 0;
			if (CE) begin
				WB_ADDR_SAVE <= WB_ADDR;
				WB_D_SAVE <= WB_D;
				WBE_SAVE <= WBE;
			end
		end
	end
	
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			GR <= '{'h01234567,'h11111111,'h89ABCDEF,'h11111111,'0,'0,'0,'0,'0,'0,'0,'0,'0,'0,'0,'0,'0};
		end
		else  begin
			if (WAE && CE) begin
				GR[WA_ADDR] <= WA_D;
			end
			if (WBE_SAVE) begin
				GR[WB_ADDR_SAVE] <= WB_D_SAVE;
			end
		end
	end

	assign RA_Q = GR[RA_ADDR];
	assign RB_Q = GR[RB_ADDR];
	
	reg [31:0] GR0;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			GR0 <= '0;
		end
		else if (CE) begin
			if (WAE && !WA_ADDR) begin
				GR0 <= WA_D;
			end
			if (WBE && !WB_ADDR) begin
				GR0 <= WB_D;
			end
		end
	end
	
	assign R0_Q = GR0;
	
`else
	
	bit  [4:0] WB_ADDR_SAVE;
	bit [31:0] WB_D_SAVE;
	bit        WBE_SAVE;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			WB_ADDR_SAVE <= '0;
			WB_D_SAVE <= '0;
			WBE_SAVE <= 0;
		end
		else begin
			WBE_SAVE <= 0;
			if (CE) begin
				WB_ADDR_SAVE <= WB_ADDR;
				WB_D_SAVE <= WB_D;
				WBE_SAVE <= WBE;
			end
		end
	end
	
	wire [4:0] REG_WR_A = CE ? WA_ADDR : WB_ADDR_SAVE;
	wire [31:0] REG_D = CE ? WA_D : WB_D_SAVE;
	wire REG_WE = (WAE & CE) | WBE_SAVE;
	SH_regram regramA(.clock(CLK), .wraddress(REG_WR_A), .data(REG_D), .wren(REG_WE), .rdaddress(RA_ADDR), .q(RA_Q));
	SH_regram regramB(.clock(CLK), .wraddress(REG_WR_A), .data(REG_D), .wren(REG_WE), .rdaddress(RB_ADDR), .q(RB_Q));
	
	reg [31:0] GR0;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			GR0 <= '0;
		end
		else if (CE) begin
			if (WAE && !WA_ADDR) begin
				GR0 <= WA_D;
			end
			if (WBE && !WB_ADDR) begin
				GR0 <= WB_D;
			end
		end
	end

	assign R0_Q = GR0;
	
`endif
	
endmodule
