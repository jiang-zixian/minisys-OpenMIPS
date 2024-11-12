`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/10 14:57:39
// Design Name: 
// Module Name: inst_rom
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
// 指令存储器 ROM 模块
//////////////////////////////////////////////////////////////////////////////////
`include "Define.v"

module inst_rom(

//	input	wire										clk,
	input wire                    ce,//使能信号
	input wire[`InstAddrBus]	   addr,//要读取的指令地址
	output reg[`InstBus]		   inst//读出的指令
	
);

// 定义一个数组，大小是 InstMemNum，元素宽度是 InstBus
	reg[`InstBus]  inst_mem[0:`InstMemNum-1];

// 使用文件 inst_rom.data 初始化指令存储器
	initial $readmemh ( "inst_rom.txt", inst_mem );

//当复位信号无效时，依据输入的地址，给出指令存储器 ROM 中对应的元素
	always @ (*) begin
		if (ce == `ChipDisable) begin
			inst <= `ZeroWord;
	  end else begin
		  inst <= inst_mem[addr[`InstMemNumLog2+1:2]];
		  //OpenMIPS 是按照字节寻址的，而此处定义的指令存储器的每个地址是一个 32bit 的字，所以要将 OpenMIPS 给出的指令地址除以 4 再使用
		  //除以 4 也就是将指令地址右移 2 位，所以在读取的时候给出的地址是 addr[`InstMemNumLog2+1:2]
		end
	end

endmodule
