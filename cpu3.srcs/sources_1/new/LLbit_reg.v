//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/26 13:17:32
// Design Name: 
// Module Name: LLbit__reg
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
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module LLbit_reg(

	input	wire										clk,
	input wire										rst,
	
	// 异常是否发生，为 1 表示异常发生，为 0 表示没有异常
	input wire                    flush,
	//写端口
	input wire										LLbit_i,
	input wire                    we,
	
	//读端口1 LLbit 寄存器的值
	output reg                    LLbit_o
	
);


	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
					LLbit_o <= 1'b0;
		end else if((flush == 1'b1)) begin
					LLbit_o <= 1'b0;//如果异常发生，那么设置 LLbit_o 为 0
		end else if((we == `WriteEnable)) begin
					LLbit_o <= LLbit_i;
		end
	end

endmodule