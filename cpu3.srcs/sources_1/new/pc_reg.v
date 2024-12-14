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
// 取指阶段取出指令存储器中的指令，同时，PC 值递增，准备取下一条指令，包括 PC、IF/ID 两个模块。
// 此为PC模块
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module pc_reg(

	input wire					clk,
	input wire					rst,

	//来自控制模块的信息
	input wire[5:0]               stall,//来自控制模块 CTRL,与延迟槽有关
	input wire                    flush,//流水线清除信号
	input wire[`RegBus]           new_pc,//异常处理例程入口地址

	//来自译码阶段的信息
	input wire                    branch_flag_i,//是否发生转移
	input wire[`RegBus]           branch_target_address_i,//转移到的目标地址 32bit
	
	output reg[`InstAddrBus]			pc,
	output reg                    ce//指令存储器使能信号
	
);

	always @ (posedge clk) begin
		if (ce == `ChipDisable) begin
			pc <= 32'h00000000;
		end else begin
			if(flush == 1'b1) begin
			// 输入信号 flush 为 1 表示异常发生，将从 CTRL 模块给出的异常处理
            // 例程入口地址 new_pc 处取指执行
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