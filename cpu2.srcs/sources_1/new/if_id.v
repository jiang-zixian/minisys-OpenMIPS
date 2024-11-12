`timescale 1ns / 1ps
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

`include "Define.v"

module if_id(
	input wire					clk,
	input wire					rst,
	
	input wire[`InstAddrBus]	   if_pc,//取指阶段取得的指令对应地址
	input wire[`InstBus]          if_inst,//取指阶段取得的指令
	output reg[`InstAddrBus]      id_pc,//译码阶段的指令对应的地址
	output reg[`InstBus]          id_inst  //译码阶段的指令
	
);

	always @ (posedge clk) begin//posedge是上升沿
		if (rst == `RstEnable) begin//如果复位使能
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;//复位的时候指令也为 0，实际就是空指令
	  end else begin
		  id_pc <= if_pc;//其余时刻向下传递取指阶段的值
		  id_inst <= if_inst;
		end
	end

endmodule