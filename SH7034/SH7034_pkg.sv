package SH7034_PKG;

	//INTC
	typedef struct packed		//R/W;5FFFF84
	{
		bit [ 3: 0] IRQ0;		//R/W
		bit [ 3: 0] IRQ1;		//R/W
		bit [ 3: 0] IRQ2;		//R/W
		bit [ 3: 0] IRQ3;
	} IPRA_t;
	parameter bit [15:0] IPRA_WMASK = 16'hFFFF;
	parameter bit [15:0] IPRA_RMASK = 16'hFFFF;
	parameter bit [15:0] IPRA_INIT = 16'h0000;
	
	typedef struct packed		//R/W;5FFFF86
	{
		bit [ 3: 0] IRQ4;		//R/W
		bit [ 3: 0] IRQ5;		//R/W
		bit [ 3: 0] IRQ6;		//R/W
		bit [ 3: 0] IRQ7;		//R/W
	} IPRB_t;
	parameter bit [15:0] IPRB_WMASK = 16'hFFFF;
	parameter bit [15:0] IPRB_RMASK = 16'hFFFF;
	parameter bit [15:0] IPRB_INIT = 16'h0000;
	
	typedef struct packed		//R/W;5FFFF88
	{
		bit [ 3: 0] DMAC01;		//R/W
		bit [ 3: 0] DMAC23;		//R/W
		bit [ 3: 0] ITU0;			//R/W
		bit [ 3: 0] ITU1;			//R/W
	} IPRC_t;
	parameter bit [15:0] IPRC_WMASK = 16'hFFFF;
	parameter bit [15:0] IPRC_RMASK = 16'hFFFF;
	parameter bit [15:0] IPRC_INIT = 16'h0000;
	
	typedef struct packed		//R/W;5FFFF8A
	{
		bit [ 3: 0] ITU2;			//R/W
		bit [ 3: 0] ITU3;			//R/W
		bit [ 3: 0] ITU4;			//R/W
		bit [ 3: 0] SCI0;			//R/W
	} IPRD_t;
	parameter bit [15:0] IPRD_WMASK = 16'hFFFF;
	parameter bit [15:0] IPRD_RMASK = 16'hFFFF;
	parameter bit [15:0] IPRD_INIT = 16'h0000;
	
	typedef struct packed		//R/W;5FFFF8C
	{
		bit [ 3: 0] SCI1;			//R/W
		bit [ 3: 0] PRT;			//R/W
		bit [ 3: 0] WDT;			//R/W
		bit [ 3: 0] UNUSED;
	} IPRE_t;
	parameter bit [15:0] IPRE_WMASK = 16'hFFF0;
	parameter bit [15:0] IPRE_RMASK = 16'hFFF0;
	parameter bit [15:0] IPRE_INIT = 16'h0000;
	
	typedef struct packed		//R/W;5FFFF8E
	{
		bit         NMIL;			//R
		bit [ 5: 0] UNUSED;
		bit         NMIE;			//R/W
		bit         IRQ0S;		//R/W
		bit         IRQ1S;		//R/W
		bit         IRQ2S;		//R/W
		bit         IRQ3S;		//R/W
		bit         IRQ4S;		//R/W
		bit         IRQ5S;		//R/W
		bit         IRQ6S;		//R/W
		bit         IRQ7S;		//R/W
	} ICR_t;
	parameter bit [15:0] ICR_WMASK = 16'h01FF;
	parameter bit [15:0] ICR_RMASK = 16'h81FF;
	parameter bit [15:0] ICR_INIT = 16'h0000;
	
	//BSC
	typedef struct packed		//R/W;5FFFFA0
	{
		bit         DRAME;		//R/W
		bit         IOE;			//R/W
		bit         WARP;			//R/W
		bit         RDDTY;		//R/W
		bit         BAS;			//R/W
		bit [10: 0] UNUSED;
	} BCR_t;
	parameter bit [15:0] BCR_WMASK = 16'hF800;
	parameter bit [15:0] BCR_RMASK = 16'hF800;
	parameter bit [15:0] BCR_INIT = 16'h0000;
	
	typedef struct packed		//R/W;5FFFFA2
	{
		bit         RW7;			//R/W
		bit         RW6;			//R/W
		bit         RW5;			//R/W
		bit         RW4;			//R/W
		bit         RW3;			//R/W
		bit         RW2;			//R/W
		bit         RW1;			//R/W
		bit         RW0;			//R/W
		bit [ 5: 0] UNUSED;
		bit         WW1;			//R/W
		bit         UNUSED2;
	} WCR1_t;
	parameter bit [15:0] WCR1_WMASK = 16'hFF02;
	parameter bit [15:0] WCR1_RMASK = 16'hFF02;
	parameter bit [15:0] WCR1_INIT = 16'hFFFF;
	
	typedef struct packed		//R/W;5FFFFA4
	{
		bit         DRW7;			//R/W
		bit         DRW6;			//R/W
		bit         DRW5;			//R/W
		bit         DRW4;			//R/W
		bit         DRW3;			//R/W
		bit         DRW2;			//R/W
		bit         DRW1;			//R/W
		bit         DRW0;			//R/W
		bit         DWW7;			//R/W
		bit         DWW6;			//R/W
		bit         DWW5;			//R/W
		bit         DWW4;			//R/W
		bit         DWW3;			//R/W
		bit         DWW2;			//R/W
		bit         DWW1;			//R/W
		bit         DWW0;			//R/W
	} WCR2_t;
	parameter bit [15:0] WCR2_WMASK = 16'hFFFF;
	parameter bit [15:0] WCR2_RMASK = 16'hFFFF;
	parameter bit [15:0] WCR2_INIT = 16'hFFFF;
	
	typedef struct packed		//R/W;5FFFFA6
	{
		bit         WPU;			//R/W
		bit [ 1: 0] A02LW;		//R/W
		bit [ 1: 0] A6LW;			//R/W
		bit [10: 0] UNUSED;
	} WCR3_t;
	parameter bit [15:0] WCR3_WMASK = 16'hF800;
	parameter bit [15:0] WCR3_RMASK = 16'hF800;
	parameter bit [15:0] WCR3_INIT = 16'hF800;
	
	typedef struct packed		//R/W;5FFFFA8
	{
		bit         CW2;			//R/W
		bit         RASD;			//R/W
		bit         TPC;			//R/W
		bit         BE;			//R/W
		bit         CDTY;			//R/W
		bit         MXE;			//R/W
		bit [ 1: 0] MXC;			//R/W
		bit [ 7: 0] UNUSED2;
	} DCR_t;
	parameter bit [15:0] DCR_WMASK = 16'hFF00;
	parameter bit [15:0] DCR_RMASK = 16'hFF00;
	parameter bit [15:0] DCR_INIT = 16'h0000;
	
	typedef struct packed		//R/W;5FFFFAA
	{
		bit         PEF;			//R/W
		bit         PFRC;			//R/W
		bit         PEO;			//R/W
		bit [ 1: 0] PCHK;
		bit [10: 0] UNUSED2;
	} PCR_t;
	parameter bit [15:0] PCR_WMASK = 16'hF800;
	parameter bit [15:0] PCR_RMASK = 16'hF800;
	parameter bit [15:0] PCR_INIT = 16'h0000;
	
	typedef struct packed		//R/W;5FFFFAC
	{
		bit [ 7: 0] UNUSED;
		bit         RFSHE;		//R/W
		bit         RMODE;		//R/W
		bit [ 1: 0] RLW;			//R/W
		bit [ 3: 0] UNUSED2;
	} RCR_t;
	parameter bit [15:0] RCR_WMASK = 16'h0F00;
	parameter bit [15:0] RCR_RMASK = 16'h0F00;
	parameter bit [15:0] RCR_INIT = 16'h0000;
	
	typedef struct packed		//R/W;5FFFFAE
	{
		bit [ 7: 0] UNUSED;
		bit         CMF;
		bit         CMIE;
		bit [ 2: 0] CKS;
		bit [ 2: 0] UNUSED2;
	} RTCSR_t;
	parameter bit [15:0] RTCSR_WMASK = 16'h00F8;
	parameter bit [15:0] RTCSR_RMASK = 16'h00F8;
	parameter bit [15:0] RTCSR_INIT = 16'h0000;
	
	typedef bit [7:0] RTCNT_t;	//R/W;5FFFFB0
	parameter bit [7:0] RTCNT_WMASK = 8'hFF;
	parameter bit [7:0] RTCNT_RMASK = 8'hFF;
	parameter bit [7:0] RTCNT_INIT = 8'h00;
	
	typedef bit [7:0] RTCOR_t;	//R/W;5FFFFB2
	parameter bit [7:0] RTCOR_WMASK = 8'hFF;
	parameter bit [7:0] RTCOR_RMASK = 8'hFF;
	parameter bit [7:0] RTCOR_INIT = 8'h00;

	
	//SCI
	typedef struct packed		//R/W;5FFFEC0,5FFFEC8
	{
		bit         CA;			//R/W
		bit         CHR;			//R/W
		bit         PE;			//R/W
		bit         OE;			//R/W
		bit         STOP;			//R/W
		bit         MP;			//R/W
		bit [ 1: 0] CKS;			//R/W
	} SMR_t;
	parameter bit [7:0] SMR_WMASK = 8'hFF;
	parameter bit [7:0] SMR_RMASK = 8'hFF;
	parameter bit [7:0] SMR_INIT = 8'h00;
	
	typedef bit [7:0] BRR_t;	//R/W;5FFFEC1,5FFFEC9
	parameter bit [7:0] BRR_WMASK = 8'hFF;
	parameter bit [7:0] BRR_RMASK = 8'hFF;
	parameter bit [7:0] BRR_INIT = 8'hFF;
	
	typedef struct packed		//R/W;5FFFEC2,5FFFECA
	{
		bit         TIE;			//R/W
		bit         RIE;			//R/W
		bit         TE;			//R/W
		bit         RE;			//R/W
		bit         MPIE;			//R/W
		bit         TEIE;			//R/W
		bit [ 1: 0] CKE;			//R/W
	} SCR_t;
	parameter bit [7:0] SCR_WMASK = 8'hFF;
	parameter bit [7:0] SCR_RMASK = 8'hFF;
	parameter bit [7:0] SCR_INIT = 8'h00;
	
	typedef bit [7:0] TDR_t;	//R/W;5FFFEC3,5FFFECB
	parameter bit [7:0] TDR_WMASK = 8'hFF;
	parameter bit [7:0] TDR_RMASK = 8'hFF;
	parameter bit [7:0] TDR_INIT = 8'hFF;
	
	typedef struct packed		//R/W;5FFFEC4,5FFFECC
	{
		bit         TDRE;			//R/W
		bit         RDRF;			//R/W
		bit         ORER;			//R/W
		bit         FER;			//R/W
		bit         PER;			//R/W
		bit         TEND;			//R
		bit         MPB;			//R
		bit         MPBT;			//R/W
	} SSR_t;
	parameter bit [7:0] SSR_WMASK = 8'hF9;
	parameter bit [7:0] SSR_RMASK = 8'hFF;
	parameter bit [7:0] SSR_INIT = 8'h84;
	
	typedef bit [7:0] RDR_t;	//R;5FFFEC5,5FFFECD
	parameter bit [7:0] RDR_WMASK = 8'h00;
	parameter bit [7:0] RDR_RMASK = 8'hFF;
	parameter bit [7:0] RDR_INIT = 8'h00;

	//FRT
