module mips32_test;

reg clk1,clk2;
integer k;

MIPS32 mips(clk1,clk2);

initial
	begin
	clk1=0;
	clk2=0;
	
	repeat(20)
		begin 
		#5 clk1=1; #5 clk1 =0;
		#5 clk2=0; #5 clk2 =0;
	end
	
initial 
	begin
		for(k=0;k<31;k++)
			mips.regs[k];
	mips.Mem[0] = 32'h1020000A;
	mips.Mem[1] = 32'h10400014;
	mips.Mem[2] = 32'h10600019;
	mips.Mem[3] = 32'h18842000;
	mips.Mem[4] = 32'h18842000;
	mips.Mem[5] = 32'h00811000;
	mips.Mem[6] = 32'h18842000;
	mips.Mem[7] = 32'h00A41800;
	mips.Mem[8] = 32'h08000000;

	mips.halted=0;
	mips.PC =0;
	mips.taken_branch = 0;
	
	#300
	for(k=0;k<6;k++)
		$display("R%1d - %2d",k,mips.regs[k]);
	end
	
	

endmodule
