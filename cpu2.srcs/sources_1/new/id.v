`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/07 12:24:22
// Design Name: 
// Module Name: id
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
// ID 模块的作用是对指令进行译码，得到最终运算的类型、子类型、源操作数 1、源操作
// 数 2、要写入的目的寄存器地址等信息，其中运算类型指的是逻辑运算、移位运算、算术运算
// 等，子类型指的是更加详细的运算类型，比如：当运算类型是逻辑运算时，运算子类型可以是
// 逻辑"或"运算、逻辑"与"运算、逻辑"异或"运算等。
//////////////////////////////////////////////////////////////////////////////////
`include "Define.v"

module id(
	input wire					   rst,
	input wire[`InstAddrBus]	   pc_i,//译码阶段的指令对应的地址
	input wire[`InstBus]          inst_i,//译码阶段的指令 32bit

	input wire[`RegBus]           reg1_data_i,//从 Regfile 输入的第一个读寄存器端口的输入
	input wire[`RegBus]           reg2_data_i,//从 Regfile 输入的第二个读寄存器端口的输入

	//送到regfile的信息
	output reg                    reg1_read_o,//regfile 模块的第一个读寄存器端口的读使能信号
	output reg                    reg2_read_o,//regfile 模块的第二个读寄存器端口的读使能信号
	output reg[`RegAddrBus]       reg1_addr_o,//Regfile 模块的第一个读寄存器端口的读地址信号 5bit
	output reg[`RegAddrBus]       reg2_addr_o,//Regfile 模块的第二个读寄存器端口的读地址信号 5bit 	      
	
	//送到执行阶段的信息
	output reg[`AluOpBus]         aluop_o,//译码阶段的指令要进行的运算的子类型 8bit
	output reg[`AluSelBus]        alusel_o,//译码阶段的指令要进行的运算的类型 3bit
	output reg[`RegBus]           reg1_o,//译码阶段的指令要进行的运算的源操作数1
	output reg[`RegBus]           reg2_o,//译码阶段的指令要进行的运算的源操作数2
	output reg[`RegAddrBus]       wd_o,//译码阶段的指令要写入的目的寄存器地址 5bit
	output reg                    wreg_o//译码阶段的指令是否有要写入的目的寄存器
);
// 取得指令的指令码，功能码
// 对于 ori 指令只需通过判断第 26-31bit 的值，即可判断是否是 ori 指令
  wire[5:0] op = inst_i[31:26];
  wire[4:0] op2 = inst_i[10:6];
  wire[5:0] op3 = inst_i[5:0];
  wire[4:0] op4 = inst_i[20:16];
  
  // 保存指令执行需要的立即数
  reg[`RegBus]	imm;
  
  // 指示指令是否有效
  reg instvalid;
  
 //一、对指令进行译码 
	always @ (*) begin	
		if (rst == `RstEnable) begin
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
			instvalid <= `InstValid;
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= `NOPRegAddr;
			reg2_addr_o <= `NOPRegAddr;
			imm <= 32'h0;			
	  end else begin
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= inst_i[15:11];
			wreg_o <= `WriteDisable;
			instvalid <= `InstInvalid;	   
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= inst_i[25:21];// 默认通过 Regfile 读端口 1 读取的寄存器地址
			reg2_addr_o <= inst_i[20:16];// 默认通过 Regfile 读端口 2 读取的寄存器地址		
			imm <= `ZeroWord;			
		  case (op)
		  	`EXE_ORI:			begin                        //ORI指令
		  	    //ori指令需要将结果写入目的寄存器
		  		wreg_o <= `WriteEnable;
		  		//运算的子类型是逻辑或		
		  		aluop_o <= `EXE_OR_OP;
		  		//运算的类型是 逻辑运算
		  		alusel_o <= `EXE_RES_LOGIC;
		  		//需要通过regfile的读端口1读取寄存器
		  		reg1_read_o <= 1'b1;	
		  		//不需要通过regfile的读端口2读取寄存器
		  		reg2_read_o <= 1'b0;	
		  		//指令执行需要的立即数  	
				imm <= {16'h0, inst_i[15:0]};		
				//指令执行要写的目的寄存器地址
				wd_o <= inst_i[20:16];
				//ori指令是有效指令
				instvalid <= `InstValid;	
		  	end 							 
		    default:			begin
		    end
		  endcase		  //case op			
		end       //if
	end         //always
	
//二、确定进行运算的源操作数 1 
	always @ (*) begin
		if(rst == `RstEnable) begin
			reg1_o <= `ZeroWord;
	  end else if(reg1_read_o == 1'b1) begin
	  	reg1_o <= reg1_data_i;
	  end else if(reg1_read_o == 1'b0) begin
	  	reg1_o <= imm;
	  end else begin
	    reg1_o <= `ZeroWord;
	  end
	end
	
	//三、确定进行运算的源操作数 2
	always @ (*) begin
		if(rst == `RstEnable) begin
			reg2_o <= `ZeroWord;
	  end else if(reg2_read_o == 1'b1) begin
	  	reg2_o <= reg2_data_i;
	  end else if(reg2_read_o == 1'b0) begin
	  	reg2_o <= imm;
	  end else begin
	    reg2_o <= `ZeroWord;
	  end
	end

endmodule