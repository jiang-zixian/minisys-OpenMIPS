`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/26 13:17:32
// Design Name: 
// Module Name: hilo_reg
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
// 移动指令会涉及到HL和LO寄存器
//////////////////////////////////////////////////////////////////////////////////
`include "Define.v"

module hilo_reg(

	input	wire										clk,
	input wire										rst,
	
	//写端口
	input wire							we,//HI、 LO 寄存器写使能信号
	input wire[`RegBus]				    hi_i,
	input wire[`RegBus]					lo_i,
	
	//读端口1
	output reg[`RegBus]           hi_o,
	output reg[`RegBus]           lo_o
	
);

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
					hi_o <= `ZeroWord;
					lo_o <= `ZeroWord;
		end else if((we == `WriteEnable)) begin//如果是 WriteEnable，那么就将输入的 hi_i、 lo_i 的值作为 HI、 LO 寄存器的新值，并通过 hi_o、 lo_o 接口输出
					hi_o <= hi_i;
					lo_o <= lo_i;
		end
	end

endmodule
