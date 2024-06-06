module test_mips32; 

 reg clk1, clk2; 
 integer k; 
 
 pipe_MIPS32 uut (clk1, clk2); 
 
 initial 
 begin 
     clk1 = 0; clk2 = 0; 
     repeat (100) // Generating two-phase clock 
     begin 
     #5 clk1 = 1; #5 clk1 = 0; 
     #5 clk2 = 1; #5 clk2 = 0; 
     end 
 end
 initial 
 begin 
     for (k=0; k<31; k=k+1) 
     uut.Reg[k] = 0; 
     
     // Arithmetic , Load and store operations...
     uut.Mem[0] = 32'h2801000a; 
     uut.Mem[1] = 32'h0ce77800;
     uut.Mem[1] = 32'h0ce77800;
     uut.Mem[2] = 32'h28020014;
     uut.Mem[3] = 32'h0ce77800;
     uut.Mem[4] = 32'h04411800;
     uut.Mem[5] = 32'h0ce77800;
     uut.Mem[6] = 32'h20220000;
     uut.Mem[7] = 32'h0ce77800;
     uut.Mem[8] = 32'h24810000;
    
    
     uut.PC = 0; 
     uut.HALTED = 0; 
     uut.TAKEN_BRANCH = 0; 

 end 
 endmodule
