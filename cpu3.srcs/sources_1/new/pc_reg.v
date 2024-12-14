//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/07 10:42:54
// Design Name: 
// Module Name: pc_reg
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
// ȡָ�׶�ȡ��ָ��洢���е�ָ�ͬʱ��PC ֵ������׼��ȡ��һ��ָ����� PC��IF/ID ����ģ�顣
// ��ΪPCģ��
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module pc_reg(

	input wire					clk,
	input wire					rst,

	//���Կ���ģ�����Ϣ
	input wire[5:0]               stall,//���Կ���ģ�� CTRL,���ӳٲ��й�
	input wire                    flush,//��ˮ������ź�
	input wire[`RegBus]           new_pc,//�쳣����������ڵ�ַ

	//��������׶ε���Ϣ
	input wire                    branch_flag_i,//�Ƿ���ת��
	input wire[`RegBus]           branch_target_address_i,//ת�Ƶ���Ŀ���ַ 32bit
	
	output reg[`InstAddrBus]			pc,
	output reg                    ce//ָ��洢��ʹ���ź�
	
);

	always @ (posedge clk) begin
		if (ce == `ChipDisable) begin
			pc <= 32'h00000000;
		end else begin
			if(flush == 1'b1) begin
			// �����ź� flush Ϊ 1 ��ʾ�쳣���������� CTRL ģ��������쳣����
            // ������ڵ�ַ new_pc ��ȡִָ��
				pc <= new_pc;
			end else if(stall[0] == `NoStop) begin
				if(branch_flag_i == `Branch) begin
					pc <= branch_target_address_i;
				end else begin
		  		pc <= pc + 4'h4;
		  	end
			end
		end
	end

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			ce <= `ChipDisable;
		end else begin
			ce <= `ChipEnable;
		end
	end

endmodule