`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/10 15:42:24
// Design Name: 
// Module Name: openmips_min_sopc
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
// 
//////////////////////////////////////////////////////////////////////////////////
`include "Define.v"

module openmips_min_sopc(

	input wire				clk,
	input wire				rst,
	output wire       rom_ce,
	output wire[`InstBus] inst,
	
	// 保存逻辑运算的结果
    output    wire[`RegBus] logicout

	
);

  //连接指令存储器
  wire[`InstAddrBus] inst_addr;
  //wire[`InstBus] inst;
  //wire rom_ce;
 

//openmips的实例化
 openmips openmips0(
		.clk(clk),
		.rst(rst),
	
		.rom_addr_o(inst_addr),
		.rom_data_i(inst),
		.rom_ce_o(rom_ce),
		.logicout(logicout)
	
	);
	
	//实例化指令存储器
	inst_rom inst_rom0(
		.addr(inst_addr),
		.inst(inst),
		.ce(rom_ce)	
	);


endmodule
