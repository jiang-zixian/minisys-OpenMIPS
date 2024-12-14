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

`include "defines.v"

module mem_wb(

	input	wire				clk,
	input wire					rst,

  //���Կ���ģ�����Ϣ
	input wire[5:0]               stall,	
    input wire                    flush,	
    
	//���Էô�׶ε���Ϣ	
	input wire[`RegAddrBus]       mem_wd,//�ô�׶ε�ָ������Ҫд���Ŀ�ļĴ�����ַ
    input wire                    mem_wreg,//�ô�׶ε�ָ�������Ƿ���Ҫд���Ŀ�ļĴ���
    input wire[`RegBus]           mem_wdata,//�ô�׶ε�ָ��Ҫд���Ŀ�ļĴ�����ַ
	input wire[`RegBus]           mem_hi,
	input wire[`RegBus]           mem_lo,
	input wire                    mem_whilo,	
	
	input wire                  mem_LLbit_we,//�ô�׶ε�ָ���Ƿ�Ҫд LLbit �Ĵ���
	input wire                  mem_LLbit_value,//�ô�׶ε�ָ��Ҫд�� LLbit �Ĵ�����ֵ

	input wire                   mem_cp0_reg_we,//�ô�׶ε�ָ���Ƿ�Ҫд CP0�еļĴ���
	input wire[4:0]              mem_cp0_reg_write_addr,
	input wire[`RegBus]          mem_cp0_reg_data,			

	//�͵���д�׶ε���Ϣ
	output reg[`RegAddrBus]      wb_wd,//��д�׶ε�ָ��Ҫд���Ŀ�ļĴ�����ַ
    output reg                   wb_wreg,//��д�׶ε�ָ���Ƿ���Ҫд���Ŀ�ļĴ���
    output reg[`RegBus]          wb_wdata,//��д�׶ε�ָ��Ҫд��Ŀ�ļĴ�����ֵ
	output reg[`RegBus]          wb_hi,
	output reg[`RegBus]          wb_lo,
	output reg                   wb_whilo,

	output reg                  wb_LLbit_we,//��д�׶ε�ָ���Ƿ�Ҫд LLbit �Ĵ���
	output reg                  wb_LLbit_value,//��д�׶ε�ָ��Ҫд�� LLbit �Ĵ�����ֵ

	output reg                   wb_cp0_reg_we,//��д�׶ε�ָ���Ƿ�Ҫд CP0�еļĴ���
	output reg[4:0]              wb_cp0_reg_write_addr,
	output reg[`RegBus]          wb_cp0_reg_data								       
	
);

// ��д�׶���ʵ��ʵ����regfileģ��

//��1���� stall[4]Ϊ Stop�� stall[5]Ϊ NoStop ʱ����ʾ�ô�׶���ͣ��
// ����д�׶μ���������ʹ�ÿ�ָ����Ϊ��һ�����ڽ����д�׶ε�ָ��
//��2���� stall[4]Ϊ NoStop ʱ���ô�׶μ������ô���ָ������д�׶�
//��3����������£����ֻ�д�׶εļĴ��� wb_wd�� wb_wreg�� wb_wdata��
// wb_hi�� wb_lo�� wb_whilo ����
	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
            wb_wd <= `NOPRegAddr;
            wb_wreg <= `WriteDisable;
            wb_wdata <= `ZeroWord;	
            wb_hi <= `ZeroWord;
            wb_lo <= `ZeroWord;
            wb_whilo <= `WriteDisable;
            wb_LLbit_we <= 1'b0;
            wb_LLbit_value <= 1'b0;		
            wb_cp0_reg_we <= `WriteDisable;
            wb_cp0_reg_write_addr <= 5'b00000;
            wb_cp0_reg_data <= `ZeroWord;			
		end else if(flush == 1'b1 ) begin//�����ˮ��
            wb_wd <= `NOPRegAddr;
            wb_wreg <= `WriteDisable;
            wb_wdata <= `ZeroWord;
            wb_hi <= `ZeroWord;
            wb_lo <= `ZeroWord;
            wb_whilo <= `WriteDisable;
            wb_LLbit_we <= 1'b0;
            wb_LLbit_value <= 1'b0;	
            wb_cp0_reg_we <= `WriteDisable;
            wb_cp0_reg_write_addr <= 5'b00000;
            wb_cp0_reg_data <= `ZeroWord;				  				  	  	
		end else if(stall[4] == `Stop && stall[5] == `NoStop) begin
            wb_wd <= `NOPRegAddr;
            wb_wreg <= `WriteDisable;
            wb_wdata <= `ZeroWord;
            wb_hi <= `ZeroWord;
            wb_lo <= `ZeroWord;
            wb_whilo <= `WriteDisable;	
            wb_LLbit_we <= 1'b0;
            wb_LLbit_value <= 1'b0;	
            wb_cp0_reg_we <= `WriteDisable;
            wb_cp0_reg_write_addr <= 5'b00000;
            wb_cp0_reg_data <= `ZeroWord;					  		  	  	  
		end else if(stall[4] == `NoStop) begin
            wb_wd <= mem_wd;
            wb_wreg <= mem_wreg;
            wb_wdata <= mem_wdata;
            wb_hi <= mem_hi;
            wb_lo <= mem_lo;
            wb_whilo <= mem_whilo;		
            wb_LLbit_we <= mem_LLbit_we;
            wb_LLbit_value <= mem_LLbit_value;
            // �ڷô�׶�û����ͣʱ������ CP0 �мĴ�����д��Ϣ���ݵ���д�׶�		
            wb_cp0_reg_we <= mem_cp0_reg_we;
            wb_cp0_reg_write_addr <= mem_cp0_reg_write_addr;
            wb_cp0_reg_data <= mem_cp0_reg_data;			  		
		end    //if
	end      //always
			

endmodule