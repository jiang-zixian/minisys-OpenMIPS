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
	
	//来自控制模块的信息
    input wire[5:0]               stall,    	
	
	input wire[`InstAddrBus]	   if_pc,//取指阶段取得的指令对应地址
	input wire[`InstBus]          if_inst,//取指阶段取得的指令
	output reg[`InstAddrBus]      id_pc,//译码阶段的指令对应的地址
	output reg[`InstBus]          id_inst  //译码阶段的指令
	
);

//（1）当 stall[1]为 Stop， stall[2]为 NoStop 时，表示取指阶段暂停，
// 而译码阶段继续，所以使用空指令作为下一个周期进入译码阶段的指令
//（2）当 stall[1]为 NoStop 时，取指阶段继续，取得的指令进入译码阶段
//（3）其余情况下，保持译码阶段的寄存器 id_pc、 id_inst 不变
	always @ (posedge clk) begin//posedge是上升沿
		if (rst == `RstEnable) begin//如果复位使能
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;//复位的时候指令也为 0，实际就是空指令
		end else if(stall[1] == `Stop && stall[2] == `NoStop) begin
                id_pc <= `ZeroWord;
                id_inst <= `ZeroWord;    
      end else if(stall[1] == `NoStop) begin
          id_pc <= if_pc;
          id_inst <= if_inst;
        end
	end

endmodule