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
	
	reg[`RegBus] shiftres;// 保存移位运算结果
	reg[`RegBus] moveres;// 移动操作的结果
    reg[`RegBus] HI;// 保存 HI 寄存器的最新值
    reg[`RegBus] LO;// 保存 LO 寄存器的最新值
    
    reg[`RegBus] arithmeticres;// 保存算术运算的结果
    reg[`DoubleRegBus] mulres;// 保存乘法结果，宽度为 64 位
	wire[`RegBus] reg2_i_mux;// 保存输入的第二个操作数 reg2_i 的补码
    wire[`RegBus] reg1_i_not;// 保存输入的第一个操作数 reg1_i 取反后的值    
    wire[`RegBus] result_sum;
    wire ov_sum;
    wire reg1_eq_reg2;// 第一个操作数是否等于第二个操作数
    wire reg1_lt_reg2;// 第一个操作数是否小于第二个操作数
    wire[`RegBus] opdata1_mult;// 乘法操作中的被乘数
    wire[`RegBus] opdata2_mult;// 乘法操作中的乘数
    wire[`DoubleRegBus] hilo_temp;// 临时保存乘法结果，宽度为 64 位        
	
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
       
//（1）如果是减法或者有符号比较运算，那么 reg2_i_mux 等于第二个操作数
// reg2_i 的补码，否则 reg2_i_mux 就等于第二个操作数 reg2_i        
	assign reg2_i_mux = ((aluop_i == `EXE_SUB_OP) || (aluop_i == `EXE_SUBU_OP) ||
                                                 (aluop_i == `EXE_SLT_OP) ) 
                                                 ? (~reg2_i)+1 : reg2_i;
    
 //（2）分三种情况：
 // A．如果是加法运算，此时 reg2_i_mux 就是第二个操作数 reg2_i，
 // 所以 result_sum 就是加法运算的结果
 // B．如果是减法运算，此时 reg2_i_mux 是第二个操作数 reg2_i 的补码，
 // 所以 result_sum 就是减法运算的结果
 // C．如果是有符号比较运算，此时 reg2_i_mux 也是第二个操作数 reg2_i
 // 的补码，所以 result_sum 也是减法运算的结果，可以通过判断减法
 // 的结果是否小于零，进而判断第一个操作数 reg1_i 是否小于第二个操
 // 作数 reg2_i
    assign result_sum = reg1_i + reg2_i_mux;                                         

//（3）计算是否溢出，加法指令（add 和 addi）、减法指令（sub）执行的时候，
// 需要判断是否溢出，满足以下两种情况之一时，有溢出：
// A． reg1_i 为正数， reg2_i_mux 为正数，但是两者之和为负数
// B． reg1_i 为负数， reg2_i_mux 为负数，但是两者之和为正数
    assign ov_sum = ((!reg1_i[31] && !reg2_i_mux[31]) && result_sum[31]) ||
                                    ((reg1_i[31] && reg2_i_mux[31]) && (!result_sum[31]));  
        
//（4）计算操作数 1 是否小于操作数 2，分两种情况：
// A． aluop_i 为 EXE_SLT_OP 表示有符号比较运算，此时又分 3 种情况
// A1． reg1_i 为负数、 reg2_i 为正数，显然 reg1_i 小于 reg2_i
// A2． reg1_i 为正数、 reg2_i 为正数，并且 reg1_i 减去 reg2_i 的值小于 0
// （即 result_sum 为负），此时也有 reg1_i 小于 reg2_i
// A3． reg1_i 为负数、 reg2_i 为负数，并且 reg1_i 减去 reg2_i 的值小于 0
// （即 result_sum 为负），此时也有 reg1_i 小于 reg2_i
// B、无符号数比较的时候，直接使用比较运算符比较 reg1_i 与 reg2_i                                    
    assign reg1_lt_reg2 = ((aluop_i == `EXE_SLT_OP)) ?
                                                 ((reg1_i[31] && !reg2_i[31]) || 
                                                 (!reg1_i[31] && !reg2_i[31] && result_sum[31])||
                               (reg1_i[31] && reg2_i[31] && result_sum[31]))
                               :    (reg1_i < reg2_i);
                               
//（5）对操作数 1 逐位取反，赋给 reg1_i_not  
    assign reg1_i_not = ~reg1_i;
      
