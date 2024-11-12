`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/08 20:25:31
// Design Name: 
// Module Name: ex_mem
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
// EX/MEM阶段：将执行阶段取得的运算结果，在下一个时钟传递到流水线访存阶段
//////////////////////////////////////////////////////////////////////////////////
`include "Define.v"

module ex_mem(
	input wire					clk,
	input wire					rst,
	
	
	//来自执行阶段的信息	
	input wire[`RegAddrBus]       ex_wd,//执行阶段的指令执行后要写入的寄存器地址
	input wire                    ex_wreg,//执行阶段的指令执行后是否有要写入的目的寄存器
	input wire[`RegBus]		       ex_wdata,//执行阶段的指令执行后要写入目的寄存器的值（运算结果）
	
	//送到访存阶段的信息
	output reg[`RegAddrBus]      mem_wd,
	output reg                   mem_wreg,
	output reg[`RegBus]			  mem_wdata
);


	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `WriteDisable;
		  mem_wdata <= `ZeroWord;	
		end else begin//直接赋值传递即可
			mem_wd <= ex_wd;
			mem_wreg <= ex_wreg;
			mem_wdata <= ex_wdata;			
		end    //if
	end      //always
			

endmodule
