import CPU_PKG::*;

module MULT (
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	
	input             RES_N,
	
	input      [31:0] CBUS_A,
	input      [31:0] CBUS_DI,
	output     [31:0] CBUS_DO,
	input             CBUS_WR,
	input       [3:0] CBUS_BA,
	input             CBUS_REQ,
	output            CBUS_BUSY,
	
	input       [1:0] MAC_SEL,
	input       [3:0] MAC_OP,
	input             MAC_WE
);

	bit [31:0] MACL;
	bit [31:0] MACH;
	bit [31:0] MA;
	bit [31:0] MB;
	
	wire [63:0] SRES =   $signed(MA) *   $signed(MB);
	wire [63:0] URES = $unsigned(MA) * $unsigned(MB);
	
	always @(posedge CLK or negedge RST_N) begin
		bit        MUL_EXEC;
		bit        MAC_EXEC;
		bit        SIGNED;
		
		if (!RST_N) begin
			MACL <= '0;
			MACH <= '0;
			MA <= '0;
			MB <= '0;
			MUL_EXEC <= 0;
			MAC_EXEC <= 0;
			SIGNED <= 0;
		end
		else begin
			if (MAC_SEL && MAC_WE && CE_R) begin
				case (MAC_OP) 
					4'b0000: begin		//LDS Rm,MACL/MACH
						if (MAC_SEL[0]) MACL <= CBUS_DI;
						if (MAC_SEL[1]) MACH <= CBUS_DI;
					end
					4'b0001,				//MUL.L
					4'b0010,				//DMULU.L
					4'b0011: begin		//DMULS.L
						if (MAC_SEL[0]) MA <= CBUS_DI;
						if (MAC_SEL[1]) MB <= CBUS_DI;
						MUL_EXEC <= MAC_SEL[1];
						SIGNED <= MAC_OP[0];
					end
					4'b0110,				//MULU.W
					4'b0111: begin		//MULS.W
						MA <= {{16{CBUS_DI[15]&MAC_OP[0]}},CBUS_DI[15:0]};
						MB <= {{16{CBUS_DI[31]&MAC_OP[0]}},CBUS_DI[31:16]};
						MUL_EXEC <= MAC_SEL[1];
						SIGNED <= MAC_OP[0];
					end
					4'b1001: begin		//MAC.L
						if (MAC_SEL[0]) MA <= CBUS_DI;
						if (MAC_SEL[1]) MB <= CBUS_DI;
						MAC_EXEC <= MAC_SEL[1];
						SIGNED <= MAC_OP[0];
					end
					4'b1011: begin		//MAC.W
						if (MAC_SEL[0]) MA <= {{16{CBUS_DI[15]&MAC_OP[0]}},CBUS_DI[15:0]};
						if (MAC_SEL[1]) MB <= {{16{CBUS_DI[31]&MAC_OP[0]}},CBUS_DI[15:0]};
						MAC_EXEC <= MAC_SEL[1];
						SIGNED <= MAC_OP[0];
					end
					4'b1111: {MACH,MACL} <= '0;
				endcase
			end
			
			if (MUL_EXEC) begin
				if (SIGNED) {MACH,MACL} <= SRES;
				else        {MACH,MACL} <= URES;
				MUL_EXEC <= 0;
			end
			if (MAC_EXEC) begin
				{MACH,MACL} <= $signed({MACH,MACL}) + $signed(SRES);
				MAC_EXEC <= 0;
			end
		end
	end
	
	assign CBUS_DO = MAC_SEL[1] ? MACH : MACL;
	assign CBUS_BUSY = 0;

endmodule
