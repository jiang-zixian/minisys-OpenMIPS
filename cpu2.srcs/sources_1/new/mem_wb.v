`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/08 20:44:51
// Design Name: 
// Module Name: mem_wb
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
// MEM/WBģ�飺���ô�׶ε�������������һ��ʱ�Ӵ��ݵ���д�׶�
//////////////////////////////////////////////////////////////////////////////////
`include "Define.v"

module mem_wb(
	input wire					clk,
	input wire					rst,

	//���Էô�׶ε���Ϣ	
	input wire[`RegAddrBus]       mem_wd,//�ô�׶ε�ָ������Ҫд���Ŀ�ļĴ�����ַ
	input wire                    mem_wreg,//�ô�׶ε�ָ�������Ƿ���Ҫд���Ŀ�ļĴ���
	input wire[`RegBus]			   mem_wdata,//�ô�׶ε�ָ��Ҫд���Ŀ�ļĴ�����ַ
	input wire[`RegBus]           mem_hi,
    input wire[`RegBus]           mem_lo,
    input wire                    mem_whilo,    
    
	//�͵���д�׶ε���Ϣ
	output reg[`RegAddrBus]      wb_wd,//��д�׶ε�ָ��Ҫд���Ŀ�ļĴ�����ַ
	output reg                   wb_wreg,//��д�׶ε�ָ���Ƿ���Ҫд���Ŀ�ļĴ���
	output reg[`RegBus]			  wb_wdata,//��д�׶ε�ָ��Ҫд��Ŀ�ļĴ�����ֵ
	output reg[`RegBus]          wb_hi,
    output reg[`RegBus]          wb_lo,
    output reg                   wb_whilo        	
);

// ��д�׶���ʵ��ʵ����regfileģ��
	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
			wb_wd <= `NOPRegAddr;
			wb_wreg <= `WriteDisable;
		  wb_wdata <= `ZeroWord;	
		  wb_hi <= `ZeroWord;
          wb_lo <= `ZeroWord;
          wb_whilo <= `WriteDisable;    		  
		end else begin
			wb_wd <= mem_wd;
			wb_wreg <= mem_wreg;
			wb_wdata <= mem_wdata;
			wb_hi <= mem_hi;
            wb_lo <= mem_lo;
            wb_whilo <= mem_whilo;    			
		end    //if
	end      //always
			
endmodule
