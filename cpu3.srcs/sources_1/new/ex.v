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
// EX ģ���� ID/EX ģ��õ���
// ������ alusel_i������������ aluop_i��Դ������ reg1_i��Դ������ reg2_i��Ҫд��Ŀ�ļĴ�����ַ wd_i
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module ex(

	input wire										rst,
	
	//�͵�ִ�н׶ε���Ϣ
	input wire[`AluOpBus]         aluop_i,//3bit ִ�н׶�Ҫ���е����������
    input wire[`AluSelBus]        alusel_i,//8bit ִ�н׶�Ҫ���е������������
    input wire[`RegBus]           reg1_i,//Դ������1
    input wire[`RegBus]           reg2_i,//Դ������2
    input wire[`RegAddrBus]       wd_i,//ָ��ִ��Ҫд���Ŀ�ļĴ�����ַ 5bit
    input wire                    wreg_i,//�Ƿ���Ҫд���Ŀ�ļĴ���
	input wire[`RegBus]           inst_i,
	input wire[31:0]              excepttype_i,//����׶��ռ������쳣��Ϣ
	input wire[`RegBus]          current_inst_address_i,//ִ�н׶�ָ��ĵ�ַ
	
	//HI��LO�Ĵ�����ֵ
	input wire[`RegBus]           hi_i,
	input wire[`RegBus]           lo_i,

	//��д�׶ε�ָ���Ƿ�ҪдHI��LO�����ڼ��HI��LO���������
	input wire[`RegBus]           wb_hi_i,
	input wire[`RegBus]           wb_lo_i,
	input wire                    wb_whilo_i,
	
	//�ô�׶ε�ָ���Ƿ�ҪдHI��LO�����ڼ��HI��LO���������
	input wire[`RegBus]           mem_hi_i,
	input wire[`RegBus]           mem_lo_i,
	input wire                    mem_whilo_i,

	input wire[`DoubleRegBus]     hilo_temp_i,
	input wire[1:0]               cnt_i,

	//�����ģ������
    input wire[`DoubleRegBus]     div_result_i,//���������� 64bit
    input wire                    div_ready_i,	//���������Ƿ����

	//�Ƿ�ת�ơ��Լ�link address
	input wire[`RegBus]           link_address_i,
	input wire                    is_in_delayslot_i,	

	//�ô�׶ε�ָ���Ƿ�ҪдCP0����������������
    input wire                    mem_cp0_reg_we,
	input wire[4:0]               mem_cp0_reg_write_addr,
	input wire[`RegBus]           mem_cp0_reg_data,
	
	//��д�׶ε�ָ���Ƿ�ҪдCP0����������������
    input wire                    wb_cp0_reg_we,
	input wire[4:0]               wb_cp0_reg_write_addr,
	input wire[`RegBus]           wb_cp0_reg_data,

	//��CP0��������ȡ����CP0�Ĵ�����ֵ
	input wire[`RegBus]           cp0_reg_data_i,
	output reg[4:0]               cp0_reg_read_addr_o,

	//����һ��ˮ�����ݣ�����дCP0�еļĴ���
	output reg                    cp0_reg_we_o,
	output reg[4:0]               cp0_reg_write_addr_o,
	output reg[`RegBus]           cp0_reg_data_o,
	
	output reg[`RegAddrBus]       wd_o,//ִ�н׶ε�ָ������Ҫд���Ŀ�ļĴ�����ַ 5bit
    output reg                    wreg_o,//ִ�н׶ε�ָ�������Ƿ���Ҫд���Ŀ�ļĴ��� 1bit
    output reg[`RegBus]           wdata_o,//ִ�н׶ε�ָ������Ҫд��Ŀ�ļĴ�����ֵ 32bit

	output reg[`RegBus]           hi_o,
	output reg[`RegBus]           lo_o,
	output reg                    whilo_o,
	
    output reg[`DoubleRegBus]     hilo_temp_o,//��һ��ִ�����ڵõ��ĳ˷����
    output reg[1:0]               cnt_o,//��һ��ʱ�����ڴ���ִ�н׶εĵڼ���ʱ������

    output reg[`RegBus]           div_opdata1_o,//������
    output reg[`RegBus]           div_opdata2_o,//����
    output reg                    div_start_o,//�Ƿ�ʼ��������
    output reg                    signed_div_o,//�Ƿ����з��ų�����Ϊ 1 ��ʾ���з��ų���

	//���������ļ��������Ϊ���ء��洢ָ��׼����
	output wire[`AluOpBus]        aluop_o,
	output wire[`RegBus]          mem_addr_o,
	output wire[`RegBus]          reg2_o,
	
	output wire[31:0]             excepttype_o,//����׶Ρ�ִ�н׶��ռ������쳣��Ϣ
	output wire                   is_in_delayslot_o,//ִ�н׶ε�ָ���Ƿ����ӳٲ�ָ��
	output wire[`RegBus]          current_inst_address_o,	//ִ�н׶�ָ��ĵ�ַ

	output reg					stallreq       			
	
);

	reg[`RegBus] logicout;
	reg[`RegBus] shiftres;// ������λ������
    reg[`RegBus] moveres;// �ƶ������Ľ��
    reg[`RegBus] arithmeticres;// ������������Ľ��
    reg[`DoubleRegBus] mulres;// ����˷���������Ϊ 64 λ
    reg[`RegBus] HI;// ���� HI �Ĵ���������ֵ
    reg[`RegBus] LO;// ���� LO �Ĵ���������ֵ
	wire[`RegBus] reg2_i_mux;// ��������ĵڶ��������� reg2_i �Ĳ���
    wire[`RegBus] reg1_i_not;// ��������ĵ�һ�������� reg1_i ȡ�����ֵ  
	wire[`RegBus] result_sum;
	wire ov_sum;
    wire reg1_eq_reg2;// ��һ���������Ƿ���ڵڶ���������
    wire reg1_lt_reg2;// ��һ���������Ƿ�С�ڵڶ���������
    wire[`RegBus] opdata1_mult;// �˷������еı�����
    wire[`RegBus] opdata2_mult;// �˷������еĳ���
    wire[`DoubleRegBus] hilo_temp;// ��ʱ����˷���������Ϊ 64 λ      
	reg[`DoubleRegBus] hilo_temp1;
	reg stallreq_for_madd_msub;			
	reg stallreq_for_div;
    reg trapassert; // �¶����������ʾ�Ƿ��������쳣
    reg ovassert; // �¶����������ʾ�Ƿ�������쳣

  //aluop_o���ݵ��ô�׶Σ����ڼ��ء��洢ָ��
  assign aluop_o = aluop_i;
  
  //mem_addr���ݵ��ô�׶Σ��Ǽ��ء��洢ָ���Ӧ�Ĵ洢����ַ
  assign mem_addr_o = reg1_i + {{16{inst_i[15]}},inst_i[15:0]};

  //������������Ҳ���ݵ��ô�׶Σ�Ҳ��Ϊ���ء��洢ָ��׼����
  assign reg2_o = reg2_i;
 
 // ִ�н׶�������쳣��Ϣ��������׶ε��쳣��Ϣ���������쳣������쳣����Ϣ��
  // ���е� 10bit ��ʾ�Ƿ��������쳣���� 11bit ��ʾ�Ƿ�������쳣
  assign excepttype_o = {excepttype_i[31:12],ovassert,trapassert,excepttype_i[9:8],8'h00};
  
	assign is_in_delayslot_o = is_in_delayslot_i;
	
	// ��ǰ����ִ�н׶�ָ��ĵ�ַ
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

//��1������Ǽ��������з��űȽ����㣬��ô reg2_i_mux ���ڵڶ���������
// reg2_i �Ĳ��룬���� reg2_i_mux �͵��ڵڶ��������� reg2_i   
	assign reg2_i_mux = ((aluop_i == `EXE_SUB_OP) || (aluop_i == `EXE_SUBU_OP) ||
											 (aluop_i == `EXE_SLT_OP)|| (aluop_i == `EXE_TLT_OP) ||
	                       (aluop_i == `EXE_TLTI_OP) || (aluop_i == `EXE_TGE_OP) ||
	                       (aluop_i == `EXE_TGEI_OP)) 
											 ? (~reg2_i)+1 : reg2_i;

 //��2�������������
 // A������Ǽӷ����㣬��ʱ reg2_i_mux ���ǵڶ��������� reg2_i��
 // ���� result_sum ���Ǽӷ�����Ľ��
 // B������Ǽ������㣬��ʱ reg2_i_mux �ǵڶ��������� reg2_i �Ĳ��룬
 // ���� result_sum ���Ǽ�������Ľ��
 // C��������з��űȽ����㣬��ʱ reg2_i_mux Ҳ�ǵڶ��������� reg2_i
 // �Ĳ��룬���� result_sum Ҳ�Ǽ�������Ľ��������ͨ���жϼ���
 // �Ľ���Ƿ�С���㣬�����жϵ�һ�������� reg1_i �Ƿ�С�ڵڶ�����
 // ���� reg2_i
	assign result_sum = reg1_i + reg2_i_mux;										 

