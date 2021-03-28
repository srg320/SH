

module INTC (
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	
	input             RES_N,
	input             NMI_N,
	input       [7:0] IRQ_N,
	output            IRQOUT_N,
	
	input       [3:0] INT_MASK,
	input             INT_ACK,
	input             INT_ACP,
	output reg  [3:0] INT_LVL,
	output reg  [7:0] INT_VEC,
	output reg        INT_REQ,
	
	input             VECT_REQ,
	output            VECT_WAIT,
	
	input      [27:0] IBUS_A,
	input      [31:0] IBUS_DI,
	output     [31:0] IBUS_DO,
	input       [3:0] IBUS_BA,
	input             IBUS_WE,
	input             IBUS_REQ,
	output            IBUS_BUSY,
	output            IBUS_ACT,
	
	input             UBC_IRQ,
	input             DMAC0_IRQ,
	input             DMAC1_IRQ,
	input             DMAC2_IRQ,
	input             DMAC3_IRQ,
	input             WDT_IRQ,
	input             BSC_IRQ,
	input             SCI0_ERI_IRQ,
	input             SCI0_RXI_IRQ,
	input             SCI0_TXI_IRQ,
	input             SCI0_TEI_IRQ,
	input             SCI1_ERI_IRQ,
	input             SCI1_RXI_IRQ,
	input             SCI1_TXI_IRQ,
	input             SCI1_TEI_IRQ,
	input       [4:0] ITU_IMIA_IRQ,
	input       [4:0] ITU_IMIB_IRQ,
	input       [4:0] ITU_OVI_IRQ
);

	import SH7034_PKG::*;

	IPRA_t     IPRA;
	IPRB_t     IPRB;
	IPRC_t     IPRC;
	IPRD_t     IPRD;
	IPRE_t     IPRE;
	ICR_t      ICR;
	
	bit [ 3:0] LVL;
	bit [ 7:0] VEC;
	bit        NMI_REQ;
	bit [ 7:0] IRQ_REQ;
	bit        NMI_PEND;
	bit        IRQ0_PEND;
	bit        IRQ1_PEND;
	bit        IRQ2_PEND;
	bit        IRQ3_PEND;
	bit        IRQ4_PEND;
	bit        IRQ5_PEND;
	bit        IRQ6_PEND;
	bit        IRQ7_PEND;
	bit        UBC_PEND;
	bit        DMAC0_PEND;
	bit        DMAC1_PEND;
	bit        DMAC2_PEND;
	bit        DMAC3_PEND;
	bit        WDT_PEND;
	bit        BSC_PEND;
	bit        SCI0_ERI_PEND;
	bit        SCI0_RXI_PEND;
	bit        SCI0_TXI_PEND;
	bit        SCI0_TEI_PEND;
	bit        SCI1_ERI_PEND;
	bit        SCI1_RXI_PEND;
	bit        SCI1_TXI_PEND;
	bit        SCI1_TEI_PEND;
	bit [ 4:0] ITU_IMIA_PEND;
	bit [ 4:0] ITU_IMIB_PEND;
	bit [ 4:0] ITU_OVI_PEND;
	bit        VBREQ;
	
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
		bit [7:0] IRQ_OLD[2];
		
		if (!RST_N) begin
			IRQ_OLD <= '{2{'0}};
			IRQ_REQ <= '0;
		end
		else if (CE_R) begin	
			IRQ_OLD[0] <= ~IRQ_N;
			IRQ_OLD[1] <= IRQ_OLD[0];
			IRQ_REQ <= '0;
			if (IRQ_OLD[0][0] && IRQ_OLD[1][0] && !IRQ_N[0]) begin
				IRQ_REQ[0] <= 1;
			end
