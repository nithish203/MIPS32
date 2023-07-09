module mips(clk1,clk2);

input clk1,clk2;

reg [31:0] PC, IF_ID_IR, IF_ID_NPC;
reg [31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm;
reg [2:0]  ID_EX_type,EX_MEM_type,MEM_WB_type;
reg [31:0] EX_MEM_A, EX_MEM_B, EX_MEM_ALUOUT, EX_MEM_IR;
reg 		  EX_MEM_cond;
reg [31:0] MEM_WB_IR, MEM_WB_ALUOUT, MEM_WB_LMD;

reg halted, taken_branch;

reg [31:0] regs[0:31];
reg [31:0] Mem[0:1023];


parameter ADD = 6'b000000, SUB = 6'b000001, MUL = 6'b000010, DIV = 6'b000011,
			 ADDI = 6'b000100, SUBI = 6'b000101, AND = 6'b000110, ANDI = 6'b000111,
			 HLT = 6'b001000, NOR = 6'b001001, NOT = 6'b001010, OR = 6'b001011,
			 ORI = 6'b001100, XOR = 6'b001101, BEQZ = 6'b001110, XORI = 6'b001111,
			 MOVN = 6'b010000, MOVE = 6'b010010, NEGU = 6'b010011,
			 LW = 6'b010100, SW = 6'b010101, BNEQZ = 6'b010110;
			 
parameter RR_ALU=3'b000, RM_ALU = 3'b001, LOAD = 3'b010, STORE = 3'b011, BRANCH = 3'b100, HALT = 3'b101;


//IF stage

always @(posedge clk1)
begin
	if (halted == 0)
		begin
			if((EX_MEM_cond == 1 && EX_MEM_IR[31:26] == BEQZ)||(EX_MEM_cond == 0 && EX_MEM_IR[31:26] == BNEQZ)) //The signals are from the Execute stage if the branch is
					begin																										    		  //taken then the PC, IR value should be changed accordingly
					IF_ID_IR <= Mem[EX_MEM_ALUOUT];	
					taken_branch <= 1'b1;
					IF_ID_NPC <= EX_MEM_ALUOUT+1;
					PC <= EX_MEM_ALUOUT+1;
					end
			else
					begin
					IF_ID_IR <= Mem[PC];
					IF_ID_NPC <= PC+1;
					PC <= PC+1;
					end
		end
		
end

//ID Stage

always @(posedge clk2)
begin
	if(halted ==0)
		begin
		if(IF_ID_IR[25:21] == 5'b00000)
			ID_EX_A<=0;
		else
			ID_EX_A<= regs[IF_ID_IR[25:21]];
			
		if(IF_ID_IR[20:16] == 5'b00000)
			ID_EX_B<=0;
		else
			ID_EX_B<= regs[IF_ID_IR[20:16]];
			
		ID_EX_NPC <= IF_ID_NPC;
		ID_EX_IR <= IF_ID_IR;
		ID_EX_Imm <= {{16{IF_ID_IR[15]}},{IF_ID_IR[15:0]}};
		
		case(IF_ID_IR[31:26])
			ADD,SUB,AND,OR,NOT,XOR,NEGU,MUL,DIV,MOVE,MOVN:      ID_EX_type <= RR_ALU;
			ADDI,SUBI,ANDI,ORI,XORI: 									 ID_EX_type <= RM_ALU;
			LW:																 ID_EX_type <= LOAD;
			SW:																 ID_EX_type <= STORE;
			BNEQZ,BEQZ:														 ID_EX_type <= BRANCH;
			HLT:																 ID_EX_type <= HALT;
			default:															 ID_EX_type <= HALT;
		endcase
			
		end
end

//EX Stage

always @(posedge clk1)
	if(halted==0)
	begin
		EX_MEM_type<= ID_EX_type;
		EX_MEM_IR <= ID_EX_IR;
		taken_branch <= 0;
		
		case(ID_EX_type)
			RR_ALU: begin
						case(IF_ID_IR[31:26])
							ADD: EX_MEM_ALUOUT <= ID_EX_A + ID_EX_B;
							SUB: EX_MEM_ALUOUT <= ID_EX_A - ID_EX_B;
							AND: EX_MEM_ALUOUT <= ID_EX_A & ID_EX_B;
							OR : EX_MEM_ALUOUT <= ID_EX_A | ID_EX_B;
							NOT: EX_MEM_ALUOUT <= ~(ID_EX_A);
							XOR: EX_MEM_ALUOUT <= ID_EX_A ^ ID_EX_B;
							NEGU: EX_MEM_ALUOUT <= -(ID_EX_A);
							MUL: EX_MEM_ALUOUT <= ID_EX_A * ID_EX_B;
							DIV: EX_MEM_ALUOUT <= ID_EX_A / ID_EX_B;
							MOVE: EX_MEM_ALUOUT <= ID_EX_A;
							MOVN: EX_MEM_ALUOUT <= -(ID_EX_A);
						endcase
					  end
					  
			RM_ALU: begin
						case(IF_ID_IR[31:26])
							ADDI: EX_MEM_ALUOUT <= ID_EX_A + ID_EX_Imm;
							SUBI: EX_MEM_ALUOUT <= ID_EX_A - ID_EX_Imm;
							ANDI: EX_MEM_ALUOUT <= ID_EX_A & ID_EX_Imm;
							ORI : EX_MEM_ALUOUT <= ID_EX_A | ID_EX_Imm;
							XORI: EX_MEM_ALUOUT <= ID_EX_A ^ ID_EX_Imm;
						endcase
					  end
					  
			LOAD,STORE: begin
						EX_MEM_ALUOUT <= ID_EX_A & ID_EX_Imm;
						EX_MEM_B <= ID_EX_B;
					 end
					 
			BRANCH: begin
						EX_MEM_ALUOUT <= ID_EX_NPC & ID_EX_Imm;
						EX_MEM_cond <= (ID_EX_A == 0);
					  end
				
		endcase			
	end
	
//MEM stage

always @(posedge clk2)
	if(halted == 0)
	begin
	MEM_WB_type <= EX_MEM_type;
	MEM_WB_IR <= EX_MEM_IR;
	
	case(EX_MEM_type)
		RR_ALU, RM_ALU :  MEM_WB_ALUOUT <= EX_MEM_ALUOUT;
		LOAD: 				MEM_WB_LMD <= Mem[EX_MEM_ALUOUT];
		STORE: 				if(taken_branch == 0) Mem[EX_MEM_ALUOUT] <= EX_MEM_B;
	endcase
	end

//WB stage

always @(posedge clk1)
	begin
		if(taken_branch==0)
			case(MEM_WB_type)
				RR_ALU: regs[MEM_WB_IR[15:11]] <= MEM_WB_ALUOUT;
				RM_ALU: regs[MEM_WB_IR[20:16]] <= MEM_WB_ALUOUT;
				LOAD:	  regs[MEM_WB_IR[20:16]] <= MEM_WB_LMD;
				HALT:   halted <= 1'b1;
			endcase
	end

endmodule
