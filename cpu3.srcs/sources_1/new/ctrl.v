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

`include "defines.v"

module ctrl(

	input wire										rst,

	input wire[31:0]             excepttype_i,//最终的异常类型
	input wire[`RegBus]          cp0_epc_i,//EPC寄存器的最新值

	input wire                   stallreq_from_id,//处于译码阶段的指令是否请求流水线暂停

  //来自执行阶段的暂停请求
	input wire                   stallreq_from_ex,

	output reg[`RegBus]          new_pc,//异常处理入口地址
	output reg                   flush,	//1bit 是否清除流水线
	output reg[5:0]              stall    
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
			flush <= 1'b0;
			new_pc <= `ZeroWord;
		end else if(excepttype_i != `ZeroWord) begin
		  flush <= 1'b1;
		  stall <= 6'b000000;
			case (excepttype_i)
				32'h00000001:		begin   //interrupt
					new_pc <= 32'h00000020;
				end
				32'h00000008:		begin   //syscall
					new_pc <= 32'h00000040;
				end
				32'h0000000a:		begin   //inst_invalid
					new_pc <= 32'h00000040;
				end
				32'h0000000d:		begin   //trap
					new_pc <= 32'h00000040;
				end
				32'h0000000c:		begin   //ov 溢出
					new_pc <= 32'h00000040;
				end
				32'h0000000e:		begin   //eret 异常返回指令
					new_pc <= cp0_epc_i;
				end
				default	: begin
				end
			endcase 						
		end else if(stallreq_from_ex == `Stop) begin
			stall <= 6'b001111;
			flush <= 1'b0;		
		end else if(stallreq_from_id == `Stop) begin
			stall <= 6'b000111;	
			flush <= 1'b0;		
		end else begin
			stall <= 6'b000000;
			flush <= 1'b0;
			new_pc <= `ZeroWord;		
		end    //if
	end      //always
			

endmodule