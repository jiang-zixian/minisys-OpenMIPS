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

`include "defines.v"

module mem_wb(

	input	wire				clk,
	input wire					rst,

  //来自控制模块的信息
	input wire[5:0]               stall,	
    input wire                    flush,	
    
	//来自访存阶段的信息	
	input wire[`RegAddrBus]       mem_wd,//访存阶段的指令最终要写入的目的寄存器地址
    input wire                    mem_wreg,//访存阶段的指令最终是否有要写入的目的寄存器
    input wire[`RegBus]           mem_wdata,//访存阶段的指令要写入的目的寄存器地址
	input wire[`RegBus]           mem_hi,
	input wire[`RegBus]           mem_lo,
	input wire                    mem_whilo,	
	
	input wire                  mem_LLbit_we,//访存阶段的指令是否要写 LLbit 寄存器
	input wire                  mem_LLbit_value,//访存阶段的指令要写入 LLbit 寄存器的值

	input wire                   mem_cp0_reg_we,//访存阶段的指令是否要写 CP0中的寄存器
	input wire[4:0]              mem_cp0_reg_write_addr,
	input wire[`RegBus]          mem_cp0_reg_data,			

	//送到回写阶段的信息
	output reg[`RegAddrBus]      wb_wd,//回写阶段的指令要写入的目的寄存器地址
    output reg                   wb_wreg,//回写阶段的指令是否有要写入的目的寄存器
    output reg[`RegBus]          wb_wdata,//回写阶段的指令要写入目的寄存器的值
	output reg[`RegBus]          wb_hi,
	output reg[`RegBus]          wb_lo,
	output reg                   wb_whilo,

	output reg                  wb_LLbit_we,//回写阶段的指令是否要写 LLbit 寄存器
	output reg                  wb_LLbit_value,//回写阶段的指令要写入 LLbit 寄存器的值

	output reg                   wb_cp0_reg_we,//回写阶段的指令是否要写 CP0中的寄存器
	output reg[4:0]              wb_cp0_reg_write_addr,
	output reg[`RegBus]          wb_cp0_reg_data								       
	
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
            wb_LLbit_we <= 1'b0;
            wb_LLbit_value <= 1'b0;		
            wb_cp0_reg_we <= `WriteDisable;
            wb_cp0_reg_write_addr <= 5'b00000;
            wb_cp0_reg_data <= `ZeroWord;			
		end else if(flush == 1'b1 ) begin//清除流水线
            wb_wd <= `NOPRegAddr;
            wb_wreg <= `WriteDisable;
            wb_wdata <= `ZeroWord;
            wb_hi <= `ZeroWord;
            wb_lo <= `ZeroWord;
            wb_whilo <= `WriteDisable;
            wb_LLbit_we <= 1'b0;
            wb_LLbit_value <= 1'b0;	
            wb_cp0_reg_we <= `WriteDisable;
            wb_cp0_reg_write_addr <= 5'b00000;
            wb_cp0_reg_data <= `ZeroWord;				  				  	  	
		end else if(stall[4] == `Stop && stall[5] == `NoStop) begin
            wb_wd <= `NOPRegAddr;
            wb_wreg <= `WriteDisable;
            wb_wdata <= `ZeroWord;
            wb_hi <= `ZeroWord;
            wb_lo <= `ZeroWord;
            wb_whilo <= `WriteDisable;	
            wb_LLbit_we <= 1'b0;
            wb_LLbit_value <= 1'b0;	
            wb_cp0_reg_we <= `WriteDisable;
            wb_cp0_reg_write_addr <= 5'b00000;
            wb_cp0_reg_data <= `ZeroWord;					  		  	  	  
		end else if(stall[4] == `NoStop) begin
            wb_wd <= mem_wd;
            wb_wreg <= mem_wreg;
            wb_wdata <= mem_wdata;
            wb_hi <= mem_hi;
            wb_lo <= mem_lo;
            wb_whilo <= mem_whilo;		
            wb_LLbit_we <= mem_LLbit_we;
            wb_LLbit_value <= mem_LLbit_value;
            // 在访存阶段没有暂停时，将对 CP0 中寄存器的写信息传递到回写阶段		
            wb_cp0_reg_we <= mem_cp0_reg_we;
            wb_cp0_reg_write_addr <= mem_cp0_reg_write_addr;
            wb_cp0_reg_data <= mem_cp0_reg_data;			  		
		end    //if
	end      //always
			

endmodule