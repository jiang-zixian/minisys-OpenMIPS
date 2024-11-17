`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/07 11:43:55
// Design Name: 
// Module Name: regfile
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
// 译码阶段：将对取到的指令进行译码：给出要进行的运算类型，以及参与运算的操作数。译码阶段包括 Regfile、ID 和 ID/EX 三个模块。
// regfile模块，实现了 32 个 32 位通用整数寄存器，可以同时进行两个寄存器的读操作和一个寄存器的写操作
// 回写阶段其实就实现在regfile模块
//////////////////////////////////////////////////////////////////////////////////
`include "Define.v"

module regfile(

	input wire					clk,
	input wire					rst,
	
	//写端口
	input wire							we,//写使能信号
	input wire[`RegAddrBus]				waddr,//要写入的寄存器地址
	input wire[`RegBus]					wdata,//要写入的数据
	
	//读端口1
	input wire							re1,//第一个读寄存器端口读使能信号
	input wire[`RegAddrBus]			    raddr1,//第一个读寄存器端口要读取的寄存器的地址
	output reg[`RegBus]                rdata1,//第一个读寄存器端口输出的寄存器值
	
	//读端口2
	input wire							re2,//第二个读寄存器端口读使能信号
	input wire[`RegAddrBus]			    raddr2,//第二个读寄存器端口要读取的寄存器的地址
	output reg[`RegBus]                 rdata2//第二个读寄存器端口输出的寄存器值
	
);

//一、定义 32 个 32 位寄存器
	reg[`RegBus]  regs[0:`RegNum-1];

//二、写操作 
	always @ (posedge clk) begin//写操作只发生在时钟信号的上升沿
		if (rst == `RstDisable) begin
			if((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin//写操作目的寄存器不可以等于0
				//之所以要判断目的寄存器不为 0，是因为 MIPS32 架构规定$0 的值只能为 0，所以不要写入
				regs[waddr] <= wdata;
			end
		end
	end

//三、读端口 1 的读操作	
	always @ (*) begin
		if(rst == `RstEnable) begin
			  rdata1 <= `ZeroWord;
	  end else if(raddr1 == `RegNumLog2'h0) begin//`define RegNumLog2 5 寻址通用寄存器使用的地址位数
	  		rdata1 <= `ZeroWord;//如果读取的是$0，那么直接给出0
	  end else if((raddr1 == waddr) && (we == `WriteEnable) 
	  //这里可以解决相隔两条指令的数据相关问题，可见书籍P110
	  	            && (re1 == `ReadEnable)) begin//如果第一个读寄存器端口要读取的目标寄存器与要写入的目的寄存器是同一个寄存器，那么直接将要写入的值作为第一个读寄存器端口的输出
	  	  rdata1 <= wdata;
	  end else if(re1 == `ReadEnable) begin//以上都不满足，那么从raddr1处读值赋给对应寄存器
	      rdata1 <= regs[raddr1];
	  end else begin
	      rdata1 <= `ZeroWord;
	  end
	end

//四、读端口 2 的读操作	
	always @ (*) begin//一旦要输入的raddr1和raddr2发生变化，那么立即给出新地址对应的寄存器的值
		if(rst == `RstEnable) begin
			  rdata2 <= `ZeroWord;
	  end else if(raddr2 == `RegNumLog2'h0) begin
	  		rdata2 <= `ZeroWord;
	  end else if((raddr2 == waddr) && (we == `WriteEnable) 
	  	            && (re2 == `ReadEnable)) begin
	  	  rdata2 <= wdata;
	  end else if(re2 == `ReadEnable) begin
	      rdata2 <= regs[raddr2];
	  end else begin
	      rdata2 <= `ZeroWord;
	  end
	end

endmodule