//	typedef struct packed		//R/W;FFFFFE10
//	{
//		bit         ICIE;			//R/W
//		bit [ 2: 0] UNUSED;
//		bit         OCIAE;		//R/W
//		bit         OCIBE;		//R/W
//		bit         OVIE;			//R/W
//		bit         UNUSED2;
//	} TIER_t;
//	parameter bit [7:0] TIER_WMASK = 8'h8E;
//	parameter bit [7:0] TIER_RMASK = 8'h8E;
//	parameter bit [7:0] TIER_INIT = 8'h01;
//	
//	typedef struct packed		//R/W;FFFFFE11
//	{
//		bit         ICF;			//R/W
//		bit [ 2: 0] UNUSED;
//		bit         OCFA;			//R/W
//		bit         OCFB;			//R/W
//		bit         OVF;			//R/W
//		bit         CCLRA;		//R/W
//	} FTCSR_t;
//	parameter bit [7:0] FTCSR_WMASK = 8'h8F;
//	parameter bit [7:0] FTCSR_RMASK = 8'h8F;
//	parameter bit [7:0] FTCSR_INIT = 8'h00;
//	
//	typedef bit [15:0] FRC_t;	//R/W;FFFFFE12-FFFFFE13
//	parameter bit [15:0] FRC_WMASK = 16'hFFFF;
//	parameter bit [15:0] FRC_RMASK = 16'hFFFF;
//	parameter bit [15:0] FRC_INIT = 16'h0000;
//	
//	typedef bit [15:0] OCR_t;	//R/W;FFFFFE14-FFFFFE15
//	parameter bit [15:0] OCR_WMASK = 16'hFFFF;
//	parameter bit [15:0] OCR_RMASK = 16'hFFFF;
//	parameter bit [15:0] OCR_INIT = 16'hFFFF;
//	
//	typedef struct packed		//R/W;FFFFFE16
//	{
//		bit         IEDG;			//R/W
//		bit [ 4: 0] UNUSED;
//		bit [ 1: 0] CKS;			//R/W
//	} TCR_t;
//	parameter bit [7:0] TCR_WMASK = 8'h83;
//	parameter bit [7:0] TCR_RMASK = 8'h83;
//	parameter bit [7:0] TCR_INIT = 8'h00;
//	
//	typedef struct packed		//R/W;FFFFFE17
//	{
//		bit [ 2: 0] UNUSED;
//		bit         OCRS;			//R/W
//		bit [ 1: 0] UNUSED2;
//		bit         OLVLA;		//R/W
//		bit         OLVLB;		//R/W
//	} TOCR_t;
//	parameter bit [7:0] TOCR_WMASK = 8'h13;
//	parameter bit [7:0] TOCR_RMASK = 8'h13;
//	parameter bit [7:0] TOCR_INIT = 8'hE0;
//	
//	typedef bit [15:0] FICR_t;	//R;FFFFFE18-FFFFFE19
//	parameter bit [15:0] FICR_WMASK = 16'h0000;
//	parameter bit [15:0] FICR_RMASK = 16'hFFFF;
//	parameter bit [15:0] FICR_INIT = 16'h0000;

	//WDT
	typedef bit [7:0] WTCNT_t;	//R;5FFFFB8/W;5FFFFB9
	parameter bit [7:0] WTCNT_WMASK = 8'hFF;
	parameter bit [7:0] WTCNT_RMASK = 8'hFF;
	parameter bit [7:0] WTCNT_INIT = 8'h00;
	
	typedef struct packed		//R;5FFFFB8/W;5FFFFB8
	{
		bit         OVF;			//R/W0
		bit         WTIT;			//R/W
		bit         TME;			//R/W
		bit [ 1: 0] UNUSED;
		bit [ 2: 0] CKS;			//R/W
	} WTCSR_t;
	parameter bit [7:0] WTCSR_WMASK = 8'hE7;
	parameter bit [7:0] WTCSR_RMASK = 8'hE7;
	parameter bit [7:0] WTCSR_INIT = 8'h18;
	
	typedef struct packed		//R;5FFFFBA/W;5FFFFBB
	{
		bit         WOVF;			//R/W0
		bit         RSTE;			//R/W
		bit         RSTS;			//R/W
		bit [ 4: 0] UNUSED;
	} RSTCSR_t;
	parameter bit [7:0] RSTCSR_WMASK = 8'hE0;
	parameter bit [7:0] RSTCSR_RMASK = 8'hE0;
	parameter bit [7:0] RSTCSR_INIT = 8'h1F;
	
	//DMAC
	typedef bit [31:0] SARx_t;	//R/W;5FFFF40,5FFFF50,5FFFF60,5FFFF70
	parameter bit [31:0] SARx_WMASK = 32'hFFFFFFFF;
	parameter bit [31:0] SARx_RMASK = 32'hFFFFFFFF;
	parameter bit [31:0] SARx_INIT = 32'h00000000;
	
	typedef bit [31:0] DARx_t;	//R/W;5FFFF44,5FFFF54,5FFFF64,5FFFF74
	parameter bit [31:0] DARx_WMASK = 32'hFFFFFFFF;
	parameter bit [31:0] DARx_RMASK = 32'hFFFFFFFF;
	parameter bit [31:0] DARx_INIT = 32'h00000000;
	
	typedef bit [15:0] TCRx_t;	//R/W;5FFFF4A,5FFFF5A,5FFFF6A,5FFFF7A
	parameter bit [15:0] TCRx_WMASK = 16'hFFFF;
	parameter bit [15:0] TCRx_RMASK = 16'hFFFF;
	parameter bit [15:0] TCRx_INIT = 16'h0000;
	
	typedef struct packed		//R/W;5FFFF4E,5FFFF5E,5FFFF6E,5FFFF7E
	{
		bit [ 1: 0] DM;			//R/W
		bit [ 1: 0] SM;			//R/W
		bit [ 3: 0] RS;			//R/W
		bit         AM;			//R/W0
		bit         AL;			//R/W0
		bit         DS;			//R/W0
		bit         TM;			//R/W
		bit         TS;			//R/W
		bit         IE;			//R/W
		bit         TE;			//R/W0
		bit         DE;			//R/W
	} CHCRx_t;
	parameter bit [15:0] CHCRx_WMASK = 16'hFFFF;
	parameter bit [15:0] CHCRx_RMASK = 16'hFFFF;
	parameter bit [15:0] CHCRx_INIT = 16'h0000;
	
	typedef struct packed		//R/W;5FFFF48
	{
		bit [ 5: 0] UNUSED;
		bit [ 1: 0] PR;			//R/W
		bit [ 5: 0] UNUSED2;
		bit         AE;			//R/W0
		bit         NMIF;			//R/W0
		bit         DME;			//R/W
	} DMAOR_t;
	parameter bit [15:0] DMAOR_WMASK = 16'h0307;
	parameter bit [15:0] DMAOR_RMASK = 16'h0307;
	parameter bit [15:0] DMAOR_INIT = 16'h0000;
	
	//UBC
