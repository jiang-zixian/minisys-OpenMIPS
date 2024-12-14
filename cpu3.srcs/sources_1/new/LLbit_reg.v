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
	
	// �쳣�Ƿ�����Ϊ 1 ��ʾ�쳣������Ϊ 0 ��ʾû���쳣
	input wire                    flush,
	//д�˿�
	input wire										LLbit_i,
	input wire                    we,
	
	//���˿�1 LLbit �Ĵ�����ֵ
	output reg                    LLbit_o
	
);


	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
					LLbit_o <= 1'b0;
		end else if((flush == 1'b1)) begin
					LLbit_o <= 1'b0;//����쳣��������ô���� LLbit_o Ϊ 0
		end else if((we == `WriteEnable)) begin
					LLbit_o <= LLbit_i;
		end
	end

endmodule