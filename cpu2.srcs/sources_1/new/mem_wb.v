`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/08 20:44:51
// Design Name: 
// Module Name: mem_wb
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
// MEM/WB模块：将访存阶段的运算结果，在下一个时钟传递到回写阶段
//////////////////////////////////////////////////////////////////////////////////
`include "Define.v"

module mem_wb(
	input wire					clk,
	input wire					rst,
	
  //来自控制模块的信息
    input wire[5:0]               stall,    	

	//来自访存阶段的信息	
	input wire[`RegAddrBus]       mem_wd,//访存阶段的指令最终要写入的目的寄存器地址
	input wire                    mem_wreg,//访存阶段的指令最终是否有要写入的目的寄存器
	input wire[`RegBus]			   mem_wdata,//访存阶段的指令要写入的目的寄存器地址
	input wire[`RegBus]           mem_hi,
    input wire[`RegBus]           mem_lo,
    input wire                    mem_whilo,    
    
	//送到回写阶段的信息
	output reg[`RegAddrBus]      wb_wd,//回写阶段的指令要写入的目的寄存器地址
	output reg                   wb_wreg,//回写阶段的指令是否有要写入的目的寄存器
	output reg[`RegBus]			  wb_wdata,//回写阶段的指令要写入目的寄存器的值
	output reg[`RegBus]          wb_hi,
    output reg[`RegBus]          wb_lo,
    output reg                   wb_whilo        	
);

// 回写阶段其实就实现在regfile模块

//（1）当 stall[4]为 Stop， stall[5]为 NoStop 时，表示访存阶段暂停，
// 而回写阶段继续，所以使用空指令作为下一个周期进入回写阶段的指令
//（2）当 stall[4]为 NoStop 时，访存阶段继续，访存后的指令进入回写阶段
//（3）其余情况下，保持回写阶段的寄存器 wb_wd、 wb_wreg、 wb_wdata、
// wb_hi、 wb_lo、 wb_whilo 不变
	always @ (posedge clk) begin
        if(rst == `RstEnable) begin
            wb_wd <= `NOPRegAddr;
            wb_wreg <= `WriteDisable;
          wb_wdata <= `ZeroWord;    
          wb_hi <= `ZeroWord;
          wb_lo <= `ZeroWord;
          wb_whilo <= `WriteDisable;    
        end else if(stall[4] == `Stop && stall[5] == `NoStop) begin
            wb_wd <= `NOPRegAddr;
            wb_wreg <= `WriteDisable;
          wb_wdata <= `ZeroWord;
          wb_hi <= `ZeroWord;
          wb_lo <= `ZeroWord;
          wb_whilo <= `WriteDisable;                
        end else if(stall[4] == `NoStop) begin
            wb_wd <= mem_wd;
            wb_wreg <= mem_wreg;
            wb_wdata <= mem_wdata;
            wb_hi <= mem_hi;
            wb_lo <= mem_lo;
            wb_whilo <= mem_whilo;            
        end    //if
    end      //always
			
endmodule
