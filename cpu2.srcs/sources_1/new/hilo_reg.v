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
// �ƶ�ָ����漰��HL��LO�Ĵ���
//////////////////////////////////////////////////////////////////////////////////
`include "Define.v"

module hilo_reg(

	input	wire										clk,
	input wire										rst,
	
	//д�˿�
	input wire							we,//HI�� LO �Ĵ���дʹ���ź�
	input wire[`RegBus]				    hi_i,
	input wire[`RegBus]					lo_i,
	
	//���˿�1
	output reg[`RegBus]           hi_o,
	output reg[`RegBus]           lo_o
	
);

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
					hi_o <= `ZeroWord;
					lo_o <= `ZeroWord;
		end else if((we == `WriteEnable)) begin//����� WriteEnable����ô�ͽ������ hi_i�� lo_i ��ֵ��Ϊ HI�� LO �Ĵ�������ֵ����ͨ�� hi_o�� lo_o �ӿ����
					hi_o <= hi_i;
					lo_o <= lo_i;
		end
	end

endmodule
