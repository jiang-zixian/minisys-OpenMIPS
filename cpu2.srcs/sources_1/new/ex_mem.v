`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/08 20:25:31
// Design Name: 
// Module Name: ex_mem
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
// EX/MEM�׶Σ���ִ�н׶�ȡ�õ�������������һ��ʱ�Ӵ��ݵ���ˮ�߷ô�׶�
//////////////////////////////////////////////////////////////////////////////////
`include "Define.v"

module ex_mem(
	input wire					clk,
	input wire					rst,
	
	
	//����ִ�н׶ε���Ϣ	
	input wire[`RegAddrBus]       ex_wd,//ִ�н׶ε�ָ��ִ�к�Ҫд��ļĴ�����ַ
	input wire                    ex_wreg,//ִ�н׶ε�ָ��ִ�к��Ƿ���Ҫд���Ŀ�ļĴ���
	input wire[`RegBus]		       ex_wdata,//ִ�н׶ε�ָ��ִ�к�Ҫд��Ŀ�ļĴ�����ֵ����������
	input wire[`RegBus]           ex_hi,
    input wire[`RegBus]           ex_lo,
    input wire                    ex_whilo,     
    
	//�͵��ô�׶ε���Ϣ
	output reg[`RegAddrBus]      mem_wd,
	output reg                   mem_wreg,
	output reg[`RegBus]			  mem_wdata,
	output reg[`RegBus]          mem_hi,//�ô�׶ε�ָ��Ҫд�� LO �Ĵ�����ֵ
    output reg[`RegBus]          mem_lo,//�ô�׶ε�ָ��Ҫд�� HI �Ĵ�����ֵ
    output reg                   mem_whilo//�ô�׶ε�ָ���Ƿ�Ҫд HI�� LO �Ĵ���
);


	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `WriteDisable;
		    mem_wdata <= `ZeroWord;
		    mem_hi <= `ZeroWord;
            mem_lo <= `ZeroWord;
            mem_whilo <= `WriteDisable;    	    
		end else begin//ֱ�Ӹ�ֵ���ݼ���
			mem_wd <= ex_wd;
			mem_wreg <= ex_wreg;
			mem_wdata <= ex_wdata;	
			mem_hi <= ex_hi;
            mem_lo <= ex_lo;
            mem_whilo <= ex_whilo;    		
		end    //if
	end      //always
			

endmodule
