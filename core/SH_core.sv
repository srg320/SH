import CPU_PKG::*;

module SH_core (
	input             CLK,
	input             RST_N,
	input             CE,
	
	input             RES,
	input             NMI,
	
	output     [31:0] BUS_A,
	input      [31:0] BUS_DI,
	output     [31:0] BUS_DO,
	output            BUS_WR,
	output      [3:0] BUS_BA,
	output            BUS_REQ,
	input             BUS_WAIT,
	
	output      [1:0] MAC_SEL,
	output      [3:0] MAC_OP,
	output            MAC_WE,
	
	input    IntReq_t INTI,
	output   IntAck_t INTO
);
	
	import SH2_PKG::*;

	//CPU registers
	bit [31:0] PC;
	bit [31:0] GBR;
	bit [31:0] VBR;
	bit [31:0] PR;
	SR_t       SR;
	
	PipelineState_t PIPE;
	bit        ID_STALL;
	bit        EX_STALL;
	bit [31:0] RD_SAVE;
	bit [ 2:0] STATE;
	DecInstr_t ID_DECI;
	bit        STBY;
	bit [31:0] ALU_RES;
	bit        ALU_T;
	SR_t       SR_NEW;
	bit        SR_T;
	
	bit        MA_ACTIVE;
	bit        IF_ACTIVE;
	bit        INST_SPLIT;
	bit        LOAD_SPLIT;
	bit        MAWB_STALL;
	bit        IFID_STALL;
	bit        BR_COND;
	
	//Register file
	bit  [4:0] REGS_RAN;
	bit  [4:0] REGS_RBN;
	bit [31:0] REGS_RAQ;
	bit [31:0] REGS_RBQ;
	bit [31:0] REGS_R0Q;
	
	bit  [4:0] REGS_WAN;
	bit [31:0] REGS_WAD;
	bit        REGS_WAE;
	bit  [4:0] REGS_WBN;
	bit [31:0] REGS_WBD;
	bit        REGS_WBE;
	
	assign REGS_RAN = ID_DECI.RA.N;
	assign REGS_RBN = ID_DECI.RB.N;
	
	SH2_regfile regfile (CLK, RST_N, CE, REGS_WAN, REGS_WAD, REGS_WAE, REGS_WBN, REGS_WBD, REGS_WBE, 
								REGS_RAN, REGS_RAQ, REGS_RBN, REGS_RBQ, REGS_R0Q);

	
	//**********************************************************
	//PC
	//**********************************************************
	wire PC_STALL = (MA_ACTIVE & BUS_WAIT) | (IF_ACTIVE & BUS_WAIT) | INST_SPLIT | IFID_STALL/*STATE != ID_DECI.LST*/;
	bit [31:0] NPC;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			NPC <= '0;
		end
		else if (CE) begin
			if (PIPE.EX.DI.PCW && !EX_STALL) begin
				NPC <= ALU_RES;
			end else if (!PC_STALL && !STBY) begin
				NPC <= PC + 2;
			end
		end
	end
	
	assign PC = NPC;
	
	wire LOAD_ISSUE = PIPE.EX.DI.MEM.R && ((PIPE.EX.DI.RA.N == ID_DECI.RA.N && ID_DECI.RA.R) || (PIPE.EX.DI.RA.N == ID_DECI.RB.N && ID_DECI.RB.R));
	wire INST_ISSUE = ~PIPE.ID.PC[1] && (PIPE.EX.DI.MEM.R || PIPE.EX.DI.MEM.W || PIPE.EX.DI.MAC.R || PIPE.EX.DI.MAC.W);
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			MA_ACTIVE <= 0;
			IF_ACTIVE <= 0;
			INST_SPLIT <= 0;
			LOAD_SPLIT <= 0;
			MAWB_STALL <= 0;
		end
		else if (CE) begin
			if (LOAD_ISSUE && !INST_SPLIT && (!MA_ACTIVE || !BUS_WAIT) && !EX_STALL) begin
				LOAD_SPLIT <= 1;
			end else if (INST_SPLIT && (!MA_ACTIVE || !BUS_WAIT)) begin
				LOAD_SPLIT <= 0;
			end
			
			if ((PIPE.EX.DI.MEM.R || PIPE.EX.DI.MEM.W || PIPE.EX.DI.MAC.R || PIPE.EX.DI.MAC.W) && !INST_SPLIT && (!IF_ACTIVE || !BUS_WAIT)) begin
				MA_ACTIVE <= 1;
			end else if (!BUS_WAIT && MA_ACTIVE) begin
				MA_ACTIVE <= 0;
			end
			
			if ((PC[1] && (!MA_ACTIVE || !BUS_WAIT) && !IFID_STALL && !EX_STALL) || 
				 (PIPE.EX.BC && (!MA_ACTIVE || !BUS_WAIT)) /*|| 
				 ((!PC[1] || PIPE.EX.BC) && INST_SPLIT && (!MA_ACTIVE || !BUS_WAIT) && !IFID_STALL)*/) begin
				IF_ACTIVE <= 1;
			end else if (!BUS_WAIT && IF_ACTIVE && !PC_STALL) begin
				IF_ACTIVE <= 0;
			end
			
			if ((INST_ISSUE && !INST_SPLIT && (!MA_ACTIVE || !BUS_WAIT) && (!IFID_STALL || STATE == ID_DECI.LST)) || 
				 (LOAD_ISSUE && !INST_SPLIT && (!MA_ACTIVE || !BUS_WAIT) && !EX_STALL)) begin
				INST_SPLIT <= 1;
			end else if (INST_SPLIT && (!MA_ACTIVE || !BUS_WAIT)) begin
				INST_SPLIT <= 0;
			end
			
			if (INST_SPLIT && (!MA_ACTIVE || !BUS_WAIT)) begin
				MAWB_STALL <= 1;
			end else if (MAWB_STALL && (!IF_ACTIVE || !BUS_WAIT)) begin
				MAWB_STALL <= 0;
			end
		end
	end
	
	
	//**********************************************************
	// IF stage
	//**********************************************************
	wire IF_STALL = (MA_ACTIVE & BUS_WAIT) | (IF_ACTIVE & BUS_WAIT) | INST_SPLIT | IFID_STALL;
	
	bit        NEED_FETCH;
	always @(posedge CLK or negedge RST_N) begin
		bit [15:0] SAVE_IR;
		bit [15:0] NEW_IR;
		IFtoID_t   SAVE_ID;
		
		if (!RST_N) begin
			PIPE.ID.IR <= 16'h0000;
			PIPE.ID.PC <= '0;
			SAVE_IR <= '0;
		end
		else if (CE) begin
			if (!PC[1] || NEED_FETCH) begin
				NEW_IR = PC[1] ? BUS_DI[15:0] : BUS_DI[31:16];
			end
			else begin
				NEW_IR = SAVE_IR;
			end
			
			if ((BR_COND && ID_DECI.BR.BT == CB) || PIPE.EX.BC || INTI.REQ || STBY) begin
				NEW_IR = 16'h0000;//NOP
			end
				
			if (!IF_STALL) begin
				if (!PC[1] || NEED_FETCH) begin
					SAVE_IR <= BUS_DI[15:0];
				end
				
				if (!ID_DECI.LST) begin
					PIPE.ID.IR <= NEW_IR;
					PIPE.ID.PC <= PC;
				end
				else begin
					SAVE_ID.IR <= NEW_IR;
					SAVE_ID.PC <= PC;
				end
			end
			if (!ID_STALL) begin
				if (ID_DECI.LST && STATE == ID_DECI.LST) begin
					PIPE.ID <= SAVE_ID;
				end
			end
		end
	end

	//**********************************************************
	//ID stage
	//**********************************************************
	assign ID_STALL = (MA_ACTIVE & BUS_WAIT) | (IF_ACTIVE & BUS_WAIT) | INST_SPLIT;
	
	assign BR_COND = ID_DECI.BR.BI & ((SR_T == ID_DECI.BR.BCV) | (ID_DECI.BR.BT == UCB));
	
	wire [15:0] DEC_IR = RES        ? {8'hF1,6'b000000,~NMI,1'b0} : 
	                     INTI.REQ   ? {8'hF0,INTI.VEC} : 
							   IFID_STALL ? PIPE.EX.IR : PIPE.ID.IR;
	SH_decoder decoder (DEC_IR, STATE, BR_COND, ID_DECI);
	
	wire BP_T_EXID = ID_DECI.BR.BI & ID_DECI.BR.BT != UCB & PIPE.EX.DI.CTRL.W & PIPE.EX.DI.CTRL.S == SR_;
	always_comb begin
		if (BP_T_EXID) begin
			SR_T = SR_NEW.T;
		end
		else begin
			SR_T = SR.T;
		end
	end
	
	wire [2:0] NEXT_STATE = STATE == ID_DECI.LST ? 3'd0 : STATE + 3'd1;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			PIPE.EX.IR <= '0;
			PIPE.EX.PC <= '0;
			PIPE.EX.DI <= DECI_RESET;
			PIPE.EX.RA <= '0;
			PIPE.EX.RB <= '0;
			PIPE.EX.R0 <= '0;
			PIPE.EX.BC <= 0;
			STATE <= '0;
			IFID_STALL <= 0;
			STBY <= 1;
		end
		else if (CE) begin
			if (!ID_STALL) begin
				PIPE.EX.IR <= DEC_IR;
				PIPE.EX.PC <= PIPE.ID.PC;
				PIPE.EX.DI <= ID_DECI;
				PIPE.EX.RA <= REGS_RAQ;
				PIPE.EX.RB <= REGS_RBQ;
				PIPE.EX.R0 <= REGS_R0Q;
				PIPE.EX.BC <= BR_COND;
				STATE <= NEXT_STATE;
				IFID_STALL <= |NEXT_STATE;
				
				if (STBY && (INTI.REQ || RES)) STBY <= 0;
			end	
			
		end
	end

	//**********************************************************
	//EX stage
	//**********************************************************
	//Bypassing datapath
	wire BP_A_EXEX = (PIPE.EX.DI.RA.N == PIPE.MA.DI.RA.N && PIPE.EX.DI.RA.R && PIPE.MA.DI.RA.W && !PIPE.MA.DI.MEM.R) ||
						  (PIPE.EX.DI.RA.N == PIPE.MA.DI.RB.N && PIPE.EX.DI.RA.R && PIPE.MA.DI.RB.W);

	wire BP_B_EXEX = (PIPE.EX.DI.RB.N == PIPE.MA.DI.RA.N && PIPE.EX.DI.RB.R && PIPE.MA.DI.RA.W && !PIPE.MA.DI.MEM.R) ||
						  (PIPE.EX.DI.RB.N == PIPE.MA.DI.RB.N && PIPE.EX.DI.RB.R && PIPE.MA.DI.RB.W);
	
	wire BP_C_EXEX = 5'd0               == PIPE.MA.DI.RA.N && PIPE.EX.DI.R0R && PIPE.MA.DI.RA.W && !PIPE.MA.DI.MEM.R;
	
	wire BP_A_MAEX = (PIPE.EX.DI.RA.N == PIPE.WB.DI.RA.N && PIPE.EX.DI.RA.R && PIPE.WB.DI.RA.W && !PIPE.WB.DI.MEM.R) ||
						  (PIPE.EX.DI.RA.N == PIPE.WB.DI.RB.N && PIPE.EX.DI.RA.R && PIPE.WB.DI.RB.W);
	
	wire BP_B_MAEX = (PIPE.EX.DI.RB.N == PIPE.WB.DI.RA.N && PIPE.EX.DI.RB.R && PIPE.WB.DI.RA.W && !PIPE.WB.DI.MEM.R) ||
						  (PIPE.EX.DI.RB.N == PIPE.WB.DI.RB.N && PIPE.EX.DI.RB.R && PIPE.WB.DI.RB.W);
	
	wire BP_C_MAEX = 5'd0               == PIPE.WB.DI.RA.N && PIPE.EX.DI.R0R && PIPE.WB.DI.RA.W && !PIPE.WB.DI.MEM.R;
	
	wire BP_A_WBEX = (PIPE.EX.DI.RA.N == PIPE.WB2.DI.RA.N && PIPE.EX.DI.RA.R && PIPE.WB2.DI.RA.W /*&& !PIPE.WB.DI.MEM.R*/) ||
						  (PIPE.EX.DI.RA.N == PIPE.WB2.DI.RB.N && PIPE.EX.DI.RA.R && PIPE.WB2.DI.RB.W);
	
	wire BP_B_WBEXA = PIPE.EX.DI.RB.N == PIPE.WB2.DI.RA.N && PIPE.EX.DI.RB.R && PIPE.WB2.DI.RA.W /*&& !PIPE.WB.DI.MEM.R*/;
	
	wire BP_B_WBEXB = PIPE.EX.DI.RB.N == PIPE.WB2.DI.RB.N && PIPE.EX.DI.RB.R && PIPE.WB2.DI.RB.W /*&& !PIPE.WB.DI.MEM.R*/;
	
	wire BP_C_WBEX = 5'd0               == PIPE.WB2.DI.RA.N && PIPE.EX.DI.R0R && PIPE.WB2.DI.RA.W /*&& !PIPE.WB.DI.MEM.R*/;
	
	wire BP_A_MALD = (PIPE.EX.DI.RA.N == PIPE.MA.DI.RA.N && PIPE.EX.DI.RA.R && PIPE.MA.DI.RA.W && PIPE.MA.DI.MEM.R);

	wire BP_B_MALD = (PIPE.EX.DI.RB.N == PIPE.MA.DI.RA.N && PIPE.EX.DI.RB.R && PIPE.MA.DI.RA.W && PIPE.MA.DI.MEM.R);
						  
	wire BP_A_WBLD = (PIPE.EX.DI.RA.N == PIPE.WB.DI.RA.N && PIPE.EX.DI.RA.R && PIPE.WB.DI.RA.W && PIPE.WB.DI.MEM.R);

	wire BP_B_WBLD = (PIPE.EX.DI.RB.N == PIPE.WB.DI.RA.N && PIPE.EX.DI.RB.R && PIPE.WB.DI.RA.W && PIPE.WB.DI.MEM.R);
	
	bit [31:0] REG_A;
	bit [31:0] REG_B;
	bit [31:0] REG_C;
	always_comb begin
		bit [11:0] ir_imm;
		bit [31:0] temp, IMM_VAL, SCR_VAL;
		bit [31:0] BP_A, BP_B, BP_C;
		
		ir_imm = PIPE.EX.IR[11:0];
		
		case (PIPE.EX.DI.IMMT)
			ZIMM4:  temp = {{28{1'b0}},      ir_imm[ 3:0]};
			SIMM8:  temp = {{24{ir_imm[ 7]}},ir_imm[ 7:0]};
			ZIMM8:  temp = {{24{1'b0}},      ir_imm[ 7:0]};
			SIMM12: temp = {{20{ir_imm[11]}},ir_imm[11:0]};
			ZERO:   temp = 32'h00000000;
			ONE:    temp = 32'h00000001;
		endcase
		
		if (PIPE.EX.DI.BR.BI) begin
			IMM_VAL = {temp[30:0],1'b0};
		end else begin
			case (PIPE.EX.DI.MEM.SZ)
				2'b00:   IMM_VAL = temp;
				2'b01:   IMM_VAL = {temp[30:0],1'b0};
				default: IMM_VAL= {temp[29:0],2'b00};
			endcase
		end
		
		case (PIPE.EX.DI.CTRL.S)
			SR_:  SCR_VAL = SR;
			GBR_: SCR_VAL = GBR;
			VBR_: SCR_VAL = VBR;
		endcase
		
		if (BP_A_EXEX) begin
			BP_A = PIPE.MA.RES;
		end
		else if (BP_A_MALD) begin
			BP_A = RD_SAVE;
		end
		else if (BP_A_WBLD || PIPE.EX.DI.DP.BPLDA) begin
			BP_A = PIPE.WB.RD;
		end
		else if (BP_A_MAEX) begin
			BP_A = PIPE.WB.RES;
		end
		else if (BP_A_WBEX || PIPE.EX.DI.DP.BPWBA) begin
			BP_A = PIPE.WB2.RESA;
		end
		else begin
			BP_A = PIPE.EX.RA;
		end
		
		case (PIPE.EX.DI.DP.RSA)
			GRX: REG_A = BP_A;
//			GR0: REG_A = PIPE.IDEX.R0;
			default: REG_A = 32'h0;
		endcase
		
		if (BP_B_EXEX || PIPE.EX.DI.DP.BPMAB) begin
			BP_B = PIPE.MA.RES;
		end
		else if (BP_B_MALD) begin
			BP_B = RD_SAVE;
		end
		else if (BP_B_WBLD) begin
			BP_B = PIPE.WB.RD;
		end
		else if (BP_B_MAEX) begin
			BP_B = PIPE.WB.RES;
		end
		else if (BP_B_WBEXA) begin
			BP_B = PIPE.WB2.RESA;
		end
		else if (BP_B_WBEXB) begin
			BP_B = PIPE.WB2.RESB;
		end
		else begin
			BP_B = PIPE.EX.RB;
		end
		
		case (PIPE.EX.DI.DP.RSB)
			GRX: REG_B = BP_B;
			PC_: REG_B = {PC[31:2],PC[1:0] & {2{~PIPE.EX.DI.DP.PCM}}};
			SCR: REG_B = SCR_VAL;
			default: REG_B = 32'h0;
		endcase
		
		if (BP_C_EXEX) begin
			BP_C = PIPE.MA.RES;
		end
		else if (BP_C_MAEX) begin
			BP_C = PIPE.WB.RES;
		end
		else if (BP_C_WBEX) begin
			BP_C = PIPE.WB2.RESA;
		end
		else begin
			BP_C = PIPE.EX.R0;
		end
		
		case (PIPE.EX.DI.DP.RSC)
			GRX: REG_C = BP_C;
			IMM: REG_C = IMM_VAL;
			default: REG_C = 32'h0;
		endcase
	end
	
	always_comb begin
		bit [31:0] ALU_A;
		bit [31:0] ALU_B;
		bit [31:0] ADDER_RES;
		bit        ADDER_C;
		bit        ADDER_V;
		bit [31:0] LOG_RES;
		bit        LOG_Z;
		bit [31:0] EXT_RES;
		bit [31:0] SHIFT_RES;
		bit        SHIFT_C;
		
		bit [31:0] adder_a;
		bit  [3:0] adder_code;
		bit  [2:0] adder_cmp;
		bit        ge_hs, eq, str_eq;
		bit [31:0] log_b;
		bit        cmp;
		
		case (PIPE.EX.DI.ALU.SA)
			0: ALU_A = REG_A;
			1: ALU_A = REG_C;
		endcase

		case (PIPE.EX.DI.ALU.SB)
			0: ALU_B = REG_B;
			1: ALU_B = REG_C;
		endcase
		
		adder_a = PIPE.EX.DI.ALU.OP == DIV ? {ALU_A[30:0],SR.T} : ALU_A;
		adder_code = PIPE.EX.DI.ALU.OP == DIV ? {1'b0,SR.M~^SR.Q} : PIPE.EX.DI.ALU.CD;
		adder_cmp = PIPE.EX.DI.ALU.CMP;
		{ADDER_C,ADDER_RES} = Adder(adder_a,ALU_B,SR.T,adder_code);
		ADDER_V = (ALU_A[31] & (ALU_B[31] ^ adder_cmp[0]) & ~ADDER_RES[31]) | (~ALU_A[31] & ~(ALU_B[31] ^ adder_cmp[0]) & ADDER_RES[31]);
		ge_hs = (~ALU_A[31] & ~ALU_B[31] & ~ADDER_RES[31]) | (ALU_A[31] & ALU_B[31] & ~ADDER_RES[31]) | ((adder_cmp[0] ^ ALU_A[31]) & (~adder_cmp[0] ^ ALU_B[31]));
		eq = ~|ADDER_RES[31:0];
		
		log_b = PIPE.EX.DI.TAS ? 32'h00000080 : ALU_B;
		LOG_RES = Log(ALU_A,log_b,PIPE.EX.DI.ALU.CD);
		LOG_Z = ~|LOG_RES;
		str_eq = ~|LOG_RES[31:24] | ~|LOG_RES[23:16] | ~|LOG_RES[15:8] | ~|LOG_RES[7:0];
		
		EXT_RES = Ext(ALU_A,ALU_B,PIPE.EX.DI.ALU.CD);
		
		{SHIFT_C,SHIFT_RES} = Shifter(ALU_A,SR.T,PIPE.EX.DI.ALU.CD);
		
		cmp = 0;
		case (PIPE.EX.DI.ALU.OP)
			ADD: begin
				ALU_RES = ADDER_RES;
				case (PIPE.EX.DI.ALU.CMP[2:1])
					2'b00: cmp = eq;
					2'b01: cmp = ge_hs;
					2'b11: cmp = ge_hs & ~eq;
					default:;
				endcase
			end
			LOG: begin
				ALU_RES = LOG_RES;
				cmp = str_eq;
			end
			EXT: ALU_RES = EXT_RES;
			SHIFT: ALU_RES = SHIFT_RES;
			DIV: ALU_RES = ADDER_RES;
			default: ALU_RES = ALU_B;
		endcase
								
		ALU_T = 0;
		case (PIPE.EX.DI.ALU.OP)
			ADD: case (PIPE.EX.DI.ALU.CD[3:2])
					2'b01: ALU_T <= cmp;
					2'b10: ALU_T <= ADDER_C;
					2'b11: ALU_T <= ADDER_V;
					default:;
				endcase
			LOG: ALU_T <= LOG_Z;
			SHIFT: ALU_T <= SHIFT_C;
			DIV: ALU_T <= ADDER_C;
			default: ;
		endcase
	end
	
	bit [31:0] MA_ADDR;
	always_comb begin
		case (PIPE.EX.DI.MEM.ADDS)
			ALUA:    MA_ADDR = REG_A;
			ALUB:    MA_ADDR = REG_B;
			ALURES:  MA_ADDR = ALU_RES;
		endcase
	end
	
	bit [31:0] MA_WD;
	always_comb begin
		case (PIPE.EX.DI.MEM.WDS)
			ALUA: MA_WD = REG_A;
			ALUB: MA_WD = REG_B;
			ALURES: MA_WD = ALU_RES;
		endcase
	end
	
	assign EX_STALL = (MA_ACTIVE & BUS_WAIT) | (IF_ACTIVE & BUS_WAIT) | INST_SPLIT;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			PIPE.MA.IR <= '0;
			PIPE.MA.DI <= DECI_RESET;
			PIPE.MA.RES <= '0;
			PIPE.MA.ADDR <= '0;
			PIPE.MA.WD <= '0;
			NEED_FETCH <= 0;
		end
		else if (CE) begin
			if (!EX_STALL) begin
				PIPE.MA.IR <= PIPE.EX.IR;
				PIPE.MA.DI <= PIPE.EX.DI;
				PIPE.MA.RES <= PIPE.EX.DI.BR.BI ? REG_B : ALU_RES;
				PIPE.MA.ADDR <= MA_ADDR;
				PIPE.MA.WD <= MA_WD;
				
				NEED_FETCH <= PIPE.EX.BC;
			end
		end
	end
	
	always_comb begin
		SR_NEW = SR;
		case (PIPE.EX.DI.CTRL.SRS)
			LOAD: SR_NEW <= ALU_RES & 32'h000003f3;
			ALU:case (PIPE.EX.DI.ALU.OP)
					ADD: SR_NEW.T <= ALU_T;
					LOG: SR_NEW.T <= ALU_T;
					SHIFT: SR_NEW.T <= ALU_T;
					DIV: begin
						SR_NEW.Q <= REG_A[31] ^ SR.M ^ ALU_T;
						SR_NEW.T <= (REG_A[31] ^ SR.M ^ ALU_T) ~^ SR.M;
					end
					NOP: SR_NEW.T <= ALU_RES[0];
					default:;
				endcase
			DIV0S: begin
				SR_NEW.Q <= REG_A[31];
				SR_NEW.M <= REG_B[31];
				SR_NEW.T <= REG_A[31] ^ REG_B[31];
			end
			DIV0U: begin
				SR_NEW.Q <= 0;
				SR_NEW.M <= 0;
				SR_NEW.T <= 0;
			end
			IMSK: SR_NEW.I <= INTI.LVL;
		endcase
	end
	
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			SR <= '0;
			GBR <= '0;
			VBR <= '0;
		end
		else if (CE) begin
			if (!EX_STALL) begin
				if (PIPE.EX.DI.CTRL.W) begin
					case (PIPE.EX.DI.CTRL.S)
						SR_:  SR <= SR_NEW;
						GBR_: GBR <= ALU_RES;
						VBR_: VBR <= ALU_RES;
						default:;
					endcase
				end
			end
		end
	end
	
	
	//**********************************************************
	//MA stage
	//**********************************************************
	bit [31:0] MA_RDATA;
	always_comb begin
		bit [1:0] mask;
		bit [31:0] temp;

		case (PIPE.MA.DI.MEM.SZ)
			2'b00:    mask = 2'b11;
			2'b01:    mask = 2'b10;
			default: mask = 2'b00;
		endcase
		
		temp = ByteShiftRigth(BUS_DI, (~PIPE.MA.ADDR[1:0] & mask));
		
		case (PIPE.MA.DI.MEM.SZ)
			2'b00:    MA_RDATA = {{24{temp[ 7]}},temp[ 7:0]};
			2'b01:    MA_RDATA = {{16{temp[15]}},temp[15:0]};
			default: MA_RDATA = temp;
		endcase
	end
	
	wire MA_STALL = (MA_ACTIVE & BUS_WAIT) | (IF_ACTIVE & BUS_WAIT) | MAWB_STALL;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			PIPE.WB.IR <= '0;
			PIPE.WB.DI <= DECI_RESET;
			PIPE.WB.RES <= '0;
			PIPE.WB.RD <= '0;
		end
		else if (CE) begin
			if (!MA_STALL && !INST_SPLIT) begin
				PIPE.WB.IR <= PIPE.MA.IR;
				PIPE.WB.DI <= PIPE.MA.DI;
				PIPE.WB.RES <= PIPE.MA.RES;
				PIPE.WB.RD <= MA_RDATA;
				RD_SAVE <= MA_RDATA;
			end
			else if (!MA_STALL && INST_SPLIT) begin
				RD_SAVE <= MA_RDATA;
			end
			else if (!(IF_ACTIVE & BUS_WAIT) && MAWB_STALL) begin
				PIPE.WB.IR <= PIPE.MA.IR;
				PIPE.WB.DI <= PIPE.MA.DI;
				PIPE.WB.RES <= PIPE.MA.RES;
				PIPE.WB.RD <= RD_SAVE;
			end
		end
	end
	
	bit [31:0] MA_WDATA;
	bit [3:0] MA_BA;
	always_comb begin
		bit [31:0] temp;

		temp = PIPE.MA.WD;
		
		case (PIPE.MA.DI.MEM.SZ)
			2'b00:   MA_WDATA = {temp[7:0],temp[7:0],temp[7:0],temp[7:0]};
			2'b01:   MA_WDATA = {temp[15:0],temp[15:0]};
			default: MA_WDATA = temp;
		endcase
		
		case (PIPE.MA.DI.MEM.SZ)
			2'b00:   MA_BA = 4'b0001 << ~PIPE.MA.ADDR[1:0];
			2'b01:   MA_BA = 4'b0011 << {~PIPE.MA.ADDR[1],1'b0};
			default: MA_BA = 4'b1111;
		endcase
	end
	
	//**********************************************************
	//WB stage
	//**********************************************************
	wire WB_STALL = (MA_ACTIVE & BUS_WAIT) | (IF_ACTIVE & BUS_WAIT) | MAWB_STALL;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			PIPE.WB2.IR <= '0;
			PIPE.WB2.DI <= DECI_RESET;
			PIPE.WB2.RESA <= '0;
			PIPE.WB2.RESB <= '0;
		end
		else if (CE) begin
			if (!WB_STALL && !INST_SPLIT) begin
				PIPE.WB2.IR <= PIPE.WB.IR;
				PIPE.WB2.DI <= PIPE.WB.DI;
				PIPE.WB2.RESA <= (PIPE.WB.DI.MEM.R || PIPE.WB.DI.MAC.R) ? PIPE.WB.RD : PIPE.WB.RES;
				PIPE.WB2.RESB <= PIPE.WB.RES;
			end
			else if (!(IF_ACTIVE & BUS_WAIT) && MAWB_STALL) begin
				PIPE.WB2.IR <= PIPE.WB.IR;
				PIPE.WB2.DI <= PIPE.WB.DI;
				PIPE.WB2.RESA <= (PIPE.WB.DI.MEM.R || PIPE.WB.DI.MAC.R) ? PIPE.WB.RD : PIPE.WB.RES;
				PIPE.WB2.RESB <= PIPE.WB.RES;
			end
		end
	end
	
	assign REGS_WAN = PIPE.WB.DI.RA.N;
	assign REGS_WAD = (PIPE.WB.DI.MEM.R || (PIPE.WB.DI.MAC.R && !PIPE.WB.DI.MEM.W)) ? PIPE.WB.RD : PIPE.WB.RES;
	assign REGS_WAE = PIPE.WB.DI.RA.W & !WB_STALL;
	
	assign REGS_WBN = PIPE.WB.DI.RB.N;
	assign REGS_WBD = PIPE.WB.RES;
	assign REGS_WBE = PIPE.WB.DI.RB.W & !WB_STALL;
	
	
	assign BUS_A = MA_ACTIVE ? PIPE.MA.ADDR : PC;
	assign BUS_DO = MA_WDATA;
	assign BUS_WR = PIPE.MA.DI.MEM.W & MA_ACTIVE;
	assign BUS_BA = MA_BA | {4{IF_ACTIVE & ~INST_SPLIT & ~IFID_STALL}};
	assign BUS_REQ = ((PIPE.MA.DI.MEM.R | PIPE.MA.DI.MEM.W) & MA_ACTIVE & ~MAWB_STALL) | (IF_ACTIVE & ~INST_SPLIT & ~IFID_STALL);
	
	assign MAC_SEL = PIPE.MA.DI.MAC.S & {2{MA_ACTIVE & ~MA_STALL}};
	assign MAC_OP = PIPE.MA.DI.MAC.OP;
	assign MAC_WE = |PIPE.MA.DI.MAC.S & PIPE.MA.DI.MAC.W & MA_ACTIVE & ~MA_STALL;
	
	assign INTO.LVL = SR.I;
	assign INTO.ACK = PIPE.EX.DI.IACK;
	
endmodule
