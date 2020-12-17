import CPU_PKG::*;

module INTC (
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	
	input             RES_N,
	input             NMI_N,
	
	input       [3:0] IRL_N,
	
	input      [31:0] IBUS_A,
	input      [31:0] IBUS_DI,
	output     [31:0] IBUS_DO,
	input       [3:0] IBUS_BA,
	input             IBUS_WE,
	input             IBUS_REQ,
	output            IBUS_BUSY,
	output            IBUS_ACT,
	
	input             UBC_IRQ,
	input             DIVU_IRQ,
	input       [7:0] DIVU_VEC,
	input             DMAC0_IRQ,
	input       [7:0] DMAC0_VEC,
	input             DMAC1_IRQ,
	input       [7:0] DMAC1_VEC,
	input             WDT_IRQ,
	input             BSC_IRQ,
	input             SCI_ERI_IRQ,
	input             SCI_RXI_IRQ,
	input             SCI_TXI_IRQ,
	input             SCI_TEI_IRQ,
	input             FRT_ICI_IRQ,
	input             FRT_OCI_IRQ,
	input             FRT_OVI_IRQ,
	
	input    IntAck_t INTI,
	output   IntReq_t INTO
);

	ICR_t      ICR;
	IPRA_t     IPRA;
	IPRB_t     IPRB;
	VCRWDT_t   VCRWDT;
	VCRA_t     VCRA;
	VCRB_t     VCRB;
	VCRC_t     VCRC;
	VCRD_t     VCRD;
	
	bit [ 3:0] LVL;
	bit [ 7:0] VEC;
	bit        NMI_REQ;
	bit        IRL_REQ;
	bit [ 3:0] IRL_LVL;
	bit        NMI_PEND;
