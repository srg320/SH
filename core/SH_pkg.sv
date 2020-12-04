package SH2_PKG;

	typedef enum {
		GRX,  
		IMM,
		PC_,
		SCR
	} RegSource_t;
	
	typedef enum {
		REGA, 
		REGB,
		REGC
	} ALUSource_t;
	
	typedef enum {
		ZIMM4,
		SIMM8,
		ZIMM8,
		SIMM12,
		ZERO,
		ONE
	} IMMType_t;
	
	typedef enum {
		ALUA,
		ALUB,
		ALURES
	} AddrSrc_t;
	
//	typedef enum {
//		REGA_, 
//		REGB_,
//		ALU_
//	} WDSource_t;
	
	typedef enum {
		ADD, 
		LOG, 
		EXT,
		SHIFT,
		MULT,
		DIV,
		NOP
	} ALUType_t;
	
	typedef enum {
		BYTE,
		WORD,
		LONG
	} MemSize_t;

	typedef enum {
		SR_,
		GBR_,
		VBR_
	} CtrlReg_t;
	
	typedef enum {
		LOAD,
		ALU,
		DIV0S,
		DIV0U,
		IMSK
	} SRSet_t;
	
	typedef enum {
		CB,
		DCB,
		UCB
	} BranchType_t;
	
	
	typedef struct packed
	{
		RegSource_t  RSA;
		RegSource_t  RSB;
		RegSource_t  RSC;
		bit          PCM;		//PC masked
		bit          BPWBA;	//Bypass register A from WB.RES
		bit          BPLDA;	//Bypass register A from WB.RD
		bit          BPMAB;	//Bypass register B from MA.RES
	} Datapath_t;
	
	typedef struct packed
	{
		bit          SA;
		bit          SB;
		ALUType_t    OP;		//ALU operation type
		bit [3:0]    CD;		//ALU operation code
		bit [2:0]    CMP;		//CMP operation code
	} ALU_t;
	
	typedef struct packed
	{
		AddrSrc_t    ADDS;	//Address source
		AddrSrc_t    WDS;		//Write data source
		bit [1:0]    SZ;		//Memory access size
		bit          R;		//Data memory read
		bit          W;		//Data memory write
	} Mem_t;
	
	typedef struct packed
	{
		bit [4:0]    N;		//Register address
		bit          R;		//Register read
		bit          W;		//Register write
	} Reg_t;
	
	typedef struct packed
	{
		bit [1:0]    S;		//MAC register select
		bit          R;		//MAC register read
		bit          W;		//MAC register write
		bit [3:0]    OP;		//MAC operation
	} MAC_t;
	
	typedef struct packed
	{
		bit          W;		//System control register write
		CtrlReg_t    S;		//System control register select
		SRSet_t      SRS;		//SR register set
	} Control_t;
	
	typedef struct packed
	{
		bit          BI;		//Branch instruction
		BranchType_t BT;		//Branch type
		bit          BCV;		//Branch condition value
		bit          BSR;		//Branch subrouting
	} Branch_t;
	
	typedef struct packed
	{
		Datapath_t   DP;
		IMMType_t    IMMT;	//Immediate type
		ALU_t        ALU;
		Mem_t        MEM;
		Reg_t        RA;
		Reg_t        RB;
		bit          R0R;		//Register 0 read
		bit          PCW;		//PC write
		Control_t    CTRL;
		MAC_t        MAC;
		Branch_t     BR;
		bit          TAS;		//TAS instruction
		bit [2:0]    LST;		//Last state
		bit          IACK;	//Interrupt acknowledge
	} DecInstr_t;

	parameter DecInstr_t DECI_RESET = '{'{GRX, GRX, GRX, 0, 0, 0, 0},
												 SIMM8,
												 '{0, 0, NOP, 4'b0000, 3'b000},
												 '{ALURES, ALUB, BYTE, 0, 0},
												 '{5'd0, 0, 0},
												 '{5'd0, 0, 0},
												 0,
												 0,
												 '{0, SR_, LOAD},
												 '{2'b00, 0, 0, 4'b0000},
												 '{0, CB, 0, 0},
												 3'b000,
												 1'b0,
												 1'b0};
	
	typedef struct
	{
		bit [15:0] IR;
		bit [31:0] PC;
	} IFtoID_t;
	
	typedef struct
	{
		bit [15:0] IR;
		DecInstr_t DI;			//Decoded instruction
		bit [31:0] PC;
		bit [31:0] RA;
		bit [31:0] RB;
		bit [31:0] R0;
		bit        BC;			//Branch condition
	} IDtoEX_t;

	typedef struct
	{
		bit [15:0] IR;
		DecInstr_t DI;			//Decoded instruction
		bit [31:0] RES;		//ALU output
		bit [31:0] ADDR;		//Data memory address
		bit [31:0] WD;			//Write data
//		bit        LOCK;
	} EXtoMA_t;

	typedef struct
	{
		bit [15:0] IR;
		DecInstr_t DI;			//Decoded instruction
		bit [31:0] RES;
		bit [31:0] RD;			//Read data
		bit        LOCK;
	} MAtoWB_t;
	
	typedef struct
	{
		bit [15:0] IR;
		DecInstr_t DI;			//Decoded instruction
		bit [31:0] RESA;
		bit [31:0] RESB;
		bit        LOCK;
	} WB_t;
	
	typedef struct
	{
		IFtoID_t ID;
		IDtoEX_t EX;
		EXtoMA_t MA;
		MAtoWB_t WB;
		WB_t     WB2;
	} PipelineState_t;
	
	function bit[31:0] ByteShiftRigth(input bit[31:0] val, input bit[1:0] s);
		bit[31:0] temp0, temp1;
		
		temp1 = s[1] ? val >> 16 : val;
		temp0 = s[0] ? temp1 >> 8 : temp1;
		return temp0;
	endfunction

	typedef struct packed
	{
		bit [21: 0] UNUSED;
		bit         M;
		bit         Q;
		bit [ 3: 0] I;
		bit [ 1: 0] UNUSED2;
		bit         S;
		bit         T;
	} SR_t;
	
	localparam SR_T 	= 0;
	localparam SR_S 	= 1;
	localparam SR_I0 	= 4;
	localparam SR_I1 	= 5;
	localparam SR_I2 	= 6;
	localparam SR_I3 	= 7;
	localparam SR_Q 	= 8;
	localparam SR_M 	= 9;


	//ALU
	function bit [32:0] Adder(input bit [31:0] a, input bit [31:0] b, input bit ci, input bit [3:0] code);
		bit [31:0] b2;
		bit        ci2;
		bit [32:0] sum;
		
		b2 = b ^ {32{code[0]}};
		ci2 = code[1] ? ci : code[0];
		sum = {1'b0,a} + {1'b0,b2} + {{32{1'b0}},ci2};
		
		return sum;
	endfunction
	
	function bit [31:0] Log(input bit [31:0] a, input bit [31:0] b, input bit [3:0] code);
		bit [31:0] b2;
		bit [31:0] res;
		
		b2 = b ^ {32{code[0]}};
		case (code[2:1])
			2'b00: res = a & b2;
			2'b01: res = a ^ b2;
			2'b10: res = a | b2;
			2'b11: res = b2;
		endcase
	
		return res;
	endfunction
	
	function bit [31:0] Ext(input bit [31:0] a, input bit [31:0] b, input bit [3:0] code);
		bit [31:0] res;
	
		case (code[2:0])
			3'b000: res = {b[31:16],b[7:0],b[15:8]};
			3'b001: res = {b[15:0],b[31:16]};
			3'b010: res = {b[15:0],a[31:16]};
			3'b011: res = b;
			3'b100: res = {{24{1'b0}},b[7:0]};
			3'b101: res = {{16{1'b0}},b[15:0]};
			3'b110: res = {{24{b[7]}},b[7:0]};
			3'b111: res = {{16{b[15]}},b[15:0]};
		endcase
	
		return res;
	endfunction
	
	function bit [32:0] Shifter(input bit [31:0] a, input bit ci, input bit [3:0] code);
		bit [31:0] res;
		bit        ci2;
		bit        co;
	
		case (code[2:0])
			3'b000: ci2 = 0;
			3'b001: ci2 = 0;
			3'b010: ci2 = 0;
			3'b011: ci2 = a[31];
			3'b100: ci2 = a[31];
			3'b101: ci2 = a[0];
			3'b110: ci2 = ci;
			3'b111: ci2 = ci;
		endcase
		
		if (!code[3]) begin
			res = !code[0] ? {a[30:0],ci2} : {ci2, a[31:1]};
		end else begin
			case (code[2:0])
				3'b000: res = {a[29:0],{2{1'b0}}};
				3'b001: res = {{2{1'b0}},a[31:2]};
				3'b010: res = {a[23:0],{8{1'b0}}};
				3'b011: res = {{8{1'b0}},a[31:24]};
				3'b100: res = {a[15:0],{16{1'b0}}};
				3'b101: res = {{16{1'b0}},a[31:16]};
				3'b110: res = {a[15:0],{16{1'b0}}};
				3'b111: res = {{16{1'b0}},a[31:16]};
			endcase
		end
		co = code[0] ? a[31] : a[0];
		
		return {co,res};
	endfunction
	
endpackage
