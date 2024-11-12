`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/08 20:13:10
// Design Name: 
// Module Name: ex
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
// EX 模块会从 ID/EX 模块得到运
// 算类型 alusel_i、运算子类型 aluop_i、源操作数 reg1_i、源操作数 reg2_i、要写的目的寄存器地址 wd_i
//////////////////////////////////////////////////////////////////////////////////
`include "Define.v"

module ex(

	input wire										rst,
	
	//送到执行阶段的信息
	input wire[`AluOpBus]         aluop_i,//3bit 执行阶段要进行的运算的类型
	input wire[`AluSelBus]        alusel_i,//8bit 执行阶段要进行的运算的子类型
	input wire[`RegBus]           reg1_i,//源操作数1
	input wire[`RegBus]           reg2_i,//源操作数2
	input wire[`RegAddrBus]       wd_i,//指令执行要写入的目的寄存器地址 5bit
	input wire                    wreg_i,//是否有要写入的目的寄存器

	
	output reg[`RegAddrBus]       wd_o,//执行阶段的指令最终要写入的目的寄存器地址 5bit
	output reg                    wreg_o,//执行阶段的指令最终是否有要写入的目的寄存器 1bit
	output reg[`RegBus]	    	   wdata_o,//执行阶段的指令最终要写入目的寄存器的值 32bit
	
	// 保存逻辑运算的结果
    output    wire[`RegBus] logicout
	
);

// 保存逻辑运算的结果
	reg[`RegBus] logicout_real;
	
	//一、依据 aluop_i 指示的运算子类型进行运算，此处只有逻辑"或"运算
	always @ (*) begin
		if(rst == `RstEnable) begin
			logicout_real <= `ZeroWord;
		end else begin
			case (aluop_i)
				`EXE_OR_OP:			begin
					logicout_real <= reg1_i | reg2_i;
				end
				default:				begin
					logicout_real <= `ZeroWord;
				end
			endcase
		end    //if
	end      //always
	
	assign logicout = logicout_real;

//依据 alusel_i 指示的运算类型，选择一个运算结果作为最终结果,此处只有逻辑运算结果 
 always @ (*) begin
	 wd_o <= wd_i;	 	 	
	 wreg_o <= wreg_i;
	 case ( alusel_i ) 
	 	`EXE_RES_LOGIC:		begin
	 		wdata_o <= logicout;
	 	end
	 	default:					begin
	 		wdata_o <= `ZeroWord;
	 	end
	 endcase
 end	

endmodule