//	bit        IRL_PEND;
	
	always @(posedge CLK or negedge RST_N) begin
		bit NMI_N_OLD;
		
		if (!RST_N) begin
			NMI_REQ <= 0;
		end
		else if (CE_R) begin	
			NMI_N_OLD <= NMI_N;
			if ((~NMI_N ^ ICR.NMIE) && (NMI_N_OLD ^ ICR.NMIE) && !NMI_REQ) begin
				NMI_REQ <= 1;
			end
			else if (INTI.ACK && NMI_PEND) begin
				NMI_REQ <= 0;
			end
		end
	end
	
	always @(posedge CLK or negedge RST_N) begin
		bit [3:0] IRL_OLD[4];
		
		if (!RST_N) begin
			IRL_OLD <= '{4{'1}};
			IRL_REQ <= 0;
		end
		else if (CE_R) begin	
			IRL_OLD[0] <= ~IRL_N;
			IRL_OLD[1] <= IRL_OLD[0];
			IRL_OLD[2] <= IRL_OLD[1];
			IRL_OLD[3] <= IRL_OLD[2];
			IRL_REQ <= 0;
			if (IRL_OLD[0] == ~IRL_N && IRL_OLD[1] == ~IRL_N && IRL_OLD[2] == ~IRL_N && IRL_OLD[3] == ~IRL_N) begin
				IRL_REQ <= ~&IRL_N;
				IRL_LVL <= ~IRL_N;
			end
		end
	end
	
	wire [7:0] IRL_VEC = {5'b01000,IRL_LVL[3:1]};
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			INTO <= INT_REQ_RESET;
			NMI_PEND <= 0;
		end
		else if (CE_R) begin	
			NMI_PEND <= 0;
			if (NMI_REQ)                                    begin INTO <= '{4'hF,        8'd11,              0, 1}; NMI_PEND <= 1; end
			else if (UBC_IRQ     && 4'hF        > INTI.LVL) begin INTO <= '{4'hF,        8'd12,              0, 1};                end
			else if (IRL_REQ     && IRL_LVL     > INTI.LVL) begin INTO <= '{IRL_LVL,     IRL_VEC,            0, 1};                end
			else if (DIVU_IRQ    && IPRA.DIVUIP > INTI.LVL) begin INTO <= '{IPRA.DIVUIP, DIVU_VEC,           0, 1};                end
			else if (DMAC0_IRQ   && IPRA.DMACIP > INTI.LVL) begin INTO <= '{IPRA.DMACIP, DMAC0_VEC,          0, 1};                end
			else if (DMAC1_IRQ   && IPRA.DMACIP > INTI.LVL) begin INTO <= '{IPRA.DMACIP, DMAC1_VEC,          0, 1};                end
			else if (WDT_IRQ     && IPRA.WDTIP  > INTI.LVL) begin INTO <= '{IPRA.WDTIP,  {1'b0,VCRWDT.WITV}, 0, 1};                end
			else if (BSC_IRQ     && IPRA.WDTIP  > INTI.LVL) begin INTO <= '{IPRA.WDTIP,  {1'b0,VCRWDT.BCMV}, 0, 1};                end
			else if (SCI_ERI_IRQ && IPRB.SCIIP  > INTI.LVL) begin INTO <= '{IPRB.SCIIP,  {1'b0,VCRA.SERV},   0, 1};                end
			else if (SCI_RXI_IRQ && IPRB.SCIIP  > INTI.LVL) begin INTO <= '{IPRB.SCIIP,  {1'b0,VCRA.SRXV},   0, 1};                end
			else if (SCI_TXI_IRQ && IPRB.SCIIP  > INTI.LVL) begin INTO <= '{IPRB.SCIIP,  {1'b0,VCRB.STXV},   0, 1};                end
			else if (SCI_TEI_IRQ && IPRB.SCIIP  > INTI.LVL) begin INTO <= '{IPRB.SCIIP,  {1'b0,VCRB.STEV},   0, 1};                end
			else if (FRT_ICI_IRQ && IPRB.FRTIP  > INTI.LVL) begin INTO <= '{IPRB.FRTIP,  {1'b0,VCRC.FICV},   0, 1};                end
			else if (FRT_OCI_IRQ && IPRB.FRTIP  > INTI.LVL) begin INTO <= '{IPRB.FRTIP,  {1'b0,VCRC.FOCV},   0, 1};                end
			else if (FRT_OVI_IRQ && IPRB.FRTIP  > INTI.LVL) begin INTO <= '{IPRB.FRTIP,  {1'b0,VCRD.FOVV},   0, 1};                end
			else                                            begin INTO <= INT_REQ_RESET;                                           end
		end
	end
	
	
	//Registers
	wire REG_SEL = (IBUS_A >= 32'hFFFFFE60 & IBUS_A <= 32'hFFFFFE69) | (IBUS_A >= 32'hFFFFFEE0 & IBUS_A <= 32'hFFFFFEE5);
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			ICR    <= ICR_INIT;
			IPRA   <= IPRA_INIT;
			IPRB   <= IPRB_INIT;
			VCRWDT <= VCRWDT_INIT;
			VCRA   <= VCRA_INIT;
			VCRB   <= VCRB_INIT;
			VCRC   <= VCRC_INIT;
			VCRD   <= VCRD_INIT;
		end
		else if (CE_R) begin
			if (!RES_N) begin
				ICR    <= ICR_INIT;
				IPRA   <= IPRA_INIT;
				IPRB   <= IPRB_INIT;
				VCRWDT <= VCRWDT_INIT;
				VCRA   <= VCRA_INIT;
				VCRB   <= VCRB_INIT;
				VCRC   <= VCRC_INIT;
				VCRD   <= VCRD_INIT;
				ICR.NMIL <= NMI_N;
			end
			else if (REG_SEL && IBUS_WE && IBUS_REQ) begin
				case ({IBUS_A[7:1],1'b0})
					8'h60: begin
						if (IBUS_BA[3]) IPRB[15:8] = IBUS_DI[31:24] & IPRB_WMASK[15:8];
						if (IBUS_BA[2]) IPRB[ 7:0] = IBUS_DI[23:16] & IPRB_WMASK[ 7:0];
					end
					8'h62: begin
						if (IBUS_BA[1]) VCRA[15:8] = IBUS_DI[15:8] & VCRA_WMASK[15:8];
						if (IBUS_BA[0]) VCRA[ 7:0] = IBUS_DI[ 7:0] & VCRA_WMASK[ 7:0];
					end
					8'h64: begin
						if (IBUS_BA[3]) VCRB[15:8] = IBUS_DI[31:24] & VCRB_WMASK[15:8];
						if (IBUS_BA[2]) VCRB[ 7:0] = IBUS_DI[23:16] & VCRB_WMASK[ 7:0];
					end
					8'h66: begin
						if (IBUS_BA[1]) VCRC[15:8] = IBUS_DI[15:8] & VCRC_WMASK[15:8];
						if (IBUS_BA[0]) VCRC[ 7:0] = IBUS_DI[ 7:0] & VCRC_WMASK[ 7:0];
					end
					8'h68: begin
						if (IBUS_BA[3]) VCRD[15:8] = IBUS_DI[31:24] & VCRD_WMASK[15:8];
						if (IBUS_BA[2]) VCRD[ 7:0] = IBUS_DI[23:16] & VCRD_WMASK[ 7:0];
					end
					8'hE0: begin
						if (IBUS_BA[3]) ICR[15:8] = IBUS_DI[31:24] & ICR_WMASK[15:8];
						if (IBUS_BA[2]) ICR[ 7:0] = IBUS_DI[23:16] & ICR_WMASK[ 7:0];
					end
					8'hE2: begin
						if (IBUS_BA[1]) IPRA[15:8] = IBUS_DI[15:8] & IPRA_WMASK[15:8];
						if (IBUS_BA[0]) IPRA[ 7:0] = IBUS_DI[ 7:0] & IPRA_WMASK[ 7:0];
					end
					8'hE4: begin
						if (IBUS_BA[3]) VCRWDT[15:8] = IBUS_DI[31:24] & VCRWDT_WMASK[15:8];
						if (IBUS_BA[2]) VCRWDT[ 7:0] = IBUS_DI[23:16] & VCRWDT_WMASK[ 7:0];
					end
					default:;
				endcase
			end
		end
	end
	
	bit [31:0] BUS_DO;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			BUS_DO <= '0;
		end
		else if (CE_F) begin
			if (REG_SEL && !IBUS_WE && IBUS_REQ) begin
				case ({IBUS_A[7:1],1'b0})
					8'h60: BUS_DO <= IPRB & IPRB_RMASK;
					8'h62: BUS_DO <= VCRA & VCRA_RMASK;
					8'h64: BUS_DO <= VCRB & VCRB_RMASK;
					8'h66: BUS_DO <= VCRC & VCRC_RMASK;
					8'h68: BUS_DO <= VCRD & VCRD_RMASK;
					8'hE0: BUS_DO <= ICR & ICR_RMASK;
					8'hE2: BUS_DO <= IPRA & IPRA_RMASK;
					8'hE4: BUS_DO <= VCRWDT & VCRWDT_RMASK;
					default:BUS_DO <= '0;
				endcase
			end
		end
	end
	
	assign IBUS_DO = BUS_DO;
	assign IBUS_BUSY = 0;
	assign IBUS_ACT = REG_SEL;

endmodule
