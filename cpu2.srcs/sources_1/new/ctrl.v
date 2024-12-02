`timescale 1ns / 1ps
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
`include "Define.v"

module ctrl(

	input wire					rst,

	input wire                   stallreq_from_id,//处于译码阶段的指令是否请求流水线暂停

  //来自执行阶段的暂停请求
	input wire                   stallreq_from_ex,//处于执行阶段的指令是否请求流水线暂停
	output reg[5:0]              stall//暂停流水线控制信号 6bit       
	
//	输出信号 stall 是一个宽度为 6 的信号，其含义如下。
//    stall[0]表示取指地址 PC 是否保持不变，为 1 表示保持不变。
//    stall[1]表示流水线取指阶段是否暂停，为 1 表示暂停。
//    stall[2]表示流水线译码阶段是否暂停，为 1 表示暂停。
//    stall[3]表示流水线执行阶段是否暂停，为 1 表示暂停。
//    stall[4]表示流水线访存阶段是否暂停，为 1 表示暂停。
//    stall[5]表示流水线回写阶段是否暂停，为 1 表示暂停
	
);


	always @ (*) begin
		if(rst == `RstEnable) begin
			stall <= 6'b000000;
		end else if(stallreq_from_ex == `Stop) begin
			stall <= 6'b001111;
		end else if(stallreq_from_id == `Stop) begin
			stall <= 6'b000111;			
		end else begin
			stall <= 6'b000000;
		end    //if
	end      //always
			

endmodule
