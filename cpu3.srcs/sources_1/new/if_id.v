//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/07 11:15:26
// Design Name: 
// Module Name: if_id
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
// ��ΪIF/IDģ��,IF/ID ģ�����������ʱ����ȡָ�׶�ȡ�õ�ָ��Լ���Ӧ��ָ���ַ��������һ��ʱ�Ӵ��ݵ�����׶�
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module if_id(

	input wire										clk,
	input wire										rst,

	//���Կ���ģ�����Ϣ
	input wire[5:0]               stall,	
	input wire                    flush,

	input wire[`InstAddrBus]	   if_pc,
	input wire[`InstBus]          if_inst,
	output reg[`InstAddrBus]      id_pc,
	output reg[`InstBus]          id_inst  
	
);

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;
		end else if(flush == 1'b1 ) begin
		// flush Ϊ 1 ��ʾ�쳣������Ҫ�����ˮ�ߣ�
        // ���Ը�λ id_pc�� id_inst �Ĵ�����ֵ
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;					
		end else if(stall[1] == `Stop && stall[2] == `NoStop) begin
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;	
	  end else if(stall[1] == `NoStop) begin
            id_pc <= if_pc;
            id_inst <= if_inst;
		end
	end

endmodule