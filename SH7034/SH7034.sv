module SH7034(
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	
	input             RES_N,
	input             NMI_N,
	input             IRQ0_N,
	input             IRQ1_N,
	input             IRQ2_N,
	input             IRQ3_N,
	input             IRQ4_N,
	input             IRQ5_N,
	input             IRQ6_N,
	input             IRQ7_N,
	
	output     [21:0] A,
	input      [15:0] DI,
	output     [15:0] DO,
	output            CS0_N,
	output            CS1_N,
	output            CS2_N,
	output            CS3_N,
	output            CS4_N,
	output            CS5_N,
	output            CS6_N,
	output            CS7_N,
	output      [1:0] WE_N,
	output            RD_N,
	
	input      [21:0] EA,
	output     [15:0] EDI,
	input      [15:0] EDO,
	input             ECS0_N,
	input             ECS1_N,
	input             ECS2_N,
	input             ECS3_N,
	input             ECS4_N,
	input             ECS5_N,
	input             ECS6_N,
	input             ECS7_N,
	input       [1:0] EWE_N,
	input             ERD_N,
	
	input             WAIT_N,
	input             BREQ_N,
	output            BACK_N,
	
	input             DREQ0,
	output            DACK0,
	input             DREQ1,
	output            DACK1,
	
	input             RXD0,
	output            TXD0,
	output            SCKO0,
	input             SCKI0,
	input             RXD1,
	output            TXD1,
	output            SCKO1,
	input             SCKI1,
	
	output            WDTOVF_N,
	
	input       [2:0] MD
);
	import SH7034_PKG::*;
	
	bit [27:0] CBUS_A;
	bit [31:0] CBUS_DO;
	bit [31:0] CBUS_DI;
	bit        CBUS_WR;
	bit  [3:0] CBUS_BA;
	bit        CBUS_REQ;
	
	bit [27:0] IBUS_A;
	bit [31:0] IBUS_DO;
	bit [31:0] IBUS_DI;
	bit  [3:0] IBUS_BA;
	bit        IBUS_WE;
	bit        IBUS_REQ;
	bit        IBUS_WAIT;
	bit        IBUS_LOCK;
	
	bit  [3:0] INT_LVL;
	bit  [7:0] INT_VEC;
	bit        INT_REQ;
	bit  [3:0] INT_MASK;
	bit        INT_ACK;
	bit        INT_ACP;
	bit        VECT_REQ;
	bit        VECT_WAIT;
	
	//BSC
	bit [31:0] BSC_DO;
	bit        BSC_BUSY;
	bit        BSC_ACK;
	
	//DMAC
	bit [31:0] DMAC_DO;
	bit        DMAC_ACT;
	bit        DMAC_BUSY;
	bit        DMAC0_IRQ;
	bit  [7:0] DMAC0_VEC;
	bit        DMAC1_IRQ;
	bit  [7:0] DMAC1_VEC;
	
	//INTC
	bit [31:0] INTC_DO;
	bit        INTC_ACT;
	bit        INTC_BUSY;
	
	//MULT
	bit  [1:0] MAC_SEL;
	bit  [3:0] MAC_OP;
	bit        MAC_S;
	bit        MAC_WE;
	bit [31:0] MULT_DO;
	
	//SCI
	bit [31:0] SCI0_DO;
	bit [31:0] SCI1_DO;
	bit        SCI_ACT0;
	bit        SCI_ACT1;
	bit        TEI0_IRQ;
	bit        TXI0_IRQ;
	bit        RXI0_IRQ;
	bit        ERI0_IRQ;
	bit        TEI1_IRQ;
	bit        TXI1_IRQ;
	bit        RXI1_IRQ;
	bit        ERI1_IRQ;
	
	//FRT
	bit [31:0] FRT_DO;
	bit        FRT_ACT;
	bit        ICI_IRQ;
	bit        OCIA_IRQ;
	bit        OCIB_IRQ;
	bit        OVI_IRQ;
	
	//WDT
	bit [31:0] WDT_DO;
	bit        WDT_ACT;
	bit        ITI_IRQ;
	bit        WDT_PRES;
	bit        WDT_MRES;
	
	//UBC
	bit [31:0] UBC_DO;
	bit        UBC_ACT;
	bit        UBC_IRQ;
	
	//Internal clocks
	bit        CLK4_CE;
	bit        CLK8_CE;
	bit        CLK16_CE;
	bit        CLK32_CE;
	bit        CLK64_CE;
	bit        CLK128_CE;
	bit        CLK256_CE;
	bit        CLK512_CE;
	bit        CLK1024_CE;
	//bit        CLK2048_CE;
	bit        CLK4096_CE;
	bit        CLK8192_CE;
	
	SH_core core
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE(CE_R),
		
		.RES_N(RES_N),
		.NMI_N(NMI_N),
		
		.BUS_A(CBUS_A),
		.BUS_DI(CBUS_DI),
		.BUS_DO(CBUS_DO),
		.BUS_WR(CBUS_WR),
		.BUS_BA(CBUS_BA),
		.BUS_REQ(CBUS_REQ),
		.BUS_WAIT(CACHE_BUSY),
		
		.MAC_SEL(MAC_SEL),
		.MAC_OP(MAC_OP),
		.MAC_S(MAC_S),
		.MAC_WE(MAC_WE),
		
		.INT_LVL(INT_LVL),
		.INT_VEC(INT_VEC),
		.INT_REQ(INT_REQ),
		.INT_MASK(INT_MASK),
		.INT_ACK(INT_ACK),
		.INT_ACP(INT_ACP),
		.VECT_REQ(VECT_REQ),
		.VECT_WAIT(VECT_WAIT)
	);
	
	assign CBUS_DI = MAC_SEL ? MULT_DO : IBUS_DI;
	
	wire [31:0] MULT_DI = MAC_SEL && MAC_OP[3:2] == 2'b10 ? IBUS_DI : CBUS_DO;
	MULT mult
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.RES_N(RES_N),
		
		.CBUS_A(CBUS_A),
		.CBUS_DI(MULT_DI),
		.CBUS_DO(MULT_DO),
		.CBUS_WR(CBUS_WR),
		.CBUS_BA(CBUS_BA),
		.CBUS_REQ(CBUS_REQ),
		.CBUS_BUSY(),
		
		.MAC_SEL(MAC_SEL),
		.MAC_OP(MAC_OP),
		.MAC_S(MAC_S),
		.MAC_WE(MAC_WE)
	);
	
	assign IBUS_DO = MAC_SEL && !MAC_OP && !MAC_WE ? MULT_DO : CBUS_DO;
	
	assign IBUS_DI = INTC_ACT ? INTC_DO : 
