`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/07 11:15:26
// Design Name: 
// Module Name: if_id
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
// ȡָ�׶�ȡ��ָ��洢���е�ָ�ͬʱ��PC ֵ������׼��ȡ��һ��ָ����� PC��IF/ID ����ģ�顣
// ��ΪIF/IDģ��,IF/ID ģ�����������ʱ����ȡָ�׶�ȡ�õ�ָ��Լ���Ӧ��ָ���ַ��������һ��ʱ�Ӵ��ݵ�����׶�
//////////////////////////////////////////////////////////////////////////////////

`include "Define.v"

module if_id(
	input wire					clk,
	input wire					rst,
	
	input wire[`InstAddrBus]	   if_pc,//ȡָ�׶�ȡ�õ�ָ���Ӧ��ַ
	input wire[`InstBus]          if_inst,//ȡָ�׶�ȡ�õ�ָ��
	output reg[`InstAddrBus]      id_pc,//����׶ε�ָ���Ӧ�ĵ�ַ
	output reg[`InstBus]          id_inst  //����׶ε�ָ��
	
);

	always @ (posedge clk) begin//posedge��������
		if (rst == `RstEnable) begin//�����λʹ��
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;//��λ��ʱ��ָ��ҲΪ 0��ʵ�ʾ��ǿ�ָ��
	  end else begin
		  id_pc <= if_pc;//����ʱ�����´���ȡָ�׶ε�ֵ
		  id_inst <= if_inst;
		end
	end

endmodule