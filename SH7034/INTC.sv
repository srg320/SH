module SH7034_INTC (
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
	
	input             VBUS_WAIT,
	
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
	
	const bit [ 5: 0] NMI_INT       = 6'd1;
	const bit [ 5: 0] UBC_INT       = 6'd2;
	const bit [ 5: 0] IRQ0_INT      = 6'd3;
	const bit [ 5: 0] IRQ1_INT      = 6'd4; 
	const bit [ 5: 0] IRQ2_INT      = 6'd5; 
	const bit [ 5: 0] IRQ3_INT      = 6'd6; 
	const bit [ 5: 0] IRQ4_INT      = 6'd7;
	const bit [ 5: 0] IRQ5_INT      = 6'd8;
	const bit [ 5: 0] IRQ6_INT      = 6'd9;
	const bit [ 5: 0] IRQ7_INT      = 6'd10; 
	const bit [ 5: 0] DMAC0_INT     = 6'd11;
	const bit [ 5: 0] DMAC1_INT     = 6'd12;
	const bit [ 5: 0] DMAC2_INT     = 6'd13;
	const bit [ 5: 0] DMAC3_INT     = 6'd14;
	const bit [ 5: 0] WDT_INT       = 6'd15;
	const bit [ 5: 0] BSC_INT       = 6'd16;
	const bit [ 5: 0] SCI0_ERI_INT  = 6'd17;
	const bit [ 5: 0] SCI0_RXI_INT  = 6'd18;
	const bit [ 5: 0] SCI0_TXI_INT  = 6'd19;
	const bit [ 5: 0] SCI0_TEI_INT  = 6'd20;
	const bit [ 5: 0] SCI1_ERI_INT  = 6'd21;
	const bit [ 5: 0] SCI1_RXI_INT  = 6'd22; 
	const bit [ 5: 0] SCI1_TXI_INT  = 6'd23;
	const bit [ 5: 0] SCI1_TEI_INT  = 6'd24;
	const bit [ 5: 0] ITU0_IMIA_INT = 6'd25;
	const bit [ 5: 0] ITU0_IMIB_INT = 6'd26;
	const bit [ 5: 0] ITU0_OVI_INT  = 6'd27;
	const bit [ 5: 0] ITU1_IMIA_INT = 6'd28; 
	const bit [ 5: 0] ITU1_IMIB_INT = 6'd29;
	const bit [ 5: 0] ITU1_OVI_INT  = 6'd30;
	const bit [ 5: 0] ITU2_IMIA_INT = 6'd31;
	const bit [ 5: 0] ITU2_IMIB_INT = 6'd32;
	const bit [ 5: 0] ITU2_OVI_INT  = 6'd33;
	const bit [ 5: 0] ITU3_IMIA_INT = 6'd34;
	const bit [ 5: 0] ITU3_IMIB_INT = 6'd35;
	const bit [ 5: 0] ITU3_OVI_INT  = 6'd36;
	const bit [ 5: 0] ITU4_IMIA_INT = 6'd37;
	const bit [ 5: 0] ITU4_IMIB_INT = 6'd38;
	const bit [ 5: 0] ITU4_OVI_INT  = 6'd39;

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
	bit [38:0] INT_PEND;
	bit        VBREQ;
	
	always @(posedge CLK or negedge RST_N) begin
		bit NMI_N_OLD;
		
		if (!RST_N) begin
			NMI_REQ <= 0;
		end
		else if (CE_R) begin	
			NMI_N_OLD <= NMI_N;
			if (~(NMI_N ^ ICR.NMIE) && (NMI_N_OLD ^ ICR.NMIE) && !NMI_REQ) begin
				NMI_REQ <= 1;
			end
			else if (INT_ACP && NMI_REQ) begin
				NMI_REQ <= 0;
			end
		end
	end
	
	always @(posedge CLK or negedge RST_N) begin
		bit [7:0] IRQ_OLD;
		
		if (!RST_N) begin
			IRQ_OLD <= '{2{'0}};
			IRQ_REQ <= '0;
		end
		else if (CE_R) begin	
			IRQ_OLD <= ~IRQ_N;
			for (int i=0; i<8; i++) begin
				IRQ_REQ[i] <= 0;
				if (IRQ_OLD[i] && !IRQ_N[i]) begin
					IRQ_REQ[i] <= 1;
				end
			end
		end
	end
	
	bit [ 5: 0] INT_ACTIVE;
	bit [ 5: 0] INT_ACCEPTED;
	always_comb begin
				if (NMI_REQ)                                        begin INT_ACTIVE <= NMI_INT; end
				else if (UBC_IRQ         && 4'hF        > INT_MASK) begin INT_ACTIVE <= UBC_INT; end
				else if (IRQ_REQ[0]      && IPRA.IRQ0   > INT_MASK) begin INT_ACTIVE <= IRQ0_INT; end
				else if (IRQ_REQ[1]      && IPRA.IRQ1   > INT_MASK) begin INT_ACTIVE <= IRQ1_INT; end
				else if (IRQ_REQ[2]      && IPRA.IRQ2   > INT_MASK) begin INT_ACTIVE <= IRQ2_INT; end
				else if (IRQ_REQ[3]      && IPRA.IRQ3   > INT_MASK) begin INT_ACTIVE <= IRQ3_INT; end
				else if (IRQ_REQ[4]      && IPRB.IRQ4   > INT_MASK) begin INT_ACTIVE <= IRQ4_INT; end
				else if (IRQ_REQ[5]      && IPRB.IRQ5   > INT_MASK) begin INT_ACTIVE <= IRQ5_INT; end
				else if (IRQ_REQ[6]      && IPRB.IRQ6   > INT_MASK) begin INT_ACTIVE <= IRQ6_INT; end
				else if (IRQ_REQ[7]      && IPRB.IRQ7   > INT_MASK) begin INT_ACTIVE <= IRQ7_INT; end
				else if (DMAC0_IRQ       && IPRC.DMAC01 > INT_MASK) begin INT_ACTIVE <= DMAC0_INT; end
				else if (DMAC1_IRQ       && IPRC.DMAC01 > INT_MASK) begin INT_ACTIVE <= DMAC1_INT; end
				else if (DMAC2_IRQ       && IPRC.DMAC23 > INT_MASK) begin INT_ACTIVE <= DMAC2_INT; end
				else if (DMAC3_IRQ       && IPRC.DMAC23 > INT_MASK) begin INT_ACTIVE <= DMAC3_INT; end
				else if (WDT_IRQ         && IPRE.WDT    > INT_MASK) begin INT_ACTIVE <= WDT_INT; end
				else if (BSC_IRQ         && IPRE.WDT    > INT_MASK) begin INT_ACTIVE <= BSC_INT; end
				else if (SCI0_ERI_IRQ    && IPRD.SCI0   > INT_MASK) begin INT_ACTIVE <= SCI0_ERI_INT; end
				else if (SCI0_RXI_IRQ    && IPRD.SCI0   > INT_MASK) begin INT_ACTIVE <= SCI0_RXI_INT; end
				else if (SCI0_TXI_IRQ    && IPRD.SCI0   > INT_MASK) begin INT_ACTIVE <= SCI0_TXI_INT; end
				else if (SCI0_TEI_IRQ    && IPRD.SCI0   > INT_MASK) begin INT_ACTIVE <= SCI0_TEI_INT; end
				else if (SCI1_ERI_IRQ    && IPRE.SCI1   > INT_MASK) begin INT_ACTIVE <= SCI1_ERI_INT; end
				else if (SCI1_RXI_IRQ    && IPRE.SCI1   > INT_MASK) begin INT_ACTIVE <= SCI1_RXI_INT; end
				else if (SCI1_TXI_IRQ    && IPRE.SCI1   > INT_MASK) begin INT_ACTIVE <= SCI1_TXI_INT; end
				else if (SCI1_TEI_IRQ    && IPRE.SCI1   > INT_MASK) begin INT_ACTIVE <= SCI1_TEI_INT; end
				else if (ITU_IMIA_IRQ[0] && IPRC.ITU0   > INT_MASK) begin INT_ACTIVE <= ITU0_IMIA_INT; end
				else if (ITU_IMIB_IRQ[0] && IPRC.ITU0   > INT_MASK) begin INT_ACTIVE <= ITU0_IMIB_INT; end
				else if (ITU_OVI_IRQ[0]  && IPRC.ITU0   > INT_MASK) begin INT_ACTIVE <= ITU0_OVI_INT; end
				else if (ITU_IMIA_IRQ[1] && IPRC.ITU1   > INT_MASK) begin INT_ACTIVE <= ITU1_IMIA_INT; end
				else if (ITU_IMIB_IRQ[1] && IPRC.ITU1   > INT_MASK) begin INT_ACTIVE <= ITU1_IMIB_INT; end
				else if (ITU_OVI_IRQ[1]  && IPRC.ITU1   > INT_MASK) begin INT_ACTIVE <= ITU1_OVI_INT; end
				else if (ITU_IMIA_IRQ[2] && IPRD.ITU2   > INT_MASK) begin INT_ACTIVE <= ITU2_IMIA_INT; end
				else if (ITU_IMIB_IRQ[2] && IPRD.ITU2   > INT_MASK) begin INT_ACTIVE <= ITU2_IMIB_INT; end
				else if (ITU_OVI_IRQ[2]  && IPRD.ITU2   > INT_MASK) begin INT_ACTIVE <= ITU2_OVI_INT; end
				else if (ITU_IMIA_IRQ[3] && IPRD.ITU3   > INT_MASK) begin INT_ACTIVE <= ITU3_IMIA_INT; end
				else if (ITU_IMIB_IRQ[3] && IPRD.ITU3   > INT_MASK) begin INT_ACTIVE <= ITU3_IMIB_INT; end
				else if (ITU_OVI_IRQ[3]  && IPRD.ITU3   > INT_MASK) begin INT_ACTIVE <= ITU3_OVI_INT; end
				else if (ITU_IMIA_IRQ[4] && IPRD.ITU4   > INT_MASK) begin INT_ACTIVE <= ITU4_IMIA_INT; end
				else if (ITU_IMIB_IRQ[4] && IPRD.ITU4   > INT_MASK) begin INT_ACTIVE <= ITU4_IMIB_INT; end
				else if (ITU_OVI_IRQ[4]  && IPRD.ITU4   > INT_MASK) begin INT_ACTIVE <= ITU4_OVI_INT; end
				else                                                begin INT_ACTIVE <= 6'd0; end
	end
	assign INT_REQ = |INT_ACTIVE;
	
	always_comb begin
		case (INT_ACTIVE)
			NMI_INT:       INT_LVL <= 4'hF;
			UBC_INT:       INT_LVL <= 4'hF;
			IRQ0_INT:      INT_LVL <= IPRA.IRQ0;
			IRQ1_INT:      INT_LVL <= IPRA.IRQ1;
			IRQ2_INT:      INT_LVL <= IPRA.IRQ2;
			IRQ3_INT:      INT_LVL <= IPRA.IRQ3;
			IRQ4_INT:      INT_LVL <= IPRB.IRQ4;
			IRQ5_INT:      INT_LVL <= IPRB.IRQ5;
			IRQ6_INT:      INT_LVL <= IPRB.IRQ6;
			IRQ7_INT:      INT_LVL <= IPRB.IRQ7;
			DMAC0_INT:     INT_LVL <= IPRC.DMAC01;
			DMAC1_INT:     INT_LVL <= IPRC.DMAC01;
			DMAC2_INT:     INT_LVL <= IPRC.DMAC23;
			DMAC3_INT:     INT_LVL <= IPRC.DMAC23;
			WDT_INT:       INT_LVL <= IPRE.WDT;
			BSC_INT:       INT_LVL <= IPRE.WDT;
			SCI0_ERI_INT:  INT_LVL <= IPRD.SCI0;
			SCI0_RXI_INT:  INT_LVL <= IPRD.SCI0;
			SCI0_TXI_INT:  INT_LVL <= IPRD.SCI0;
			SCI0_TEI_INT:  INT_LVL <= IPRD.SCI0;
			SCI1_ERI_INT:  INT_LVL <= IPRE.SCI1;
			SCI1_RXI_INT:  INT_LVL <= IPRE.SCI1;
			SCI1_TXI_INT:  INT_LVL <= IPRE.SCI1;
			SCI1_TEI_INT:  INT_LVL <= IPRE.SCI1;
			ITU0_IMIA_INT: INT_LVL <= IPRC.ITU0;
			ITU0_IMIB_INT: INT_LVL <= IPRC.ITU0;
			ITU0_OVI_INT:  INT_LVL <= IPRC.ITU0;
			ITU1_IMIA_INT: INT_LVL <= IPRC.ITU1;
			ITU1_IMIB_INT: INT_LVL <= IPRC.ITU1;
			ITU1_OVI_INT:  INT_LVL <= IPRC.ITU1;
			ITU2_IMIA_INT: INT_LVL <= IPRD.ITU2;
			ITU2_IMIB_INT: INT_LVL <= IPRD.ITU2;
			ITU2_OVI_INT:  INT_LVL <= IPRD.ITU2;
			ITU3_IMIA_INT: INT_LVL <= IPRD.ITU3;
			ITU3_IMIB_INT: INT_LVL <= IPRD.ITU3;
			ITU3_OVI_INT:  INT_LVL <= IPRD.ITU3;
			ITU4_IMIA_INT: INT_LVL <= IPRD.ITU4;
			ITU4_IMIB_INT: INT_LVL <= IPRD.ITU4;
			ITU4_OVI_INT:  INT_LVL <= IPRD.ITU4;
			default:       INT_LVL <= 4'h0;
		endcase
	end
	
	always_comb begin
		case (INT_ACCEPTED)
			NMI_INT:       INT_VEC <= 8'd11;
			UBC_INT:       INT_VEC <= 8'd12;
			IRQ0_INT:      INT_VEC <= 8'd64;
			IRQ1_INT:      INT_VEC <= 8'd65;
			IRQ2_INT:      INT_VEC <= 8'd66;
			IRQ3_INT:      INT_VEC <= 8'd67;
			IRQ4_INT:      INT_VEC <= 8'd68;
			IRQ5_INT:      INT_VEC <= 8'd69;
			IRQ6_INT:      INT_VEC <= 8'd70;
			IRQ7_INT:      INT_VEC <= 8'd71;
			DMAC0_INT:     INT_VEC <= 8'd72;
			DMAC1_INT:     INT_VEC <= 8'd74;
			DMAC2_INT:     INT_VEC <= 8'd76;
			DMAC3_INT:     INT_VEC <= 8'd78;
			WDT_INT:       INT_VEC <= 8'd112;
			BSC_INT:       INT_VEC <= 8'd113;
			SCI0_ERI_INT:  INT_VEC <= 8'd100;
			SCI0_RXI_INT:  INT_VEC <= 8'd101;
			SCI0_TXI_INT:  INT_VEC <= 8'd102;
			SCI0_TEI_INT:  INT_VEC <= 8'd103;
			SCI1_ERI_INT:  INT_VEC <= 8'd104;
			SCI1_RXI_INT:  INT_VEC <= 8'd105;
			SCI1_TXI_INT:  INT_VEC <= 8'd106;
			SCI1_TEI_INT:  INT_VEC <= 8'd107;
			ITU0_IMIA_INT: INT_VEC <= 8'd80;
			ITU0_IMIB_INT: INT_VEC <= 8'd81;
			ITU0_OVI_INT:  INT_VEC <= 8'd82;
			ITU1_IMIA_INT: INT_VEC <= 8'd84;
			ITU1_IMIB_INT: INT_VEC <= 8'd85;
			ITU1_OVI_INT:  INT_VEC <= 8'd86;
			ITU2_IMIA_INT: INT_VEC <= 8'd88;
			ITU2_IMIB_INT: INT_VEC <= 8'd89;
			ITU2_OVI_INT:  INT_VEC <= 8'd90;
			ITU3_IMIA_INT: INT_VEC <= 8'd92;
			ITU3_IMIB_INT: INT_VEC <= 8'd93;
			ITU3_OVI_INT:  INT_VEC <= 8'd94;
			ITU4_IMIA_INT: INT_VEC <= 8'd96;
			ITU4_IMIB_INT: INT_VEC <= 8'd97;
			ITU4_OVI_INT:  INT_VEC <= 8'd98;
			default:       INT_VEC <= 8'd0;
		endcase
	end
	
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			VBREQ <= 0;
			INT_ACCEPTED <= '0;
		end else if (CE_F) begin	
			if (VECT_REQ && !VBREQ) begin
				VBREQ <= 1;
			end else if (VBREQ && !VBUS_WAIT) begin
				VBREQ <= 0;
			end
		end else if (CE_R) begin	
			if (INT_ACP) INT_ACCEPTED <= INT_ACTIVE;
			if (INT_ACK) INT_ACCEPTED <= '0;
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
						if (IBUS_BA[0]) IPRB[ 7: 0] = IBUS_DI[ 7: 0] & IPRB_WMASK[ 7:0];
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
