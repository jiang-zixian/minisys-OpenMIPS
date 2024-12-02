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
// ȡָ�׶�ȡ��ָ��洢���е�ָ�ͬʱ��PC ֵ������׼��ȡ��һ��ָ����� PC��IF/ID ����ģ�顣
// ��ΪPCģ��
//////////////////////////////////////////////////////////////////////////////////

`include "Define.v"

module pc_reg(

	input wire			clk,//ʱ���ź�
	input wire			rst,//��λ�ź�
	
	//���Կ���ģ�����Ϣ
    input wire[5:0]               stall,	
	
	output reg[`InstAddrBus]	pc,//InstAddrBus ���ʾָ���ַ�ߵĿ��
	output reg                  ce//ָ��Ĵ�����ʹ���ź�
	
);
//TODO ����Դ������������always��˳�򷴹����������ﰴ�����ϵĴ���д��
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin//��λ��ʱ��ָ��洢������
			ce <= `ChipDisable;
		end else begin
			ce <= `ChipEnable;
		end
	end
	
	always @ (posedge clk) begin
		if (ce == `ChipDisable) begin
			pc <= 32'h00000000;
		end else if(stall[0] == `NoStop) begin
	 		pc <= pc + 4'h4;//ָ��洢��ʹ�ܵ�ʱ��PC ��ֵÿʱ�����ڼ� 4��
	 		//��ʾ��һ��ָ��ĵ�ַ����Ϊһ��ָ���� 32 λ������Ƶ�minisys-cpu�ǿ��԰����ֽ�Ѱַ�ģ�һ��ָ���Ӧ 4 ���ֽڣ����� PC �� 4 ָ����һ��ָ���ַ
		end
	end
	

endmodule

