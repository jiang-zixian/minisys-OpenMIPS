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
// 取指阶段取出指令存储器中的指令，同时，PC 值递增，准备取下一条指令，包括 PC、IF/ID 两个模块。
// 此为IF/ID模块,IF/ID 模块的作用是暂时保存取指阶段取得的指令，以及对应的指令地址，并在下一个时钟传递到译码阶段
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module if_id(

	input wire										clk,
	input wire										rst,

	//来自控制模块的信息
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
		// flush 为 1 表示异常发生，要清除流水线，
        // 所以复位 id_pc、 id_inst 寄存器的值
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