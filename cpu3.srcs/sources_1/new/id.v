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
//
//
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module id(

	input wire						rst,
	input wire[`InstAddrBus]	   pc_i,//译码阶段的指令对应的地址
    input wire[`InstBus]          inst_i,//译码阶段的指令 32bit

    //处于执行阶段指令的运算子类型，用于解决load相关
    input wire[`AluOpBus]			ex_aluop_i,

	//处于执行阶段的指令要写入的目的寄存器信息
    input wire                    ex_wreg_i,//处于执行阶段的指令是否要写目的寄存器
    input wire[`RegBus]           ex_wdata_i,//处于执行阶段的指令要写的目的寄存器地址
    input wire[`RegAddrBus]       ex_wd_i,//处于执行阶段的指令要写入目的寄存器的数据
	
	//处于访存阶段的指令要写入的目的寄存器信息
    input wire                    mem_wreg_i,//处于访存阶段的指令是否要写目的寄存器
    input wire[`RegBus]           mem_wdata_i,//处于访存阶段的指令要写的目的寄存器地址
    input wire[`RegAddrBus]       mem_wd_i,//处于访存阶段的指令要写入目的寄存器的数据
	
	input wire[`RegBus]           reg1_data_i,//从 Regfile 输入的第一个读寄存器端口的输入
    input wire[`RegBus]           reg2_data_i,//从 Regfile 输入的第二个读寄存器端口的输入

	//如果上一条指令是转移指令，那么下一条指令在译码的时候is_in_delayslot为true
	input wire                    is_in_delayslot_i,

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
	output reg                    wreg_o,//译码阶段的指令是否有要写入的目的寄存器
	output wire[`RegBus]          inst_o,

	output reg                    next_inst_in_delayslot_o,//下一条进入译码阶段的指令是否位于延迟槽
	output reg                    branch_flag_o,//是否发生转移
	output reg[`RegBus]           branch_target_address_o,//转移到的目标地址     
	output reg[`RegBus]           link_addr_o,//转移指令要保存的返回地址
	output reg                    is_in_delayslot_o,//当前处于译码阶段的指令是否位于延迟槽

    output wire[31:0]             excepttype_o,//收集的异常信息 32bit
    output wire[`RegBus]          current_inst_address_o,//译码阶段指令的地址 32bit
	
	output wire                   stallreq	
);

    wire[5:0] op = inst_i[31:26];
    wire[4:0] op2 = inst_i[10:6];
    wire[5:0] op3 = inst_i[5:0];
    wire[4:0] op4 = inst_i[20:16];
    reg[`RegBus]	imm;
    reg instvalid;
    wire[`RegBus] pc_plus_8;
    wire[`RegBus] pc_plus_4;
    wire[`RegBus] imm_sll2_signedext;  
    
    // 新定义的一个变量，表示要读取的寄存器 1 是否与上一条指令存在 load 相关
    reg stallreq_for_reg1_loadrelate;
    // 新定义的一个变量，表示要读取的寄存器 2 是否与上一条指令存在 load 相关
    reg stallreq_for_reg2_loadrelate;
    // 新定义的一个变量，表示上一条指令是否是加载指令
    wire pre_inst_is_load;
    
    reg excepttype_is_syscall; // 是否是系统调用异常 syscall
    reg excepttype_is_eret; // 是否是异常返回指令 eret
  
    assign pc_plus_8 = pc_i + 8;//保存当前译码阶段指令后面第 2 条指令的地址
    assign pc_plus_4 = pc_i +4;//保存当前译码阶段指令后面紧接着的指令的地址
    // imm_sll2_signedext 对应分支指令中的 offset 左移两位，再符号扩展至 32 位的值
    assign imm_sll2_signedext = {{14{inst_i[15]}}, inst_i[15:0], 2'b00 };   

  
  // 依据输入信号 ex_aluop_i 的值，判断上一条指令是否是加载指令，
  // 如果是加载指令，那么置 pre_inst_is_load 为 1，反之置为 0
  assign pre_inst_is_load = ((ex_aluop_i == `EXE_LB_OP) || 
  													(ex_aluop_i == `EXE_LBU_OP)||
  													(ex_aluop_i == `EXE_LH_OP) ||
  													(ex_aluop_i == `EXE_LHU_OP)||
  													(ex_aluop_i == `EXE_LW_OP) ||
  													(ex_aluop_i == `EXE_LWR_OP)||
  													(ex_aluop_i == `EXE_LWL_OP)||
  													(ex_aluop_i == `EXE_LL_OP) ||
  													(ex_aluop_i == `EXE_SC_OP)) ? 1'b1 : 1'b0;

  assign inst_o = inst_i;

