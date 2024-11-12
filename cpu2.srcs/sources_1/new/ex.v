`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/08 20:13:10
// Design Name: 
// Module Name: ex
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
// EX ģ���� ID/EX ģ��õ���
// ������ alusel_i������������ aluop_i��Դ������ reg1_i��Դ������ reg2_i��Ҫд��Ŀ�ļĴ�����ַ wd_i
//////////////////////////////////////////////////////////////////////////////////
`include "Define.v"

module ex(

	input wire										rst,
	
	//�͵�ִ�н׶ε���Ϣ
	input wire[`AluOpBus]         aluop_i,//3bit ִ�н׶�Ҫ���е����������
	input wire[`AluSelBus]        alusel_i,//8bit ִ�н׶�Ҫ���е������������
	input wire[`RegBus]           reg1_i,//Դ������1
	input wire[`RegBus]           reg2_i,//Դ������2
	input wire[`RegAddrBus]       wd_i,//ָ��ִ��Ҫд���Ŀ�ļĴ�����ַ 5bit
	input wire                    wreg_i,//�Ƿ���Ҫд���Ŀ�ļĴ���

	
	output reg[`RegAddrBus]       wd_o,//ִ�н׶ε�ָ������Ҫд���Ŀ�ļĴ�����ַ 5bit
	output reg                    wreg_o,//ִ�н׶ε�ָ�������Ƿ���Ҫд���Ŀ�ļĴ��� 1bit
	output reg[`RegBus]	    	   wdata_o,//ִ�н׶ε�ָ������Ҫд��Ŀ�ļĴ�����ֵ 32bit
	
	// �����߼�����Ľ��
    output    wire[`RegBus] logicout
	
);

// �����߼�����Ľ��
	reg[`RegBus] logicout_real;
	
	//һ������ aluop_i ָʾ�����������ͽ������㣬�˴�ֻ���߼�"��"����
	always @ (*) begin
		if(rst == `RstEnable) begin
			logicout_real <= `ZeroWord;
		end else begin
			case (aluop_i)
				`EXE_OR_OP:			begin
					logicout_real <= reg1_i | reg2_i;
				end
				default:				begin
					logicout_real <= `ZeroWord;
				end
			endcase
		end    //if
	end      //always
	
	assign logicout = logicout_real;

//���� alusel_i ָʾ���������ͣ�ѡ��һ����������Ϊ���ս��,�˴�ֻ���߼������� 
 always @ (*) begin
	 wd_o <= wd_i;	 	 	
	 wreg_o <= wreg_i;
	 case ( alusel_i ) 
	 	`EXE_RES_LOGIC:		begin
	 		wdata_o <= logicout;
	 	end
	 	default:					begin
	 		wdata_o <= `ZeroWord;
	 	end
	 endcase
 end	

endmodule
