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

`include "defines.v"

module ex(

	input wire										rst,
	
	//送到执行阶段的信息
	input wire[`AluOpBus]         aluop_i,//3bit 执行阶段要进行的运算的类型
    input wire[`AluSelBus]        alusel_i,//8bit 执行阶段要进行的运算的子类型
    input wire[`RegBus]           reg1_i,//源操作数1
    input wire[`RegBus]           reg2_i,//源操作数2
    input wire[`RegAddrBus]       wd_i,//指令执行要写入的目的寄存器地址 5bit
    input wire                    wreg_i,//是否有要写入的目的寄存器
	input wire[`RegBus]           inst_i,
	input wire[31:0]              excepttype_i,//译码阶段收集到的异常信息
	input wire[`RegBus]          current_inst_address_i,//执行阶段指令的地址
	
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

	input wire[`DoubleRegBus]     hilo_temp_i,
	input wire[1:0]               cnt_i,

	//与除法模块相连
    input wire[`DoubleRegBus]     div_result_i,//除法运算结果 64bit
    input wire                    div_ready_i,	//除法运算是否结束

	//是否转移、以及link address
	input wire[`RegBus]           link_address_i,
	input wire                    is_in_delayslot_i,	

	//访存阶段的指令是否要写CP0，用来检测数据相关
    input wire                    mem_cp0_reg_we,
	input wire[4:0]               mem_cp0_reg_write_addr,
	input wire[`RegBus]           mem_cp0_reg_data,
	
	//回写阶段的指令是否要写CP0，用来检测数据相关
    input wire                    wb_cp0_reg_we,
	input wire[4:0]               wb_cp0_reg_write_addr,
	input wire[`RegBus]           wb_cp0_reg_data,

	//与CP0相连，读取其中CP0寄存器的值
	input wire[`RegBus]           cp0_reg_data_i,
	output reg[4:0]               cp0_reg_read_addr_o,

	//向下一流水级传递，用于写CP0中的寄存器
	output reg                    cp0_reg_we_o,
	output reg[4:0]               cp0_reg_write_addr_o,
	output reg[`RegBus]           cp0_reg_data_o,
	
	output reg[`RegAddrBus]       wd_o,//执行阶段的指令最终要写入的目的寄存器地址 5bit
    output reg                    wreg_o,//执行阶段的指令最终是否有要写入的目的寄存器 1bit
    output reg[`RegBus]           wdata_o,//执行阶段的指令最终要写入目的寄存器的值 32bit

	output reg[`RegBus]           hi_o,
	output reg[`RegBus]           lo_o,
	output reg                    whilo_o,
	
    output reg[`DoubleRegBus]     hilo_temp_o,//第一个执行周期得到的乘法结果
    output reg[1:0]               cnt_o,//下一个时钟周期处于执行阶段的第几个时钟周期

    output reg[`RegBus]           div_opdata1_o,//被除数
    output reg[`RegBus]           div_opdata2_o,//除数
    output reg                    div_start_o,//是否开始除法运算
    output reg                    signed_div_o,//是否是有符号除法，为 1 表示是有符号除法

	//下面新增的几个输出是为加载、存储指令准备的
	output wire[`AluOpBus]        aluop_o,
	output wire[`RegBus]          mem_addr_o,
	output wire[`RegBus]          reg2_o,
	
	output wire[31:0]             excepttype_o,//译码阶段、执行阶段收集到的异常信息
	output wire                   is_in_delayslot_o,//执行阶段的指令是否是延迟槽指令
	output wire[`RegBus]          current_inst_address_o,	//执行阶段指令的地址

	output reg					stallreq       			
	
);

	reg[`RegBus] logicout;
	reg[`RegBus] shiftres;// 保存移位运算结果
    reg[`RegBus] moveres;// 移动操作的结果
    reg[`RegBus] arithmeticres;// 保存算术运算的结果
    reg[`DoubleRegBus] mulres;// 保存乘法结果，宽度为 64 位
    reg[`RegBus] HI;// 保存 HI 寄存器的最新值
    reg[`RegBus] LO;// 保存 LO 寄存器的最新值
	wire[`RegBus] reg2_i_mux;// 保存输入的第二个操作数 reg2_i 的补码
    wire[`RegBus] reg1_i_not;// 保存输入的第一个操作数 reg1_i 取反后的值  
	wire[`RegBus] result_sum;
	wire ov_sum;
    wire reg1_eq_reg2;// 第一个操作数是否等于第二个操作数
    wire reg1_lt_reg2;// 第一个操作数是否小于第二个操作数
    wire[`RegBus] opdata1_mult;// 乘法操作中的被乘数
    wire[`RegBus] opdata2_mult;// 乘法操作中的乘数
    wire[`DoubleRegBus] hilo_temp;// 临时保存乘法结果，宽度为 64 位      
	reg[`DoubleRegBus] hilo_temp1;
	reg stallreq_for_madd_msub;			
	reg stallreq_for_div;
    reg trapassert; // 新定义变量，表示是否有自陷异常
    reg ovassert; // 新定义变量，表示是否有溢出异常

  //aluop_o传递到访存阶段，用于加载、存储指令
  assign aluop_o = aluop_i;
  
  //mem_addr传递到访存阶段，是加载、存储指令对应的存储器地址
  assign mem_addr_o = reg1_i + {{16{inst_i[15]}},inst_i[15:0]};

  //将两个操作数也传递到访存阶段，也是为记载、存储指令准备的
  assign reg2_o = reg2_i;
 
 // 执行阶段输出的异常信息就是译码阶段的异常信息加上自陷异常、溢出异常的信息，
  // 其中第 10bit 表示是否有自陷异常，第 11bit 表示是否有溢出异常
  assign excepttype_o = {excepttype_i[31:12],ovassert,trapassert,excepttype_i[9:8],8'h00};
  
	assign is_in_delayslot_o = is_in_delayslot_i;
	
	// 当前处于执行阶段指令的地址
	assign current_inst_address_o = current_inst_address_i;

	always @ (*) begin
		if(rst == `RstEnable) begin
			logicout <= `ZeroWord;
		end else begin
			case (aluop_i)
				`EXE_OR_OP:			begin
					logicout <= reg1_i | reg2_i;
				end
				`EXE_AND_OP:		begin
					logicout <= reg1_i & reg2_i;
				end
				`EXE_NOR_OP:		begin
					logicout <= ~(reg1_i |reg2_i);
				end
				`EXE_XOR_OP:		begin
					logicout <= reg1_i ^ reg2_i;
				end
				default:				begin
					logicout <= `ZeroWord;
				end
			endcase
		end    //if
	end      //always

	always @ (*) begin
		if(rst == `RstEnable) begin
			shiftres <= `ZeroWord;
		end else begin
			case (aluop_i)
				`EXE_SLL_OP:			begin
					shiftres <= reg2_i << reg1_i[4:0] ;
				end
				`EXE_SRL_OP:		begin
					shiftres <= reg2_i >> reg1_i[4:0];
				end
				`EXE_SRA_OP:		begin
					shiftres <= ({32{reg2_i[31]}} << (6'd32-{1'b0, reg1_i[4:0]})) 
												| reg2_i >> reg1_i[4:0];
				end
				default:				begin
					shiftres <= `ZeroWord;
				end
			endcase
		end    //if
	end      //always

//（1）如果是减法或者有符号比较运算，那么 reg2_i_mux 等于第二个操作数
// reg2_i 的补码，否则 reg2_i_mux 就等于第二个操作数 reg2_i   
	assign reg2_i_mux = ((aluop_i == `EXE_SUB_OP) || (aluop_i == `EXE_SUBU_OP) ||
											 (aluop_i == `EXE_SLT_OP)|| (aluop_i == `EXE_TLT_OP) ||
	                       (aluop_i == `EXE_TLTI_OP) || (aluop_i == `EXE_TGE_OP) ||
	                       (aluop_i == `EXE_TGEI_OP)) 
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
	assign reg1_lt_reg2 = ((aluop_i == `EXE_SLT_OP) || (aluop_i == `EXE_TLT_OP) ||
	                       (aluop_i == `EXE_TLTI_OP) || (aluop_i == `EXE_TGE_OP) ||
	                       (aluop_i == `EXE_TGEI_OP)) ?
												 ((reg1_i[31] && !reg2_i[31]) || 
												 (!reg1_i[31] && !reg2_i[31] && result_sum[31])||
			                   (reg1_i[31] && reg2_i[31] && result_sum[31]))
			                   :	(reg1_i < reg2_i);
  
  assign reg1_i_not = ~reg1_i;
							
	always @ (*) begin
		if(rst == `RstEnable) begin
			arithmeticres <= `ZeroWord;
		end else begin
			case (aluop_i)
				`EXE_SLT_OP, `EXE_SLTU_OP:		begin
					arithmeticres <= reg1_lt_reg2 ;
				end
				`EXE_ADD_OP, `EXE_ADDU_OP, `EXE_ADDI_OP, `EXE_ADDIU_OP:		begin
					arithmeticres <= result_sum; 
				end
				`EXE_SUB_OP, `EXE_SUBU_OP:		begin
					arithmeticres <= result_sum; 
				end		
				`EXE_CLZ_OP:		begin
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
				`EXE_CLO_OP:		begin
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
				default:				begin
					arithmeticres <= `ZeroWord;
				end
			endcase
		end
	end

	always @ (*) begin
		if(rst == `RstEnable) begin
			trapassert <= `TrapNotAssert;
		end else begin
			trapassert <= `TrapNotAssert;
			case (aluop_i)
				`EXE_TEQ_OP, `EXE_TEQI_OP:		begin
					if( reg1_i == reg2_i ) begin
						trapassert <= `TrapAssert;
					end
				end
				`EXE_TGE_OP, `EXE_TGEI_OP, `EXE_TGEIU_OP, `EXE_TGEU_OP:		begin
					if( ~reg1_lt_reg2 ) begin
						trapassert <= `TrapAssert;
					end
				end
				`EXE_TLT_OP, `EXE_TLTI_OP, `EXE_TLTIU_OP, `EXE_TLTU_OP:		begin
					if( reg1_lt_reg2 ) begin
						trapassert <= `TrapAssert;
					end
				end
				`EXE_TNE_OP, `EXE_TNEI_OP:		begin
					if( reg1_i != reg2_i ) begin
						trapassert <= `TrapAssert;
					end
				end
				default:				begin
					trapassert <= `TrapNotAssert;
				end
			endcase
		end
	end

  //取得乘法操作的操作数，如果是有符号除法且操作数是负数，那么取反加一
	assign opdata1_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP) ||
													(aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MSUB_OP))
													&& (reg1_i[31] == 1'b1)) ? (~reg1_i + 1) : reg1_i;
//取得乘法运算的乘数，如果是有符号乘法且乘数是负数，那么取补码    
  assign opdata2_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP) ||
													(aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MSUB_OP))
													&& (reg2_i[31] == 1'b1)) ? (~reg2_i + 1) : reg2_i;	

  assign hilo_temp = opdata1_mult * opdata2_mult;																				

//（4.1）对临时乘法结果进行修正，最终的乘法结果保存在变量 mulres 中，主要有两点：
// A．如果是有符号乘法指令 mult、 mul，那么需要修正临时乘法结果，如下：
// A1．如果被乘数与乘数两者一正一负，那么需要对临时乘法结果
// hilo_temp 求补码，作为最终的乘法结果，赋给变量 mulres。
// A2．如果被乘数与乘数同号，那么 hilo_temp 的值就作为最终的
// 乘法结果，赋给变量 mulres。
// B．如果是无符号乘法指令 multu，那么 hilo_temp 的值就作为最终的乘法结果,
// 赋给变量 mulres    

//（4.2）对临时乘法结果进行修正，最终的乘法结果保存在变量 mulres 中，有两种情况：
// A．如果是有符号乘法运算 madd、 msub，那么需要修正临时乘法结果，如下：
// A1．如果被乘数与乘数两者一正一负，那么需要对临时乘法结果
// hilo_temp 求补码，作为最终的乘法结果，赋给变量 mulres。
// A2．如果被乘数与乘数同号，那么 hilo_temp 的值就作为 mulres
// 的值。
// B．如果是无符号乘法运算 maddu、 msubu，那么 hilo_temp 的值就作为
// 最终的乘法结果，赋给变量 mulres
	always @ (*) begin
		if(rst == `RstEnable) begin
			mulres <= {`ZeroWord,`ZeroWord};
		end else if ((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MUL_OP) ||
									(aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MSUB_OP))begin
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

  always @ (*) begin
    stallreq = stallreq_for_madd_msub || stallreq_for_div;
  end

  //MADD、MADDU、MSUB、MSUBU指令
	always @ (*) begin
		if(rst == `RstEnable) begin
			hilo_temp_o <= {`ZeroWord,`ZeroWord};
			cnt_o <= 2'b00;
			stallreq_for_madd_msub <= `NoStop;
		end else begin
			
			case (aluop_i) 
				`EXE_MADD_OP, `EXE_MADDU_OP:		begin
					if(cnt_i == 2'b00) begin
						hilo_temp_o <= mulres;
						cnt_o <= 2'b01;
						stallreq_for_madd_msub <= `Stop;
						hilo_temp1 <= {`ZeroWord,`ZeroWord};
					end else if(cnt_i == 2'b01) begin
						hilo_temp_o <= {`ZeroWord,`ZeroWord};						
						cnt_o <= 2'b10;
						hilo_temp1 <= hilo_temp_i + {HI,LO};
						stallreq_for_madd_msub <= `NoStop;
					end
				end
				`EXE_MSUB_OP, `EXE_MSUBU_OP:		begin
					if(cnt_i == 2'b00) begin
						hilo_temp_o <=  ~mulres + 1 ;
						cnt_o <= 2'b01;
						stallreq_for_madd_msub <= `Stop;
					end else if(cnt_i == 2'b01)begin
						hilo_temp_o <= {`ZeroWord,`ZeroWord};						
						cnt_o <= 2'b10;
						hilo_temp1 <= hilo_temp_i + {HI,LO};
						stallreq_for_madd_msub <= `NoStop;
					end				
				end
				default:	begin
					hilo_temp_o <= {`ZeroWord,`ZeroWord};
					cnt_o <= 2'b00;
					stallreq_for_madd_msub <= `NoStop;				
				end
			endcase
		end
	end	

  //DIV、DIVU指令	
	always @ (*) begin
		if(rst == `RstEnable) begin
			stallreq_for_div <= `NoStop;
	    div_opdata1_o <= `ZeroWord;
			div_opdata2_o <= `ZeroWord;
			div_start_o <= `DivStop;
			signed_div_o <= 1'b0;
		end else begin
			stallreq_for_div <= `NoStop;
	    div_opdata1_o <= `ZeroWord;
			div_opdata2_o <= `ZeroWord;
			div_start_o <= `DivStop;
			signed_div_o <= 1'b0;	
			case (aluop_i) 
				`EXE_DIV_OP:		begin
					if(div_ready_i == `DivResultNotReady) begin
	    			div_opdata1_o <= reg1_i;
						div_opdata2_o <= reg2_i;
						div_start_o <= `DivStart;
						signed_div_o <= 1'b1;
						stallreq_for_div <= `Stop;
					end else if(div_ready_i == `DivResultReady) begin
	    			div_opdata1_o <= reg1_i;
						div_opdata2_o <= reg2_i;
						div_start_o <= `DivStop;
						signed_div_o <= 1'b1;
						stallreq_for_div <= `NoStop;
					end else begin						
	    			div_opdata1_o <= `ZeroWord;
						div_opdata2_o <= `ZeroWord;
						div_start_o <= `DivStop;
						signed_div_o <= 1'b0;
						stallreq_for_div <= `NoStop;
					end					
				end
				`EXE_DIVU_OP:		begin
					if(div_ready_i == `DivResultNotReady) begin
	    			div_opdata1_o <= reg1_i;
						div_opdata2_o <= reg2_i;
						div_start_o <= `DivStart;
						signed_div_o <= 1'b0;
						stallreq_for_div <= `Stop;
					end else if(div_ready_i == `DivResultReady) begin
	    			div_opdata1_o <= reg1_i;
						div_opdata2_o <= reg2_i;
						div_start_o <= `DivStop;
						signed_div_o <= 1'b0;
						stallreq_for_div <= `NoStop;
					end else begin						
	    			div_opdata1_o <= `ZeroWord;
						div_opdata2_o <= `ZeroWord;
						div_start_o <= `DivStop;
						signed_div_o <= 1'b0;
						stallreq_for_div <= `NoStop;
					end					
				end
				default: begin
				end
			endcase
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
	   		moveres <= HI;
	   	end
	   	`EXE_MFLO_OP:		begin
	   		moveres <= LO;
	   	end
	   	`EXE_MOVZ_OP:		begin
	   		moveres <= reg1_i;
	   	end
	   	`EXE_MOVN_OP:		begin
	   		moveres <= reg1_i;
	   	end
	   	`EXE_MFC0_OP:		begin
	   	  cp0_reg_read_addr_o <= inst_i[15:11];//要从CP0中读取的寄存器的地址
	   		moveres <= cp0_reg_data_i;//读取到的CP0中指定寄存器的值
	   		//判断是否存在数据相关
	   		if( mem_cp0_reg_we == `WriteEnable &&
	   				  mem_cp0_reg_write_addr == inst_i[15:11] ) begin
	   				moveres <= mem_cp0_reg_data;//与访存阶段存在数据相关
	   		end else if( wb_cp0_reg_we == `WriteEnable &&
	   				 							 wb_cp0_reg_write_addr == inst_i[15:11] ) begin
	   				moveres <= wb_cp0_reg_data;//与回写阶段存在数据相关
	   		end
	   	end	   	
	   	default : begin
	   	end
	   endcase
	  end
	end	 

 always @ (*) begin
	 wd_o <= wd_i;
	 	 	 	
	 if(((aluop_i == `EXE_ADD_OP) || (aluop_i == `EXE_ADDI_OP) || 
	      (aluop_i == `EXE_SUB_OP)) && (ov_sum == 1'b1)) begin
	 	wreg_o <= `WriteDisable;
	 	ovassert <= 1'b1;//发生了溢出异常
	 end else begin
	  wreg_o <= wreg_i;
	  ovassert <= 1'b0;//没有发生溢出异常
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
	 	`EXE_RES_ARITHMETIC:	begin
	 		wdata_o <= arithmeticres;
	 	end
	 	`EXE_RES_MUL:		begin
	 		wdata_o <= mulres[31:0];
	 	end	 	
	 	`EXE_RES_JUMP_BRANCH:	begin
	 		wdata_o <= link_address_i;
	 	end	 	
	 	default:					begin
	 		wdata_o <= `ZeroWord;
	 	end
	 endcase
 end	

	always @ (*) begin
		if(rst == `RstEnable) begin
			whilo_o <= `WriteDisable;
			hi_o <= `ZeroWord;
			lo_o <= `ZeroWord;		
		end else if((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MULTU_OP)) begin
			whilo_o <= `WriteEnable;
			hi_o <= mulres[63:32];
			lo_o <= mulres[31:0];			
		end else if((aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MADDU_OP)) begin
			whilo_o <= `WriteEnable;
			hi_o <= hilo_temp1[63:32];
			lo_o <= hilo_temp1[31:0];
		end else if((aluop_i == `EXE_MSUB_OP) || (aluop_i == `EXE_MSUBU_OP)) begin
			whilo_o <= `WriteEnable;
			hi_o <= hilo_temp1[63:32];
			lo_o <= hilo_temp1[31:0];		
		end else if((aluop_i == `EXE_DIV_OP) || (aluop_i == `EXE_DIVU_OP)) begin
			whilo_o <= `WriteEnable;
			hi_o <= div_result_i[63:32];
			lo_o <= div_result_i[31:0];							
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

	always @ (*) begin
		if(rst == `RstEnable) begin
			cp0_reg_write_addr_o <= 5'b00000;
			cp0_reg_we_o <= `WriteDisable;
			cp0_reg_data_o <= `ZeroWord;
		end else if(aluop_i == `EXE_MTC0_OP) begin
			cp0_reg_write_addr_o <= inst_i[15:11];
			cp0_reg_we_o <= `WriteEnable;
			cp0_reg_data_o <= reg1_i;
	  end else begin
			cp0_reg_write_addr_o <= 5'b00000;
			cp0_reg_we_o <= `WriteDisable;
			cp0_reg_data_o <= `ZeroWord;
		end				
	end		

endmodule