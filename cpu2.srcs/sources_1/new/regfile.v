`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/07 11:43:55
// Design Name: 
// Module Name: regfile
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
// ����׶Σ�����ȡ����ָ��������룺����Ҫ���е��������ͣ��Լ���������Ĳ�����������׶ΰ��� Regfile��ID �� ID/EX ����ģ�顣
// regfileģ�飬ʵ���� 32 �� 32 λͨ�������Ĵ���������ͬʱ���������Ĵ����Ķ�������һ���Ĵ�����д����
// ��д�׶���ʵ��ʵ����regfileģ��
//////////////////////////////////////////////////////////////////////////////////
`include "Define.v"

module regfile(

	input wire					clk,
	input wire					rst,
	
	//д�˿�
	input wire							we,//дʹ���ź�
	input wire[`RegAddrBus]				waddr,//Ҫд��ļĴ�����ַ
	input wire[`RegBus]					wdata,//Ҫд�������
	
	//���˿�1
	input wire							re1,//��һ�����Ĵ����˿ڶ�ʹ���ź�
	input wire[`RegAddrBus]			    raddr1,//��һ�����Ĵ����˿�Ҫ��ȡ�ļĴ����ĵ�ַ
	output reg[`RegBus]                rdata1,//��һ�����Ĵ����˿�����ļĴ���ֵ
	
	//���˿�2
	input wire							re2,//�ڶ������Ĵ����˿ڶ�ʹ���ź�
	input wire[`RegAddrBus]			    raddr2,//�ڶ������Ĵ����˿�Ҫ��ȡ�ļĴ����ĵ�ַ
	output reg[`RegBus]                 rdata2//�ڶ������Ĵ����˿�����ļĴ���ֵ
	
);

//һ������ 32 �� 32 λ�Ĵ���
	reg[`RegBus]  regs[0:`RegNum-1];

//����д���� 
	always @ (posedge clk) begin//д����ֻ������ʱ���źŵ�������
		if (rst == `RstDisable) begin
			if((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin//д����Ŀ�ļĴ��������Ե���0
				//֮����Ҫ�ж�Ŀ�ļĴ�����Ϊ 0������Ϊ MIPS32 �ܹ��涨$0 ��ֵֻ��Ϊ 0�����Բ�Ҫд��
				regs[waddr] <= wdata;
			end
		end
	end

//�������˿� 1 �Ķ�����	
	always @ (*) begin
		if(rst == `RstEnable) begin
			  rdata1 <= `ZeroWord;
	  end else if(raddr1 == `RegNumLog2'h0) begin//`define RegNumLog2 5 Ѱַͨ�üĴ���ʹ�õĵ�ַλ��
	  		rdata1 <= `ZeroWord;//�����ȡ����$0����ôֱ�Ӹ���0
	  end else if((raddr1 == waddr) && (we == `WriteEnable) 
	  //������Խ���������ָ�������������⣬�ɼ��鼮P110
	  	            && (re1 == `ReadEnable)) begin//�����һ�����Ĵ����˿�Ҫ��ȡ��Ŀ��Ĵ�����Ҫд���Ŀ�ļĴ�����ͬһ���Ĵ�������ôֱ�ӽ�Ҫд���ֵ��Ϊ��һ�����Ĵ����˿ڵ����
	  	  rdata1 <= wdata;
	  end else if(re1 == `ReadEnable) begin//���϶������㣬��ô��raddr1����ֵ������Ӧ�Ĵ���
	      rdata1 <= regs[raddr1];
	  end else begin
	      rdata1 <= `ZeroWord;
	  end
	end

//�ġ����˿� 2 �Ķ�����	
	always @ (*) begin//һ��Ҫ�����raddr1��raddr2�����仯����ô���������µ�ַ��Ӧ�ļĴ�����ֵ
		if(rst == `RstEnable) begin
			  rdata2 <= `ZeroWord;
	  end else if(raddr2 == `RegNumLog2'h0) begin
	  		rdata2 <= `ZeroWord;
	  end else if((raddr2 == waddr) && (we == `WriteEnable) 
	  	            && (re2 == `ReadEnable)) begin
	  	  rdata2 <= wdata;
	  end else if(re2 == `ReadEnable) begin
	      rdata2 <= regs[raddr2];
	  end else begin
	      rdata2 <= `ZeroWord;
	  end
	end

endmodule