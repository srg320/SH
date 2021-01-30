import CPU_PKG::*;

module INTC (
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	
	input             RES_N,
	input             NMI_N,
	input       [3:0] IRL_N,
	
	input       [3:0] INT_MASK,
	input             INT_ACK,
	input             INT_ACP,
	output      [3:0] INT_LVL,
	output      [7:0] INT_VEC,
	output            INT_REQ,
	
	input             VECT_REQ,
	output            VECT_WAIT,
	
	input      [31:0] IBUS_A,
	input      [31:0] IBUS_DI,
	output     [31:0] IBUS_DO,
	input       [3:0] IBUS_BA,
	input             IBUS_WE,
	input             IBUS_REQ,
	output            IBUS_BUSY,
	output            IBUS_ACT,
	
	output      [3:0] VBUS_A,
	input       [7:0] VBUS_DI,
	output            VBUS_REQ,
	input             VBUS_WAIT,
	
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
	input             FRT_OVI_IRQ
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
	bit        IRL_PEND;
	bit        UBC_PEND;
	bit        DIVU_PEND;
	bit        DMAC0_PEND;
	bit        DMAC1_PEND;
	bit        WDT_PEND;
	bit        BSC_PEND;
	bit        SCI_ERI_PEND;
	bit        SCI_RXI_PEND;
	bit        SCI_TXI_PEND;
	bit        SCI_TEI_PEND;
	bit        FRT_ICI_PEND;
	bit        FRT_OCI_PEND;
	bit        FRT_OVI_PEND;
	bit [ 7:0] EXT_VEC;
	
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
			else if (INT_ACK && NMI_PEND) begin
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
			if (IRL_OLD[0] == ~IRL_N && IRL_OLD[1] == ~IRL_N && IRL_OLD[2] == ~IRL_N && IRL_OLD[3] == ~IRL_N && !(&IRL_N)/* && !IRL_REQ*/) begin
				IRL_REQ <= 1;
			end
				IRL_LVL <= ~IRL_N;
//			else if (INT_ACK && IRL_PEND) begin
//				IRL_REQ <= 0;
//				IRL_OLD <= '{4{'1}};
//			end
		end
	end
	
	wire [7:0] IRL_VEC = !ICR.VECMD ? {5'b01000,IRL_LVL[3:1]} : VBUS_DI;
	always @(posedge CLK or negedge RST_N) begin
		bit INT_CLR;
		if (!RST_N) begin
//			INT_LVL <= '0;
//			INT_VEC <= 0;
			INT_REQ <= 0;
			NMI_PEND <= 0;
			IRL_PEND <= 0;
		end else if (CE_R) begin	
//			NMI_PEND <= 0;
//			IRL_PEND <= 0;
			if (!INT_REQ) begin
				if (NMI_REQ)                                    begin INT_REQ <= 1'b1; NMI_PEND <= 1; end
				else if (UBC_IRQ     && 4'hF        > INT_MASK) begin INT_REQ <= 1'b1; UBC_PEND <= 1; end
				else if (IRL_REQ     && IRL_LVL     > INT_MASK) begin INT_REQ <= 1'b1; IRL_PEND <= 1; end
				else if (DIVU_IRQ    && IPRA.DIVUIP > INT_MASK) begin INT_REQ <= 1'b1; DIVU_PEND <= 1; end
				else if (DMAC0_IRQ   && IPRA.DMACIP > INT_MASK) begin INT_REQ <= 1'b1; DMAC0_PEND <= 1; end
				else if (DMAC1_IRQ   && IPRA.DMACIP > INT_MASK) begin INT_REQ <= 1'b1; DMAC1_PEND <= 1; end
				else if (WDT_IRQ     && IPRA.WDTIP  > INT_MASK) begin INT_REQ <= 1'b1; WDT_PEND <= 1; end
				else if (BSC_IRQ     && IPRA.WDTIP  > INT_MASK) begin INT_REQ <= 1'b1; BSC_PEND <= 1; end
				else if (SCI_ERI_IRQ && IPRB.SCIIP  > INT_MASK) begin INT_REQ <= 1'b1; SCI_ERI_PEND <= 1; end
				else if (SCI_RXI_IRQ && IPRB.SCIIP  > INT_MASK) begin INT_REQ <= 1'b1; SCI_RXI_PEND <= 1; end
				else if (SCI_TXI_IRQ && IPRB.SCIIP  > INT_MASK) begin INT_REQ <= 1'b1; SCI_TXI_PEND <= 1; end
				else if (SCI_TEI_IRQ && IPRB.SCIIP  > INT_MASK) begin INT_REQ <= 1'b1; SCI_TEI_PEND <= 1; end
				else if (FRT_ICI_IRQ && IPRB.FRTIP  > INT_MASK) begin INT_REQ <= 1'b1; FRT_ICI_PEND <= 1;  end
				else if (FRT_OCI_IRQ && IPRB.FRTIP  > INT_MASK) begin INT_REQ <= 1'b1; FRT_OCI_PEND <= 1; end
				else if (FRT_OVI_IRQ && IPRB.FRTIP  > INT_MASK) begin INT_REQ <= 1'b1; FRT_OVI_PEND <= 1; end
				else                                            begin INT_REQ <= 1'b0; end
			end else if (INT_CLR) begin
				INT_REQ <= 0;
				NMI_PEND <= 0;
				UBC_PEND <= 0;
				IRL_PEND <= 0;
				DIVU_PEND <= 0;
				DMAC0_PEND <= 0;
				DMAC1_PEND <= 0;
				WDT_PEND <= 0;
				BSC_PEND <= 0;
				SCI_ERI_PEND <= 0;
				SCI_RXI_PEND <= 0;
				SCI_TXI_PEND <= 0;
				SCI_TEI_PEND <= 0;
				FRT_ICI_PEND <= 0;
				FRT_OCI_PEND <= 0;
				FRT_OVI_PEND <= 0;
			end
		end else if (CE_F) begin
			INT_CLR <= 0;
			if (VBREQ && !VBUS_WAIT && INT_REQ) begin
				INT_CLR <= 1;
			end
		end
	end
	
	always_comb begin
		if      (NMI_PEND)     begin INT_LVL <= 4'hF;        INT_VEC <= 8'd11;              end
		else if (UBC_PEND)     begin INT_LVL <= 4'hF;        INT_VEC <= 8'd12;              end
		else if (IRL_PEND)     begin INT_LVL <= IRL_LVL;     INT_VEC <= IRL_VEC;            end
		else if (DIVU_PEND)    begin INT_LVL <= IPRA.DIVUIP; INT_VEC <= DIVU_VEC;           end
		else if (DMAC0_PEND)   begin INT_LVL <= IPRA.DMACIP; INT_VEC <= DMAC0_VEC;          end
		else if (DMAC1_PEND)   begin INT_LVL <= IPRA.DMACIP; INT_VEC <= DMAC1_VEC;          end
		else if (WDT_PEND)     begin INT_LVL <= IPRA.WDTIP;  INT_VEC <= {1'b0,VCRWDT.WITV}; end
		else if (BSC_PEND)     begin INT_LVL <= IPRA.WDTIP;  INT_VEC <= {1'b0,VCRWDT.BCMV}; end
		else if (SCI_ERI_PEND) begin INT_LVL <= IPRB.SCIIP;  INT_VEC <= {1'b0,VCRA.SERV};   end
		else if (SCI_RXI_PEND) begin INT_LVL <= IPRB.SCIIP;  INT_VEC <= {1'b0,VCRA.SRXV};   end
		else if (SCI_TXI_PEND) begin INT_LVL <= IPRB.SCIIP;  INT_VEC <= {1'b0,VCRB.STXV};   end
		else if (SCI_TEI_PEND) begin INT_LVL <= IPRB.SCIIP;  INT_VEC <= {1'b0,VCRB.STEV};   end
		else if (FRT_ICI_PEND) begin INT_LVL <= IPRB.FRTIP;  INT_VEC <= {1'b0,VCRC.FICV};   end
		else if (FRT_OCI_PEND) begin INT_LVL <= IPRB.FRTIP;  INT_VEC <= {1'b0,VCRC.FOCV};   end
		else if (FRT_OVI_PEND) begin INT_LVL <= IPRB.FRTIP;  INT_VEC <= {1'b0,VCRD.FOVV};   end
		else                   begin INT_LVL <= 4'hF;        INT_VEC <= 8'd0;               end
	end
	
	bit [3:0] VBA;
	bit       VBREQ;
	always @(posedge CLK or negedge RST_N) begin
//		bit VLATCH;
		
		if (!RST_N) begin
			VBREQ <= 0;
			VBA <= '0;
		end else if (CE_F) begin	
//			VLATCH <= 0;
			if (VECT_REQ && IRL_PEND && ICR.VECMD && !VBREQ) begin
				VBREQ <= 1;
				VBA <= IRL_LVL;
			end else if (VBREQ && !VBUS_WAIT) begin
				VBREQ <= 0;
//				VLATCH <= 1;
			end
//		end else if (CE_R) begin	
//			if (VLATCH ) begin
//				EXT_VEC <= VBUS_DI;
//			end
		end
	end
	assign VECT_WAIT = VBREQ;
	
	assign VBUS_A   = VBA;
	assign VBUS_REQ = VBREQ;
	
	
	
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
