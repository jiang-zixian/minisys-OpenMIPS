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

`include "defines.v"

module id_ex(

	input	wire										clk,
	input wire										rst,

	//���Կ���ģ�����Ϣ
	input wire[5:0]				  stall,
	input wire                   flush,//��ˮ������ź�
	
	//������׶δ��ݵ���Ϣ
	input wire[`AluOpBus]         id_aluop,//����׶ε�ָ��Ҫ���е������������
    input wire[`AluSelBus]        id_alusel,//����׶ε�ָ��Ҫ���е����������
    input wire[`RegBus]           id_reg1,//����׶ε�ָ��Ҫ���е������Դ������1
    input wire[`RegBus]           id_reg2,//����׶ε�ָ��Ҫ���е������Դ������2
    input wire[`RegAddrBus]       id_wd,//����׶ε�ָ��Ҫд���Ŀ�ļĴ�����ַ
    input wire                    id_wreg,    //����׶ε�ָ��Ҫд���Ŀ�ļĴ�����ַ
    input wire[`RegBus]           id_link_address,//��������׶ε�ת��ָ��Ҫ����ķ��ص�ַ 32bit
    input wire                    id_is_in_delayslot,//��ǰ��������׶ε�ָ���Ƿ�λ���ӳٲ�
    input wire                    next_inst_in_delayslot_i,
	input wire[`RegBus]           id_inst,		
	input wire[`RegBus]           id_current_inst_address,//����׶�ָ��ĵ�ַ
	input wire[31:0]              id_excepttype,//����׶��ռ������쳣��Ϣ
	
	//���ݵ�ִ�н׶ε���Ϣ
	output reg[`AluOpBus]         ex_aluop,//ִ�н׶ε�ָ��Ҫ���е������������
    output reg[`AluSelBus]        ex_alusel,//ִ�н׶ε�ָ��Ҫ���е����������
    output reg[`RegBus]           ex_reg1,//ִ�н׶ε�ָ��Ҫ���е������Դ������1
    output reg[`RegBus]           ex_reg2,//ִ�н׶ε�ָ��Ҫ���е������Դ������2
    output reg[`RegAddrBus]       ex_wd,//ִ�н׶ε�ָ��Ҫд���Ŀ�ļĴ�����ַ
    output reg                    ex_wreg,//ִ�н׶ε�ָ��Ҫд���Ŀ�ļĴ�����ַ
    output reg[`RegBus]           ex_link_address,
    output reg                    ex_is_in_delayslot,
    output reg                    is_in_delayslot_o, //��ǰ��������׶ε�ָ���Ƿ�λ���ӳٲ�  
	output reg[`RegBus]           ex_inst,
	output reg[31:0]              ex_excepttype,//����׶��ռ������쳣��Ϣ
	output reg[`RegBus]          ex_current_inst_address	//ִ�н׶�ָ��ĵ�ַ
	
);

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			ex_aluop <= `EXE_NOP_OP;
			ex_alusel <= `EXE_RES_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_wd <= `NOPRegAddr;
			ex_wreg <= `WriteDisable;
			ex_link_address <= `ZeroWord;
			ex_is_in_delayslot <= `NotInDelaySlot;
            is_in_delayslot_o <= `NotInDelaySlot;		
            ex_inst <= `ZeroWord;	
            ex_excepttype <= `ZeroWord;
            ex_current_inst_address <= `ZeroWord;
		end else if(flush == 1'b1 ) begin//�����ˮ��
			ex_aluop <= `EXE_NOP_OP;
			ex_alusel <= `EXE_RES_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_wd <= `NOPRegAddr;
			ex_wreg <= `WriteDisable;
			ex_excepttype <= `ZeroWord;
			ex_link_address <= `ZeroWord;
			ex_inst <= `ZeroWord;
			ex_is_in_delayslot <= `NotInDelaySlot;
            ex_current_inst_address <= `ZeroWord;	
            is_in_delayslot_o <= `NotInDelaySlot;		    
		end else if(stall[2] == `Stop && stall[3] == `NoStop) begin
			ex_aluop <= `EXE_NOP_OP;
			ex_alusel <= `EXE_RES_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_wd <= `NOPRegAddr;
			ex_wreg <= `WriteDisable;	
			ex_link_address <= `ZeroWord;
			ex_is_in_delayslot <= `NotInDelaySlot;
            ex_inst <= `ZeroWord;			
            ex_excepttype <= `ZeroWord;
            ex_current_inst_address <= `ZeroWord;	
		end else if(stall[2] == `NoStop) begin		
			ex_aluop <= id_aluop;
			ex_alusel <= id_alusel;
			ex_reg1 <= id_reg1;
			ex_reg2 <= id_reg2;
			ex_wd <= id_wd;
			ex_wreg <= id_wreg;		
			ex_link_address <= id_link_address;
			ex_is_in_delayslot <= id_is_in_delayslot;
            is_in_delayslot_o <= next_inst_in_delayslot_i;
            ex_inst <= id_inst;			
            ex_excepttype <= id_excepttype;
            ex_current_inst_address <= id_current_inst_address;		
		end
	end
	
endmodule