`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/10 16:14:02
// Design Name: 
// Module Name: openmips_min_sopc_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// testBench
//////////////////////////////////////////////////////////////////////////////////
`include "Define.v"

module openmips_min_sopc_tb();

  reg     CLOCK_50;
  reg     rst;
  wire        rom_ce;
  wire[`InstBus] inst;
  // �����߼�����Ľ��
  wire[`RegBus] logicout;

  
       
  initial begin
    CLOCK_50 = 1'b0;
    forever #10 CLOCK_50 = ~CLOCK_50;
  end
      
  initial begin
   // rst= `RstDisable;
    rst = `RstEnable;
    #50 rst= `RstDisable;
    #1000 $stop;
  end
       
  openmips_min_sopc openmips_min_sopc0(
		.clk(CLOCK_50),
		.rst(rst)	,
		.rom_ce(rom_ce),
		.inst(inst),
		.logicout(logicout)
	);

endmodule
