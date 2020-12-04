import CPU_PKG::*;

module DMAC (
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	
	input             RES_N,
	
	input      [31:0] IBUS_A,
	input      [31:0] IBUS_DI,
	output     [31:0] IBUS_DO,
	input       [3:0] IBUS_BA,
	input             IBUS_WE,
	input             IBUS_REQ,
	output reg        IBUS_BUSY,
	output            IBUS_ACT,
	
	output            DMAC0_IRQ,
	output      [7:0] DMAC0_VEC,
	output            DMAC1_IRQ,
	output      [7:0] DMAC1_VEC
	
);

	SARx_t      SAR0;
	SARx_t      SAR1;
	DARx_t      DAR0;
	DARx_t      DAR1;
	TCRx_t      TCR0;
	TCRx_t      TCR1;
	CHCRx_t     CHCR0;
	CHCRx_t     CHCR1;
	DRCRx_t     DRCR0;
	DRCRx_t     DRCR1;
	VCRDMAx_t   VCRDMA0;
	VCRDMAx_t   VCRDMA1;
	DMAOR_t     DMAOR;

	
	assign DMAC0_IRQ = 0;
	assign DMAC0_VEC = VCRDMA0.VC;
	assign DMAC1_IRQ = 0;
	assign DMAC1_VEC = VCRDMA1.VC;
	
		//Registers
	wire REG1_SEL = (IBUS_A == 32'hFFFFFE71 && IBUS_A == 32'hFFFFFE72);
	wire REG2_SEL = (IBUS_A >= 32'hFFFFFF80 && IBUS_A <= 32'hFFFFFFB3);
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			SAR0 <= SARx_INIT;
			SAR1 <= SARx_INIT;
			DAR0 <= DARx_INIT;
			DAR1 <= DARx_INIT;
			TCR0 <= TCRx_INIT;
			TCR1 <= TCRx_INIT;
			CHCR0 <= CHCRx_INIT;
			CHCR1 <= CHCRx_INIT;
			DRCR0 <= DRCRx_INIT;
			DRCR1 <= DRCRx_INIT;
			VCRDMA0 <= VCRDMAx_INIT;
			VCRDMA1 <= VCRDMAx_INIT;
			DMAOR <= DMAOR_INIT;
			// synopsys translate_off
			
			// synopsys translate_on
		end
		else if (CE_R) begin
			if (!RES_N) begin
				SAR0 <= SARx_INIT;
				SAR1 <= SARx_INIT;
				DAR0 <= DARx_INIT;
				DAR1 <= DARx_INIT;
				TCR0 <= TCRx_INIT;
				TCR1 <= TCRx_INIT;
				CHCR0 <= CHCRx_INIT;
				CHCR1 <= CHCRx_INIT;
				DRCR0 <= DRCRx_INIT;
				DRCR1 <= DRCRx_INIT;
				VCRDMA0 <= VCRDMAx_INIT;
				VCRDMA1 <= VCRDMAx_INIT;
				DMAOR <= DMAOR_INIT;
			end
			else if (REG1_SEL && IBUS_WE && IBUS_REQ) begin
				if (IBUS_BA[2]) DRCR0 <= IBUS_DI[23:16] & DRCRx_WMASK;
				if (IBUS_BA[1]) DRCR1 <= IBUS_DI[15:8] & DRCRx_WMASK;
			end
			else if (REG2_SEL && IBUS_WE && IBUS_REQ) begin
				case ({IBUS_A[5:2],2'b00})
					6'h00: SAR0 <= IBUS_DI;
					6'h04: DAR0 <= IBUS_DI;
					6'h08: TCR0 <= IBUS_DI[23:0];
					6'h0C: CHCR0 <= IBUS_DI & CHCRx_WMASK;
					6'h10: SAR1 <= IBUS_DI;
					6'h14: DAR1 <= IBUS_DI;
					6'h18: TCR1 <= IBUS_DI[23:0];
					6'h1C: CHCR1 <= IBUS_DI & CHCRx_WMASK;
					6'h20: VCRDMA0 <= IBUS_DI & VCRDMAx_WMASK;
					6'h28: VCRDMA1 <= IBUS_DI & VCRDMAx_WMASK;
					6'h30: DMAOR <= IBUS_DI & DMAOR_WMASK;
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
			if (REG1_SEL && !IBUS_WE && IBUS_REQ) begin
				REG_DO <= {8'h00,DRCR0 & DRCRx_RMASK,DRCR1 & DRCRx_RMASK,8'h00};
			end
			else if (REG2_SEL && !IBUS_WE && IBUS_REQ) begin
				case ({IBUS_A[5:2],2'b00})
					6'h00: REG_DO <= SAR0;
					6'h04: REG_DO <= DAR0;
					6'h08: REG_DO <= {8'h00,TCR0};
					6'h0C: REG_DO <= CHCR0 & CHCRx_RMASK;
					6'h10: REG_DO <= SAR1;
					6'h14: REG_DO <= DAR1;
					6'h18: REG_DO <= {8'h00,TCR1};
					6'h1C: REG_DO <= CHCR1 & CHCRx_RMASK;
					6'h20: REG_DO <= VCRDMA0 & VCRDMAx_RMASK;
					6'h28: REG_DO <= VCRDMA1 & VCRDMAx_RMASK;
					6'h30: REG_DO <= DMAOR & DMAOR_RMASK;
					default:REG_DO <= '0;
				endcase
			end
		end
	end
	
	assign IBUS_DO = REG1_SEL || REG2_SEL ? REG_DO : '0;
	assign IBUS_BUSY = 0;
	assign IBUS_ACT = REG1_SEL | REG2_SEL;
	

endmodule
