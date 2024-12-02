`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/07 10:42:54
// Design Name: 
// Module Name: pc_reg
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
// 取指阶段取出指令存储器中的指令，同时，PC 值递增，准备取下一条指令，包括 PC、IF/ID 两个模块。
// 此为PC模块
//////////////////////////////////////////////////////////////////////////////////

`include "Define.v"

module pc_reg(

	input wire			clk,//时钟信号
	input wire			rst,//复位信号
	
	//来自控制模块的信息
    input wire[5:0]               stall,	
	
	output reg[`InstAddrBus]	pc,//InstAddrBus 宏表示指令地址线的宽度
	output reg                  ce//指令寄存器的使能信号
	
);
//TODO 光盘源码中下面两个always的顺序反过来，我这里按照书上的代码写的
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin//复位的时候指令存储器禁用
			ce <= `ChipDisable;
		end else begin
			ce <= `ChipEnable;
		end
	end
	
	always @ (posedge clk) begin
		if (ce == `ChipDisable) begin
			pc <= 32'h00000000;
		end else if(stall[0] == `NoStop) begin
	 		pc <= pc + 4'h4;//指令存储器使能的时候，PC 的值每时钟周期加 4。
	 		//表示下一条指令的地址，因为一条指令是 32 位，而设计的minisys-cpu是可以按照字节寻址的，一条指令对应 4 个字节，所以 PC 加 4 指向下一条指令地址
		end
	end
	

endmodule