//			IRQ_LVL <= ~IRL_N;
		end
	end
	
	always @(posedge CLK or negedge RST_N) begin
		bit INT_CLR;
		if (!RST_N) begin
			INT_REQ <= 0;
			NMI_PEND <= 0;
			IRQ0_PEND <= 0;
			IRQ1_PEND <= 0;
			IRQ2_PEND <= 0;
			IRQ3_PEND <= 0;
			IRQ4_PEND <= 0;
			IRQ5_PEND <= 0;
			IRQ6_PEND <= 0;
			IRQ7_PEND <= 0;
		end else if (CE_R) begin	
			if (!INT_REQ) begin
				if (NMI_REQ)                                        begin INT_REQ <= 1'b1; NMI_PEND <= 1; end
				else if (UBC_IRQ         && 4'hF        > INT_MASK) begin INT_REQ <= 1'b1; UBC_PEND <= 1; end
				else if (IRQ_REQ[0]      && IPRA.IRQ0   > INT_MASK) begin INT_REQ <= 1'b1; IRQ0_PEND <= 1; end
				else if (IRQ_REQ[1]      && IPRA.IRQ1   > INT_MASK) begin INT_REQ <= 1'b1; IRQ1_PEND <= 1; end
				else if (IRQ_REQ[2]      && IPRA.IRQ2   > INT_MASK) begin INT_REQ <= 1'b1; IRQ2_PEND <= 1; end
				else if (IRQ_REQ[3]      && IPRA.IRQ3   > INT_MASK) begin INT_REQ <= 1'b1; IRQ3_PEND <= 1; end
				else if (IRQ_REQ[4]      && IPRB.IRQ4   > INT_MASK) begin INT_REQ <= 1'b1; IRQ4_PEND <= 1; end
				else if (IRQ_REQ[5]      && IPRB.IRQ5   > INT_MASK) begin INT_REQ <= 1'b1; IRQ5_PEND <= 1; end
				else if (IRQ_REQ[6]      && IPRB.IRQ6   > INT_MASK) begin INT_REQ <= 1'b1; IRQ6_PEND <= 1; end
				else if (IRQ_REQ[7]      && IPRB.IRQ7   > INT_MASK) begin INT_REQ <= 1'b1; IRQ7_PEND <= 1; end
				else if (DMAC0_IRQ       && IPRC.DMAC01 > INT_MASK) begin INT_REQ <= 1'b1; DMAC0_PEND <= 1; end
				else if (DMAC1_IRQ       && IPRC.DMAC01 > INT_MASK) begin INT_REQ <= 1'b1; DMAC1_PEND <= 1; end
				else if (DMAC2_IRQ       && IPRC.DMAC23 > INT_MASK) begin INT_REQ <= 1'b1; DMAC2_PEND <= 1; end
				else if (DMAC3_IRQ       && IPRC.DMAC23 > INT_MASK) begin INT_REQ <= 1'b1; DMAC3_PEND <= 1; end
				else if (WDT_IRQ         && IPRE.WDT    > INT_MASK) begin INT_REQ <= 1'b1; WDT_PEND <= 1; end
				else if (BSC_IRQ         && IPRE.WDT    > INT_MASK) begin INT_REQ <= 1'b1; BSC_PEND <= 1; end
				else if (SCI0_ERI_IRQ    && IPRD.SCI0   > INT_MASK) begin INT_REQ <= 1'b1; SCI0_ERI_PEND <= 1; end
				else if (SCI0_RXI_IRQ    && IPRD.SCI0   > INT_MASK) begin INT_REQ <= 1'b1; SCI0_RXI_PEND <= 1; end
				else if (SCI0_TXI_IRQ    && IPRD.SCI0   > INT_MASK) begin INT_REQ <= 1'b1; SCI0_TXI_PEND <= 1; end
				else if (SCI0_TEI_IRQ    && IPRD.SCI0   > INT_MASK) begin INT_REQ <= 1'b1; SCI0_TEI_PEND <= 1; end
				else if (SCI1_ERI_IRQ    && IPRE.SCI1   > INT_MASK) begin INT_REQ <= 1'b1; SCI1_ERI_PEND <= 1; end
				else if (SCI1_RXI_IRQ    && IPRE.SCI1   > INT_MASK) begin INT_REQ <= 1'b1; SCI1_RXI_PEND <= 1; end
				else if (SCI1_TXI_IRQ    && IPRE.SCI1   > INT_MASK) begin INT_REQ <= 1'b1; SCI1_TXI_PEND <= 1; end
				else if (SCI1_TEI_IRQ    && IPRE.SCI1   > INT_MASK) begin INT_REQ <= 1'b1; SCI1_TEI_PEND <= 1; end
				else if (ITU_IMIA_IRQ[0] && IPRC.ITU0   > INT_MASK) begin INT_REQ <= 1'b1; ITU_IMIA_PEND[0] <= 1;  end
				else if (ITU_IMIB_IRQ[0] && IPRC.ITU0   > INT_MASK) begin INT_REQ <= 1'b1; ITU_IMIB_PEND[0] <= 1; end
				else if (ITU_OVI_IRQ[0]  && IPRC.ITU0   > INT_MASK) begin INT_REQ <= 1'b1; ITU_OVI_PEND[0] <= 1; end
				else if (ITU_IMIA_IRQ[1] && IPRC.ITU1   > INT_MASK) begin INT_REQ <= 1'b1; ITU_IMIA_PEND[1] <= 1;  end
				else if (ITU_IMIB_IRQ[1] && IPRC.ITU1   > INT_MASK) begin INT_REQ <= 1'b1; ITU_IMIB_PEND[1] <= 1; end
				else if (ITU_OVI_IRQ[1]  && IPRC.ITU1   > INT_MASK) begin INT_REQ <= 1'b1; ITU_OVI_PEND[1] <= 1; end
				else if (ITU_IMIA_IRQ[2] && IPRD.ITU2   > INT_MASK) begin INT_REQ <= 1'b1; ITU_IMIA_PEND[2] <= 1;  end
				else if (ITU_IMIB_IRQ[2] && IPRD.ITU2   > INT_MASK) begin INT_REQ <= 1'b1; ITU_IMIB_PEND[2] <= 1; end
				else if (ITU_OVI_IRQ[2]  && IPRD.ITU2   > INT_MASK) begin INT_REQ <= 1'b1; ITU_OVI_PEND[2] <= 1; end
				else if (ITU_IMIA_IRQ[3] && IPRD.ITU3   > INT_MASK) begin INT_REQ <= 1'b1; ITU_IMIA_PEND[3] <= 1;  end
				else if (ITU_IMIB_IRQ[3] && IPRD.ITU3   > INT_MASK) begin INT_REQ <= 1'b1; ITU_IMIB_PEND[3] <= 1; end
				else if (ITU_OVI_IRQ[3]  && IPRD.ITU3   > INT_MASK) begin INT_REQ <= 1'b1; ITU_OVI_PEND[3] <= 1; end
				else if (ITU_IMIA_IRQ[4] && IPRD.ITU4   > INT_MASK) begin INT_REQ <= 1'b1; ITU_IMIA_PEND[4] <= 1;  end
				else if (ITU_IMIB_IRQ[4] && IPRD.ITU4   > INT_MASK) begin INT_REQ <= 1'b1; ITU_IMIB_PEND[4] <= 1; end
				else if (ITU_OVI_IRQ[4]  && IPRD.ITU4   > INT_MASK) begin INT_REQ <= 1'b1; ITU_OVI_PEND[4] <= 1; end
				else                                                begin INT_REQ <= 1'b0; end
			end else if (INT_CLR) begin
				INT_REQ <= 0;
				NMI_PEND <= 0;
				UBC_PEND <= 0;
				IRQ0_PEND <= 0;
				IRQ1_PEND <= 0;
				IRQ2_PEND <= 0;
				IRQ3_PEND <= 0;
				IRQ4_PEND <= 0;
				IRQ5_PEND <= 0;
				IRQ6_PEND <= 0;
				IRQ7_PEND <= 0;
				DMAC0_PEND <= 0;
				DMAC1_PEND <= 0;
				DMAC2_PEND <= 0;
				DMAC3_PEND <= 0;
				WDT_PEND <= 0;
				BSC_PEND <= 0;
				SCI0_ERI_PEND <= 0;
				SCI0_RXI_PEND <= 0;
				SCI0_TXI_PEND <= 0;
				SCI0_TEI_PEND <= 0;
				SCI1_ERI_PEND <= 0;
				SCI1_RXI_PEND <= 0;
				SCI1_TXI_PEND <= 0;
				SCI1_TEI_PEND <= 0;
				ITU_IMIA_PEND<= '0;
				ITU_IMIB_PEND <= '0;
				ITU_OVI_PEND <= '0;
			end
		end else if (CE_F) begin
			INT_CLR <= 0;
			if (VBREQ && INT_REQ) begin
				INT_CLR <= 1;
			end
		end
	end
	
	always_comb begin
		if      (NMI_PEND)     begin INT_LVL <= 4'hF;        INT_VEC <= 8'd11;              end
		else if (UBC_PEND)     begin INT_LVL <= 4'hF;        INT_VEC <= 8'd12;              end
		else if (IRQ0_PEND)    begin INT_LVL <= IPRA.IRQ0;   INT_VEC <= 8'd64;              end
		else if (IRQ1_PEND)    begin INT_LVL <= IPRA.IRQ1;   INT_VEC <= 8'd65;              end
		else if (IRQ2_PEND)    begin INT_LVL <= IPRA.IRQ2;   INT_VEC <= 8'd66;              end
		else if (IRQ3_PEND)    begin INT_LVL <= IPRA.IRQ3;   INT_VEC <= 8'd67;              end
		else if (IRQ4_PEND)    begin INT_LVL <= IPRB.IRQ4;   INT_VEC <= 8'd68;              end
		else if (IRQ5_PEND)    begin INT_LVL <= IPRB.IRQ5;   INT_VEC <= 8'd69;              end
		else if (IRQ6_PEND)    begin INT_LVL <= IPRB.IRQ6;   INT_VEC <= 8'd70;              end
		else if (IRQ7_PEND)    begin INT_LVL <= IPRB.IRQ7;   INT_VEC <= 8'd71;              end
		else if (DMAC0_PEND)   begin INT_LVL <= IPRC.DMAC01; INT_VEC <= 8'd72;              end
		else if (DMAC1_PEND)   begin INT_LVL <= IPRC.DMAC01; INT_VEC <= 8'd74;              end
		else if (DMAC2_PEND)   begin INT_LVL <= IPRC.DMAC23; INT_VEC <= 8'd76;              end
		else if (DMAC3_PEND)   begin INT_LVL <= IPRC.DMAC23; INT_VEC <= 8'd78;              end
		else if (WDT_PEND)     begin INT_LVL <= IPRE.WDT;    INT_VEC <= 8'd112;             end
		else if (BSC_PEND)     begin INT_LVL <= IPRE.WDT;    INT_VEC <= 8'd113;             end
		else if (SCI0_ERI_PEND) begin INT_LVL <= IPRD.SCI0;  INT_VEC <= 8'd100;             end
		else if (SCI0_RXI_PEND) begin INT_LVL <= IPRD.SCI0;  INT_VEC <= 8'd101;             end
		else if (SCI0_TXI_PEND) begin INT_LVL <= IPRD.SCI0;  INT_VEC <= 8'd102;             end
		else if (SCI0_TEI_PEND) begin INT_LVL <= IPRD.SCI0;  INT_VEC <= 8'd103;             end
		else if (SCI1_ERI_PEND) begin INT_LVL <= IPRE.SCI1;  INT_VEC <= 8'd104;             end
		else if (SCI1_RXI_PEND) begin INT_LVL <= IPRE.SCI1;  INT_VEC <= 8'd105;             end
		else if (SCI1_TXI_PEND) begin INT_LVL <= IPRE.SCI1;  INT_VEC <= 8'd106;             end
		else if (SCI1_TEI_PEND) begin INT_LVL <= IPRE.SCI1;  INT_VEC <= 8'd107;             end
		else if (ITU_IMIA_PEND[0]) begin INT_LVL <= IPRC.ITU0;  INT_VEC <= 8'd80;   end
		else if (ITU_IMIB_PEND[0]) begin INT_LVL <= IPRC.ITU0;  INT_VEC <= 8'd81;   end
		else if (ITU_OVI_PEND[0]) begin INT_LVL <= IPRC.ITU0;  INT_VEC <= 8'd82;   end
		else if (ITU_IMIA_PEND[1]) begin INT_LVL <= IPRC.ITU1;  INT_VEC <= 8'd84;   end
		else if (ITU_IMIB_PEND[1]) begin INT_LVL <= IPRC.ITU1;  INT_VEC <= 8'd85;   end
		else if (ITU_OVI_PEND[1]) begin INT_LVL <= IPRC.ITU1;  INT_VEC <= 8'd86;   end
		else if (ITU_IMIA_PEND[2]) begin INT_LVL <= IPRD.ITU2;  INT_VEC <= 8'd88;   end
		else if (ITU_IMIB_PEND[2]) begin INT_LVL <= IPRD.ITU2;  INT_VEC <= 8'd89;   end
		else if (ITU_OVI_PEND[2]) begin INT_LVL <= IPRD.ITU2;  INT_VEC <= 8'd90;   end
		else if (ITU_IMIA_PEND[3]) begin INT_LVL <= IPRD.ITU3;  INT_VEC <= 8'd92;   end
		else if (ITU_IMIB_PEND[3]) begin INT_LVL <= IPRD.ITU3;  INT_VEC <= 8'd93;   end
		else if (ITU_OVI_PEND[3]) begin INT_LVL <= IPRD.ITU3;  INT_VEC <= 8'd94;   end
		else if (ITU_IMIA_PEND[4]) begin INT_LVL <= IPRD.ITU4;  INT_VEC <= 8'd96;   end
		else if (ITU_IMIB_PEND[4]) begin INT_LVL <= IPRD.ITU4;  INT_VEC <= 8'd97;   end
		else if (ITU_OVI_PEND[4]) begin INT_LVL <= IPRD.ITU4;  INT_VEC <= 8'd98;   end
		else                   begin INT_LVL <= 4'hF;        INT_VEC <= 8'd0;               end
	end
	
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			VBREQ <= 0;
		end else if (CE_F) begin	
			if (VECT_REQ && !VBREQ) begin
				VBREQ <= 1;
			end else if (VBREQ) begin
				VBREQ <= 0;
			end
		end
	end
	assign VECT_WAIT = VBREQ;
	
	assign IRQOUT_N = 1;
	
	//Registers
	wire REG_SEL = (IBUS_A >= 28'h5FFFF84 & IBUS_A <= 28'h5FFFF8F);
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			IPRA <= IPRA_INIT;
			IPRB <= IPRB_INIT;
			IPRC <= IPRC_INIT;
			IPRD <= IPRD_INIT;
			IPRE <= IPRE_INIT;
			ICR  <= ICR_INIT;
		end
		else if (CE_R) begin
			if (!RES_N) begin
				IPRA <= IPRA_INIT;
				IPRB <= IPRB_INIT;
				IPRC <= IPRC_INIT;
				IPRD <= IPRD_INIT;
				IPRE <= IPRE_INIT;
				ICR  <= ICR_INIT;
				ICR.NMIL <= NMI_N;
			end
			else if (REG_SEL && IBUS_WE && IBUS_REQ) begin
				case ({IBUS_A[3:2],2'b00})
					4'h4: begin
						if (IBUS_BA[3]) IPRA[15: 8] = IBUS_DI[31:24] & IPRA_WMASK[15:8];
						if (IBUS_BA[2]) IPRA[ 7: 0] = IBUS_DI[23:16] & IPRA_WMASK[ 7:0];
						if (IBUS_BA[1]) IPRB[15: 8] = IBUS_DI[15: 8] & IPRB_WMASK[15:8];
						if (IBUS_BA[0]) IPRB[ 7: 0] = IBUS_DI[15: 8] & IPRB_WMASK[ 7:0];
					end
					4'h8: begin
						if (IBUS_BA[3]) IPRC[15: 8] = IBUS_DI[31:24] & IPRC_WMASK[15:8];
						if (IBUS_BA[2]) IPRC[ 7: 0] = IBUS_DI[23:16] & IPRC_WMASK[ 7:0];
						if (IBUS_BA[1]) IPRD[15: 8] = IBUS_DI[15: 8] & IPRD_WMASK[15:8];
						if (IBUS_BA[0]) IPRD[ 7: 0] = IBUS_DI[ 7: 0] & IPRD_WMASK[ 7:0];
					end
					4'hC: begin
						if (IBUS_BA[3]) IPRE[15:8] = IBUS_DI[31:24] & IPRE_WMASK[15:8];
						if (IBUS_BA[2]) IPRE[ 7:0] = IBUS_DI[23:16] & IPRE_WMASK[ 7:0];
						if (IBUS_BA[1]) ICR[15:8]  = IBUS_DI[15: 8] & ICR_WMASK[15:8];
						if (IBUS_BA[0]) ICR[ 7:0]  = IBUS_DI[ 7: 0] & ICR_WMASK[ 7:0];
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
				case ({IBUS_A[3:2],2'b00})
					4'h4: BUS_DO <= {IPRA & IPRA_RMASK,IPRB & IPRB_RMASK};
					4'h8: BUS_DO <= {IPRC & IPRC_RMASK,IPRD & IPRD_RMASK};
					4'hC: BUS_DO <= {IPRE & IPRE_RMASK,ICR & ICR_RMASK};
					default:BUS_DO <= '0;
				endcase
			end
		end
	end
	
	assign IBUS_DO = BUS_DO;
	assign IBUS_BUSY = 0;
	assign IBUS_ACT = REG_SEL;

endmodule
