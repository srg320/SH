import CPU_PKG::*;

module BSC (
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	
	input             RES_N,
	
	output reg [26:0] A,
	input      [31:0] DI,
	output reg [31:0] DO,
	output reg        BS_N,
	output reg        CS0_N,
	output reg        CS1_N,
	output reg        CS2_N,
	output reg        CS3_N,
	output reg        RD_WR_N,	//WE_N
	output reg        CE_N,		//RAS_N
	output reg        OE_N,		//CAS_N
	output reg  [3:0] WE_N,		//CASxx_N, DQMxx
	output reg        RD_N,
	input             WAIT_N,
	input             BRLS_N,	//BACK_N
	output            BGR_N,	//BREQ_N
	output            IVECF_N,
	input       [5:0] MD,
	
	input      [31:0] IBUS_A,
	input      [31:0] IBUS_DI,
	output     [31:0] IBUS_DO,
	input       [3:0] IBUS_BA,
	input             IBUS_WE,
	input             IBUS_REQ,
	output            IBUS_BUSY,
	input             IBUS_LOCK,
	output            IBUS_ACT,
	
	output            IRQ,
	
	output reg        CACK,
	output            BUS_RLS
);

	BCR1_t      BCR1;
	BCR2_t      BCR2;
	WCR_t       WCR;
	MCR_t       MCR;
	RTCSR_t     RTCSR;
	RTCNT_t     RTCNT;
	RTCOR_t     RTCOR;
	
	function bit [1:0] GetAreaW(input bit [1:0] area, input WCR_t wcr);
		bit [1:0] res;
	
		case (area)
			2'd0: res = wcr.W0;
			2'd1: res = wcr.W1;
			2'd2: res = wcr.W2;
			2'd3: res = wcr.W3;
		endcase
		return res;
	endfunction
	
	function bit [1:0] GetAreaIW(input bit [1:0] area, input WCR_t wcr);
		bit [1:0] res;
	
		case (area)
			2'd0: res = wcr.IW0;
			2'd1: res = wcr.IW1;
			2'd2: res = wcr.IW2;
			2'd3: res = wcr.IW3;
		endcase
		return res;
	endfunction
	
	function bit [1:0] GetAreaLW(input bit [1:0] area, input BCR1_t bcr1);
		bit [1:0] res;
	
		case (area)
			2'd0: res = bcr1.A0LW;
			2'd1: res = bcr1.A1LW;
			2'd2: res = bcr1.AHLW;
			2'd3: res = bcr1.AHLW;
		endcase
		return res;
	endfunction
	
	function bit [1:0] GetAreaSZ(input bit [1:0] area, input BCR2_t bcr2, input bit [1:0] a0sz);
		bit [1:0] res;
	
		case (area)
			2'd0: res = a0sz;
			2'd1: res = bcr2.A1SZ;
			2'd2: res = bcr2.A2SZ;
			2'd3: res = bcr2.A3SZ;
		endcase
		return res;
	endfunction
	
	bit         BREQ;
	wire        BACK = ~BRLS_N;
	bit         BGR;
	wire        BRLS = ~BRLS_N;
	
	wire        MASTER = ~MD[5];
	wire [1:0]  A0_SZ = MD[4:3] + 2'b01;
	
	typedef enum bit[2:0] {
		T0 = 3'b000,  
		T1 = 3'b001,
		T2 = 3'b010,
		TW = 3'b011,
		TI = 3'b100
	} BusState_t;
	BusState_t BUS_STATE;
	
	
	wire BUS_ACCESS_REQ = IBUS_A[31:27] ==? 5'b00?00 && IBUS_REQ; 
	
	bit         BUSY;
	bit  [31:0] DAT_BUF;
	bit   [3:0] NEXT_BA;
	always @(posedge CLK or negedge RST_N) begin
		BusState_t STATE_NEXT;
		bit  [2:0] WAIT_CNT;
		bit [31:0] IBUS_DI_SAVE;
		bit        IBUS_WE_SAVE;
		bit  [1:0] AREA_SZ;
//		bit        RD_LAST;
//		bit  [1:0] CS_LAST;
//		bit        NO_IDLE;
		
		if (!RST_N) begin
			BUSY <= 0;
			CS0_N <= 1;
			CS1_N <= 1;
			CS2_N <= 1;
			CS3_N <= 1;
			BS_N <= 1;
			RD_WR_N <= 1;
			RD_N <= 1;
			WE_N <= 4'b1111;
			CACK <= 0;
			BUS_STATE <= T0;
			WAIT_CNT <= '0;
			NEXT_BA <= '0;
