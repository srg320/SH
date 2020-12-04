import CPU_PKG::*;

module SCI (
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	
	input             RES_N,
	
	input             RXD,
	output reg        TXD,
	output reg        SCKO,
	input             SCKI,
	
	input             CLK4_CE,
	input             CLK16_CE,
	input             CLK64_CE,
	input             CLK256_CE,
	
	input      [31:0] IBUS_A,
	input      [31:0] IBUS_DI,
	output     [31:0] IBUS_DO,
	input       [3:0] IBUS_BA,
	input             IBUS_WE,
	input             IBUS_REQ,
	output            IBUS_BUSY,
	output            IBUS_ACT,
	
	output            TEI_IRQ,
	output            TXI_IRQ,
	output            RXI_IRQ,
	output            ERI_IRQ
);

	RDR_t       RDR;
	TDR_t       TDR;
	SMR_t       SMR;
	SCR_t       SCR;
	SSR_t       SSR;
	BRR_t       BRR;
	bit   [7:0] RSR;
	bit   [7:0] TSR;
	bit         TEI;
	bit         TXI;
	bit         RXI;
	bit         ERI;
	
	bit         SCE_R;
	bit         SCE_F;
	bit         TX_RUN;
	
	wire REG_SEL = (IBUS_A >= 32'hFFFFFE00 && IBUS_A <= 32'hFFFFFE05);