//依据不同的算术运算类型，给 arithmeticres 变量赋值                                
    always @ (*) begin
        if(rst == `RstEnable) begin
            arithmeticres <= `ZeroWord;
        end else begin
            case (aluop_i)
                `EXE_SLT_OP, `EXE_SLTU_OP:        begin
                    arithmeticres <= reg1_lt_reg2 ;
                end
                `EXE_ADD_OP, `EXE_ADDU_OP, `EXE_ADDI_OP, `EXE_ADDIU_OP:        begin
                    arithmeticres <= result_sum; 
                end
                `EXE_SUB_OP, `EXE_SUBU_OP:        begin
                    arithmeticres <= result_sum; 
                end        
                `EXE_CLZ_OP:        begin
                    arithmeticres <= reg1_i[31] ? 0 : reg1_i[30] ? 1 : reg1_i[29] ? 2 :
                                                     reg1_i[28] ? 3 : reg1_i[27] ? 4 : reg1_i[26] ? 5 :
                                                     reg1_i[25] ? 6 : reg1_i[24] ? 7 : reg1_i[23] ? 8 : 
                                                     reg1_i[22] ? 9 : reg1_i[21] ? 10 : reg1_i[20] ? 11 :
                                                     reg1_i[19] ? 12 : reg1_i[18] ? 13 : reg1_i[17] ? 14 : 
                                                     reg1_i[16] ? 15 : reg1_i[15] ? 16 : reg1_i[14] ? 17 : 
                                                     reg1_i[13] ? 18 : reg1_i[12] ? 19 : reg1_i[11] ? 20 :
                                                     reg1_i[10] ? 21 : reg1_i[9] ? 22 : reg1_i[8] ? 23 : 
                                                     reg1_i[7] ? 24 : reg1_i[6] ? 25 : reg1_i[5] ? 26 : 
                                                     reg1_i[4] ? 27 : reg1_i[3] ? 28 : reg1_i[2] ? 29 : 
                                                     reg1_i[1] ? 30 : reg1_i[0] ? 31 : 32 ;
                end
                `EXE_CLO_OP:        begin
                    arithmeticres <= (reg1_i_not[31] ? 0 : reg1_i_not[30] ? 1 : reg1_i_not[29] ? 2 :
                                                     reg1_i_not[28] ? 3 : reg1_i_not[27] ? 4 : reg1_i_not[26] ? 5 :
                                                     reg1_i_not[25] ? 6 : reg1_i_not[24] ? 7 : reg1_i_not[23] ? 8 : 
                                                     reg1_i_not[22] ? 9 : reg1_i_not[21] ? 10 : reg1_i_not[20] ? 11 :
                                                     reg1_i_not[19] ? 12 : reg1_i_not[18] ? 13 : reg1_i_not[17] ? 14 : 
                                                     reg1_i_not[16] ? 15 : reg1_i_not[15] ? 16 : reg1_i_not[14] ? 17 : 
                                                     reg1_i_not[13] ? 18 : reg1_i_not[12] ? 19 : reg1_i_not[11] ? 20 :
                                                     reg1_i_not[10] ? 21 : reg1_i_not[9] ? 22 : reg1_i_not[8] ? 23 : 
                                                     reg1_i_not[7] ? 24 : reg1_i_not[6] ? 25 : reg1_i_not[5] ? 26 : 
                                                     reg1_i_not[4] ? 27 : reg1_i_not[3] ? 28 : reg1_i_not[2] ? 29 : 
                                                     reg1_i_not[1] ? 30 : reg1_i_not[0] ? 31 : 32) ;
                end
                default:                begin
                    arithmeticres <= `ZeroWord;
                end
            endcase
        end
    end
    
//（1）取得乘法运算的被乘数，如果是有符号乘法且被乘数是负数，那么取补码
        assign opdata1_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP))
                                                        && (reg1_i[31] == 1'b1)) ? (~reg1_i + 1) : reg1_i;
//（2）取得乘法运算的乘数，如果是有符号乘法且乘数是负数，那么取补码    
      assign opdata2_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP))
                                                        && (reg2_i[31] == 1'b1)) ? (~reg2_i + 1) : reg2_i;        
//（3）得到临时乘法结果，保存在变量 hilo_temp 中    
      assign hilo_temp = opdata1_mult * opdata2_mult;                                                                                
    
//（4）对临时乘法结果进行修正，最终的乘法结果保存在变量 mulres 中，主要有两点：
// A．如果是有符号乘法指令 mult、 mul，那么需要修正临时乘法结果，如下：
// A1．如果被乘数与乘数两者一正一负，那么需要对临时乘法结果
// hilo_temp 求补码，作为最终的乘法结果，赋给变量 mulres。
// A2．如果被乘数与乘数同号，那么 hilo_temp 的值就作为最终的
// 乘法结果，赋给变量 mulres。
// B．如果是无符号乘法指令 multu，那么 hilo_temp 的值就作为最终的乘法结果,
// 赋给变量 mulres    
        always @ (*) begin
            if(rst == `RstEnable) begin
                mulres <= {`ZeroWord,`ZeroWord};
            end else if ((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MUL_OP))begin
                if(reg1_i[31] ^ reg2_i[31] == 1'b1) begin
                    mulres <= ~hilo_temp + 1;
                end else begin
                  mulres <= hilo_temp;
                end
            end else begin
                    mulres <= hilo_temp;
            end
        end        
        
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
	 
     // 如果是 add、 addi、 sub、 subi 指令，且发生溢出，那么设置 wreg_o 为
     // WriteDisable，表示不写目的寄存器	 
	 if(((aluop_i == `EXE_ADD_OP) || (aluop_i == `EXE_ADDI_OP) || 
          (aluop_i == `EXE_SUB_OP)) && (ov_sum == 1'b1)) begin
         wreg_o <= `WriteDisable;
     end else begin
      wreg_o <= wreg_i;
     end	 
	 
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
        `EXE_RES_ARITHMETIC:	begin//除乘法外的简单算术操作指令
             wdata_o <= arithmeticres;
         end
         `EXE_RES_MUL:        begin//乘法
             wdata_o <= mulres[31:0];
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
		end else if((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MULTU_OP)) begin
                 whilo_o <= `WriteEnable;
                 hi_o <= mulres[63:32];
                 lo_o <= mulres[31:0];                 
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
