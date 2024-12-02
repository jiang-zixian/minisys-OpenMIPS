`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/02 17:51:47
// Design Name: 
// Module Name: ctrl
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
// 
//////////////////////////////////////////////////////////////////////////////////
`include "Define.v"

module ctrl(

	input wire					rst,

	input wire                   stallreq_from_id,//��������׶ε�ָ���Ƿ�������ˮ����ͣ

  //����ִ�н׶ε���ͣ����
	input wire                   stallreq_from_ex,//����ִ�н׶ε�ָ���Ƿ�������ˮ����ͣ
	output reg[5:0]              stall//��ͣ��ˮ�߿����ź� 6bit       
	
//	����ź� stall ��һ�����Ϊ 6 ���źţ��京�����¡�
//    stall[0]��ʾȡָ��ַ PC �Ƿ񱣳ֲ��䣬Ϊ 1 ��ʾ���ֲ��䡣
//    stall[1]��ʾ��ˮ��ȡָ�׶��Ƿ���ͣ��Ϊ 1 ��ʾ��ͣ��
//    stall[2]��ʾ��ˮ������׶��Ƿ���ͣ��Ϊ 1 ��ʾ��ͣ��
//    stall[3]��ʾ��ˮ��ִ�н׶��Ƿ���ͣ��Ϊ 1 ��ʾ��ͣ��
//    stall[4]��ʾ��ˮ�߷ô�׶��Ƿ���ͣ��Ϊ 1 ��ʾ��ͣ��
//    stall[5]��ʾ��ˮ�߻�д�׶��Ƿ���ͣ��Ϊ 1 ��ʾ��ͣ
	
);


	always @ (*) begin
		if(rst == `RstEnable) begin
			stall <= 6'b000000;
		end else if(stallreq_from_ex == `Stop) begin
			stall <= 6'b001111;
		end else if(stallreq_from_id == `Stop) begin
			stall <= 6'b000111;			
		end else begin
			stall <= 6'b000000;
		end    //if
	end      //always
			

endmodule