//��3�������Ƿ�������ӷ�ָ�add �� addi��������ָ�sub��ִ�е�ʱ��
// ��Ҫ�ж��Ƿ���������������������֮һʱ���������
// A�� reg1_i Ϊ������ reg2_i_mux Ϊ��������������֮��Ϊ����
// B�� reg1_i Ϊ������ reg2_i_mux Ϊ��������������֮��Ϊ����
	assign ov_sum = ((!reg1_i[31] && !reg2_i_mux[31]) && result_sum[31]) ||
									((reg1_i[31] && reg2_i_mux[31]) && (!result_sum[31]));  
		
//��4����������� 1 �Ƿ�С�ڲ����� 2�������������
                                    // A�� aluop_i Ϊ EXE_SLT_OP ��ʾ�з��űȽ����㣬��ʱ�ַ� 3 �����
                                    // A1�� reg1_i Ϊ������ reg2_i Ϊ��������Ȼ reg1_i С�� reg2_i
                                    // A2�� reg1_i Ϊ������ reg2_i Ϊ���������� reg1_i ��ȥ reg2_i ��ֵС�� 0
                                    // ���� result_sum Ϊ��������ʱҲ�� reg1_i С�� reg2_i
                                    // A3�� reg1_i Ϊ������ reg2_i Ϊ���������� reg1_i ��ȥ reg2_i ��ֵС�� 0
                                    // ���� result_sum Ϊ��������ʱҲ�� reg1_i С�� reg2_i
                                    // B���޷������Ƚϵ�ʱ��ֱ��ʹ�ñȽ�������Ƚ� reg1_i �� reg2_i   									
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

  //ȡ�ó˷������Ĳ�������������з��ų����Ҳ������Ǹ�������ôȡ����һ
	assign opdata1_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP) ||
													(aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MSUB_OP))
													&& (reg1_i[31] == 1'b1)) ? (~reg1_i + 1) : reg1_i;
//ȡ�ó˷�����ĳ�����������з��ų˷��ҳ����Ǹ�������ôȡ����    
  assign opdata2_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP) ||
													(aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MSUB_OP))
													&& (reg2_i[31] == 1'b1)) ? (~reg2_i + 1) : reg2_i;	

  assign hilo_temp = opdata1_mult * opdata2_mult;																				

//��4.1������ʱ�˷�����������������յĳ˷���������ڱ��� mulres �У���Ҫ�����㣺
// A��������з��ų˷�ָ�� mult�� mul����ô��Ҫ������ʱ�˷���������£�
// A1��������������������һ��һ������ô��Ҫ����ʱ�˷����
// hilo_temp ���룬��Ϊ���յĳ˷�������������� mulres��
// A2����������������ͬ�ţ���ô hilo_temp ��ֵ����Ϊ���յ�
// �˷�������������� mulres��
// B��������޷��ų˷�ָ�� multu����ô hilo_temp ��ֵ����Ϊ���յĳ˷����,
// �������� mulres    

//��4.2������ʱ�˷�����������������յĳ˷���������ڱ��� mulres �У������������
// A��������з��ų˷����� madd�� msub����ô��Ҫ������ʱ�˷���������£�
// A1��������������������һ��һ������ô��Ҫ����ʱ�˷����
// hilo_temp ���룬��Ϊ���յĳ˷�������������� mulres��
// A2����������������ͬ�ţ���ô hilo_temp ��ֵ����Ϊ mulres
// ��ֵ��
// B��������޷��ų˷����� maddu�� msubu����ô hilo_temp ��ֵ����Ϊ
// ���յĳ˷�������������� mulres
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

  //�õ����µ�HI��LO�Ĵ�����ֵ���˴�Ҫ���ָ�������������
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

  //MADD��MADDU��MSUB��MSUBUָ��
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

  //DIV��DIVUָ��	
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

	//MFHI��MFLO��MOVN��MOVZָ��
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
	   	  cp0_reg_read_addr_o <= inst_i[15:11];//Ҫ��CP0�ж�ȡ�ļĴ����ĵ�ַ
	   		moveres <= cp0_reg_data_i;//��ȡ����CP0��ָ���Ĵ�����ֵ
	   		//�ж��Ƿ�����������
	   		if( mem_cp0_reg_we == `WriteEnable &&
	   				  mem_cp0_reg_write_addr == inst_i[15:11] ) begin
	   				moveres <= mem_cp0_reg_data;//��ô�׶δ����������
	   		end else if( wb_cp0_reg_we == `WriteEnable &&
	   				 							 wb_cp0_reg_write_addr == inst_i[15:11] ) begin
	   				moveres <= wb_cp0_reg_data;//���д�׶δ����������
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
	 	ovassert <= 1'b1;//����������쳣
	 end else begin
	  wreg_o <= wreg_i;
	  ovassert <= 1'b0;//û�з�������쳣
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