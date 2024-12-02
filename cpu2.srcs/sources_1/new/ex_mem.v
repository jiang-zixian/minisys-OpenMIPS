`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/08 20:25:31
// Design Name: 
// Module Name: ex_mem
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
// EX/MEM阶段：将执行阶段取得的运算结果，在下一个时钟传递到流水线访存阶段
//////////////////////////////////////////////////////////////////////////////////
`include "Define.v"

module ex_mem(
	input wire					clk,
	input wire					rst,
	
	//来自控制模块的信息
    input wire[5:0]            stall,    	
	
	//来自执行阶段的信息	
	input wire[`RegAddrBus]       ex_wd,//执行阶段的指令执行后要写入的寄存器地址
	input wire                    ex_wreg,//执行阶段的指令执行后是否有要写入的目的寄存器
	input wire[`RegBus]		       ex_wdata,//执行阶段的指令执行后要写入目的寄存器的值（运算结果）
	input wire[`RegBus]           ex_hi,
    input wire[`RegBus]           ex_lo,
    input wire                    ex_whilo,   
    
	input wire[`DoubleRegBus]     hilo_i,	
    input wire[1:0]               cnt_i,          
    
	//送到访存阶段的信息
	output reg[`RegAddrBus]      mem_wd,
	output reg                   mem_wreg,
	output reg[`RegBus]			  mem_wdata,
	output reg[`RegBus]          mem_hi,//访存阶段的指令要写入 LO 寄存器的值
    output reg[`RegBus]          mem_lo,//访存阶段的指令要写入 HI 寄存器的值
    output reg                   mem_whilo,//访存阶段的指令是否要写 HI、 LO 寄存器
    
	output reg[`DoubleRegBus]    hilo_o,
    output reg[1:0]              cnt_o        
);

//（1）当 stall[3]为 Stop， stall[4]为 NoStop 时，表示执行阶段暂停，
// 而访存阶段继续，所以使用空指令作为下一个周期进入访存阶段的指令
//（2）当 stall[3]为 NoStop 时，执行阶段继续，执行后的指令进入访存阶段
//（3）其余情况下，保持访存阶段的寄存器 mem_wb、 mem_wreg、 mwm_wdata、
// mem_hi、 mem_lo、 mem_whilo 不变
	always @ (posedge clk) begin
        if(rst == `RstEnable) begin
            mem_wd <= `NOPRegAddr;
            mem_wreg <= `WriteDisable;
            mem_wdata <= `ZeroWord;    
            mem_hi <= `ZeroWord;
            mem_lo <= `ZeroWord;
            mem_whilo <= `WriteDisable;        
            hilo_o <= {`ZeroWord, `ZeroWord};
            cnt_o <= 2'b00;    
        end else if(stall[3] == `Stop && stall[4] == `NoStop) begin
            mem_wd <= `NOPRegAddr;
            mem_wreg <= `WriteDisable;
            mem_wdata <= `ZeroWord;
            mem_hi <= `ZeroWord;
            mem_lo <= `ZeroWord;
            mem_whilo <= `WriteDisable;
// 在流水线执行阶段暂停的时候，将输入信号 hilo_i 通过输出接口 hilo_o 送出，
// 输入信号 cnt_i 通过输出接口 cnt_o 送出。其余时刻， hilo_o 为 0， cnt_o
// 也为 0          
            hilo_o <= hilo_i;
            cnt_o <= cnt_i;                                  
        end else if(stall[3] == `NoStop) begin
            mem_wd <= ex_wd;
            mem_wreg <= ex_wreg;
            mem_wdata <= ex_wdata;    
            mem_hi <= ex_hi;
            mem_lo <= ex_lo;
            mem_whilo <= ex_whilo;    
            hilo_o <= {`ZeroWord, `ZeroWord};
            cnt_o <= 2'b00;    
        end else begin
            hilo_o <= hilo_i;
            cnt_o <= cnt_i;                                            
        end    //if
    end      //always
			

endmodule
