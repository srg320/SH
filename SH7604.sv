module SH7604 (
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	
	input             RES_N,
	input             NMI_N,
	
	input       [3:0] IRL_N,
	
	output     [26:0] A,
	input      [31:0] DI,
	output     [31:0] DO,
	output            BS_N,
	output            CS0_N,
	output            CS1_N,
	output            CS2_N,
	output            CS3_N,
	output            RD_WR_N,	//WE_N
	output            CE_N,		//RAS_N
	output            OE_N,		//CAS_N
	output      [3:0] WE_N,		//CASxx_N/DQMxx
	output            RD_N,
	output            IVECF_N,
	
	input      [26:0] EA,
	output     [31:0] EDI,
	input      [31:0] EDO,
	input             EBS_N,
	input             ECS0_N,
	input             ECS1_N,
	input             ECS2_N,
	input             ECS3_N,
	input             ERD_WR_N,	//WE_N
	input             ECE_N,		//RAS_N
	input             EOE_N,		//CAS_N
	input       [3:0] EWE_N,		//CASxx_N/DQMxx
	input             ERD_N,
	input             EIVECF_N,
	
	input             WAIT_N,
	input             BRLS_N,	//BACK_N
	output            BGR_N,	//BREQ_N
	
	input             DREQ0,
	output            DACK0,
	input             DREQ1,
	output            DACK1,
	
	output            FTOA,
	output            FTOB,
	input             FTCI,
	input             FTI,
	
	input             RXD,
	output            TXD,
	output            SCKO,
	input             SCKI,
	
	output            WDTOVF_N,
	
	input       [5:0] MD
	
);
	import CPU_PKG::*;
	
	bit [31:0] CBUS_A;
	bit [31:0] CBUS_DO;
	bit [31:0] CBUS_DI;
	bit        CBUS_WR;
	bit  [3:0] CBUS_BA;
	bit        CBUS_REQ;
	
	bit [31:0] IBUS_A;
	bit [31:0] IBUS_DO;
	bit [31:0] IBUS_DI;
	bit  [3:0] IBUS_BA;
	bit        IBUS_WE;
	bit        IBUS_REQ;
	bit        IBUS_WAIT;
	bit        IBUS_LOCK;
	
	//CACHE
	bit [31:0] CACHE_DO;
	bit        CACHE_BUSY;
	bit        CACHE_ACT;
	
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
	IntReq_t   INTC_INTO;
	IntAck_t   CPU_INTO;
	
	//MULT
	bit  [1:0] MAC_SEL;
	bit  [3:0] MAC_OP;
	bit        MAC_WE;
	bit [31:0] MULT_DO;
	
	//SCI
	bit [31:0] SCI_DO;
	bit        SCI_ACT;
	bit        TEI_IRQ;
	bit        TXI_IRQ;
	bit        RXI_IRQ;
	bit        ERI_IRQ;
	
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

	//DIVU
	bit [31:0] DIVU_DO;
	bit        DIVU_ACT;
	bit        DIVU_IRQ;
	bit  [7:0] DIVU_VEC;
	
	//Div clocks
	bit        CLK2_CE;
	bit        CLK4_CE;
	bit        CLK8_CE;
	bit        CLK16_CE;
	bit        CLK32_CE;
	bit        CLK64_CE;
	bit        CLK128_CE;
	bit        CLK256_CE;
	bit        CLK512_CE;
	bit        CLK1024_CE;
	bit        CLK2048_CE;
	bit        CLK4096_CE;
	bit        CLK8192_CE;
	
	SH_core core
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE(CE_R),
		
		.RES(~RES_N),
		.NMI(~NMI_N),
		
		.BUS_A(CBUS_A),
		.BUS_DI(CBUS_DI),
		.BUS_DO(CBUS_DO),
		.BUS_WR(CBUS_WR),
		.BUS_BA(CBUS_BA),
		.BUS_REQ(CBUS_REQ),
		.BUS_WAIT(CACHE_BUSY),
		
		.MAC_SEL(MAC_SEL),
		.MAC_OP(MAC_OP),
		.MAC_WE(MAC_WE),
		
		.INTI(INTC_INTO),
		.INTO(CPU_INTO)
	);
	
	assign CBUS_DI = MAC_SEL ? MULT_DO : CACHE_DO;
	
	wire [31:0] MULT_DI = MAC_OP[3:2] == 2'b10 ? CACHE_DO : CBUS_DO;
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
		.MAC_WE(MAC_WE)
	);
	
	CACHE cache
	(
		.CLK(CLK),
		.RST_N(RST_N & RES_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.RES_N(RES_N),
		
		.CBUS_A(CBUS_A),
		.CBUS_DI(CBUS_DO),
		.CBUS_DO(CACHE_DO),
		.CBUS_WR(CBUS_WR),
		.CBUS_BA(CBUS_BA),
		.CBUS_REQ(CBUS_REQ),
		.CBUS_BUSY(CACHE_BUSY),
		
		.IBUS_A(IBUS_A),
		.IBUS_DI(IBUS_DI),
		.IBUS_DO(IBUS_DO),
		.IBUS_WE(IBUS_WE),
		.IBUS_BA(IBUS_BA),
		.IBUS_REQ(IBUS_REQ),
		.IBUS_WAIT(IBUS_WAIT),
		.IBUS_LOCK(IBUS_LOCK)
	);
	
	assign IBUS_DI = INTC_ACT ? INTC_DO : 
						  FRT_ACT  ? FRT_DO : 
						  WDT_ACT  ? WDT_DO : 
						  SCI_ACT  ? SCI_DO : 
						  DIVU_ACT ? DIVU_DO : 
						  DMAC_ACT ? DMAC_DO : 
						  BSC_DO;
	assign IBUS_WAIT = DMAC_BUSY;

	
	bit  [31:0] DBUS_A;
	bit  [31:0] DBUS_DI;
	bit  [31:0] DBUS_DO;
	bit   [3:0] DBUS_BA;
	bit         DBUS_WE;
	bit         DBUS_REQ;
	bit         DBUS_WAIT;
	bit         DBUS_LOCK;
	DMAC dmac
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.RES_N(RES_N),
		.NMI_N(NMI_N),
		
		.DREQ0(DREQ0),
		.DACK0(DACK0),
		.DREQ1(DREQ1),
		.DACK1(DACK1),
		
		.RXI_IRQ(1'b0),
		.TXI_IRQ(1'b0),
		
		.IBUS_A(IBUS_A),
		.IBUS_DI(IBUS_DO),
		.IBUS_DO(DMAC_DO),
		.IBUS_BA(IBUS_BA),
		.IBUS_WE(IBUS_WE),
		.IBUS_REQ(IBUS_REQ),
		.IBUS_BUSY(DMAC_BUSY),
		.IBUS_LOCK(IBUS_LOCK),
		.IBUS_ACT(DMAC_ACT),
		
		.DBUS_A(DBUS_A),
		.DBUS_DI(BSC_DO),
		.DBUS_DO(DBUS_DO),
		.DBUS_BA(DBUS_BA),
		.DBUS_WE(DBUS_WE),
		.DBUS_REQ(DBUS_REQ),
		.DBUS_WAIT(BSC_BUSY),
		.DBUS_LOCK(DBUS_LOCK),
		
		.BSC_ACK(BSC_ACK),
		
		.DMAC0_IRQ(DMAC0_IRQ),
		.DMAC0_VEC(DMAC0_VEC),
		.DMAC1_IRQ(DMAC1_IRQ),
		.DMAC1_VEC(DMAC1_VEC)
	);
	
	bit  [26:0] IA;
	bit  [31:0] IDI;
	bit  [31:0] IDO;
	bit         IBS_N;
	bit         ICS0_N;
	bit         ICS1_N;
	bit         ICS2_N;
	bit         ICS3_N;
	bit         IRD_WR_N;
	bit         ICE_N;
	bit         IOE_N;
	bit   [3:0] IWE_N;
	bit         IRD_N;
	bit         IIVECF_N;
	bit         BUS_RLS;
	BSC bsc
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.RES_N(RES_N),
		
		.A(IA),
		.DI(IDI),
		.DO(IDO),
		.BS_N(IBS_N),
		.CS0_N(ICS0_N),
		.CS1_N(ICS1_N),
		.CS2_N(ICS2_N),
		.CS3_N(ICS3_N),
		.RD_WR_N(IRD_WR_N),
		.CE_N(ICE_N),
		.OE_N(IOE_N),
		.WE_N(IWE_N),
		.RD_N(IRD_N),
		.IVECF_N(IIVECF_N),
		.WAIT_N(WAIT_N),
		.BRLS_N(BRLS_N),
		.BGR_N(BGR_N),
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
	
	assign {A,DO}                         = !BUS_RLS ? {IA,IDO}                            : {EA,EDO};
	assign IDI                            = !BUS_RLS ? DI                                  : EDO;
	assign {BS_N,CS0_N,CS1_N,CS2_N,CS3_N} = !BUS_RLS ? {IBS_N,ICS0_N,ICS1_N,ICS2_N,ICS3_N} : {EBS_N,ECS0_N,ECS1_N,ECS2_N,ECS3_N};
	assign {RD_WR_N,CE_N,OE_N,WE_N,RD_N,IVECF_N}  = !BUS_RLS ? {IRD_WR_N,ICE_N,IOE_N,IWE_N,IRD_N,IIVECF_N}  : {ERD_WR_N,ECE_N,EOE_N,EWE_N,ERD_N,EIVECF_N};
	assign EDI = DI;
	
	
	INTC intc
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.RES_N(RES_N),
		.NMI_N(NMI_N),
		
		.IRL_N(IRL_N),
		
		.IBUS_A(IBUS_A),
		.IBUS_DI(IBUS_DO),
		.IBUS_DO(INTC_DO),
		.IBUS_BA(IBUS_BA),
		.IBUS_WE(IBUS_WE),
		.IBUS_REQ(IBUS_REQ),
		.IBUS_BUSY(),
		.IBUS_ACT(INTC_ACT),
		
		.UBC_IRQ(1'b0),
		.DIVU_IRQ(DIVU_IRQ),
		.DIVU_VEC(DIVU_VEC),
		.DMAC0_IRQ(DMAC0_IRQ),
		.DMAC0_VEC(DMAC0_VEC),
		.DMAC1_IRQ(DMAC1_IRQ),
		.DMAC1_VEC(DMAC1_VEC),
		.WDT_IRQ(ITI_IRQ),
		.BSC_IRQ(1'b0),
		.SCI_ERI_IRQ(ERI_IRQ),
		.SCI_RXI_IRQ(RXI_IRQ),
		.SCI_TXI_IRQ(TXI_IRQ),
		.SCI_TEI_IRQ(TEI_IRQ),
		.FRT_ICI_IRQ(ICI_IRQ),
		.FRT_OCI_IRQ(OCIA_IRQ | OCIB_IRQ),
		.FRT_OVI_IRQ(OVI_IRQ),
		
		.INTI(CPU_INTO),
		.INTO(INTC_INTO)
	);
	
	//Clock divider
	always @(posedge CLK or negedge RST_N) begin
		bit [12:0] DIV_CNT;
		
		if (!RST_N) begin
			CLK2_CE <= 0;
			CLK4_CE <= 0;
			CLK8_CE <= 0;
			CLK16_CE <= 0;
			CLK32_CE <= 0;
			CLK64_CE <= 0;
			CLK128_CE <= 0;
			CLK256_CE <= 0;
			CLK512_CE <= 0;
			CLK1024_CE <= 0;
			CLK2048_CE <= 0;
			CLK4096_CE <= 0;
			CLK8192_CE <= 0;
			DIV_CNT <= '0;
		end
		else if (CE_R) begin	
			DIV_CNT <= DIV_CNT + 13'd1;
			
			CLK2_CE    <= (DIV_CNT ==? 13'b????????????1);
			CLK4_CE    <= (DIV_CNT ==? 13'b???????????11);
			CLK8_CE    <= (DIV_CNT ==? 13'b??????????111);
			CLK16_CE   <= (DIV_CNT ==? 13'b?????????1111);
			CLK32_CE   <= (DIV_CNT ==? 13'b????????11111);
			CLK64_CE   <= (DIV_CNT ==? 13'b???????111111);
			CLK128_CE  <= (DIV_CNT ==? 13'b??????1111111);
			CLK256_CE  <= (DIV_CNT ==? 13'b?????11111111);
			CLK512_CE  <= (DIV_CNT ==? 13'b????111111111);
			CLK1024_CE <= (DIV_CNT ==? 13'b???1111111111);
			CLK2048_CE <= (DIV_CNT ==? 13'b??11111111111);
			CLK4096_CE <= (DIV_CNT ==? 13'b?111111111111);
			CLK8192_CE <= (DIV_CNT ==? 13'b1111111111111);
		end
	end

	SCI sci
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.RES_N(RES_N),
		
		.RXD(RXD),
		.TXD(TXD),
		.SCKO(SCKO),
		.SCKI(SCKI),
		
		.CLK4_CE(CLK4_CE),
		.CLK16_CE(CLK16_CE),
		.CLK64_CE(CLK64_CE),
		.CLK256_CE(CLK256_CE),
		
		.IBUS_A(IBUS_A),
		.IBUS_DI(IBUS_DO),
		.IBUS_DO(SCI_DO),
		.IBUS_BA(IBUS_BA),
		.IBUS_WE(IBUS_WE),
		.IBUS_REQ(IBUS_REQ),
		.IBUS_BUSY(),
		.IBUS_ACT(SCI_ACT),
		
		.TEI_IRQ(TEI_IRQ),
		.TXI_IRQ(TXI_IRQ),
		.RXI_IRQ(RXI_IRQ),
		.ERI_IRQ(ERI_IRQ)
	);
	
	FRT frt
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.RES_N(RES_N),
		
		.FTOA(FTOA),
		.FTOB(FTOB),
		.FTCI(FTCI),
		.FTI(FTI),
		
		.CLK8_CE(CLK8_CE),
		.CLK32_CE(CLK32_CE),
		.CLK128_CE(CLK128_CE),
		
		.IBUS_A(IBUS_A),
		.IBUS_DI(IBUS_DO),
		.IBUS_DO(FRT_DO),
		.IBUS_BA(IBUS_BA),
		.IBUS_WE(IBUS_WE),
		.IBUS_REQ(IBUS_REQ),
		.IBUS_BUSY(),
		.IBUS_ACT(FRT_ACT),
		
		.ICI_IRQ(ICI_IRQ),
		.OCIA_IRQ(OCIA_IRQ),
		.OCIB_IRQ(OCIB_IRQ),
		.OVI_IRQ(OVI_IRQ)
	);
	
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
		
		.IBUS_A(IBUS_A),
		.IBUS_DI(IBUS_DO),
		.IBUS_DO(WDT_DO),
		.IBUS_BA(IBUS_BA),
		.IBUS_WE(IBUS_WE),
		.IBUS_REQ(IBUS_REQ),
		.IBUS_BUSY(),
		.IBUS_ACT(WDT_ACT),
		
		.ITI_IRQ(ITI_IRQ),
		.PRES(WDT_PRES),
		.MRES(WDT_MRES)
	);
	
	DIVU divu
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.RES_N(RES_N),
		
		.IBUS_A(IBUS_A),
		.IBUS_DI(IBUS_DO),
		.IBUS_DO(DIVU_DO),
		.IBUS_BA(IBUS_BA),
		.IBUS_WE(IBUS_WE),
		.IBUS_REQ(IBUS_REQ),
		.IBUS_BUSY(),
		.IBUS_ACT(DIVU_ACT),
		
		.IRQ(DIVU_IRQ),
		.VEC(DIVU_VEC)
	);
	
//	always @(posedge CLK or negedge RST_N) begin
//		bit RES_N_OLD;
//		
//		if (!RST_N) begin
//			INTI <= INT_REQ_RESET;
//			RES_N_OLD <= 0;
//		end
//		else begin	
//			RES_N_OLD <= RES_N;
//			if (!RES_N && RES_N_OLD) begin
//				INTI.REQ <= 1;
//				INTI.RES <= 1;
//			end
//			
//			if (INTO.ACK && INTI.REQ) begin
//				INTI.REQ <= 0;
//				INTI.RES <= 0;
//			end
//		end
//	end
	
endmodule
