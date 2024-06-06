module pipe_MIPS32(clk1 , clk2);

    input clk1,clk2;

    reg [31:0] PC, IF_ID_IR, IF_ID_NPC; 
    reg [31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm,ID_EX_Imm1; 
    reg [31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B,EX_WB_NPC; 
    reg EX_MEM_cond;
    reg [31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD; 

    reg [2:0] ID_EX_type, EX_MEM_type, MEM_WB_type; //for recognizing type of microinstructions in each stage
     
    reg [31:0] Reg [0:31]; 
    reg [31:0] Mem [0:1023]; 

    parameter ADD=6'b000000, SUB=6'b000001, AND=6'b000010, OR=6'b000011, SLT=6'b000100,
    MUL=6'b000101,XOR = 6'b000110, HLT=6'b111111, LW=6'b001000, SW=6'b001001,  ADDI=6'b001010, SUBI=6'b001011,SLTI=6'b001100, 
    BNEQZ=6'b001101, BEQZ=6'b001110, BEQ = 6'b001111,BNQ = 6'b010000,JL = 6'b111101 ,JR = 6'b111100;

    parameter RR_ALU=3'b000, RM_ALU=3'b001, LOAD=3'b010, STORE=3'b011, 
    BRANCH=3'b100, HALT=3'b101,JMP = 3'b110,JRR = 3'b111;

    reg HALTED;
    reg TAKEN_BRANCH;

     //IF Stage
 
    always@(posedge clk1)
    begin
        if(HALTED==0)
        begin 
    
            if(((EX_MEM_IR[31:26]) == BNEQZ && (EX_MEM_cond))
            ||((EX_MEM_IR[31:26]) == BEQZ && (EX_MEM_cond)) || ((EX_MEM_IR[31:26]) == BEQ && (EX_MEM_cond))
             || ((EX_MEM_IR[31:26]) == BNQ && (EX_MEM_cond)) || EX_MEM_IR[31:26] == JL)
            begin
    
                IF_ID_IR <=  Mem[EX_MEM_ALUOut];
                TAKEN_BRANCH <=  1'b1;
                IF_ID_NPC <=  EX_MEM_ALUOut+1;
                PC <=  EX_MEM_ALUOut +1;
    
            end
            
            else if(EX_MEM_IR[31:26] == JR)
            begin
                IF_ID_IR <=  Mem[Reg[31]];
                TAKEN_BRANCH = 1'b0;
                IF_ID_NPC <=  Mem[Reg[31]];
                PC <=  Mem[Reg[31]];
            end

            else
            begin 
                IF_ID_IR <=  Mem[PC];
                IF_ID_NPC <= PC+1;
                PC <=  PC +1;
            end
        end
    end

    
//ID Stage

    always@(posedge clk2) 
    begin
        if(HALTED ==0)
        begin 
            if(IF_ID_IR[25:21] == 5'b00000) ID_EX_A <= 0;
            else ID_EX_A <=  Reg[IF_ID_IR[25:21]];
            
            if(IF_ID_IR[20:16] == 5'b00000) ID_EX_B <= 0;
            else ID_EX_B <=  Reg[IF_ID_IR[20:16]];
            
            ID_EX_NPC <=  IF_ID_NPC; 
            ID_EX_IR <=  IF_ID_IR; 
            ID_EX_Imm <=  {{16{IF_ID_IR[15]}}, {IF_ID_IR[15:0]}};
            ID_EX_Imm1 <=  { {4'b0000},{IF_ID_IR[25:0]},{2'b00}};
            
            case (IF_ID_IR[31:26]) 
            
                ADD,SUB,AND,OR,SLT,MUL: ID_EX_type <= RR_ALU; 
                ADDI,SUBI,SLTI: ID_EX_type <=  RM_ALU; 
                LW: ID_EX_type <=  LOAD; 
                SW: ID_EX_type <=  STORE; 
                BNEQZ,BEQZ: ID_EX_type <=  BRANCH; 
                HLT: ID_EX_type <= HALT; 
                JL:ID_EX_type <= JMP; 
                JR :ID_EX_type <= JRR;
                default: ID_EX_type <=  HALT; 
            
            endcase
            
        end
    end

    //Exe Stage
    always@(posedge clk1)
    begin 
        if(HALTED==0)
        begin 
            EX_MEM_type <=  ID_EX_type; 
            EX_MEM_IR <=  ID_EX_IR; 
            TAKEN_BRANCH <=  0; 
            
            case (ID_EX_type) 
                RR_ALU: begin 
                    case (ID_EX_IR[31:26])  
                        ADD: EX_MEM_ALUOut <=  ID_EX_A + ID_EX_B; 
                        SUB: EX_MEM_ALUOut <=  ID_EX_A - ID_EX_B; 
                        AND: EX_MEM_ALUOut <=  ID_EX_A & ID_EX_B; 
                        OR: EX_MEM_ALUOut <=  ID_EX_A | ID_EX_B; 
                        XOR:  EX_MEM_ALUOut <=  ID_EX_A ^ ID_EX_B; 
                        SLT: EX_MEM_ALUOut <=  ID_EX_A < ID_EX_B; 
                        MUL: EX_MEM_ALUOut <=  ID_EX_A * ID_EX_B; 
                        default: EX_MEM_ALUOut <=  32'hxxxxxxxx; 
                    endcase
                end
                
                RM_ALU: begin 
                    case (ID_EX_IR[31:26])
                        ADDI: EX_MEM_ALUOut <=  ID_EX_A + ID_EX_Imm; 
                        SUBI: EX_MEM_ALUOut <=  ID_EX_A - ID_EX_Imm; 
                        SLTI: EX_MEM_ALUOut <=  ID_EX_A < ID_EX_Imm; 
                        default: EX_MEM_ALUOut <=  32'hxxxxxxxx; 
                    endcase
                end
                
                LOAD, STORE: 
                begin 
                    EX_MEM_ALUOut <=  ID_EX_A + ID_EX_Imm; 
                    EX_MEM_B <=  ID_EX_B; 
                end
                
                BRANCH: begin 
                    EX_MEM_ALUOut <=  ID_EX_NPC + ID_EX_Imm; 
                    case(ID_EX_IR[31:26])
                       BEQZ: EX_MEM_cond <=  (ID_EX_A == 0); 
                       BNEQZ:EX_MEM_cond <= (ID_EX_A!=0);
                       BEQ : EX_MEM_cond <= (ID_EX_A==ID_EX_B);
                       BNQ:EX_MEM_cond <=(ID_EX_A!=ID_EX_B);
                    endcase
                    end
                JMP:begin
                    EX_MEM_ALUOut <= {{PC[31:28]},{ID_EX_Imm1[27:0]}}; 

                end
                JR : begin 
                    EX_WB_NPC <= ID_EX_NPC;
                end

            endcase
        end
    end

    
    // MEM Stage 
    always @(posedge clk2) 
    begin
        if (HALTED == 0) 
        begin 
            MEM_WB_type <= EX_MEM_type; 
            MEM_WB_IR <=  EX_MEM_IR; 
            
            case (EX_MEM_type) 
                RR_ALU, RM_ALU: MEM_WB_ALUOut <=  EX_MEM_ALUOut; 
                LOAD: MEM_WB_LMD <=  Mem[EX_MEM_ALUOut]; 
                STORE:
                    if (TAKEN_BRANCH == 0) 
                    Mem[EX_MEM_ALUOut] <=  EX_MEM_B; 
                JRR:
                    MEM_WB_ALUOut<= EX_WB_NPC;
            endcase
        end
    end

    // WB Stage
 
    always @(posedge clk1)
    begin 
        if (TAKEN_BRANCH == 0) 
            case (MEM_WB_type) 
                RR_ALU: Reg[MEM_WB_IR[15:11]] <=  MEM_WB_ALUOut; 
                RM_ALU: Reg[MEM_WB_IR[20:16]] <=  MEM_WB_ALUOut; 
                LOAD: Reg[MEM_WB_IR[20:16]] <=  MEM_WB_LMD; 
                HALT: HALTED <=  1'b1; 
                JRR:Reg[31] <= MEM_WB_ALUOut;
            endcase
    end 
endmodule