// excepttype_o 的低 8bit 留给外部中断，第 8bit 表示是否是 syscall 指令引起的
// 系统调用异常，第 9bit 表示是否是无效指令引起的异常，第 12bit 表示是否是 eret
// 指令， eret 指令可以认为是一种特殊的异常——返回异常
  assign excepttype_o = {19'b0,excepttype_is_eret,2'b0,
  												instvalid, excepttype_is_syscall,8'b0};

// 输入信号 pc_i 就是当前处于译码阶段的指令的地址
	assign current_inst_address_o = pc_i;
    
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
			link_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
			next_inst_in_delayslot_o <= `NotInDelaySlot;
			excepttype_is_syscall <= `False_v;
			excepttype_is_eret <= `False_v;								
	  end else begin
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= inst_i[15:11];
			wreg_o <= `WriteDisable;
			instvalid <= `InstInvalid;	   
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= inst_i[25:21];
			reg2_addr_o <= inst_i[20:16];		
			imm <= `ZeroWord;
			link_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;	
			next_inst_in_delayslot_o <= `NotInDelaySlot;
			excepttype_is_syscall <= `False_v;	
			excepttype_is_eret <= `False_v;					 			
		  case (op)
		    `EXE_SPECIAL_INST:		begin
		    	case (op2)
		    		5'b00000:			begin
		    			case (op3)
		    				`EXE_OR:	begin
		    					wreg_o <= `WriteEnable;		aluop_o <= `EXE_OR_OP;
		  						alusel_o <= `EXE_RES_LOGIC; 	reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end  
		    				`EXE_AND:	begin
		    					wreg_o <= `WriteEnable;		aluop_o <= `EXE_AND_OP;
		  						alusel_o <= `EXE_RES_LOGIC;	  reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	
		  						instvalid <= `InstValid;	
								end  	
		    				`EXE_XOR:	begin
		    					wreg_o <= `WriteEnable;		aluop_o <= `EXE_XOR_OP;
		  						alusel_o <= `EXE_RES_LOGIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	
		  						instvalid <= `InstValid;	
								end  				
		    				`EXE_NOR:	begin
		    					wreg_o <= `WriteEnable;		aluop_o <= `EXE_NOR_OP;
		  						alusel_o <= `EXE_RES_LOGIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	
		  						instvalid <= `InstValid;	
								end 
								`EXE_SLLV: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_SLL_OP;
		  						alusel_o <= `EXE_RES_SHIFT;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end 
								`EXE_SRLV: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_SRL_OP;
		  						alusel_o <= `EXE_RES_SHIFT;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end 					
								`EXE_SRAV: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_SRA_OP;
		  						alusel_o <= `EXE_RES_SHIFT;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;			
		  					end
								`EXE_MFHI: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_MFHI_OP;
		  						alusel_o <= `EXE_RES_MOVE;   reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
		  						instvalid <= `InstValid;	
								end
								`EXE_MFLO: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_MFLO_OP;
		  						alusel_o <= `EXE_RES_MOVE;   reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
		  						instvalid <= `InstValid;	
								end
								`EXE_MTHI: begin
									wreg_o <= `WriteDisable;		aluop_o <= `EXE_MTHI_OP;
		  						reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0; instvalid <= `InstValid;	
								end
								`EXE_MTLO: begin
									wreg_o <= `WriteDisable;		aluop_o <= `EXE_MTLO_OP;
		  						reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0; instvalid <= `InstValid;	
								end
								`EXE_MOVN: begin
									aluop_o <= `EXE_MOVN_OP;
		  						alusel_o <= `EXE_RES_MOVE;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;
								 	if(reg2_o != `ZeroWord) begin
	 									wreg_o <= `WriteEnable;
	 								end else begin
	 									wreg_o <= `WriteDisable;
	 								end
								end
								`EXE_MOVZ: begin
									aluop_o <= `EXE_MOVZ_OP;
		  						alusel_o <= `EXE_RES_MOVE;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;
								 	if(reg2_o == `ZeroWord) begin
	 									wreg_o <= `WriteEnable;
	 								end else begin
	 									wreg_o <= `WriteDisable;
	 								end		  							
								end
								`EXE_SLT: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_SLT_OP;
		  						alusel_o <= `EXE_RES_ARITHMETIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end
								`EXE_SLTU: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_SLTU_OP;
		  						alusel_o <= `EXE_RES_ARITHMETIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end
								`EXE_SYNC: begin
									wreg_o <= `WriteDisable;		aluop_o <= `EXE_NOP_OP;
		  						alusel_o <= `EXE_RES_NOP;		reg1_read_o <= 1'b0;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end								
								`EXE_ADD: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_ADD_OP;
		  						alusel_o <= `EXE_RES_ARITHMETIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end
								`EXE_ADDU: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_ADDU_OP;
		  						alusel_o <= `EXE_RES_ARITHMETIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end
								`EXE_SUB: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_SUB_OP;
		  						alusel_o <= `EXE_RES_ARITHMETIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end
								`EXE_SUBU: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_SUBU_OP;
		  						alusel_o <= `EXE_RES_ARITHMETIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end
								`EXE_MULT: begin
									wreg_o <= `WriteDisable;		aluop_o <= `EXE_MULT_OP;
		  						reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
								end
								`EXE_MULTU: begin
									wreg_o <= `WriteDisable;		aluop_o <= `EXE_MULTU_OP;
		  						reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
								end
								`EXE_DIV: begin
									wreg_o <= `WriteDisable;		aluop_o <= `EXE_DIV_OP;
		  						reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
								end
								`EXE_DIVU: begin
									wreg_o <= `WriteDisable;		aluop_o <= `EXE_DIVU_OP;
		  						reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
								end			
								`EXE_JR: begin
									wreg_o <= `WriteDisable;		aluop_o <= `EXE_JR_OP;
		  						alusel_o <= `EXE_RES_JUMP_BRANCH;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
		  						link_addr_o <= `ZeroWord;
		  						
			            	branch_target_address_o <= reg1_o;
			            	branch_flag_o <= `Branch;
			           
			            next_inst_in_delayslot_o <= `InDelaySlot;
			            instvalid <= `InstValid;	
								end
								`EXE_JALR: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_JALR_OP;
		  						alusel_o <= `EXE_RES_JUMP_BRANCH;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
		  						wd_o <= inst_i[15:11];
		  						link_addr_o <= pc_plus_8;
		  						
			            	branch_target_address_o <= reg1_o;
			            	branch_flag_o <= `Branch;
			           
			            next_inst_in_delayslot_o <= `InDelaySlot;
			            instvalid <= `InstValid;	
								end													 											  											
						    default:	begin
						    end
						  endcase
						 end
						default: begin
						end
					endcase	
          case (op3)
								`EXE_TEQ: begin
									wreg_o <= `WriteDisable;		aluop_o <= `EXE_TEQ_OP;
		  						alusel_o <= `EXE_RES_NOP;   reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
		  						instvalid <= `InstValid;
		  					end
		  					`EXE_TGE: begin
									wreg_o <= `WriteDisable;		aluop_o <= `EXE_TGE_OP;
		  						alusel_o <= `EXE_RES_NOP;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;
		  					end		
		  					`EXE_TGEU: begin
									wreg_o <= `WriteDisable;		aluop_o <= `EXE_TGEU_OP;
		  						alusel_o <= `EXE_RES_NOP;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;
		  					end	
		  					`EXE_TLT: begin
									wreg_o <= `WriteDisable;		aluop_o <= `EXE_TLT_OP;
		  						alusel_o <= `EXE_RES_NOP;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;
		  					end
		  					`EXE_TLTU: begin
									wreg_o <= `WriteDisable;		aluop_o <= `EXE_TLTU_OP;
		  						alusel_o <= `EXE_RES_NOP;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;
		  					end	
		  					`EXE_TNE: begin
									wreg_o <= `WriteDisable;		aluop_o <= `EXE_TNE_OP;
		  						alusel_o <= `EXE_RES_NOP;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;
		  					end
		  					`EXE_SYSCALL: begin
									wreg_o <= `WriteDisable;		aluop_o <= `EXE_SYSCALL_OP;
		  						alusel_o <= `EXE_RES_NOP;   reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
		  						instvalid <= `InstValid; excepttype_is_syscall<= `True_v;
		  					end							 																					
								default:	begin
								end	
					 endcase									
					end									  
		  	`EXE_ORI:			begin                        //ORI指令
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_OR_OP;
		  		alusel_o <= `EXE_RES_LOGIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {16'h0, inst_i[15:0]};		wd_o <= inst_i[20:16];
					instvalid <= `InstValid;	
		  	end
		  	`EXE_ANDI:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_AND_OP;
		  		alusel_o <= `EXE_RES_LOGIC;	reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {16'h0, inst_i[15:0]};		wd_o <= inst_i[20:16];		  	
					instvalid <= `InstValid;	
				end	 	
		  	`EXE_XORI:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_XOR_OP;
		  		alusel_o <= `EXE_RES_LOGIC;	reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {16'h0, inst_i[15:0]};		wd_o <= inst_i[20:16];		  	
					instvalid <= `InstValid;	
				end	 		
		  	`EXE_LUI:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_OR_OP;
		  		alusel_o <= `EXE_RES_LOGIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {inst_i[15:0], 16'h0};		wd_o <= inst_i[20:16];		  	
					instvalid <= `InstValid;	
				end			
				`EXE_SLTI:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_SLT_OP;
		  		alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};		wd_o <= inst_i[20:16];		  	
					instvalid <= `InstValid;	
				end
				`EXE_SLTIU:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_SLTU_OP;
		  		alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};		wd_o <= inst_i[20:16];		  	
					instvalid <= `InstValid;	
				end
				`EXE_PREF:			begin
		  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_NOP_OP;
		  		alusel_o <= `EXE_RES_NOP; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;	  	  	
					instvalid <= `InstValid;	
				end						
				`EXE_ADDI:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_ADDI_OP;
		  		alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};		wd_o <= inst_i[20:16];		  	
					instvalid <= `InstValid;	
				end
				`EXE_ADDIU:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_ADDIU_OP;
		  		alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};		wd_o <= inst_i[20:16];		  	
					instvalid <= `InstValid;	
				end
				`EXE_J:			begin
		  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_J_OP;
		  		alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
		  		link_addr_o <= `ZeroWord;
			    branch_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
			    branch_flag_o <= `Branch;
			    next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    instvalid <= `InstValid;	
				end
				`EXE_JAL:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_JAL_OP;
		  		alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
		  		wd_o <= 5'b11111;	
		  		link_addr_o <= pc_plus_8 ;
			    branch_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
			    branch_flag_o <= `Branch;
			    next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    instvalid <= `InstValid;	
				end
				`EXE_BEQ:			begin
		  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_BEQ_OP;
		  		alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  		instvalid <= `InstValid;	
		  		if(reg1_o == reg2_o) begin
			    	branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    	branch_flag_o <= `Branch;
			    	next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    end
				end
				`EXE_BGTZ:			begin
		  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_BGTZ_OP;
		  		alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
		  		instvalid <= `InstValid;	
		  		if((reg1_o[31] == 1'b0) && (reg1_o != `ZeroWord)) begin
			    	branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    	branch_flag_o <= `Branch;
			    	next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    end
				end
				`EXE_BLEZ:			begin
		  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_BLEZ_OP;
		  		alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
		  		instvalid <= `InstValid;	
		  		if((reg1_o[31] == 1'b1) || (reg1_o == `ZeroWord)) begin
			    	branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    	branch_flag_o <= `Branch;
			    	next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    end
				end
				`EXE_BNE:			begin
		  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_BLEZ_OP;
		  		alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  		instvalid <= `InstValid;	
		  		if(reg1_o != reg2_o) begin
			    	branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    	branch_flag_o <= `Branch;
			    	next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    end
				end
				`EXE_LB:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_LB_OP;
		  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
				end
				`EXE_LBU:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_LBU_OP;
		  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
				end
				`EXE_LH:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_LH_OP;
		  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
				end
				`EXE_LHU:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_LHU_OP;
		  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
				end
				`EXE_LW:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_LW_OP;
		  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
				end
				`EXE_LL:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_LL_OP;
		  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
				end
				`EXE_LWL:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_LWL_OP;
		  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	  	
					wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
				end
				`EXE_LWR:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_LWR_OP;
		  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	  	
					wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
				end			
				`EXE_SB:			begin
		  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_SB_OP;
		  		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
		  		alusel_o <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SH:			begin
		  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_SH_OP;
		  		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
		  		alusel_o <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SW:			begin
		  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_SW_OP;
		  		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
		  		alusel_o <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SWL:			begin
		  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_SWL_OP;
		  		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
		  		alusel_o <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SWR:			begin
		  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_SWR_OP;
		  		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
		  		alusel_o <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SC:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_SC_OP;
		  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	  	
					wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
					alusel_o <= `EXE_RES_LOAD_STORE; 
				end								
				`EXE_REGIMM_INST:		begin
					case (op4)
						`EXE_BGEZ:	begin
							wreg_o <= `WriteDisable;		aluop_o <= `EXE_BGEZ_OP;
		  				alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
		  				instvalid <= `InstValid;	
		  				if(reg1_o[31] == 1'b0) begin
			    			branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    			branch_flag_o <= `Branch;
			    			next_inst_in_delayslot_o <= `InDelaySlot;		  	
			   			end
						end
						`EXE_BGEZAL:		begin
							wreg_o <= `WriteEnable;		aluop_o <= `EXE_BGEZAL_OP;
		  				alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
		  				link_addr_o <= pc_plus_8; 
		  				wd_o <= 5'b11111;  	instvalid <= `InstValid;
		  				if(reg1_o[31] == 1'b0) begin
			    			branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    			branch_flag_o <= `Branch;
			    			next_inst_in_delayslot_o <= `InDelaySlot;
			   			end
						end
						`EXE_BLTZ:		begin
						  wreg_o <= `WriteDisable;		aluop_o <= `EXE_BGEZAL_OP;
		  				alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
		  				instvalid <= `InstValid;	
		  				if(reg1_o[31] == 1'b1) begin
			    			branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    			branch_flag_o <= `Branch;
			    			next_inst_in_delayslot_o <= `InDelaySlot;		  	
			   			end
						end
						`EXE_BLTZAL:		begin
							wreg_o <= `WriteEnable;		aluop_o <= `EXE_BGEZAL_OP;
		  				alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
		  				link_addr_o <= pc_plus_8;	
		  				wd_o <= 5'b11111; instvalid <= `InstValid;
		  				if(reg1_o[31] == 1'b1) begin
			    			branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    			branch_flag_o <= `Branch;
			    			next_inst_in_delayslot_o <= `InDelaySlot;
			   			end
						end
						`EXE_TEQI:			begin
		  				wreg_o <= `WriteDisable;		aluop_o <= `EXE_TEQI_OP;
		  				alusel_o <= `EXE_RES_NOP; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
							imm <= {{16{inst_i[15]}}, inst_i[15:0]};		  	
							instvalid <= `InstValid;	
						end
						`EXE_TGEI:			begin
		  				wreg_o <= `WriteDisable;		aluop_o <= `EXE_TGEI_OP;
		  				alusel_o <= `EXE_RES_NOP; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
							imm <= {{16{inst_i[15]}}, inst_i[15:0]};		  	
							instvalid <= `InstValid;	
						end
						`EXE_TGEIU:			begin
		  				wreg_o <= `WriteDisable;		aluop_o <= `EXE_TGEIU_OP;
		  				alusel_o <= `EXE_RES_NOP; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
							imm <= {{16{inst_i[15]}}, inst_i[15:0]};		  	
							instvalid <= `InstValid;	
						end
						`EXE_TLTI:			begin
		  				wreg_o <= `WriteDisable;		aluop_o <= `EXE_TLTI_OP;
		  				alusel_o <= `EXE_RES_NOP; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
							imm <= {{16{inst_i[15]}}, inst_i[15:0]};		  	
							instvalid <= `InstValid;	
						end
						`EXE_TLTIU:			begin
		  				wreg_o <= `WriteDisable;		aluop_o <= `EXE_TLTIU_OP;
		  				alusel_o <= `EXE_RES_NOP; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
							imm <= {{16{inst_i[15]}}, inst_i[15:0]};		  	
							instvalid <= `InstValid;	
						end
						`EXE_TNEI:			begin
		  				wreg_o <= `WriteDisable;		aluop_o <= `EXE_TNEI_OP;
		  				alusel_o <= `EXE_RES_NOP; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
							imm <= {{16{inst_i[15]}}, inst_i[15:0]};		  	
							instvalid <= `InstValid;	
						end						
						default:	begin
						end
					endcase
				end								
				`EXE_SPECIAL2_INST:		begin
					case ( op3 )
						`EXE_CLZ:		begin
							wreg_o <= `WriteEnable;		aluop_o <= `EXE_CLZ_OP;
		  				alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
							instvalid <= `InstValid;	
						end
						`EXE_CLO:		begin
							wreg_o <= `WriteEnable;		aluop_o <= `EXE_CLO_OP;
		  				alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
							instvalid <= `InstValid;	
						end
						`EXE_MUL:		begin
							wreg_o <= `WriteEnable;		aluop_o <= `EXE_MUL_OP;
		  				alusel_o <= `EXE_RES_MUL; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	
		  				instvalid <= `InstValid;	  			
						end
						`EXE_MADD:		begin
							wreg_o <= `WriteDisable;		aluop_o <= `EXE_MADD_OP;
		  				alusel_o <= `EXE_RES_MUL; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	  			
		  				instvalid <= `InstValid;	
						end
						`EXE_MADDU:		begin
							wreg_o <= `WriteDisable;		aluop_o <= `EXE_MADDU_OP;
		  				alusel_o <= `EXE_RES_MUL; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	  			
		  				instvalid <= `InstValid;	
						end
						`EXE_MSUB:		begin
							wreg_o <= `WriteDisable;		aluop_o <= `EXE_MSUB_OP;
		  				alusel_o <= `EXE_RES_MUL; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	  			
		  				instvalid <= `InstValid;	
						end
						`EXE_MSUBU:		begin
							wreg_o <= `WriteDisable;		aluop_o <= `EXE_MSUBU_OP;
		  				alusel_o <= `EXE_RES_MUL; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	  			
		  				instvalid <= `InstValid;	
						end						
						default:	begin
						end
					endcase      //EXE_SPECIAL_INST2 case
				end																		  	
		    default:			begin
		    end
		  endcase		  //case op
		  
		  if (inst_i[31:21] == 11'b00000000000) begin
		  	if (op3 == `EXE_SLL) begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_SLL_OP;
		  		alusel_o <= `EXE_RES_SHIFT; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b1;	  	
					imm[4:0] <= inst_i[10:6];		wd_o <= inst_i[15:11];
					instvalid <= `InstValid;	
				end else if ( op3 == `EXE_SRL ) begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_SRL_OP;
		  		alusel_o <= `EXE_RES_SHIFT; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b1;	  	
					imm[4:0] <= inst_i[10:6];		wd_o <= inst_i[15:11];
					instvalid <= `InstValid;	
				end else if ( op3 == `EXE_SRA ) begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_SRA_OP;
		  		alusel_o <= `EXE_RES_SHIFT; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b1;	  	
					imm[4:0] <= inst_i[10:6];		wd_o <= inst_i[15:11];
					instvalid <= `InstValid;	
				end
			end		  

     	if(inst_i == `EXE_ERET) begin
				wreg_o <= `WriteDisable;		aluop_o <= `EXE_ERET_OP;
		  	alusel_o <= `EXE_RES_NOP;   reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
		  	instvalid <= `InstValid; excepttype_is_eret<= `True_v;				
			end else if(inst_i[31:21] == 11'b01000000000 && 
										inst_i[10:0] == 11'b00000000000) begin
				aluop_o <= `EXE_MFC0_OP;
				alusel_o <= `EXE_RES_MOVE;
				wd_o <= inst_i[20:16];
				wreg_o <= `WriteEnable;
				instvalid <= `InstValid;	   
				reg1_read_o <= 1'b0;
				reg2_read_o <= 1'b0;		
			end else if(inst_i[31:21] == 11'b01000000100 && 
										inst_i[10:0] == 11'b00000000000) begin
				aluop_o <= `EXE_MTC0_OP;
				alusel_o <= `EXE_RES_NOP;
				wreg_o <= `WriteDisable;
				instvalid <= `InstValid;	   
				reg1_read_o <= 1'b1;
				reg1_addr_o <= inst_i[20:16];
				reg2_read_o <= 1'b0;					
			end
		  
		end       //if
	end         //always
	
	
//为解决数据相关问题，给 reg1_o 赋值的过程增加了两种情况：
//1．如果 Regfile 模块读端口 1 要读取的寄存器就是执行阶段要写的目的寄存器，
// 那么直接把执行阶段的结果 ex_wdata_i 作为 reg1_o 的值;
//2．如果 Regfile 模块读端口 1 要读取的寄存器就是访存阶段要写的目的寄存器，
// 那么直接把访存阶段的结果 mem_wdata_i 作为 reg1_o 的值;

// 为解决load相关问题，如果上一条指令是加载指令，且该加载指令要加载到的目的寄存器就是当前指令
// 要通过 Regfile 模块读端口 1 读取的通用寄存器，那么表示存在 load 相关，
// 设置 stallreq_for_reg1_loadrelate 为 Stop
	always @ (*) begin
			stallreq_for_reg1_loadrelate <= `NoStop;	
		if(rst == `RstEnable) begin
			reg1_o <= `ZeroWord;	
		end else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg1_addr_o 
								&& reg1_read_o == 1'b1 ) begin
		  stallreq_for_reg1_loadrelate <= `Stop;							
		end else if((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) 
								&& (ex_wd_i == reg1_addr_o)) begin
			reg1_o <= ex_wdata_i; 
		end else if((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) 
								&& (mem_wd_i == reg1_addr_o)) begin
			reg1_o <= mem_wdata_i; 			
	  end else if(reg1_read_o == 1'b1) begin
	  	reg1_o <= reg1_data_i;
	  end else if(reg1_read_o == 1'b0) begin
	  	reg1_o <= imm;
	  end else begin
	    reg1_o <= `ZeroWord;
	  end
	end
	
	// 如果上一条指令是加载指令，且该加载指令要加载到的目的寄存器就是当前指令
    // 要通过 Regfile 模块读端口 2 读取的通用寄存器，那么表示存在 load 相关，
    // 设置 stallreq_for_reg2_loadrelate 为 Stop
	always @ (*) begin
			stallreq_for_reg2_loadrelate <= `NoStop;
		if(rst == `RstEnable) begin
			reg2_o <= `ZeroWord;
		end else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg2_addr_o 
								&& reg2_read_o == 1'b1 ) begin
		  stallreq_for_reg2_loadrelate <= `Stop;			
		end else if((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) 
								&& (ex_wd_i == reg2_addr_o)) begin
			reg2_o <= ex_wdata_i; 
		end else if((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) 
								&& (mem_wd_i == reg2_addr_o)) begin
			reg2_o <= mem_wdata_i;			
	  end else if(reg2_read_o == 1'b1) begin
	  	reg2_o <= reg2_data_i;
	  end else if(reg2_read_o == 1'b0) begin
	  	reg2_o <= imm;
	  end else begin
	    reg2_o <= `ZeroWord;
	  end
	end
	
    assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;	

// 输出变量 is_in_delayslot_o 表示当前译码阶段指令是否是延迟槽指令
	always @ (*) begin
		if(rst == `RstEnable) begin
			is_in_delayslot_o <= `NotInDelaySlot;
		end else begin
		  is_in_delayslot_o <= is_in_delayslot_i;		
	  end
	end

endmodule