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
	
	//���Կ���ģ�����Ϣ
    input wire[5:0]            stall,    	
	
	//����ִ�н׶ε���Ϣ	
	input wire[`RegAddrBus]       ex_wd,//ִ�н׶ε�ָ��ִ�к�Ҫд��ļĴ�����ַ
	input wire                    ex_wreg,//ִ�н׶ε�ָ��ִ�к��Ƿ���Ҫд���Ŀ�ļĴ���
	input wire[`RegBus]		       ex_wdata,//ִ�н׶ε�ָ��ִ�к�Ҫд��Ŀ�ļĴ�����ֵ����������
	input wire[`RegBus]           ex_hi,
    input wire[`RegBus]           ex_lo,
    input wire                    ex_whilo,   
    
	input wire[`DoubleRegBus]     hilo_i,	
    input wire[1:0]               cnt_i,          
    
	//�͵��ô�׶ε���Ϣ
	output reg[`RegAddrBus]      mem_wd,
	output reg                   mem_wreg,
	output reg[`RegBus]			  mem_wdata,
	output reg[`RegBus]          mem_hi,//�ô�׶ε�ָ��Ҫд�� LO �Ĵ�����ֵ
    output reg[`RegBus]          mem_lo,//�ô�׶ε�ָ��Ҫд�� HI �Ĵ�����ֵ
    output reg                   mem_whilo,//�ô�׶ε�ָ���Ƿ�Ҫд HI�� LO �Ĵ���
    
	output reg[`DoubleRegBus]    hilo_o,
    output reg[1:0]              cnt_o        
);

//��1���� stall[3]Ϊ Stop�� stall[4]Ϊ NoStop ʱ����ʾִ�н׶���ͣ��
// ���ô�׶μ���������ʹ�ÿ�ָ����Ϊ��һ�����ڽ���ô�׶ε�ָ��
//��2���� stall[3]Ϊ NoStop ʱ��ִ�н׶μ�����ִ�к��ָ�����ô�׶�
//��3����������£����ַô�׶εļĴ��� mem_wb�� mem_wreg�� mwm_wdata��
// mem_hi�� mem_lo�� mem_whilo ����
	always @ (posedge clk) begin
        if(rst == `RstEnable) begin
            mem_wd <= `NOPRegAddr;
            mem_wreg <= `WriteDisable;
            mem_wdata <= `ZeroWord;    
            mem_hi <= `ZeroWord;
            mem_lo <= `ZeroWord;
            mem_whilo <= `WriteDisable;        
            hilo_o <= {`ZeroWord, `ZeroWord};
            cnt_o <= 2'b00;    
        end else if(stall[3] == `Stop && stall[4] == `NoStop) begin
            mem_wd <= `NOPRegAddr;
            mem_wreg <= `WriteDisable;
            mem_wdata <= `ZeroWord;
            mem_hi <= `ZeroWord;
            mem_lo <= `ZeroWord;
            mem_whilo <= `WriteDisable;
// ����ˮ��ִ�н׶���ͣ��ʱ�򣬽������ź� hilo_i ͨ������ӿ� hilo_o �ͳ���
// �����ź� cnt_i ͨ������ӿ� cnt_o �ͳ�������ʱ�̣� hilo_o Ϊ 0�� cnt_o
// ҲΪ 0          
            hilo_o <= hilo_i;
            cnt_o <= cnt_i;                                  
        end else if(stall[3] == `NoStop) begin
            mem_wd <= ex_wd;
            mem_wreg <= ex_wreg;
            mem_wdata <= ex_wdata;    
            mem_hi <= ex_hi;
            mem_lo <= ex_lo;
            mem_whilo <= ex_whilo;    
            hilo_o <= {`ZeroWord, `ZeroWord};
            cnt_o <= 2'b00;    
        end else begin
            hilo_o <= hilo_i;
            cnt_o <= cnt_i;                                            
        end    //if
    end      //always
			

endmodule
