`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/08 20:37:39
// Design Name: 
// Module Name: mem
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
// ����ô�׶��ˣ��������� ori ָ���Ҫ�������ݴ洢���������ڷô�
// �׶Σ������κ��£�ֻ�Ǽ򵥵ؽ�ִ�н׶εĽ�����д�׶δ��ݼ��ɡ�
// ��ˮ�߷ô�׶ΰ��� MEM��MEM/WB ����ģ�顣
//////////////////////////////////////////////////////////////////////////////////
`include "Define.v"

module mem(
	input wire					rst,
	
	//����ִ�н׶ε���Ϣ	
	input wire[`RegAddrBus]       wd_i,//�ô�׶ε�ָ��Ҫд���Ŀ�ļĴ�����ַ
	input wire                    wreg_i,//�ô�׶ε�ָ���Ƿ���Ҫд���Ŀ�ļĴ���
	input wire[`RegBus]			   wdata_i,//�ô�׶ε�ָ��Ҫд��Ŀ�ļĴ�����ֵ
	input wire[`RegBus]           hi_i,
    input wire[`RegBus]           lo_i,
    input wire                    whilo_i,    
    
	//�͵���д�׶ε���Ϣ
	output reg[`RegAddrBus]      wd_o,//�ô�׶ε�ָ������Ҫд���Ŀ�ļĴ�����ַ
	output reg                   wreg_o,//�ô�׶ε�ָ�������Ƿ���Ҫд���Ŀ�ļĴ���
	output reg[`RegBus]			  wdata_o,//�ô�׶ε�ָ������Ҫд��Ŀ�ļĴ�����ֵ
	output reg[`RegBus]          hi_o,//�ô�׶ε�ָ������Ҫд�� HI �Ĵ�����ֵ
    output reg[`RegBus]          lo_o,//�ô�׶ε�ָ������Ҫд�� LO �Ĵ�����ֵ
    output reg                   whilo_o    
);

	
	always @ (*) begin
		if(rst == `RstEnable) begin
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
		  wdata_o <= `ZeroWord;
		  hi_o <= `ZeroWord;
          lo_o <= `ZeroWord;
          whilo_o <= `WriteDisable;    		
		end else begin
		  wd_o <= wd_i;
			wreg_o <= wreg_i;
			wdata_o <= wdata_i;
			hi_o <= hi_i;
            lo_o <= lo_i;
            whilo_o <= whilo_i;    			
		end    //if
	end      //always
			

endmodule
