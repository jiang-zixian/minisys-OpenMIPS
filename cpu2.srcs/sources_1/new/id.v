`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/07 12:24:22
// Design Name: 
// Module Name: id
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
// ID ģ��������Ƕ�ָ��������룬�õ�������������͡������͡�Դ������ 1��Դ����
// �� 2��Ҫд���Ŀ�ļĴ�����ַ����Ϣ��������������ָ�����߼����㡢��λ���㡢��������
// �ȣ�������ָ���Ǹ�����ϸ���������ͣ����磺�������������߼�����ʱ�����������Ϳ�����
// �߼�"��"���㡢�߼�"��"���㡢�߼�"���"����ȡ�
//////////////////////////////////////////////////////////////////////////////////
`include "Define.v"

module id(
	input wire					   rst,
	input wire[`InstAddrBus]	   pc_i,//����׶ε�ָ���Ӧ�ĵ�ַ
	input wire[`InstBus]          inst_i,//����׶ε�ָ�� 32bit

	input wire[`RegBus]           reg1_data_i,//�� Regfile ����ĵ�һ�����Ĵ����˿ڵ�����
	input wire[`RegBus]           reg2_data_i,//�� Regfile ����ĵڶ������Ĵ����˿ڵ�����

	//�͵�regfile����Ϣ
	output reg                    reg1_read_o,//regfile ģ��ĵ�һ�����Ĵ����˿ڵĶ�ʹ���ź�
	output reg                    reg2_read_o,//regfile ģ��ĵڶ������Ĵ����˿ڵĶ�ʹ���ź�
	output reg[`RegAddrBus]       reg1_addr_o,//Regfile ģ��ĵ�һ�����Ĵ����˿ڵĶ���ַ�ź� 5bit
	output reg[`RegAddrBus]       reg2_addr_o,//Regfile ģ��ĵڶ������Ĵ����˿ڵĶ���ַ�ź� 5bit 	      
	
	//�͵�ִ�н׶ε���Ϣ
	output reg[`AluOpBus]         aluop_o,//����׶ε�ָ��Ҫ���е������������ 8bit
	output reg[`AluSelBus]        alusel_o,//����׶ε�ָ��Ҫ���е���������� 3bit
	output reg[`RegBus]           reg1_o,//����׶ε�ָ��Ҫ���е������Դ������1
	output reg[`RegBus]           reg2_o,//����׶ε�ָ��Ҫ���е������Դ������2
	output reg[`RegAddrBus]       wd_o,//����׶ε�ָ��Ҫд���Ŀ�ļĴ�����ַ 5bit
	output reg                    wreg_o//����׶ε�ָ���Ƿ���Ҫд���Ŀ�ļĴ���
);
// ȡ��ָ���ָ���룬������
// ���� ori ָ��ֻ��ͨ���жϵ� 26-31bit ��ֵ�������ж��Ƿ��� ori ָ��
  wire[5:0] op = inst_i[31:26];
  wire[4:0] op2 = inst_i[10:6];
  wire[5:0] op3 = inst_i[5:0];
  wire[4:0] op4 = inst_i[20:16];
  
  // ����ָ��ִ����Ҫ��������
  reg[`RegBus]	imm;
  
  // ָʾָ���Ƿ���Ч
  reg instvalid;
  
 //һ����ָ��������� 
	always @ (*) begin	
		if (rst == `RstEnable) begin
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
			instvalid <= `InstValid;
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= `NOPRegAddr;
			reg2_addr_o <= `NOPRegAddr;
			imm <= 32'h0;			
	  end else begin
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= inst_i[15:11];
			wreg_o <= `WriteDisable;
			instvalid <= `InstInvalid;	   
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= inst_i[25:21];// Ĭ��ͨ�� Regfile ���˿� 1 ��ȡ�ļĴ�����ַ
			reg2_addr_o <= inst_i[20:16];// Ĭ��ͨ�� Regfile ���˿� 2 ��ȡ�ļĴ�����ַ		
			imm <= `ZeroWord;			
		  case (op)
		  	`EXE_ORI:			begin                        //ORIָ��
		  	    //oriָ����Ҫ�����д��Ŀ�ļĴ���
		  		wreg_o <= `WriteEnable;
		  		//��������������߼���		
		  		aluop_o <= `EXE_OR_OP;
		  		//����������� �߼�����
		  		alusel_o <= `EXE_RES_LOGIC;
		  		//��Ҫͨ��regfile�Ķ��˿�1��ȡ�Ĵ���
		  		reg1_read_o <= 1'b1;	
		  		//����Ҫͨ��regfile�Ķ��˿�2��ȡ�Ĵ���
		  		reg2_read_o <= 1'b0;	
		  		//ָ��ִ����Ҫ��������  	
				imm <= {16'h0, inst_i[15:0]};		
				//ָ��ִ��Ҫд��Ŀ�ļĴ�����ַ
				wd_o <= inst_i[20:16];
				//oriָ������Чָ��
				instvalid <= `InstValid;	
		  	end 							 
		    default:			begin
		    end
		  endcase		  //case op			
		end       //if
	end         //always
	
//����ȷ�����������Դ������ 1 
	always @ (*) begin
		if(rst == `RstEnable) begin
			reg1_o <= `ZeroWord;
	  end else if(reg1_read_o == 1'b1) begin
	  	reg1_o <= reg1_data_i;
	  end else if(reg1_read_o == 1'b0) begin
	  	reg1_o <= imm;
	  end else begin
	    reg1_o <= `ZeroWord;
	  end
	end
	
	//����ȷ�����������Դ������ 2
	always @ (*) begin
		if(rst == `RstEnable) begin
			reg2_o <= `ZeroWord;
	  end else if(reg2_read_o == 1'b1) begin
	  	reg2_o <= reg2_data_i;
	  end else if(reg2_read_o == 1'b0) begin
	  	reg2_o <= imm;
	  end else begin
	    reg2_o <= `ZeroWord;
	  end
	end

endmodule