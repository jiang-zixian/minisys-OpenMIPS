`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/08 20:44:51
// Design Name: 
// Module Name: mem_wb
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
// MEM/WB模块：将访存阶段的运算结果，在下一个时钟传递到回写阶段
//////////////////////////////////////////////////////////////////////////////////
`include "Define.v"

module mem_wb(
	input wire					clk,
	input wire					rst,

	//来自访存阶段的信息	
	input wire[`RegAddrBus]       mem_wd,//访存阶段的指令最终要写入的目的寄存器地址
	input wire                    mem_wreg,//访存阶段的指令最终是否有要写入的目的寄存器
	input wire[`RegBus]			   mem_wdata,//访存阶段的指令要写入的目的寄存器地址

	//送到回写阶段的信息
	output reg[`RegAddrBus]      wb_wd,//回写阶段的指令要写入的目的寄存器地址
	output reg                   wb_wreg,//回写阶段的指令是否有要写入的目的寄存器
	output reg[`RegBus]			  wb_wdata//回写阶段的指令要写入目的寄存器的值
	
);

// 回写阶段其实就实现在regfile模块
	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
			wb_wd <= `NOPRegAddr;
			wb_wreg <= `WriteDisable;
		  wb_wdata <= `ZeroWord;	
		end else begin
			wb_wd <= mem_wd;
			wb_wreg <= mem_wreg;
			wb_wdata <= mem_wdata;
		end    //if
	end      //always
			
endmodule