//						  FRT_ACT  ? FRT_DO : 
						  WDT_ACT  ? WDT_DO : 
						  SCI0_ACT ? SCI0_DO : 
						  SCI1_ACT ? SCI1_DO : 
//						  UBC_ACT  ? UBC_DO : 
//						  DMAC_ACT ? DMAC_DO : 
						  BSC_DO;
	assign IBUS_WAIT = DMAC_BUSY | INTC_BUSY;

	
//	UBC UBC
//	(
//		.CLK(CLK),
//		.RST_N(RST_N),
//		.CE_R(CE_R),
//		.CE_F(CE_F),
//		
//		.RES_N(RES_N),
//		
//		.IBUS_A(IBUS_A),
//		.IBUS_DI(IBUS_DO),
//		.IBUS_DO(UBC_DO),
//		.IBUS_BA(IBUS_BA),
//		.IBUS_WE(IBUS_WE),
//		.IBUS_REQ(IBUS_REQ),
//		.IBUS_BUSY(),
//		.IBUS_ACT(UBC_ACT),
//		
//		.IRQ(UBC_IRQ)
//	);
	
	bit  [28:0] DBUS_A;
	bit  [31:0] DBUS_DI;
	bit  [31:0] DBUS_DO;
	bit   [3:0] DBUS_BA;
	bit         DBUS_WE;
	bit         DBUS_REQ;
	bit         DBUS_WAIT;
	bit         DBUS_LOCK;
