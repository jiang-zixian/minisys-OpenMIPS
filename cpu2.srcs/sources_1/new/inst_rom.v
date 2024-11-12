`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/10 14:57:39
// Design Name: 
// Module Name: inst_rom
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
// ָ��洢�� ROM ģ��
//////////////////////////////////////////////////////////////////////////////////
`include "Define.v"

module inst_rom(

//	input	wire										clk,
	input wire                    ce,//ʹ���ź�
	input wire[`InstAddrBus]	   addr,//Ҫ��ȡ��ָ���ַ
	output reg[`InstBus]		   inst//������ָ��
	
);

// ����һ�����飬��С�� InstMemNum��Ԫ�ؿ���� InstBus
	reg[`InstBus]  inst_mem[0:`InstMemNum-1];

// ʹ���ļ� inst_rom.data ��ʼ��ָ��洢��
	initial $readmemh ( "inst_rom.txt", inst_mem );

//����λ�ź���Чʱ����������ĵ�ַ������ָ��洢�� ROM �ж�Ӧ��Ԫ��
	always @ (*) begin
		if (ce == `ChipDisable) begin
			inst <= `ZeroWord;
	  end else begin
		  inst <= inst_mem[addr[`InstMemNumLog2+1:2]];
		  //OpenMIPS �ǰ����ֽ�Ѱַ�ģ����˴������ָ��洢����ÿ����ַ��һ�� 32bit ���֣�����Ҫ�� OpenMIPS ������ָ���ַ���� 4 ��ʹ��
		  //���� 4 Ҳ���ǽ�ָ���ַ���� 2 λ�������ڶ�ȡ��ʱ������ĵ�ַ�� addr[`InstMemNumLog2+1:2]
		end
	end

endmodule
