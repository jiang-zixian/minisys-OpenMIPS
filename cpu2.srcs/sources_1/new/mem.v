`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/08 20:37:39
// Design Name: 
// Module Name: mem
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
// 进入访存阶段了，但是由于 ori 指令不需要访问数据存储器，所以在访存
// 阶段，不做任何事，只是简单地将执行阶段的结果向回写阶段传递即可。
// 流水线访存阶段包括 MEM、MEM/WB 两个模块。
//////////////////////////////////////////////////////////////////////////////////
`include "Define.v"

module mem(
	input wire					rst,
	
	//来自执行阶段的信息	
	input wire[`RegAddrBus]       wd_i,//访存阶段的指令要写入的目的寄存器地址
	input wire                    wreg_i,//访存阶段的指令是否有要写入的目的寄存器
	input wire[`RegBus]			   wdata_i,//访存阶段的指令要写入目的寄存器的值
	input wire[`RegBus]           hi_i,
    input wire[`RegBus]           lo_i,
    input wire                    whilo_i,    
    
	//送到回写阶段的信息
	output reg[`RegAddrBus]      wd_o,//访存阶段的指令最终要写入的目的寄存器地址
	output reg                   wreg_o,//访存阶段的指令最终是否有要写入的目的寄存器
	output reg[`RegBus]			  wdata_o,//访存阶段的指令最终要写入目的寄存器的值
	output reg[`RegBus]          hi_o,//访存阶段的指令最终要写入 HI 寄存器的值
    output reg[`RegBus]          lo_o,//访存阶段的指令最终要写入 LO 寄存器的值
    output reg                   whilo_o    
);

	
	always @ (*) begin
		if(rst == `RstEnable) begin
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
		  wdata_o <= `ZeroWord;
		  hi_o <= `ZeroWord;
          lo_o <= `ZeroWord;
          whilo_o <= `WriteDisable;    		
		end else begin
		  wd_o <= wd_i;
			wreg_o <= wreg_i;
			wdata_o <= wdata_i;
			hi_o <= hi_i;
            lo_o <= lo_i;
            whilo_o <= whilo_i;    			
		end    //if
	end      //always
			

endmodule
