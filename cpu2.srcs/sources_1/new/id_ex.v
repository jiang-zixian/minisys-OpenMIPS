`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/08 13:05:50
// Design Name: 
// Module Name: id_ex
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
// ID/EXģ�飬������׶�ȡ�õ��������͡�Դ��������Ҫд��Ŀ�ļĴ�����ַ�Ƚ��������һ��ʱ�Ӵ��ݵ���ˮ��ִ�н׶Ρ�
//////////////////////////////////////////////////////////////////////////////////
`include "Define.v"

module id_ex(
	input wire					clk,
	input wire					rst,

	//���Կ���ģ�����Ϣ
	input wire[5:0]				stall,
	
	//������׶δ��ݵ���Ϣ
	input wire[`AluOpBus]         id_aluop,//����׶ε�ָ��Ҫ���е������������
	input wire[`AluSelBus]        id_alusel,//����׶ε�ָ��Ҫ���е����������
	input wire[`RegBus]           id_reg1,//����׶ε�ָ��Ҫ���е������Դ������1
	input wire[`RegBus]           id_reg2,//����׶ε�ָ��Ҫ���е������Դ������2
	input wire[`RegAddrBus]       id_wd,//����׶ε�ָ��Ҫд���Ŀ�ļĴ�����ַ
	input wire                    id_wreg,	//����׶ε�ָ��Ҫд���Ŀ�ļĴ�����ַ
	
	//���ݵ�ִ�н׶ε���Ϣ
	output reg[`AluOpBus]         ex_aluop,//ִ�н׶ε�ָ��Ҫ���е������������
	output reg[`AluSelBus]        ex_alusel,//ִ�н׶ε�ָ��Ҫ���е����������
	output reg[`RegBus]           ex_reg1,//ִ�н׶ε�ָ��Ҫ���е������Դ������1
	output reg[`RegBus]           ex_reg2,//ִ�н׶ε�ָ��Ҫ���е������Դ������2
	output reg[`RegAddrBus]       ex_wd,//ִ�н׶ε�ָ��Ҫд���Ŀ�ļĴ�����ַ
	output reg                    ex_wreg//ִ�н׶ε�ָ��Ҫд���Ŀ�ļĴ�����ַ
	
);

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			ex_aluop <= `EXE_NOP_OP;
			ex_alusel <= `EXE_RES_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_wd <= `NOPRegAddr;
			ex_wreg <= `WriteDisable;
		end else if(stall[2] == `Stop && stall[3] == `NoStop) begin
                ex_aluop <= `EXE_NOP_OP;
                ex_alusel <= `EXE_RES_NOP;
                ex_reg1 <= `ZeroWord;
                ex_reg2 <= `ZeroWord;
                ex_wd <= `NOPRegAddr;
                ex_wreg <= `WriteDisable;            
        end else if(stall[2] == `NoStop) begin        
            ex_aluop <= id_aluop;
            ex_alusel <= id_alusel;
            ex_reg1 <= id_reg1;
            ex_reg2 <= id_reg2;
            ex_wd <= id_wd;
            ex_wreg <= id_wreg;    	
		end
	end
	
endmodule