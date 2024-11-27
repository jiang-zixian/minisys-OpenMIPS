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
    output    wire[`RegBus] logicout,
    
    // 输出寄存器 1、2、3、4 的值
    output wire[`RegBus] out_r1,
    output wire[`RegBus] out_r2,
    output wire[`RegBus] out_r3,
    output wire[`RegBus] out_r4,
    output wire[`RegBus] out_hi,
    output wire[`RegBus] out_lo,
    
    output    wire[`RegBus]           reg1_i_out      

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
		
		.logicout(logicout),  
        .out_r1(out_r1),
        .out_r2(out_r2),
        .out_r3(out_r3),
        .out_r4(out_r4),
        .hi(out_hi),
        .lo(out_lo),
        .reg1_i_out(reg1_i_out)
	);
	
	//实例化指令存储器
	inst_rom inst_rom0(
		.addr(inst_addr),
		.inst(inst),
		.ce(rom_ce)	
	);


endmodule