//			RD_LAST <= 0;
//			CS_LAST <= '0;
		end
		else begin
//			NO_IDLE = 0;
			AREA_SZ = GetAreaSZ(A[26:25],BCR2,A0_SZ);
			STATE_NEXT = BUS_STATE;
			case (BUS_STATE)
				T0: begin
				end
				
				T1: begin
					if (CE_R) begin
						BS_N <= 1;
						case (GetAreaW(A[26:25],WCR))
							2'b00: begin
								if (!NEXT_BA) begin
									BUSY <= 0;
								end
								STATE_NEXT = T2;
							end
							2'b01: begin
								WAIT_CNT <= 3'd0;
								STATE_NEXT = TW;
							end
							2'b10: begin
								WAIT_CNT <= 3'd1;
								STATE_NEXT = TW;
							end
							2'b11: begin
								case (GetAreaLW(A[26:25],BCR1))
									2'b00: WAIT_CNT <= 3'd2;
									2'b01: WAIT_CNT <= 3'd3;
									2'b10: WAIT_CNT <= 3'd4;
									2'b11: WAIT_CNT <= 3'd5;
								endcase
								STATE_NEXT = TW;
							end
						endcase
					end
				end
				
				TW: begin
					if (CE_R) begin
						if (WAIT_CNT) begin
							WAIT_CNT <= WAIT_CNT - 3'd1;
						end
						else if (WAIT_N) begin
							if (!NEXT_BA) begin
								BUSY <= 0;
							end
							STATE_NEXT = T2;
						end
					end
				end
				
				T2: begin
					if (CE_F) begin
						case (AREA_SZ)
							2'b01: 
								case (A[1:0])
									2'b00: DAT_BUF[31:24] <= DI[7:0];
									2'b01: DAT_BUF[23:16] <= DI[7:0];
									2'b10: DAT_BUF[15: 8] <= DI[7:0];
									2'b11: DAT_BUF[ 7: 0] <= DI[7:0];
								endcase
							2'b10:
								case (A[1])
									1'b0: DAT_BUF[31:16] <= DI[15:0];
									1'b1: DAT_BUF[15: 0] <= DI[15:0];
								endcase
							2'b11: DAT_BUF <= DI;
							default:;
						endcase
						WE_N <= 4'b1111;
						RD_N <= 1;
						CACK <= 0;
//						RD_LAST <= ~RD_N;
//						CS_LAST <= A[26:25];
					end
					else if (CE_R) begin
						if (!NEXT_BA) begin
							CS0_N <= 1;
							CS1_N <= 1;
							CS2_N <= 1;
							CS3_N <= 1;
							RD_WR_N <= 1;
						end
//						if (IBUS_A[31:27] ==? 5'b00?00 && IBUS_REQ && (IBUS_A[26:25] != CS_LAST || (RD_LAST && IBUS_WE))) begin	
//							WAIT_CNT <= 3'd0;
//							case (BSC_GetAreaIW(A[26:25],WCR))
//								2'b00: begin
									STATE_NEXT = T0;
//									NO_IDLE = 1;
//								end
//								2'b01: begin
//									WAIT_CNT <= 3'd0;
//									STATE_NEXT = TI;
//								end
//								2'b10: begin
//									WAIT_CNT <= 3'd1;
//									STATE_NEXT = TI;
//								end
//								default:;
//							endcase
//						end
//						else begin
//							STATE_NEXT = T0;
//							NO_IDLE = 1;
//						end
					end
				end
				
				TI: begin
					if (CE_R) begin
						if (WAIT_CNT) begin
							WAIT_CNT <= WAIT_CNT - 3'd1;
						end
						else if (WAIT_N) begin
							STATE_NEXT = T0;
						end
