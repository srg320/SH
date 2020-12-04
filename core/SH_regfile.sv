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
	
	reg [31:0]  GR[16+1];
	
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			GR <= '{'h01234567,'h11111111,'h89ABCDEF,'h11111111,'0,'0,'0,'0,'0,'0,'0,'0,'0,'0,'0,'0,'0};
		end
		else if (CE) begin
			if (WAE) begin
				GR[WA_ADDR] <= WA_D;
			end
			if (WBE) begin
				GR[WB_ADDR] <= WB_D;
			end
		end
	end


	assign RA_Q = GR[RA_ADDR];
	assign RB_Q = GR[RB_ADDR];
	assign R0_Q = GR[0];
	
endmodule
