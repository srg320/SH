import SH2_PKG::*;

module SH_decoder (
	input      [15:0] IR,
	input       [2:0] STATE,
	input             BC,
	output DecInstr_t DECI
	
);
	
	parameter bit [4:0] R0 = 5'b00000;
	parameter bit [4:0] SP = 5'b01111;
	parameter bit [4:0] PR = 5'b10000;
	
	wire [4:0] RAN = {1'b0,IR[11:8]};
	wire [4:0] RBN = {1'b0,IR[7:4]};
	always_comb begin
		DECI = DECI_RESET;
		DECI.RA.N = RAN;
		DECI.RB.N = RBN;
		case (IR[15:12])
			4'b0000:	begin
				case (IR[3:0])
					4'b0010:	begin
						case (IR[7:4])
							4'b0000,			//STC SR,Rn
							4'b0001,			//STC GBR,Rn
							4'b0010: begin	//STC VBR,Rn
								DECI.RA = '{RAN, 0, 1};
								DECI.DP.RSB = SCR;
								case (IR[5:4])
									2'b00:  DECI.CTRL = '{0, SR_,  LOAD};
									2'b01:  DECI.CTRL = '{0, GBR_, LOAD};
									default:DECI.CTRL = '{0, VBR_, LOAD};
								endcase
							end
							default:;
						endcase
					end
					4'b0011:	begin
						case (IR[7:4])
							4'b0000,			//BSRF Rm
							4'b0010: begin	//BRAF Rm
								case (STATE)
									3'd0: begin
										DECI.RA = '{RAN, 1, 0};
										DECI.RB = '{PR,  0, ~IR[5]};
										DECI.DP.RSB = BPC;
										DECI.ALU = '{0, 0, ADD, 4'b0000, 3'b000};
										DECI.PCW = 1;
										DECI.BR = '{1, UCB, 0, ~IR[5]};
										DECI.LST = 3'd1;
									end
									3'd1: begin
										DECI.LST = 3'd1;
									end
									default:;
								endcase
							end
							default:;
						endcase
					end
					4'b0100,4'b0101,4'b0110:	begin	//MOV.x Rm,@(R0,Rn) (Rm->(Rn+R0))
						DECI.RA = '{RAN, 1, 0};
						DECI.RB = '{RBN, 1, 0};
						DECI.R0R = 1;
						DECI.ALU = '{0, 1, ADD, 4'b0000, 3'b000};
						DECI.MEM = '{ALURES, ALUB, IR[1:0], 0, 1};
					end
					4'b0111: begin	//MUL.L Rm,Rn
						case (STATE)
							3'd0: begin
								DECI.RB = '{RBN, 1, 0};
								DECI.MEM = '{ALURES, ALUB, 2'b10, 0, 0};
								DECI.MAC = '{2'b01, 0, 1, 4'b0001};
							end
							3'd1: begin
								DECI.RA = '{ RAN, 1, 0};
								DECI.MEM = '{ALURES, ALUA, 2'b10, 0, 0};
								DECI.MAC = '{2'b10, 0, 1, 4'b0001};
							end
							default:;
						endcase
						DECI.LST = 3'd1;
					end
					4'b1000:	begin
						case (IR[11:4])
							8'b00000000,			//CLRT (0->T)
							8'b00000001: begin	//SETT (1->T)
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = IR[4] ? ONE : ZERO;
								DECI.ALU = '{0, 1, NOP, 4'b0000, 3'b000};
								DECI.CTRL = '{1, SR_, ALU};
							end
							8'b00000010: begin	//CLRMAC
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ZERO;
								DECI.ALU = '{0, 1, NOP, 4'b0000, 3'b000};
								DECI.MEM = '{ALURES, ALURES, 2'b10, 0, 0};
								DECI.MAC = '{2'b11, 0, 1, 4'b1111};
							end
							default:;
						endcase
					end
					4'b1001:	begin
						case (IR[7:4])
							4'b0000: begin	//NOP
							end
							4'b0001: begin
								case (IR[11:8])
									4'b0000: begin	//DIV0U
										DECI.CTRL = '{1, SR_, DIV0U};
									end
									default:;
								endcase
							end
							4'b0010: begin	//MOVT Rn (1&SR->Rn)
								DECI.RA = '{RAN, 0, 1};
								DECI.DP.RSB = SCR;
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ONE;
								DECI.ALU = '{0, 1, LOG, 4'b0000, 3'b000};
								DECI.CTRL.S = SR_;
							end
							default:;
						endcase
					end
					4'b1010:	begin
						case (IR[7:4])
							4'b0000,			//STS MACH,Rn
							4'b0001: begin	//STS MACL,Rn
								DECI.RA = '{RAN, 0, 1};
								DECI.MEM.SZ = 2'b10;
								DECI.MAC = '{{~IR[4],IR[4]}, 1, 0, 4'b0000};
							end
							4'b0010: begin	//STS PR,Rn
								DECI.RA = '{RAN, 0, 1};
								DECI.RB = '{PR, 1, 0};
							end
							default:;
						endcase
					end
					4'b1011:	begin
						case (IR[11:4])
							8'b00000000: begin	//RTS (PR->PC)
								case (STATE)
									3'd0: begin
										DECI.RB = '{PR, 1, 0};
										DECI.PCW = 1;
										DECI.BR = '{1, UCB, 0, 0};
										DECI.LST = 3'd1;
									end
									3'd1: begin
										DECI.LST = 3'd1;
									end
									default:;
								endcase
							end
							8'b00000001: begin	//SLEEP
								case (STATE)
									3'd0: begin
										DECI.SLP = 1;
									end
									3'd1:;
									default:;
								endcase
								DECI.LST = 3'd1;
							end
							8'b00000010: begin	//RTE ((R15)->PC,R15+4->R15,(R15)->SR,R15+4->R15)
								case (STATE)
									3'd0: begin
										DECI.RB = '{SP, 1, 0};
										DECI.DP.RSC = RSC_IMM;
										DECI.IMMT = ONE;
										DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
										DECI.MEM = '{ALUB, ALUB, 2'b10, 1, 0};
										end
									3'd1: begin
										DECI.RB = '{SP, 0, 1};
										DECI.DP.BPMAB = 1;
										DECI.DP.RSC = RSC_IMM;
										DECI.IMMT = ONE;
										DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
										DECI.MEM = '{ALUB, ALUB, 2'b10, 1, 0};
										end
									3'd2: begin
										DECI.DP.BPLDA = 1;
										DECI.DP.RSC = RSC_IMM;
										DECI.IMMT = ZERO;
										DECI.ALU = '{0, 1, ADD, 4'b0000, 3'b000};
										DECI.PCW = 1;
										DECI.BR = '{1, DCB, 0, 0};
										end
									3'd3: begin
										DECI.DP.BPLDA = 1;
										DECI.DP.RSC = RSC_IMM;
										DECI.IMMT = ZERO;
										DECI.ALU = '{0, 1, ADD, 4'b0000, 3'b000};
										DECI.CTRL = '{1, SR_, LOAD};
										end
									default:;
								endcase
								DECI.LST = 3'd3;
							end
							default:;
						endcase
					end
					4'b1100,4'b1101,4'b1110:	begin	//MOV.x @(R0,Rm),Rn ((Rm+R0)->Rn)
						DECI.RA = '{RAN, 0, 1};
						DECI.RB = '{RBN, 1, 0};
						DECI.R0R = 1;
						DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
						DECI.MEM = '{ALURES, ALUB, IR[1:0], 1, 0};
					end
					4'b1111: begin	//MAC.L @Rm+,@Rn+
						case (STATE)
							3'd0: begin
								DECI.RB = '{RBN, 1, 1};
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ONE;
								DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
								DECI.MEM = '{ALUB, ALUB, 2'b10, 1, 0};
								DECI.MAC = '{2'b01, 0, 1, 4'b1001};
							end
							3'd1: begin
								DECI.RA = '{RAN, 1, 1};
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ONE;
								DECI.ALU = '{0, 1, ADD, 4'b0000, 3'b000};
								DECI.MEM = '{ALUA, ALUA, 2'b10, 1, 0};
								DECI.MAC = '{2'b10, 0, 1, 4'b1001};
							end
							default:;
						endcase
						DECI.LST = 3'd1;
					end
					default:;
				endcase
			end
			
			4'b0001:	begin	//MOV.L Rm,@(disp,Rn) (Rm->(Rn+disp*4))
				DECI.RA = '{RAN, 1, 0};
				DECI.RB = '{RBN, 1, 0};
				DECI.DP.RSC = RSC_IMM;
				DECI.IMMT = ZIMM4;
				DECI.ALU = '{0, 1, ADD, 4'b0000, 3'b000};
				DECI.MEM = '{ALURES, ALUB, 2'b10, 0, 1};
			end
			
			4'b0010:	begin
				case (IR[3:0])
					4'b0000,4'b0001,4'b0010:	begin	//MOV.x Rm,@Rn (Rm->(Rn))
						DECI.RA = '{RAN, 1, 0};
						DECI.RB = '{RBN, 1, 0};
						DECI.DP.RSC = RSC_IMM;
						DECI.IMMT = ZERO;
						DECI.ALU = '{0, 1, ADD, 4'b0000, 3'b000};
						DECI.MEM = '{ALURES, ALUB, IR[1:0], 0, 1};
					end
					4'b0100,4'b0101,4'b0110:	begin	//MOV.x Rm,@-Rn (Rm->(Rn-1/2/4), Rn-1/2/4->Rn)
						DECI.RA = '{RAN, 1, 1};
						DECI.RB = '{RBN, 1, 0};
						DECI.DP.RSC = RSC_IMM;
						DECI.IMMT = ONE;
						DECI.ALU = '{0, 1, ADD, 4'b0001, 3'b000};
						DECI.MEM = '{ALURES, ALUB, IR[1:0], 0, 1};
					end
					4'b0111:	begin	//DIV0S Rm,Rn
						DECI.RA = '{RAN, 1,0};
						DECI.RB = '{RBN, 1,0};
						DECI.CTRL = '{1, SR_, DIV0S};
					end
					4'b1000:	begin	//TST Rm,Rn
						DECI.RA = '{RAN, 1, 0};
						DECI.RB = '{RBN, 1, 0};
						DECI.ALU = '{0, 0, LOG, 4'b0000, 3'b000};///////////
						DECI.CTRL = '{1, SR_, ALU};
					end
					4'b1001:	begin	//AND Rm,Rn
						DECI.RA = '{RAN, 1, 1};
						DECI.RB = '{RBN, 1, 0};
						DECI.ALU = '{0, 0, LOG, 4'b0000, 3'b000};
					end
					4'b1010:	begin	//XOR Rm,Rn
						DECI.RA = '{RAN, 1, 1};
						DECI.RB = '{RBN, 1, 0};
						DECI.ALU = '{0, 0, LOG, 4'b0010, 3'b000};
					end
					4'b1011:	begin	//OR Rm,Rn
						DECI.RA = '{RAN, 1, 1};
						DECI.RB = '{RBN, 1, 0};
						DECI.ALU = '{0, 0, LOG, 4'b0100, 3'b000};
					end
					4'b1100:	begin	//CMP/STR Rm,Rn
						DECI.RA = '{RAN, 1, 0};
						DECI.RB = '{RBN, 1, 0};
						DECI.ALU = '{0, 0, LOG, 4'b0010, 3'b000};
						DECI.CTRL = '{1, SR_, ALU};
					end
					4'b1101:	begin	//XTRCT Rm,Rn
						DECI.RA = '{RAN, 1, 1};
						DECI.RB = '{RBN, 1, 0};
						DECI.ALU = '{0, 0, EXT, 4'b0010, 3'b000};
					end
					4'b1110,			//MULU.W Rm,Rn
					4'b1111:	begin	//MULS.W Rm,Rn
						DECI.RA = '{RAN, 1, 0};
						DECI.RB = '{RBN, 1, 0};
						DECI.ALU = '{0, 0, EXT, 4'b0010, 3'b000};
						DECI.MEM = '{ALURES, ALURES, 2'b10, 0, 0};
						DECI.MAC = '{2'b11, 0, 1, {2'b01,IR[1:0]}};
					end
					default:;
				endcase
			end
			
			4'b0011:	begin
				case (IR[3:0])
					4'b0000,			//CMP/EQ Rm,Rn
					4'b0010,			//CMP/HS Rm,Rn
					4'b0011,			//CMP/GE Rm,Rn
					4'b0110,			//CMP/HI Rm,Rn
					4'b0111: begin	//CMP/GT Rm,Rn
						DECI.RA = '{RAN, 1, 0};
						DECI.RB = '{RBN, 1, 0};
						DECI.ALU = '{0, 0, ADD, 4'b0101, IR[2:0]};
						DECI.CTRL = '{1, SR_, ALU};
					end
					4'b0100: begin	//DIV1 Rm,Rn
						DECI.RA = '{RAN, 1, 1};
						DECI.RB = '{RBN, 1, 0};
						DECI.ALU = '{0, 0, DIV, 4'b0000, 3'b000};
						DECI.CTRL = '{1, SR_, ALU};
					end
					4'b0101,			//DMULU.L Rm,Rn
					4'b1101: begin	//DMULS.L Rm,Rn
						case (STATE)
							3'd0: begin
								DECI.RB = '{RBN, 1, 0};
								DECI.MEM = '{ALURES, ALUB, 2'b10, 0, 0};
								DECI.MAC = '{2'b01, 0, 1, {3'b001,IR[3]}};
							end
							3'd1: begin
								DECI.RA = '{RAN, 1, 0};
								DECI.MEM = '{ALURES, ALUA, 2'b10, 0, 0};
								DECI.MAC = '{2'b10, 0, 1, {3'b001,IR[3]}};
							end
							default:;
						endcase
						DECI.LST = 3'd1;
					end
					4'b1000,			//SUB Rm,Rn
					4'b1010,			//SUBC Rm,Rn
					4'b1011: begin	//SUBV Rm,Rn
						DECI.RA = '{RAN, 1, 1};
						DECI.RB = '{RBN, 1, 0};
						DECI.ALU = '{0, 0, ADD, {IR[1:0],IR[1]&~IR[0],1'b1}, 3'b000};
						DECI.CTRL = '{|IR[1:0], SR_, ALU};
					end
					4'b1100,			//ADD Rm,Rn
					4'b1110,			//ADDC Rm,Rn
					4'b1111: begin	//ADDV Rm,Rn
						DECI.RA = '{RAN, 1, 1};
						DECI.RB = '{RBN, 1, 0};
						DECI.ALU = '{0, 0, ADD, {IR[1:0],IR[1]&~IR[0],1'b0}, 3'b000};
						DECI.CTRL = '{|IR[1:0], SR_, ALU};
					end
					default:;
				endcase
			end
			
			4'b0100:	begin
				case (IR[7:0])
					8'b00000000,			//SHLL Rn
					8'b00000001,			//SHLR Rn
					8'b00000100,			//ROTL Rn
					8'b00000101,			//ROTR Rn
					8'b00100000,			//SHAL Rn
					8'b00100001,			//SHAR Rn
					8'b00100100,			//ROTCL Rn
					8'b00100101: begin	//ROTCR Rn
						DECI.RA = '{RAN, 1, 1};
						DECI.ALU = '{0, 0, SHIFT, {1'b0,IR[2],IR[5],IR[0]}, 3'b000};
						DECI.CTRL = '{1, SR_, ALU};
					end
					8'b00000010,			//STS.L MACH,@-Rn
					8'b00010010: begin	//STS.L MACL,@-Rn
						DECI.RA = '{RAN, 1, 1};
						DECI.DP.RSC = RSC_IMM;
						DECI.IMMT = ONE;
						DECI.ALU = '{0, 1, ADD, 4'b0001, 3'b000};
						DECI.MEM = '{ALURES, ALUB, 2'b10, 0, 1};
						DECI.MAC = '{{~IR[4],IR[4]}, 1, 0, 4'b0000};
					end
					8'b00100010: begin	//STS.L PR,@-Rn
						DECI.RA = '{RAN, 1, 1};
						DECI.RB = '{PR, 1, 0};
						DECI.DP.RSC = RSC_IMM;
						DECI.IMMT = ONE;
						DECI.ALU = '{0, 1, ADD, 4'b0001, 3'b000};
						DECI.MEM = '{ALURES, ALUB, 2'b10, 0, 1};
					end
					8'b00000011,			//STC.L SR,@-Rn
					8'b00010011,			//STC.L GBR,@-Rn
					8'b00100011: begin	//STC.L VBR,@-Rn
						case (STATE)
							3'd0: begin
								DECI.RA = '{RAN, 1, 1};
								DECI.DP.RSB = SCR;
								case (IR[5:4])
									2'b00:  DECI.CTRL.S = SR_;
									2'b01:  DECI.CTRL.S = GBR_;
									default:DECI.CTRL.S = VBR_;
								endcase
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ONE;
								DECI.ALU = '{0, 1, ADD, 4'b0001, 3'b000};
								DECI.MEM = '{ALURES, ALUB, 2'b10, 0, 1};
								end
							3'd1: begin
								end
							default:;
						endcase
						DECI.LST = 3'd1;
					end
					8'b00000110,			//LDS.L @Rm+,MACH
					8'b00010110: begin	//LDS.L @Rm+,MACL
						DECI.RB = '{RAN, 1, 1};
						DECI.DP.RSC = RSC_IMM;
						DECI.IMMT = ONE;
						DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
						DECI.MEM = '{ALUB, ALUB, 2'b10, 1, 0};
						DECI.MAC = '{{~IR[4],IR[4]}, 0, 1, 4'b0000};
					end
					8'b00100110: begin	//LDS.L @Rm+,PR
						DECI.RA = '{PR, 0, 1};
						DECI.RB = '{RAN, 1, 1};
						DECI.DP.RSC = RSC_IMM;
						DECI.IMMT = ONE;
						DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
						DECI.MEM = '{ALUB, ALUB, 2'b10, 1, 0};
					end
					8'b00000111,			//LDC.L @Rm+,SR
					8'b00010111,			//LDC.L @Rm+,GBR
					8'b00100111: begin	//LDC.L @Rm+,VBR
						case (STATE)
							3'd0: begin
								DECI.RB = '{RAN, 1, 1};
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ONE;
								DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
								DECI.MEM = '{ALUB, ALUB, 2'b10, 1, 0};
							end
							3'd1: begin
							end
							3'd2: begin
								DECI.DP.BPLDA = 1;
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ZERO;
								DECI.ALU = '{0, 1, ADD, 4'b0000, 3'b000};
								case (IR[5:4])
									2'b00:  DECI.CTRL = '{1, SR_, LOAD};
									2'b01:  DECI.CTRL = '{1, GBR_, LOAD};
									default:DECI.CTRL = '{1, VBR_, LOAD};
								endcase
							end
							default:;
						endcase
						DECI.LST = 3'd2;
					end
					8'b00001000,			//SHLL2 Rn
					8'b00001001,			//SHLR2 Rn
					8'b00011000,			//SHLL8 Rn
					8'b00011001,			//SHLR8 Rn
					8'b00101000,			//SHLL16 Rn
					8'b00101001: begin	//SHLR16 Rn
						DECI.RA = '{RAN, 1, 1};
						DECI.ALU = '{0, 0, SHIFT, {1'b1,IR[5],IR[4],IR[0]}, 3'b000};
					end
					8'b00001010,			//LDS Rm,MACH
					8'b00011010: begin	//LDS Rm,MACL
						DECI.RA = '{RAN, 1, 0};
						DECI.MEM = '{ALURES, ALUB, 2'b10, 0, 0};
						DECI.MAC = '{{~IR[4],IR[4]}, 0, 1, 4'b0000};
					end
					8'b00101010: begin	//LDS Rm,PR
						DECI.RA = '{RAN, 1, 0};
						DECI.RB = '{PR,  0, 1};
						DECI.DP.RSC = RSC_IMM;
						DECI.IMMT = ZERO;
						DECI.ALU = '{0, 1, ADD, 4'b0000, 3'b000};
					end
					8'b00001011,			//JSR @Rm
					8'b00101011: begin	//JMP @Rm
						case (STATE)
							3'd0: begin
								DECI.RA = '{RAN, 1, 0};
								DECI.RB = '{PR, 0, ~IR[5]};
								DECI.DP.RSB = BPC;
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ZERO;
								DECI.ALU = '{0, 1, ADD, 4'b0000, 3'b000};
								DECI.PCW = 1;
								DECI.BR = '{1, UCB, 0, ~IR[5]};
								DECI.LST = 3'd1;
							end
							3'd1: begin
								DECI.LST = 3'd1;
							end
							default:;
						endcase
					end
					8'b00001110,			//LDC Rm,SR
					8'b00011110,			//LDC Rm,GBR
					8'b00101110: begin	//LDC Rm,VBR
						DECI.RB = '{RAN, 1, 0};
						case (IR[5:4])
							2'b00:  DECI.CTRL = '{1, SR_, LOAD};
							2'b01:  DECI.CTRL = '{1, GBR_, LOAD};
							default:DECI.CTRL = '{1, VBR_, LOAD};
						endcase
					end
					8'b00010000: begin	//DT Rn (Rn-1->Rn)
						DECI.RA = '{RAN, 1, 1};
						DECI.DP.RSC = RSC_IMM;
						DECI.IMMT = ONE;
						DECI.ALU = '{0, 1, ADD, 4'b0101, 3'b000};
						DECI.CTRL = '{1, SR_, ALU};
					end
					8'b00010001,			//CMP/PZ Rn
					8'b00010101: begin	//CMP/PL Rn
						DECI.RA = '{RAN, 1, 0};
						DECI.DP.RSC = RSC_IMM;
						DECI.IMMT = ZERO;
						DECI.ALU = '{0, 1, ADD, 4'b0101, {IR[2],2'b11}};
						DECI.CTRL = '{1, SR_, ALU};
					end
					8'b00011011: begin	//TAS.B @Rn
						case (STATE)
							3'd0: begin
								DECI.RA = '{RAN, 1, 0};
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ZERO;
								DECI.ALU = '{0, 1, ADD, 4'b0000, 3'b000};
								DECI.MEM = '{ALURES, ALUB, 2'b00, 1, 0};
							end
							3'd1: begin
								DECI.DP.BPMAB = 1;
							end
							3'd2: begin
								DECI.DP.BPLDA = 1;
								DECI.DP.BPMAB = 1;
								DECI.ALU = '{0, 0, LOG, 4'b0100, 3'b000};
								DECI.MEM = '{ALUB, ALURES, 2'b00, 0, 1};
							end
							3'd3: begin
								DECI.DP.BPWBA = 1;
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ZERO;
								DECI.ALU = '{0, 1, ADD, 4'b0101, 3'b000};
								DECI.CTRL = '{1, SR_, ALU};
							end
							default:;
						endcase
						DECI.TAS = 1;
						DECI.LST = 3'd3;
					end
					default:;
				endcase
				
				case (IR[3:0])
					4'b1111: begin	//MAC.W @Rm+,@Rn+
						case (STATE)
							3'd0: begin
								DECI.RB = '{RBN, 1, 1};
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ONE;
								DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
								DECI.MEM = '{ALUB, ALUB, 2'b01, 1, 0};
								DECI.MAC = '{2'b01, 0, 1, 4'b1011};
							end
							3'd1: begin
								DECI.RA = '{RAN, 1, 1};
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ONE;
								DECI.ALU = '{0, 1, ADD, 4'b0000, 3'b000};
								DECI.MEM = '{ALUA, ALUA, 2'b01, 1, 0};
								DECI.MAC = '{2'b10, 0, 1, 4'b1011};
							end
							default:;
						endcase
						DECI.LST = 3'd1;
					end
					default:;
				endcase
			end
			
			4'b0101:	begin	//MOV.L @(disp,Rm),Rn ((Rm+disp*4)->Rn)
				DECI.RA = '{RAN, 0, 1};
				DECI.RB = '{RBN, 1, 0};
				DECI.DP.RSC = RSC_IMM;
				DECI.IMMT = ZIMM4;
				DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
				DECI.MEM = '{ALURES, ALUB, 2'b10, 1, 0};
			end
			
			4'b0110:	begin
				case (IR[3:0])
					4'b0000,4'b0001,4'b0010:	begin	//MOV.x @Rm,Rn ((0+Rm)->Rn)
						DECI.RA = '{RAN, 0, 1};
						DECI.RB = '{RBN, 1, 0};
						DECI.DP.RSC = RSC_IMM;
						DECI.IMMT = ZERO;
						DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
						DECI.MEM = '{ALURES, ALUB, IR[1:0], 1, 0};
					end
					4'b0011:	begin	//MOV Rm,Rn (0+Rm->Rn)
						DECI.RA = '{RAN, 0, 1};
						DECI.RB = '{RBN, 1, 0};
						DECI.DP.RSC = RSC_IMM;
						DECI.IMMT = ZERO;
						DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
					end
					4'b0100,4'b0101,4'b0110: begin	//MOV.x @Rm+,Rn ((Rm)->Rn, (1*size)+Rm->Rm)
						DECI.RA = '{RAN, 0, 1};
						DECI.RB = '{RBN, 1, 1};
						DECI.DP.RSC = RSC_IMM;
						DECI.IMMT = ONE;
						DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
						DECI.MEM = '{ALUB, ALUB, IR[1:0], 1, 0};
					end
					4'b0111:	begin	//NOT Rm,Rn (0|~Rm->Rn)
						DECI.RA = '{RAN, 0, 1};
						DECI.RB = '{RBN, 1, 0};
						DECI.DP.RSC = RSC_IMM;
						DECI.IMMT = ZERO;
						DECI.ALU = '{1, 0, LOG, 4'b0101, 3'b000};
					end
					4'b1000,			//SWAP.B Rm,Rn
					4'b1001:	begin	//SWAP.W Rm,Rn
						DECI.RA = '{RAN, 0, 1};
						DECI.RB = '{RBN, 1, 0};
						DECI.ALU = '{0, 0, EXT, {1'b0,IR[2:0]}, 3'b000};
					end
					4'b1010,			//NEGC Rm,Rn (0-Rm-T->Rn)
					4'b1011:	begin	//NEG Rm,Rn (0-Rm->Rn)
						DECI.RA = '{RAN, 0, 1};
						DECI.RB = '{RBN, 1, 0};
						DECI.DP.RSC = RSC_IMM;
						DECI.IMMT = ZERO;
						DECI.ALU = '{1, 0, ADD, {~IR[0],1'b0,~IR[0],1'b1}, 3'b000};
						DECI.CTRL = '{~IR[0], SR_, ALU};
					end
					4'b1100,			//EXTU.B Rm,Rn
					4'b1101,			//EXTU.W Rm,Rn
					4'b1110,			//EXTS.B Rm,Rn
					4'b1111:	begin	//EXTS.W Rm,Rn
						DECI.RA = '{RAN, 0, 1};
						DECI.RB = '{RBN, 1, 0};
						DECI.ALU = '{0, 0, EXT, {1'b0,IR[2:0]}, 3'b000};
					end
					default:;
				endcase
			end
			
			4'b0111:	begin	//ADD #imm,Rn
				DECI.RA = '{RAN, 1, 1};
				DECI.DP.RSC = RSC_IMM;
				DECI.IMMT = SIMM8;
				DECI.ALU = '{0, 1, ADD, 4'b0000, 3'b000};
			end
			
			4'b1000:	begin
				case (IR[11:8])
					4'b0000,			//MOV.B R0,@(disp,Rm) (R0->(Rm+disp))
					4'b0001:	begin	//MOV.W R0,@(disp,Rm) (R0->(Rm+disp*2))
						DECI.RA = '{R0,  1, 0};
						DECI.RB = '{RBN, 1, 0};
						DECI.DP.RSC = RSC_IMM;
						DECI.IMMT = ZIMM4;
						DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
						DECI.MEM = '{ALURES, ALUA, IR[9:8], 0, 1};
					end
					4'b0100,			//MOV.B @(disp,Rm),R0 ((Rm+disp)->R0)
					4'b0101:	begin	//MOV.W @(disp,Rm),R0 ((Rm+disp*2)->R0)
						DECI.RA = '{R0,  0, 1};
						DECI.RB = '{RBN, 1, 0};
						DECI.DP.RSC = RSC_IMM;
						DECI.IMMT = ZIMM4;
						DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
						DECI.MEM = '{ALURES, ALUA, IR[9:8], 1, 0};
					end
					4'b1000:	begin	//CPM/EQ #imm,R0
						DECI.RA = '{R0, 1, 0};
						DECI.DP.RSC = RSC_IMM;
						DECI.IMMT = SIMM8;
						DECI.ALU = '{0, 1, ADD, 4'b0101, 3'b000};
						DECI.CTRL = '{1, SR_, ALU};
					end
					4'b1001,			//BT label
					4'b1011:	begin	//BF/S label
						case (STATE)
							3'd0: begin
								DECI.DP.RSB = BPC;
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = SIMM8;
								DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
								DECI.PCW = BC;
								DECI.BR = '{1, CB, ~IR[9], 0};
								DECI.LST = BC ? 3'd2 : 3'd0;
							end
							3'd1: begin
								DECI.LST = 3'd2;
							end
							3'd2: begin
								DECI.LST = 3'd2;
							end
							default:;
						endcase
					end
					4'b1101,			//BT/S label
					4'b1111:	begin	//BF/S label
						case (STATE)
							3'd0: begin
								DECI.DP.RSB = BPC;
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = SIMM8;
								DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
								DECI.PCW = BC;
								DECI.BR = '{1, DCB, ~IR[9], 0};
								DECI.LST = BC ? 3'd1 : 3'd0;
							end
							3'd1: begin
								DECI.BR = '{0, DCB, ~IR[9], 0};
								DECI.LST = 3'd1;
							end
							default:;
						endcase
					end
					default:;
				endcase
			end
			
			4'b1001,			//MOV.W @(disp,PC),Rn ((PC+disp*2)->Rn)
			4'b1101:	begin	//MOV.L @(disp,PC),Rn ((PC+disp*4)->Rn)
				DECI.RA = '{RAN, 0, 1};
				DECI.DP.RSB = BPC;
				DECI.DP.RSC = RSC_IMM;
				DECI.DP.PCM = IR[14];
				DECI.IMMT = ZIMM8;
				DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
				DECI.MEM = '{ALURES, ALUA, {IR[14],~IR[14]}, 1, 0};
			end
			
			4'b1010,			//BRA label
			4'b1011:	begin	//BSR label
				case (STATE)
					3'd0: begin
						DECI.RB = '{PR, 0, IR[12]};
						DECI.DP.RSB = BPC;
						DECI.DP.RSC = RSC_IMM;
						DECI.IMMT = SIMM12;
						DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
						DECI.PCW = 1;
						DECI.BR = '{1, UCB, 0, IR[12]};
					end
					3'd1: begin
						
					end
					default:;
				endcase
				DECI.LST = 3'd1;
			end
			
			4'b1100:	begin
				case (IR[11:8])
					4'b0000,4'b0001,4'b0010: begin	//MOV.x R0,@(disp,GBR) (R0->(GBR+disp*1/2/4))
						DECI.RA = '{R0, 1, 0};
						DECI.DP.RSB = SCR;
						DECI.DP.RSC = RSC_IMM;
						DECI.IMMT = ZIMM8;
						DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
						DECI.CTRL.S = GBR_;
						DECI.MEM = '{ALURES, ALUA, IR[9:8], 0, 1};
					end
					4'b0011: begin	//TRAPA @imm
						case (STATE)
							3'd0: begin
								
							end
							3'd1: begin
								DECI.RA = '{SP, 1, 1};
								DECI.DP.RSB = SCR;
								DECI.CTRL.S = SR_;
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ONE;
								DECI.ALU = '{0, 1, ADD, 4'b0001, 3'b000};
								DECI.MEM = '{ALURES, ALUB, 2'b10, 0, 1};
							end
							3'd2: begin
								DECI.RA = '{SP, 1, 1};
								DECI.DP.RSB = BPC;///////////////////////////////
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ONE;
								DECI.ALU = '{0, 1, ADD, 4'b0001, 3'b000};
								DECI.MEM = '{ALURES, ALUB, 2'b10, 0, 1};
							end
							3'd3: begin
								DECI.DP.RSB = SCR;
								DECI.CTRL.S = VBR_;
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ZIMM8;
								DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
								DECI.MEM = '{ALUB, ALUB, 2'b10, 1, 0};
							end
							3'd4: begin
								
							end
							3'd5: begin
								DECI.DP.BPLDA = 1;
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ZERO;
								DECI.ALU = '{0, 1, ADD, 4'b0000, 3'b000};
								DECI.PCW = 1;
								DECI.BR = '{1, UCB, 0, 0};
							end
							3'd6: begin
								
							end
							default:;
						endcase
						DECI.LST = 3'd6;
					end
					4'b0100,4'b0101,4'b0110: begin	//MOV.x @(disp,GBR),R0 ((GBR+disp*1/2/4)->R0)
						DECI.RA = '{R0, 0, 1};
						DECI.DP.RSB = SCR;
						DECI.DP.RSC = RSC_IMM;
						DECI.IMMT = ZIMM8;
						DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
						DECI.CTRL.S = GBR_;
						DECI.MEM = '{ALURES, ALUA, IR[9:8], 1, 0};
					end
					4'b0111:	begin	//MOVA @(disp,PC),R0 ((PC+disp*4)->R0)
						DECI.RA = '{R0, 0, 1};
						DECI.DP.RSB = BPC;
						DECI.DP.RSC = RSC_IMM;
						DECI.DP.PCM = 1;
						DECI.IMMT = ZIMM8;
						DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
						DECI.MEM.SZ = 2'b10;
					end
					4'b1000:	begin	//TST #imm,R0
						DECI.RA = '{R0, 1, 0};
						DECI.DP.RSC = RSC_IMM;
						DECI.IMMT = ZIMM8;
						DECI.ALU.OP = LOG;
						DECI.ALU = '{0, 1, LOG, 4'b0000, 3'b000};
						DECI.CTRL = '{1, SR_, ALU};
					end
					4'b1001:	begin	//AND #imm,R0
						DECI.RA = '{R0, 1, 1};
						DECI.DP.RSC = RSC_IMM;
						DECI.IMMT = ZIMM8;
						DECI.ALU = '{0, 1, LOG, 4'b0000, 3'b000};
					end
					4'b1010:	begin	//XOR #imm,R0
						DECI.RA = '{R0, 1, 1};
						DECI.DP.RSC = RSC_IMM;
						DECI.IMMT = ZIMM8;
						DECI.ALU = '{0, 1, LOG, 4'b0010, 3'b000};
					end
					4'b1011:	begin	//OR #imm,R0
						DECI.RA = '{R0, 1, 1};
						DECI.DP.RSC = RSC_IMM;
						DECI.IMMT = ZIMM8;
						DECI.ALU = '{0, 1, LOG, 4'b0100, 3'b000};
					end
					4'b1100,			//TST.B #imm,@(R0,GBR)
					4'b1101,			//AND.B #imm,@(R0,GBR)
					4'b1110,			//XOR.B #imm,@(R0,GBR)
					4'b1111:	begin	//OR.B #imm,@(R0,GBR)
						case (STATE)
							3'd0: begin
								DECI.R0R = 1;
								DECI.DP.RSB = SCR;
								DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
								DECI.CTRL.S = GBR_;
								DECI.MEM = '{ALURES, ALUB, 2'b00, 1, 0};
							end
							3'd1: begin
								DECI.DP.BPMAB = 1;
							end
							3'd2: begin
								DECI.DP.RSC = RSC_IMM;
								DECI.DP.BPLDA = 1;
								DECI.DP.BPMAB = 1;
								DECI.IMMT = ZIMM8;
								case (IR[9:8])
									2'b10:  DECI.ALU = '{0, 1, LOG, 4'b0010, 3'b000};
									2'b11:  DECI.ALU = '{0, 1, LOG, 4'b0100, 3'b000};
									default:DECI.ALU = '{0, 1, LOG, 4'b0000, 3'b000};
								endcase
								DECI.MEM = '{ALUB, ALURES, 2'b00, 0, |IR[9:8]};
								DECI.CTRL = '{~|IR[9:8], SR_, ALU};
							end
							default:;
						endcase
						DECI.LST = 3'd2;
					end
					default:;
				endcase
			end
			
			4'b1110:	begin	//MOV #imm,Rn
				DECI.RA = '{RAN, 0, 1};
				DECI.DP.RSC = RSC_IMM;
				DECI.ALU = '{0, 1, NOP, 4'b0000, 3'b000};
			end
			
			4'b1111:	begin	
				case (IR[11:8])
					4'b0000:	begin	//Interrupt
						case (STATE)
							3'd0: begin
								DECI.IACK = 1;
							end
							3'd1: begin
								DECI.RA = '{SP, 1, 1};
								DECI.DP.RSB = SCR;
								DECI.CTRL.S = SR_;
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ONE;
								DECI.ALU = '{0, 1, ADD, 4'b0001, 3'b000};
								DECI.MEM = '{ALURES, ALUB, 2'b10, 0, 1};
							end
							3'd2: begin
								DECI.RA = '{SP, 1, 1};
								DECI.DP.RSB = IPC;
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ONE;
								DECI.ALU = '{0, 1, ADD, 4'b0001, 3'b000};
								DECI.MEM = '{ALURES, ALUB, 2'b10, 0, 1};
							end
							3'd3: begin
								DECI.CTRL = '{1, SR_, IMSK};
							end
							3'd4: begin
								DECI.DP.RSB = SCR;
								DECI.CTRL.S = VBR_;
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ZIMM8;
								DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
								DECI.MEM = '{ALURES, ALUB, 2'b10, 1, 0};
							end
							3'd5: begin
								
							end
							3'd6: begin
								DECI.DP.BPLDA = 1;
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ZERO;
								DECI.ALU = '{0, 1, ADD, 4'b0000, 3'b000};
								DECI.PCW = 1;
								DECI.BR = '{1, UCB, 0, 0};
							end
							3'd7: begin
								
							end
							default:;
						endcase
						DECI.LST = 3'd7;
					end
					4'b0001:	begin	//RESET
						case (STATE)
							3'd0: begin
								DECI.CTRL = '{1, SR_, IMSK};
								DECI.IACK = 1;
							end
							3'd1: begin
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ZERO;
								DECI.ALU = '{0, 1, NOP, 4'b0000, 3'b000};
								DECI.CTRL = '{1, VBR_, LOAD};
							end
							3'd2: begin
								DECI.DP.BPMAB = 1;
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ZIMM8;
								DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
								DECI.MEM = '{ALURES, ALUB, 2'b10, 1, 0};
								end
							3'd3: begin
								DECI.DP.BPMAB = 1;
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ONE;
								DECI.ALU = '{1, 0, ADD, 4'b0000, 3'b000};
								DECI.MEM = '{ALURES, ALUB, 2'b10, 1, 0};
								end
							3'd4: begin
								DECI.DP.BPLDA = 1;
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ZERO;
								DECI.ALU = '{0, 1, ADD, 4'b0000, 3'b000};
								DECI.PCW = 1;
								DECI.BR = '{1, UCB, 0, 0};
								end
							3'd5: begin
								DECI.RA = '{SP, 0, 1};
								DECI.DP.BPLDA = 1;
								DECI.DP.RSC = RSC_IMM;
								DECI.IMMT = ZERO;
								DECI.ALU = '{0, 1, ADD, 4'b0000, 3'b000};
								end
							default:;
						endcase
						DECI.LST = 3'd5;
					end
					default:;
				endcase
			end
			
			default:;
		endcase
	end
 
	
endmodule