//	wire SSR_READ = REG_SEL && IBUS_A[2:0] == 3'h4 && !IBUS_WE && IBUS_REQ;
	wire SSR_WRITE = REG_SEL && IBUS_A[2:0] == 3'h4 && IBUS_WE && IBUS_REQ;
	
	//Baud rate generator
	bit         INT_CE_R;
	bit         INT_CE_F;
	bit         EXT_CE_R;
	bit         EXT_CE_F;
	always @(posedge CLK or negedge RST_N) begin
		bit   [9:0] CNT;
		bit         CS_CE;
		bit         SCKI_OLD;
		
		if (!RST_N) begin
			INT_CE_R <= 0;
			INT_CE_F <= 0;
			EXT_CE_R <= 0;
			EXT_CE_F <= 0;
			CNT <= '0;
			SCKI_OLD <= 0;
		end
		else if (CE_R) begin
			case (SMR.CKS)
				2'b00: CS_CE = CLK4_CE;
				2'b01: CS_CE = CLK16_CE;
				2'b10: CS_CE = CLK64_CE;
				2'b11: CS_CE = CLK256_CE;
			endcase
				
			INT_CE_R <= 0;
			INT_CE_F <= 0;
			if (CS_CE) begin
				CNT <= CNT + 10'd1;
				if (CNT == {1'b0,BRR,1'b1}) begin
					INT_CE_R <= 1;
				end
				else if (CNT == {BRR,2'b11}) begin
					CNT <= '0;
					INT_CE_F <= 1;
				end
			end
			
			EXT_CE_R <= 0;
			EXT_CE_F <= 0;
			SCKI_OLD <= SCKI;
			if (!SCKI && SCKI_OLD) EXT_CE_F <= 1;
			else if (SCKI && !SCKI_OLD) EXT_CE_R <= 1;
		end
	end
	
	assign SCE_R = SCR.CKE[1] ? EXT_CE_R : INT_CE_R;
	assign SCE_F = SCR.CKE[1] ? EXT_CE_F : INT_CE_F;
	
	//Transmitter
	always @(posedge CLK or negedge RST_N) begin
//		bit         SSR_CLR_PEND;
		bit   [2:0] BIT_CNT;
		
		if (!RST_N) begin
			SCKO <= 1;
			TXD <= 1;
			
			SSR.TDRE <= 1;
			SSR.TEND <= 1;
			TSR <= '0;
			TXI <= 0;
			TEI <= 0;
//			SSR_CLR_PEND <= 0;
			BIT_CNT <= '0;
			TX_RUN <= 0;
		end
		else if (CE_R) begin
			if (!SSR.TDRE && BIT_CNT == 3'd7) begin
				TSR <= TDR;
				SSR.TDRE <= 1;
				TXI <= 1;
			end
			else if (SSR.TDRE && BIT_CNT == 3'd7) begin
				SSR.TEND <= 1;
				TEI <= 1;
			end
			
//			if (SSR_READ) begin
//				if (SSR.TDRE) SSR_CLR_PEND <= 1;
//			end
			if (SSR_WRITE) begin
				if (!IBUS_DI[31] && SSR.TDRE && SCR.TE) begin
					SSR.TDRE <= 0;
					TEI <= 0;
//					if (SSR_CLR_PEND) begin
						SSR.TEND <= 0;
//						SSR_CLR_PEND <= 0;
						BIT_CNT <= 3'd7;
						TXI <= 0;
//					end
				end
			end
			
			if (SCE_F) begin
				if (!SSR.TEND) begin
					TXD <= TSR[0];
					TSR <= {TSR[7:1],1'b0};
					BIT_CNT <= BIT_CNT + 3'd1;
				end
				if (!SSR.TEND) TX_RUN <= 1;
				else if (SSR.TEND && BIT_CNT == 3'd7) TX_RUN <= 0;
			end
			
			if (SCE_R) begin
				if (SCR.CKE[1]) begin
					SCKO <= 1;
				end
				else if (TX_RUN) begin
					SCKO <= 1;
				end
			end
			else if (SCE_F) begin
				if (SCR.CKE[1]) begin
					SCKO <= 1;
				end
				else if (TX_RUN) begin
					SCKO <= 0;
				end
			end
		end
	end
	
	//Receiver
	always @(posedge CLK or negedge RST_N) begin
		bit   [2:0] BIT_CNT;
		
		if (!RST_N) begin
			RDR <= '0;
			RSR <= '0;
			SSR.RDRF <= 0;
			SSR.ORER <= 0;
			SSR.FER <= 0;
			SSR.PER <= 0;
			SSR.MPB <= 0;
			SSR.MPBT <= 0;
			RXI <= 0;
			ERI <= 0;
			BIT_CNT <= '0;
		end
		else if (CE_R) begin
			if (SCE_R) begin
				if (TX_RUN) begin
					RSR <= {RSR[6:0],RXD};
					BIT_CNT <= BIT_CNT + 3'd1;
				end
				if (BIT_CNT == 3'd7) begin
					if (!SSR.RDRF && SCR.RE) begin
						RDR <= RSR;
						SSR.RDRF <= 1;
						RXI <= 1;
					end
					else if (SSR.RDRF && SCR.RE) begin
						SSR.ORER <= 1;
						ERI <= 1;
					end
				end
			end
			
			if (SSR_WRITE) begin
				if (!IBUS_DI[30] && SSR.RDRF && SCR.RE) begin
					SSR.RDRF <= 0;
					RXI <= 0;
				end
				if (!IBUS_DI[29] && SSR.ORER && SCR.RE) begin
					SSR.ORER <= 0;
					ERI <= 0;
				end
				SSR.MPBT <= IBUS_DI[24];
			end
		end
	end
	
	assign TEI_IRQ = TEI & SCR.TEIE;
	assign TXI_IRQ = TXI & SCR.TIE;
	assign RXI_IRQ = RXI & SCR.RIE;
	assign ERI_IRQ = ERI & SCR.RIE;
	
	
	//Registers
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			TDR <= TDR_INIT;
			SMR <= SMR_INIT;
			SCR <= SCR_INIT;
			BRR <= BRR_INIT;
			// synopsys translate_off
			
			// synopsys translate_on
		end
		else if (CE_R) begin
			if (!RES_N) begin
				TDR <= TDR_INIT;
				SMR <= SMR_INIT;
				SCR <= SCR_INIT;
				BRR <= BRR_INIT;
			end
			else if (REG_SEL && IBUS_WE && IBUS_REQ) begin
				case (IBUS_A[2:0])
					3'h0: SMR <= IBUS_DI[31:24] & SMR_WMASK;
					3'h1: BRR <= IBUS_DI[23:16] & BRR_WMASK;
					3'h2: SCR <= IBUS_DI[15:8] & SCR_WMASK;
					3'h3: TDR <= IBUS_DI[7:0] & TDR_WMASK;
					default:;
				endcase
			end
		end
	end
	
	bit [31:0] REG_DO;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			REG_DO <= '0;
		end
		else if (CE_F) begin
			if (REG_SEL && !IBUS_WE && IBUS_REQ) begin
				case (IBUS_A[2:0])
					3'h0: REG_DO <= {4{SMR & SMR_WMASK}};
					3'h1: REG_DO <= {4{BRR & BRR_WMASK}};
					3'h2: REG_DO <= {4{SCR & SCR_WMASK}};
					3'h3: REG_DO <= {4{TDR & TDR_WMASK}};
					3'h4: REG_DO <= {4{SSR & SSR_RMASK}};
					3'h5: REG_DO <= {4{RDR & RDR_RMASK}};
					default:;
				endcase
			end
		end
	end
	
	assign IBUS_DO = REG_SEL ? REG_DO : 8'h00;
	assign IBUS_BUSY = 0;
	assign IBUS_ACT = REG_SEL;
	
endmodule