//	DMAC dmac
//	(
//		.CLK(CLK),
//		.RST_N(RST_N),
//		.CE_R(CE_R),
//		.CE_F(CE_F),
//		
//		.RES_N(RES_N),
//		.NMI_N(NMI_N),
//		
//		.DREQ0(DREQ0),
//		.DACK0(DACK0),
//		.DREQ1(DREQ1),
//		.DACK1(DACK1),
//		
//		.RXI_IRQ(1'b0),
//		.TXI_IRQ(1'b0),
//		
//		.IBUS_A(IBUS_A),
//		.IBUS_DI(IBUS_DO),
//		.IBUS_DO(DMAC_DO),
//		.IBUS_BA(IBUS_BA),
//		.IBUS_WE(IBUS_WE),
//		.IBUS_REQ(IBUS_REQ),
//		.IBUS_BUSY(DMAC_BUSY),
//		.IBUS_LOCK(IBUS_LOCK),
//		.IBUS_ACT(DMAC_ACT),
//		
//		.DBUS_A(DBUS_A),
//		.DBUS_DI(BSC_DO),
//		.DBUS_DO(DBUS_DO),
//		.DBUS_BA(DBUS_BA),
//		.DBUS_WE(DBUS_WE),
//		.DBUS_REQ(DBUS_REQ),
//		.DBUS_WAIT(BSC_BUSY | DIVU_BUSY),
//		.DBUS_LOCK(DBUS_LOCK),
//		
//		.BSC_ACK(BSC_ACK),
//		
//		.DMAC0_IRQ(DMAC0_IRQ),
//		.DMAC0_VEC(DMAC0_VEC),
//		.DMAC1_IRQ(DMAC1_IRQ),
//		.DMAC1_VEC(DMAC1_VEC)
//	);
	assign DBUS_A = CBUS_A;
	assign DBUS_DO = IBUS_DO;
	assign DBUS_BA = CBUS_BA;
	assign DBUS_WE = CBUS_WR;
	assign DBUS_REQ = CBUS_REQ;
	assign CACHE_BUSY = BSC_BUSY;
	
	bit  [23:0] IA;
	bit  [15:0] IDI;
	bit  [15:0] IDO;
	bit         ICS0_N;
	bit         ICS1_N;
	bit         ICS2_N;
	bit         ICS3_N;
	bit         ICS4_N;
	bit         ICS5_N;
	bit         ICS6_N;
	bit         ICS7_N;
	bit   [1:0] IWE_N;
	bit         IRD_N;
	bit         BUS_RLS;
	BSC #(.AREA3(0), .W3(1), .IW3(0), .LW3(0)) bsc
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.RES_N(RES_N),
		
		.A(IA),
		.DI(IDI),
		.DO(IDO),
		.CS0_N(ICS0_N),
		.CS1_N(ICS1_N),
		.CS2_N(ICS2_N),
		.CS3_N(ICS3_N),
		.CS4_N(ICS4_N),
		.CS5_N(ICS5_N),
		.CS6_N(ICS6_N),
		.CS7_N(ICS7_N),
		.WE_N(IWE_N),
		.RD_N(IRD_N),
		.WAIT_N(WAIT_N),
		.BREQ_N(BREQ_N),
		.BACK_N(BACK_N),
		.MD(MD),
		
		.IBUS_A(DBUS_A),
		.IBUS_DI(DBUS_DO),
		.IBUS_DO(BSC_DO),
		.IBUS_BA(DBUS_BA),
		.IBUS_WE(DBUS_WE),
		.IBUS_REQ(DBUS_REQ),
		.IBUS_BUSY(BSC_BUSY),
		.IBUS_LOCK(DBUS_LOCK),
		.IBUS_ACT(),
		
		.IRQ(),
		
		.CACK(BSC_ACK),
		.BUS_RLS(BUS_RLS)
	);
	
	assign {A,DO}                         = !BUS_RLS ? {IA[21:0],IDO} : {EA,EDO};
	assign IDI                            = !BUS_RLS ? DI        : EDO;
	assign {CS0_N,CS1_N,CS2_N,CS3_N,CS4_N,CS5_N,CS6_N,CS7_N} = !BUS_RLS ? {ICS0_N,ICS1_N,ICS2_N,ICS3_N,ICS4_N,ICS5_N,ICS6_N,ICS7_N} : {ECS0_N,ECS1_N,ECS2_N,ECS3_N,ECS4_N,ECS5_N,ECS6_N,ECS7_N};
	assign {WE_N,RD_N}  = !BUS_RLS ? {IWE_N,IRD_N}  : {EWE_N,ERD_N};
	assign EDI = DI;
	
	
	INTC intc
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.RES_N(RES_N),
		.NMI_N(NMI_N),
		.IRQ0_N(IRQ0_N),
		.IRQ1_N(IRQ1_N),
		.IRQ2_N(IRQ2_N),
		.IRQ3_N(IRQ3_N),
		.IRQ4_N(IRQ4_N),
		.IRQ5_N(IRQ5_N),
		.IRQ6_N(IRQ6_N),
		.IRQ7_N(IRQ7_N),
		
		.INT_MASK(INT_MASK),
		.INT_ACK(INT_ACK),
		.INT_ACP(INT_ACP),
		.INT_LVL(INT_LVL),
		.INT_VEC(INT_VEC),
		.INT_REQ(INT_REQ),
		.VECT_REQ(VECT_REQ),
		.VECT_WAIT(VECT_WAIT),
		
		.UBC_IRQ(UBC_IRQ),
		.DMAC0_IRQ(DMAC0_IRQ),
		.DMAC1_IRQ(DMAC1_IRQ),
		.WDT_IRQ(ITI_IRQ),
		.BSC_IRQ(1'b0),
		.SCI0_ERI_IRQ(ERI0_IRQ),
		.SCI0_RXI_IRQ(RXI0_IRQ),
		.SCI0_TXI_IRQ(TXI0_IRQ),
		.SCI0_TEI_IRQ(TEI0_IRQ),
		.SCI1_ERI_IRQ(ERI1_IRQ),
		.SCI1_RXI_IRQ(RXI1_IRQ),
		.SCI1_TXI_IRQ(TXI1_IRQ),
		.SCI1_TEI_IRQ(TEI1_IRQ),
		.FRT_ICI_IRQ(ICI_IRQ),
		.FRT_OCI_IRQ(OCIA_IRQ | OCIB_IRQ),
		.FRT_OVI_IRQ(OVI_IRQ),
		
		.IBUS_A(DBUS_A),
		.IBUS_DI(DBUS_DO),
		.IBUS_DO(INTC_DO),
		.IBUS_BA(DBUS_BA),
		.IBUS_WE(DBUS_WE),
		.IBUS_REQ(DBUS_REQ),
		.IBUS_BUSY(INTC_BUSY),
		.IBUS_ACT(INTC_ACT)
	);

	
	//Clock divider
	always @(posedge CLK or negedge RST_N) begin
		bit [12:0] DIV_CNT;
		
		if (!RST_N) begin
			CLK4_CE <= 0;
			CLK8_CE <= 0;
			CLK16_CE <= 0;
			CLK32_CE <= 0;
			CLK64_CE <= 0;
			CLK128_CE <= 0;
			CLK256_CE <= 0;
			CLK512_CE <= 0;
			CLK1024_CE <= 0;
			//CLK2048_CE <= 0;
			CLK4096_CE <= 0;
			CLK8192_CE <= 0;
			DIV_CNT <= '0;
		end
		else if (CE_R) begin	
			DIV_CNT <= DIV_CNT + 13'd1;
			
			CLK4_CE    <= (DIV_CNT ==? 13'b???????????11);
			CLK8_CE    <= (DIV_CNT ==? 13'b??????????111);
			CLK16_CE   <= (DIV_CNT ==? 13'b?????????1111);
			CLK32_CE   <= (DIV_CNT ==? 13'b????????11111);
			CLK64_CE   <= (DIV_CNT ==? 13'b???????111111);
			CLK128_CE  <= (DIV_CNT ==? 13'b??????1111111);
			CLK256_CE  <= (DIV_CNT ==? 13'b?????11111111);
			CLK512_CE  <= (DIV_CNT ==? 13'b????111111111);
			CLK1024_CE <= (DIV_CNT ==? 13'b???1111111111);
			//CLK2048_CE <= (DIV_CNT ==? 13'b??11111111111);
			CLK4096_CE <= (DIV_CNT ==? 13'b?111111111111);
			CLK8192_CE <= (DIV_CNT ==? 13'b1111111111111);
		end
	end

	SCI #(0) sci0
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.RES_N(RES_N),
		
		.RXD(RXD0),
		.TXD(TXD0),
		.SCKO(SCKO0),
		.SCKI(SCKI0),
		
		.CLK4_CE(CLK4_CE),
		.CLK16_CE(CLK16_CE),
		.CLK64_CE(CLK64_CE),
		.CLK256_CE(CLK256_CE),
		
		.IBUS_A(DBUS_A),
		.IBUS_DI(DBUS_DO),
		.IBUS_DO(SCI0_DO),
		.IBUS_BA(DBUS_BA),
		.IBUS_WE(DBUS_WE),
		.IBUS_REQ(DBUS_REQ),
		.IBUS_BUSY(),
		.IBUS_ACT(SCI0_ACT),
		
		.TEI_IRQ(TEI0_IRQ),
		.TXI_IRQ(TXI0_IRQ),
		.RXI_IRQ(RXI0_IRQ),
		.ERI_IRQ(ERI0_IRQ)
	);

	SCI #(1) sci1
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.RES_N(RES_N),
		
		.RXD(RXD1),
		.TXD(TXD1),
		.SCKO(SCKO1),
		.SCKI(SCKI1),
		
		.CLK4_CE(CLK4_CE),
		.CLK16_CE(CLK16_CE),
		.CLK64_CE(CLK64_CE),
		.CLK256_CE(CLK256_CE),
		
		.IBUS_A(DBUS_A),
		.IBUS_DI(DBUS_DO),
		.IBUS_DO(SCI1_DO),
		.IBUS_BA(DBUS_BA),
		.IBUS_WE(DBUS_WE),
		.IBUS_REQ(DBUS_REQ),
		.IBUS_BUSY(),
		.IBUS_ACT(SCI1_ACT),
		
		.TEI_IRQ(TEI1_IRQ),
		.TXI_IRQ(TXI1_IRQ),
		.RXI_IRQ(RXI1_IRQ),
		.ERI_IRQ(ERI1_IRQ)
	);
	
//	FRT frt
//	(
//		.CLK(CLK),
//		.RST_N(RST_N),
//		.CE_R(CE_R),
//		.CE_F(CE_F),
//		
//		.RES_N(RES_N),
//		
//		.FTOA(FTOA),
//		.FTOB(FTOB),
//		.FTCI(FTCI),
//		.FTI(FTI),
//		
//		.CLK8_CE(CLK8_CE),
//		.CLK32_CE(CLK32_CE),
//		.CLK128_CE(CLK128_CE),
//		
//		.IBUS_A(DBUS_A),
//		.IBUS_DI(DBUS_DO),
//		.IBUS_DO(FRT_DO),
//		.IBUS_BA(DBUS_BA),
//		.IBUS_WE(DBUS_WE),
//		.IBUS_REQ(DBUS_REQ),
//		.IBUS_BUSY(),
//		.IBUS_ACT(FRT_ACT),
//		
//		.ICI_IRQ(ICI_IRQ),
//		.OCIA_IRQ(OCIA_IRQ),
//		.OCIB_IRQ(OCIB_IRQ),
//		.OVI_IRQ(OVI_IRQ)
//	);
	
	WDT wdt
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.RES_N(RES_N),
		
		.WDTOVF_N(WDTOVF_N),
		
		.CLK2_CE(CLK8_CE),
		.CLK64_CE(CLK64_CE),
		.CLK128_CE(CLK128_CE),
		.CLK256_CE(CLK256_CE),
		.CLK512_CE(CLK512_CE),
		.CLK1024_CE(CLK1024_CE),
		.CLK4096_CE(CLK4096_CE),
		.CLK8192_CE(CLK8192_CE),
		
		.IBUS_A(DBUS_A),
		.IBUS_DI(DBUS_DO),
		.IBUS_DO(WDT_DO),
		.IBUS_BA(DBUS_BA),
		.IBUS_WE(DBUS_WE),
		.IBUS_REQ(DBUS_REQ),
		.IBUS_BUSY(),
		.IBUS_ACT(WDT_ACT),
		
		.ITI_IRQ(ITI_IRQ),
		.PRES(WDT_PRES),
		.MRES(WDT_MRES)
	);
	
	
endmodule
