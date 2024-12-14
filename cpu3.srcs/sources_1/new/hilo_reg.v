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

`include "defines.v"

module hilo_reg(

	input	wire										clk,
	input wire										rst,
	
	//写端口
	input wire										we,
	input wire[`RegBus]				    hi_i,
	input wire[`RegBus]						lo_i,
	
	//读端口1
	output reg[`RegBus]           hi_o,
	output reg[`RegBus]           lo_o
	
);

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
					hi_o <= `ZeroWord;
					lo_o <= `ZeroWord;
		end else if((we == `WriteEnable)) begin
					hi_o <= hi_i;
					lo_o <= lo_i;
		end
	end

endmodule