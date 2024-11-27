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

    //HI、LO寄存器的值
	input wire[`RegBus]           hi_i,
	input wire[`RegBus]           lo_i,

	//回写阶段的指令是否要写HI、LO，用于检测HI、LO的数据相关
	input wire[`RegBus]           wb_hi_i,
	input wire[`RegBus]           wb_lo_i,
	input wire                    wb_whilo_i,
	
	//访存阶段的指令是否要写HI、LO，用于检测HI、LO的数据相关
	input wire[`RegBus]           mem_hi_i,
	input wire[`RegBus]           mem_lo_i,
	input wire                    mem_whilo_i,
	
	output reg[`RegAddrBus]       wd_o,//执行阶段的指令最终要写入的目的寄存器地址 5bit
	output reg                    wreg_o,//执行阶段的指令最终是否有要写入的目的寄存器 1bit
	output reg[`RegBus]	    	   wdata_o,//执行阶段的指令最终要写入目的寄存器的值 32bit
	
	// 处于执行阶段的指令对 HI、 LO 寄存器的写操作请求
    output reg[`RegBus]           hi_o,
    output reg[`RegBus]           lo_o,
    output reg                    whilo_o,    
	
	// 保存逻辑运算的结果
    output    wire[`RegBus] logicout,
    
    output    wire[`RegBus]           reg1_i_out
	
);

// 保存逻辑运算的结果
	reg[`RegBus] logicout_real;
	
	// 保存移位运算结果
	reg[`RegBus] shiftres;
	
	reg[`RegBus] moveres;// 移动操作的结果
    reg[`RegBus] HI;// 保存 HI 寄存器的最新值
    reg[`RegBus] LO;// 保存 LO 寄存器的最新值
	
	//一、依据 aluop_i 指示的运算子类型进行运算
	always @ (*) begin
		if(rst == `RstEnable) begin
			logicout_real <= `ZeroWord;
		end else begin
			case (aluop_i)
				`EXE_OR_OP:			begin
					logicout_real <= reg1_i | reg2_i;
				end
				`EXE_AND_OP:		begin
                    logicout_real <= reg1_i & reg2_i;
                end
                `EXE_NOR_OP:        begin
                    logicout_real <= ~(reg1_i |reg2_i);
                end
                `EXE_XOR_OP:        begin
                    logicout_real <= reg1_i ^ reg2_i;
                end
				default:				begin
					logicout_real <= `ZeroWord;
				end
			endcase
		end    //if
	end      //always
	
	assign logicout = logicout_real;
	
	//移位运算结果
	always @ (*) begin
            if(rst == `RstEnable) begin
                shiftres <= `ZeroWord;
            end else begin
                case (aluop_i)
                    `EXE_SLL_OP:            begin
                        shiftres <= reg2_i << reg1_i[4:0] ;
                    end
                    `EXE_SRL_OP:        begin
                        shiftres <= reg2_i >> reg1_i[4:0];
                    end
                    `EXE_SRA_OP:        begin
                        shiftres <= ({32{reg2_i[31]}} << (6'd32-{1'b0, reg1_i[4:0]})) 
                                                    | reg2_i >> reg1_i[4:0];
                    end
                    default:                begin
                        shiftres <= `ZeroWord;
                    end
                endcase
            end    //if
        end      //always
        
    //得到最新的HI、LO寄存器的值，此处要解决指令数据相关问题
        always @ (*) begin
            if(rst == `RstEnable) begin
                {HI,LO} <= {`ZeroWord,`ZeroWord};
            end else if(mem_whilo_i == `WriteEnable) begin
                {HI,LO} <= {mem_hi_i,mem_lo_i};
            end else if(wb_whilo_i == `WriteEnable) begin
                {HI,LO} <= {wb_hi_i,wb_lo_i};
            end else begin
                {HI,LO} <= {hi_i,lo_i};            
            end
        end    

    //MFHI、MFLO、MOVN、MOVZ指令
	always @ (*) begin
		if(rst == `RstEnable) begin
	  	moveres <= `ZeroWord;
	  end else begin
	   moveres <= `ZeroWord;
	   case (aluop_i)
	   	`EXE_MFHI_OP:		begin
	   		moveres <= HI;// 如果是 mfhi 指令，那么将 HI 的值作为移动操作的结果
	   	end
	   	`EXE_MFLO_OP:		begin
	   		moveres <= LO;// 如果是 mflo 指令，那么将 LO 的值作为移动操作的结果
	   	end
	   	`EXE_MOVZ_OP:		begin
	   		moveres <= reg1_i;// 如果是 movz 指令，那么将 reg1_i 的值作为移动操作的结果
	   	end
	   	`EXE_MOVN_OP:		begin
	   		moveres <= reg1_i;// 如果是 movn 指令，那么将 reg1_i 的值作为移动操作的结果
	   	end
	   	default : begin
	   	end
	   endcase
	  end
	end	 

//依据 alusel_i 指示的运算类型，选择一个运算结果作为最终结果,此处只有逻辑运算结果 
 always @ (*) begin
	 wd_o <= wd_i;	 	 	
	 wreg_o <= wreg_i;
	 case ( alusel_i ) 
	 	`EXE_RES_LOGIC:		begin
	 		wdata_o <= logicout;
	 	end
	 	`EXE_RES_SHIFT:		begin
            wdata_o <= shiftres;
        end     
	 	`EXE_RES_MOVE:		begin
            wdata_o <= moveres;
        end             
	 	default:					begin
	 		wdata_o <= `ZeroWord;
	 	end
	 endcase
 end	
 
 //如果是 MTHI、 MTLO 指令，那么需要给出 whilo_o、 hi_o、 lo_i 的值
 
 //确定是否要写 HI、 LO 寄存器，如果是 mthi、 mtlo 寄存器，那么
 //要写 HI、 LO 寄存器，所以设置输出信号 whilo_o 为 WriteEnable
    always @ (*) begin
         if(rst == `RstEnable) begin
             whilo_o <= `WriteDisable;
             hi_o <= `ZeroWord;
             lo_o <= `ZeroWord;        
         end else if(aluop_i == `EXE_MTHI_OP) begin
             whilo_o <= `WriteEnable;
             hi_o <= reg1_i;
             lo_o <= LO;
         end else if(aluop_i == `EXE_MTLO_OP) begin
             whilo_o <= `WriteEnable;
             hi_o <= HI;
             lo_o <= reg1_i;
         end else begin
             whilo_o <= `WriteDisable;
             hi_o <= `ZeroWord;
             lo_o <= `ZeroWord;
         end                
     end           
     
     assign reg1_i_out=reg1_i; 

endmodule
