module SH7034_tb;

	import SH7034_PKG::*;
	
	bit        CLK;
	bit        RST_N;
	bit        CE_R, CE_F;
	
	bit        RES;
	bit [26:0] CPU_A;
	bit [31:0] CPU_DO;
	bit [31:0] CPU_DI;
	bit  [3:0] CPU_WE_N;
	bit        CPU_REQ, CPU_WAIT;
	bit        CPU_DREQ0;
	
	bit [31:0] RAM_DO, RAM_DI;
	bit RAM_WE;
	
	bit [15:0] COMM[8];
	 
	//clock generation
	always #5 CLK = ~CLK;
	 
	//reset generation
	initial begin
	  RST_N = 0;
	  #12 RST_N = 1;
	end
	
	initial begin
	  RES = 0;
	  CPU_DREQ0 = 1;
	  
	  #100 RES = 1;
	  #20 RES = 0;
	  
//	  #1000 CPU_DREQ0 = 0;
//	  #600 CPU_DREQ0 = 1;
//	  
//	  #400 CPU_DREQ0 = 0;
//	  #100 CPU_DREQ0 = 1;
	end
	
	bit [3:0] IRL_N;
	initial begin
	IRL_N = 4'hF;
//	#1200 
//	IRL_N = 4'hE;
//	#400 
//	IRL_N = 4'hF;
	end
	
	always @(posedge CLK) begin
		CE_R <= ~CE_R;
	end
	assign CE_F = ~CE_R;
	
	wire [1:0] CS0_SZ = 2'b01;
	
	SH7034 cpu
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.RES_N(~RES),
		.NMI_N(1'b1),
		
		.IRL_N(IRL_N),
		
		.A(CPU_A),
		.DI(CPU_DI),
		.DO(CPU_DO),
		.BS_N(),
		.CS0_N(),
		.CS1_N(),
		.CS2_N(),
		.CS3_N(),
		.RD_WR_N(),
		.CE_N(),
		.OE_N(),
		.WE_N(CPU_WE_N),
		.RD_N(),
		.WAIT_N(1'b1),
		.BRLS_N(1'b1),
		.BGR_N(),
		.IVECF_N(),
		
		.DREQ0(CPU_DREQ0),
		.DACK0(),
		.DREQ1(1'b1),
		.DACK1(),
		
		.MD({1'b0,CS0_SZ,3'b000})
		
	);
	
	wire ROM_SEL = CPU_A[26:14] == 13'b0000000000000;//00000000-00003FFF
	
	RAM_tb #(.bios_file("test/bios.txt"), .rom_file("test/rom.txt")) ram(CLK, RST_N, CS0_SZ, CPU_A, CPU_DO, ~CPU_WE_N, CPU_A, RAM_DO);
	
	wire REG_SEL = CPU_A[26:14] == 13'b0000000000001;//00004000-00004100
	always_comb begin
//		if (ROM_SEL)
//			CPU_DI <= RAM_DO;
//		else if (REG_SEL)
//			case ({CPU_A[5:1],1'b0})
//				6'h00: CPU_DI = {2{16'h0200}};
//				6'h02: CPU_DI = {2{16'h0000}};
//				
//				6'h20: CPU_DI = {16'h0000,COMM[0]};
//				6'h22: CPU_DI = {16'h0000,COMM[1]};
//				6'h24: CPU_DI = {16'h0000,COMM[2]};
//				6'h26: CPU_DI = {16'h0000,COMM[3]};
//				6'h28: CPU_DI = {16'h0000,COMM[4]};
//				6'h2A: CPU_DI = {16'h0000,COMM[5]};
//				6'h2C: CPU_DI = {16'h0000,COMM[6]};
//				6'h2E: CPU_DI = {16'h0000,COMM[7]};
//				default: CPU_DI = {2{16'h0000}};
//			endcase
//		else
			CPU_DI <= RAM_DO;
	end
	
	initial begin
	  COMM = '{8{'0}};

		#2730000
		COMM[0] = 16'h534D;
	end
	
//	bit BUS_ACTIVE;
//	always @(negedge CLK or negedge RST_N) begin
//		if (!RST_N) begin
//			BUS_ACTIVE <= 0;	
//		end
//		else begin
//			bit [1:0] MA_WAIT_CNT;
//			
//			if (BUS_REQ && !BUS_ACTIVE) begin
//				BUS_ACTIVE <= 1;
//				MA_WAIT_CNT <= 2;
//			end else if (BUS_ACTIVE) begin
//				if (!MA_WAIT_CNT) begin
//					BUS_ACTIVE <= 0;
//				end else begin
//					MA_WAIT_CNT <= MA_WAIT_CNT - 1;
//				end
//			end
//		end
//	end
//	
//	assign BUS_WAIT = BUS_ACTIVE;
////	assign BUS_WAIT = 0;
//	
//	assign RAM_DI = '0;
//	assign RAM_WE = '0;
//	RAM ram(CLK, RST_N, BUS_A[10:0], BUS_DO, BUS_WE, BUS_A[10:0], RAM_DO);
//	
//	assign BUS_DI = BUS_REQ ? CACHE_DO : 
//									  MAC_SEL[0] ? MACL :
//														MAC_SEL[1] ? MACH : '0;
	
	
//	always @(posedge CLK or negedge RST_N) begin
//		bit RES_OLD;
//		
//		if (!RST_N) begin
//			INTI <= INT_REQ_RESET;
//			RES_OLD <= 0;
//		end
//		else begin	
//			RES_OLD <= RES;
//			if (RES && !RES_OLD) begin
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