//	typedef bit [15:0] BARx_t;	//R/W;FFFFFF40,FFFFFF42,FFFFFF60,FFFFFF62
//	parameter bit [15:0] BARx_WMASK = 16'hFFFF;
//	parameter bit [15:0] BARx_RMASK = 16'hFFFF;
//	parameter bit [15:0] BARx_INIT = 16'h0000;
//	
//	typedef bit [15:0] BAMRx_t;	//R/W;FFFFFF44,FFFFFF46,FFFFFF64,FFFFFF66
//	parameter bit [15:0] BAMRx_WMASK = 16'hFFFF;
//	parameter bit [15:0] BAMRx_RMASK = 16'hFFFF;
//	parameter bit [15:0] BAMRx_INIT = 16'h0000;
//	
//	typedef struct packed		//R/W;FFFFFF48,FFFFFF68
//	{
//		bit [ 7: 0] UNUSED;
//		bit [ 1: 0] CP;			//R/W
//		bit [ 1: 0] ID;			//R/W
//		bit [ 1: 0] RW;			//R/W
//		bit [ 1: 0] SZ;			//R/W
//	} BBRx_t;
//	parameter bit [15:0] BBRx_WMASK = 16'h00FF;
//	parameter bit [15:0] BBRx_RMASK = 16'h00FF;
//	parameter bit [15:0] BBRx_INIT = 16'h0000;
//	
//	typedef bit [15:0] BDRB_t;	//R/W;FFFFFF70,FFFFFF72
//	parameter bit [15:0] BDRB_WMASK = 16'hFFFF;
//	parameter bit [15:0] BDRB_RMASK = 16'hFFFF;
//	parameter bit [15:0] BDRB_INIT = 16'h0000;
//	
//	typedef bit [15:0] BDMRB_t;	//R/W;FFFFFF74,FFFFFF76
//	parameter bit [15:0] BDMRB_WMASK = 16'hFFFF;
//	parameter bit [15:0] BDMRB_RMASK = 16'hFFFF;
//	parameter bit [15:0] BDMRB_INIT = 16'h0000;
//	
//	typedef struct packed		//R/W;FFFFFF78
//	{
//		bit         CMFCA;		//R/W
//		bit         CMFPA;		//R/W
//		bit         EBBE;			//R/W
//		bit         UMD;			//R/W
//		bit         UNUSED;
//		bit         PCBA;			//R/W
//		bit [ 1: 0] UNUSED2;
//		bit         CMFCB;		//R/W
//		bit         CMFPB;		//R/W
//		bit         UNUSED3;
//		bit         SEQ;			//R/W
//		bit         DBEB;			//R
//		bit         PCBB;			//R/W
//		bit [ 1: 0] UNUSED4;
//	} BRCR_t;
//	parameter bit [15:0] BRCR_WMASK = 16'hF4D4;
//	parameter bit [15:0] BRCR_RMASK = 16'hF4DC;
//	parameter bit [15:0] BRCR_INIT = 16'h0000;
	
endpackage