//						NO_IDLE = ~(IBUS_A[31:27] ==? 5'b00?00 && IBUS_REQ && (IBUS_A[26:25] != CS_LAST || (RD_LAST && IBUS_WE)));
					end
				end
				
				default:;
			endcase
			
			if (CE_R) begin
				if (BUS_STATE == T0 || BUS_STATE == T2 /*|| BUS_STATE == TI*/) begin
					if (BUS_ACCESS_REQ && !BUS_RLS && !BUSY) begin
						BUSY <= 1;
					end
					if (BUS_STATE == T2 && BUSY) begin
						case (AREA_SZ)
							2'b01: begin 
								A[1:0] <= A[1:0] + 2'd1; 
								case (A[1:0] + 2'd1)
									2'b01: begin 
										DO <= {24'h000000,IBUS_DI_SAVE[23:16]};
										WE_N <= ~{3'b000,IBUS_WE_SAVE & NEXT_BA[2]};
										NEXT_BA <= {2'b00,NEXT_BA[1:0]};
									end
									2'b10: begin 
										DO <= {24'h000000,IBUS_DI_SAVE[15: 8]}; 
										WE_N <= ~{3'b000,IBUS_WE_SAVE & NEXT_BA[1]};
										NEXT_BA <= {3'b000,NEXT_BA[0]};
									end
									2'b11: begin 
										DO <= {24'h000000,IBUS_DI_SAVE[ 7: 0]};
										WE_N <= ~{3'b000,IBUS_WE_SAVE & NEXT_BA[0]}; 
										NEXT_BA <= 4'b0000;
									end
									default: begin //shouldn't happen
										WE_N <= 4'b1111;
										NEXT_BA <= 4'b0000;
									end
								endcase
							end
							2'b10: begin 
								A[1:0] <= A[1:0] + 2'd2; 
								DO <= {16'h0000,IBUS_DI_SAVE[15: 0]};
								WE_N <= ~({2'b00,IBUS_WE_SAVE,IBUS_WE_SAVE} & {2'b00,NEXT_BA[1:0]}); 
								NEXT_BA <= 4'b0000;
							end
							2'b11: NEXT_BA <= 4'b0000;
							default: ;
						endcase
						BS_N <= 0;
						RD_N <= IBUS_WE_SAVE;
						CACK <= 1;
						STATE_NEXT = T1;
					end
					else if (BUS_ACCESS_REQ && !BUS_RLS && ((!BGR && MASTER) || (BREQ && !MASTER)) /*&& !BUSY*/) begin
						BUSY <= 1;
						
						case (GetAreaSZ(IBUS_A[26:25],BCR2,A0_SZ))
							2'b01: begin 
								case (IBUS_A[1:0])
									2'b00: begin 
										DO <= {24'h000000,IBUS_DI[31:24]}; 
										WE_N <= ~{3'b000,IBUS_WE & IBUS_BA[3]};
										NEXT_BA <= {1'b0,IBUS_BA[2:0]};
									end
									2'b01: begin 
										DO <= {24'h000000,IBUS_DI[23:16]};
										WE_N <= ~{3'b000,IBUS_WE & IBUS_BA[2]};
										NEXT_BA <= {2'b00,IBUS_BA[1:0]};
									end
									2'b10: begin 
										DO <= {24'h000000,IBUS_DI[15: 8]}; 
										WE_N <= ~{3'b000,IBUS_WE & IBUS_BA[1]};
										NEXT_BA <= {3'b000,IBUS_BA[0]};
									end
									2'b11: begin 
										DO <= {24'h000000,IBUS_DI[ 7: 0]};
										WE_N <= ~{3'b000,IBUS_WE & IBUS_BA[0]}; 
										NEXT_BA <= 4'b0000;
									end
								endcase
							end
							2'b10: begin 
								case (IBUS_A[1])
									1'b0: begin 
										DO <= {16'h0000,IBUS_DI[31:16]}; 
										WE_N <= ~{2'b00,{2{IBUS_WE}} & IBUS_BA[3:2]};
										NEXT_BA <= {2'b00,IBUS_BA[1:0]};
									end
									1'b1: begin 
										DO <= {16'h0000,IBUS_DI[15: 0]}; 
										WE_N <= ~{2'b00,{2{IBUS_WE}} & IBUS_BA[1:0]};
										NEXT_BA <= 4'b0000;
									end
								endcase
							end
							2'b11: begin 
								DO <= IBUS_DI; 
								WE_N <= ~({IBUS_WE,IBUS_WE,IBUS_WE,IBUS_WE} & IBUS_BA);
								NEXT_BA <= 4'b0000;
							end
							default:; 
						endcase
						A <= IBUS_A[26:0];
						CS0_N <= ~(IBUS_A[26:25] == 2'b00);
						CS1_N <= ~(IBUS_A[26:25] == 2'b01);
						CS2_N <= ~(IBUS_A[26:25] == 2'b10);
						CS3_N <= ~(IBUS_A[26:25] == 2'b11);
						BS_N <= 0;
						RD_WR_N <= ~IBUS_WE;
						RD_N <= IBUS_WE;
						CACK <= 1;
						
						IBUS_WE_SAVE <= IBUS_WE;
						IBUS_DI_SAVE <= IBUS_DI; 
						
						if (BUS_STATE == T0 || (BUS_STATE == T2 /*&& NO_IDLE*/) /*|| (BUS_STATE == TI && !WAIT_CNT)*/) begin
							STATE_NEXT = T1;
						end
					end
				end
			end
			BUS_STATE <= STATE_NEXT;
		end
	end
		
	bit MST_BUS_RLS;
	bit SLV_BUS_RLS;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			BREQ <= 0;
			BGR <= 0;
			MST_BUS_RLS <= 0;
			SLV_BUS_RLS <= 1;
		end
		else begin
			if (!RES_N) begin
				BREQ <= 0;
				BGR <= 0;
				MST_BUS_RLS <= 0;
				SLV_BUS_RLS <= 1;
			end
			else if (MASTER) begin
				if (BRLS && !BGR  && (BUS_STATE == T2 || BUS_STATE == T0) && !BUSY && !IBUS_LOCK && !MST_BUS_RLS && CE_F) begin
					BGR <= 1;
				end
				else if (BRLS && BGR && !MST_BUS_RLS && CE_F) begin
					MST_BUS_RLS <= 1;
				end
				else if (!BRLS && MST_BUS_RLS && CE_F) begin
					BGR <= 0;
					MST_BUS_RLS <= 0;
				end
			end
			else begin
				if (BUS_ACCESS_REQ && !BREQ && SLV_BUS_RLS && CE_F) begin
					BREQ <= 1;
				end
				else if (BREQ && BACK && SLV_BUS_RLS && CE_F) begin
					SLV_BUS_RLS <= 0;
				end
				else if (BREQ && BUS_STATE == T2 && !BUSY && !IBUS_LOCK && !SLV_BUS_RLS && CE_F) begin
					BREQ <= 0;
				end
				else if (!BREQ && !SLV_BUS_RLS && CE_F) begin
					SLV_BUS_RLS <= 1;
				end
			end
		end
	end
	
	assign BGR_N = MASTER ? ~BGR : ~BREQ;
	assign BUS_RLS = MASTER ? MST_BUS_RLS : SLV_BUS_RLS;
	
		
	//Registers
	wire REG_SEL = (IBUS_A >= 32'hFFFFFFE0);
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			BCR1  <= BCR1_INIT;
			BCR2  <= BCR2_INIT;
			WCR   <= WCR_INIT;
			MCR   <= MCR_INIT;
			RTCSR <= RTCSR_INIT;
			RTCNT <= RTCNT_INIT;
			RTCOR <= RTCOR_INIT;
			// synopsys translate_off
			WCR <= 16'hA00;
			// synopsys translate_on
		end
		else if (CE_R) begin
			if (REG_SEL && IBUS_DI[31:16] == 16'hA55A && IBUS_WE && IBUS_REQ) begin
				case ({IBUS_A[4:2],2'b00})
					5'h00: BCR1  <= IBUS_DI[15:0] & BCR1_WMASK;
					5'h04: BCR2  <= IBUS_DI[15:0] & BCR2_WMASK;
					5'h08: WCR   <= IBUS_DI[15:0] & WCR_WMASK;
					5'h0C: MCR   <= IBUS_DI[15:0] & MCR_WMASK;
					5'h10: RTCSR <= IBUS_DI[15:0] & RTCSR_WMASK;
					5'h14: RTCNT <= IBUS_DI[7:0]  & RTCNT_WMASK;
					5'h18: RTCOR <= IBUS_DI[7:0]  & RTCOR_WMASK;
					default:;
				endcase
			end
		end
	end
	
	bit [31:0] REG_DO;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			REG_DO <= '0;
		end
		else if (CE_F) begin
			if (REG_SEL && !IBUS_WE && IBUS_REQ) begin
				case ({IBUS_A[4:1],1'b0})
					5'h02: REG_DO <= {MD[5],BCR1[14:0]} & BCR1_RMASK;
					5'h06: REG_DO <= BCR2 & BCR2_RMASK;
					5'h0A: REG_DO <= WCR & WCR_RMASK;
					5'h0E: REG_DO <= MCR & MCR_RMASK;
					5'h12: REG_DO <= RTCSR & RTCSR_RMASK;
					5'h16: REG_DO <= {8'h00,RTCNT} & RTCNT_RMASK;
					5'h1A: REG_DO <= {8'h00,RTCOR} & RTCOR_RMASK;
					default:REG_DO <= '0;
				endcase
			end
		end
	end
	
	assign IBUS_DO = REG_SEL ? REG_DO : DAT_BUF;
	assign IBUS_BUSY = BUSY | ((BUS_RLS | BGR) & BUS_ACCESS_REQ);
	assign IBUS_ACT = REG_SEL;
	
	assign OE_N = 1;
	assign CE_N = 1;
	assign IRQ = 0;
	assign IVECF_N = 1;
	

endmodule
