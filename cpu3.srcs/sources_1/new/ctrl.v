//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/02 17:51:47
// Design Name: 
// Module Name: ctrl
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
// 
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module ctrl(

	input wire										rst,

	input wire[31:0]             excepttype_i,//���յ��쳣����
	input wire[`RegBus]          cp0_epc_i,//EPC�Ĵ���������ֵ

	input wire                   stallreq_from_id,//��������׶ε�ָ���Ƿ�������ˮ����ͣ

  //����ִ�н׶ε���ͣ����
	input wire                   stallreq_from_ex,

	output reg[`RegBus]          new_pc,//�쳣������ڵ�ַ
	output reg                   flush,	//1bit �Ƿ������ˮ��
	output reg[5:0]              stall    
	//	����ź� stall ��һ�����Ϊ 6 ���źţ��京�����¡�
    //    stall[0]��ʾȡָ��ַ PC �Ƿ񱣳ֲ��䣬Ϊ 1 ��ʾ���ֲ��䡣
    //    stall[1]��ʾ��ˮ��ȡָ�׶��Ƿ���ͣ��Ϊ 1 ��ʾ��ͣ��
    //    stall[2]��ʾ��ˮ������׶��Ƿ���ͣ��Ϊ 1 ��ʾ��ͣ��
    //    stall[3]��ʾ��ˮ��ִ�н׶��Ƿ���ͣ��Ϊ 1 ��ʾ��ͣ��
    //    stall[4]��ʾ��ˮ�߷ô�׶��Ƿ���ͣ��Ϊ 1 ��ʾ��ͣ��
    //    stall[5]��ʾ��ˮ�߻�д�׶��Ƿ���ͣ��Ϊ 1 ��ʾ��ͣ   
	
);


	always @ (*) begin
		if(rst == `RstEnable) begin
			stall <= 6'b000000;
			flush <= 1'b0;
			new_pc <= `ZeroWord;
		end else if(excepttype_i != `ZeroWord) begin
		  flush <= 1'b1;
		  stall <= 6'b000000;
			case (excepttype_i)
				32'h00000001:		begin   //interrupt
					new_pc <= 32'h00000020;
				end
				32'h00000008:		begin   //syscall
					new_pc <= 32'h00000040;
				end
				32'h0000000a:		begin   //inst_invalid
					new_pc <= 32'h00000040;
				end
				32'h0000000d:		begin   //trap
					new_pc <= 32'h00000040;
				end
				32'h0000000c:		begin   //ov ���
					new_pc <= 32'h00000040;
				end
				32'h0000000e:		begin   //eret �쳣����ָ��
					new_pc <= cp0_epc_i;
				end
				default	: begin
				end
			endcase 						
		end else if(stallreq_from_ex == `Stop) begin
			stall <= 6'b001111;
			flush <= 1'b0;		
		end else if(stallreq_from_id == `Stop) begin
			stall <= 6'b000111;	
			flush <= 1'b0;		
		end else begin
			stall <= 6'b000000;
			flush <= 1'b0;
			new_pc <= `ZeroWord;		
		end    //if
	end      //always
			

endmodule