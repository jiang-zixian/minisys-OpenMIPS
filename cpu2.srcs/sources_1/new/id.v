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
// ID ģ��������Ƕ�ָ��������룬�õ�������������͡������͡�Դ������ 1��Դ����
// �� 2��Ҫд���Ŀ�ļĴ�����ַ����Ϣ��������������ָ�����߼����㡢��λ���㡢��������
// �ȣ�������ָ���Ǹ�����ϸ���������ͣ����磺�������������߼�����ʱ�����������Ϳ�����
// �߼�"��"���㡢�߼�"��"���㡢�߼�"���"����ȡ�
//////////////////////////////////////////////////////////////////////////////////
`include "Define.v"

module id(
	input wire					   rst,
	input wire[`InstAddrBus]	   pc_i,//����׶ε�ָ���Ӧ�ĵ�ַ
	input wire[`InstBus]          inst_i,//����׶ε�ָ�� 32bit
	
	//����ִ�н׶ε�ָ��Ҫд���Ŀ�ļĴ�����Ϣ
    input wire                    ex_wreg_i,//����ִ�н׶ε�ָ���Ƿ�ҪдĿ�ļĴ���
    input wire[`RegBus]           ex_wdata_i,//����ִ�н׶ε�ָ��Ҫд��Ŀ�ļĴ�����ַ
    input wire[`RegAddrBus]       ex_wd_i,//����ִ�н׶ε�ָ��Ҫд��Ŀ�ļĴ���������
    
    //���ڷô�׶ε�ָ��Ҫд���Ŀ�ļĴ�����Ϣ
    input wire                    mem_wreg_i,//���ڷô�׶ε�ָ���Ƿ�ҪдĿ�ļĴ���
    input wire[`RegBus]           mem_wdata_i,//���ڷô�׶ε�ָ��Ҫд��Ŀ�ļĴ�����ַ
    input wire[`RegAddrBus]       mem_wd_i,//���ڷô�׶ε�ָ��Ҫд��Ŀ�ļĴ���������

	input wire[`RegBus]           reg1_data_i,//�� Regfile ����ĵ�һ�����Ĵ����˿ڵ�����
	input wire[`RegBus]           reg2_data_i,//�� Regfile ����ĵڶ������Ĵ����˿ڵ�����

	//�͵�regfile����Ϣ
	output reg                    reg1_read_o,//regfile ģ��ĵ�һ�����Ĵ����˿ڵĶ�ʹ���ź�
	output reg                    reg2_read_o,//regfile ģ��ĵڶ������Ĵ����˿ڵĶ�ʹ���ź�
	output reg[`RegAddrBus]       reg1_addr_o,//Regfile ģ��ĵ�һ�����Ĵ����˿ڵĶ���ַ�ź� 5bit
	output reg[`RegAddrBus]       reg2_addr_o,//Regfile ģ��ĵڶ������Ĵ����˿ڵĶ���ַ�ź� 5bit 	      
	
	//�͵�ִ�н׶ε���Ϣ
	output reg[`AluOpBus]         aluop_o,//����׶ε�ָ��Ҫ���е������������ 8bit
	output reg[`AluSelBus]        alusel_o,//����׶ε�ָ��Ҫ���е���������� 3bit
	output reg[`RegBus]           reg1_o,//����׶ε�ָ��Ҫ���е������Դ������1
	output reg[`RegBus]           reg2_o,//����׶ε�ָ��Ҫ���е������Դ������2
	output reg[`RegAddrBus]       wd_o,//����׶ε�ָ��Ҫд���Ŀ�ļĴ�����ַ 5bit
	output reg                    wreg_o//����׶ε�ָ���Ƿ���Ҫд���Ŀ�ļĴ���
);
// ȡ��ָ���ָ���룬������
// ���� ori ָ��ֻ��ͨ���жϵ� 26-31bit ��ֵ�������ж��Ƿ��� ori ָ��
  wire[5:0] op = inst_i[31:26];
  wire[4:0] op2 = inst_i[10:6];
  wire[5:0] op3 = inst_i[5:0];
  wire[4:0] op4 = inst_i[20:16];
  
  // ����ָ��ִ����Ҫ��������
  reg[`RegBus]	imm;
  
  // ָʾָ���Ƿ���Ч
  reg instvalid;
  
 //һ����ָ��������� 
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
			reg1_addr_o <= inst_i[25:21];// Ĭ��ͨ�� Regfile ���˿� 1 ��ȡ�ļĴ�����ַ
			reg2_addr_o <= inst_i[20:16];// Ĭ��ͨ�� Regfile ���˿� 2 ��ȡ�ļĴ�����ַ		
			imm <= `ZeroWord;
          case (op)
            `EXE_SPECIAL_INST:        begin
                case (op2)
                    5'b00000:            begin
                        case (op3)
                            `EXE_OR:    begin
                                wreg_o <= `WriteEnable;        aluop_o <= `EXE_OR_OP;
                                  alusel_o <= `EXE_RES_LOGIC;     reg1_read_o <= 1'b1;    reg2_read_o <= 1'b1;
                                  instvalid <= `InstValid;    
                                end  
                            `EXE_AND:    begin
                                wreg_o <= `WriteEnable;        aluop_o <= `EXE_AND_OP;
                                  alusel_o <= `EXE_RES_LOGIC;      reg1_read_o <= 1'b1;    reg2_read_o <= 1'b1;    
                                  instvalid <= `InstValid;    
                                end      
                            `EXE_XOR:    begin
                                wreg_o <= `WriteEnable;        aluop_o <= `EXE_XOR_OP;
                                  alusel_o <= `EXE_RES_LOGIC;        reg1_read_o <= 1'b1;    reg2_read_o <= 1'b1;    
                                  instvalid <= `InstValid;    
                                end                  
                            `EXE_NOR:    begin
                                wreg_o <= `WriteEnable;        aluop_o <= `EXE_NOR_OP;
                                  alusel_o <= `EXE_RES_LOGIC;        reg1_read_o <= 1'b1;    reg2_read_o <= 1'b1;    
                                  instvalid <= `InstValid;    
                                end 
                                `EXE_SLLV: begin
                                    wreg_o <= `WriteEnable;        aluop_o <= `EXE_SLL_OP;
                                  alusel_o <= `EXE_RES_SHIFT;        reg1_read_o <= 1'b1;    reg2_read_o <= 1'b1;
                                  instvalid <= `InstValid;    
                                end 
                                `EXE_SRLV: begin
                                    wreg_o <= `WriteEnable;        aluop_o <= `EXE_SRL_OP;
                                  alusel_o <= `EXE_RES_SHIFT;        reg1_read_o <= 1'b1;    reg2_read_o <= 1'b1;
                                  instvalid <= `InstValid;    
                                end                     
                                `EXE_SRAV: begin
                                    wreg_o <= `WriteEnable;        aluop_o <= `EXE_SRA_OP;
                                  alusel_o <= `EXE_RES_SHIFT;        reg1_read_o <= 1'b1;    reg2_read_o <= 1'b1;
                                  instvalid <= `InstValid;            
                                  end            
                                `EXE_SYNC: begin
                                    wreg_o <= `WriteDisable;        aluop_o <= `EXE_NOP_OP;
                                  alusel_o <= `EXE_RES_NOP;        reg1_read_o <= 1'b0;    reg2_read_o <= 1'b1;
                                  instvalid <= `InstValid;    
                                end        
                                `EXE_MFHI: begin
                                    wreg_o <= `WriteEnable;        aluop_o <= `EXE_MFHI_OP;
                                  alusel_o <= `EXE_RES_MOVE;   reg1_read_o <= 1'b0;    reg2_read_o <= 1'b0;
                                  instvalid <= `InstValid;    
                                end
                                `EXE_MFLO: begin
                                    wreg_o <= `WriteEnable;        aluop_o <= `EXE_MFLO_OP;
                                  alusel_o <= `EXE_RES_MOVE;   reg1_read_o <= 1'b0;    reg2_read_o <= 1'b0;
                                  instvalid <= `InstValid;    
                                end
                                `EXE_MTHI: begin
                                    wreg_o <= `WriteDisable;        aluop_o <= `EXE_MTHI_OP;
                                  reg1_read_o <= 1'b1;    reg2_read_o <= 1'b0; instvalid <= `InstValid;    
                                end
                                `EXE_MTLO: begin
                                    wreg_o <= `WriteDisable;        aluop_o <= `EXE_MTLO_OP;
                                  reg1_read_o <= 1'b1;    reg2_read_o <= 1'b0; instvalid <= `InstValid;    
                                end
                                `EXE_MOVN: begin
                                    aluop_o <= `EXE_MOVN_OP;
                                  alusel_o <= `EXE_RES_MOVE;   reg1_read_o <= 1'b1;    reg2_read_o <= 1'b1;
                                  instvalid <= `InstValid;
                                     if(reg2_o != `ZeroWord) begin
                                         wreg_o <= `WriteEnable;
                                     end else begin
                                         wreg_o <= `WriteDisable;
                                     end
                                end
                                `EXE_MOVZ: begin
                                    aluop_o <= `EXE_MOVZ_OP;
                                  alusel_o <= `EXE_RES_MOVE;   reg1_read_o <= 1'b1;    reg2_read_o <= 1'b1;
                                  instvalid <= `InstValid;
                                     if(reg2_o == `ZeroWord) begin
                                         wreg_o <= `WriteEnable;
                                     end else begin
                                         wreg_o <= `WriteDisable;
                                     end                                      
                                end                                                                                        
                            default:    begin
                            end
                          endcase
                         end
                        default: begin
                        end
                    endcase    
                    end                                      
              `EXE_ORI:            begin                        //ORIָ��
                  wreg_o <= `WriteEnable;        aluop_o <= `EXE_OR_OP;
                  alusel_o <= `EXE_RES_LOGIC; reg1_read_o <= 1'b1;    reg2_read_o <= 1'b0;          
                    imm <= {16'h0, inst_i[15:0]};        wd_o <= inst_i[20:16];
                    instvalid <= `InstValid;    
              end
              `EXE_ANDI:            begin
                  wreg_o <= `WriteEnable;        aluop_o <= `EXE_AND_OP;
                  alusel_o <= `EXE_RES_LOGIC;    reg1_read_o <= 1'b1;    reg2_read_o <= 1'b0;          
                    imm <= {16'h0, inst_i[15:0]};        wd_o <= inst_i[20:16];              
                    instvalid <= `InstValid;    
                end         
              `EXE_XORI:            begin
                  wreg_o <= `WriteEnable;        aluop_o <= `EXE_XOR_OP;
                  alusel_o <= `EXE_RES_LOGIC;    reg1_read_o <= 1'b1;    reg2_read_o <= 1'b0;          
                    imm <= {16'h0, inst_i[15:0]};        wd_o <= inst_i[20:16];              
                    instvalid <= `InstValid;    
                end             
              `EXE_LUI:            begin
                  wreg_o <= `WriteEnable;        aluop_o <= `EXE_OR_OP;
                  alusel_o <= `EXE_RES_LOGIC; reg1_read_o <= 1'b1;    reg2_read_o <= 1'b0;          
                    imm <= {inst_i[15:0], 16'h0};        wd_o <= inst_i[20:16];              
                    instvalid <= `InstValid;    
                end        
                `EXE_PREF:            begin
                  wreg_o <= `WriteDisable;        aluop_o <= `EXE_NOP_OP;
                  alusel_o <= `EXE_RES_NOP; reg1_read_o <= 1'b0;    reg2_read_o <= 1'b0;                
                    instvalid <= `InstValid;    
                end                                              
            default:            begin
            end
          endcase          //case op
          
          if (inst_i[31:21] == 11'b00000000000) begin
              if (op3 == `EXE_SLL) begin
                  wreg_o <= `WriteEnable;        aluop_o <= `EXE_SLL_OP;
                  alusel_o <= `EXE_RES_SHIFT; reg1_read_o <= 1'b0;    reg2_read_o <= 1'b1;          
                    imm[4:0] <= inst_i[10:6];        wd_o <= inst_i[15:11];
                    instvalid <= `InstValid;    
                end else if ( op3 == `EXE_SRL ) begin
                  wreg_o <= `WriteEnable;        aluop_o <= `EXE_SRL_OP;
                  alusel_o <= `EXE_RES_SHIFT; reg1_read_o <= 1'b0;    reg2_read_o <= 1'b1;          
                    imm[4:0] <= inst_i[10:6];        wd_o <= inst_i[15:11];
                    instvalid <= `InstValid;    
                end else if ( op3 == `EXE_SRA ) begin
                  wreg_o <= `WriteEnable;        aluop_o <= `EXE_SRA_OP;
                  alusel_o <= `EXE_RES_SHIFT; reg1_read_o <= 1'b0;    reg2_read_o <= 1'b1;          
                    imm[4:0] <= inst_i[10:6];        wd_o <= inst_i[15:11];
                    instvalid <= `InstValid;    
                end
            end          
          
		end       //if
	end         //always
	
//����ȷ�����������Դ������ 1 

//Ϊ�������������⣬�� reg1_o ��ֵ�Ĺ������������������
//1����� Regfile ģ����˿� 1 Ҫ��ȡ�ļĴ�������ִ�н׶�Ҫд��Ŀ�ļĴ�����
// ��ôֱ�Ӱ�ִ�н׶εĽ�� ex_wdata_i ��Ϊ reg1_o ��ֵ;
//2����� Regfile ģ����˿� 1 Ҫ��ȡ�ļĴ������Ƿô�׶�Ҫд��Ŀ�ļĴ�����
// ��ôֱ�Ӱѷô�׶εĽ�� mem_wdata_i ��Ϊ reg1_o ��ֵ;
	always @ (*) begin
    if(rst == `RstEnable) begin
        reg1_o <= `ZeroWord;        
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
	
	//����ȷ�����������Դ������ 2
	
	//Ϊ�������������⣬�� reg2_o ��ֵ�Ĺ������������������
    //1����� Regfile ģ����˿� 2 Ҫ��ȡ�ļĴ�������ִ�н׶�Ҫд��Ŀ�ļĴ�����
    // ��ôֱ�Ӱ�ִ�н׶εĽ�� ex_wdata_i ��Ϊ reg2_o ��ֵ;
    //2����� Regfile ģ����˿� 2 Ҫ��ȡ�ļĴ������Ƿô�׶�Ҫд��Ŀ�ļĴ�����
    // ��ôֱ�Ӱѷô�׶εĽ�� mem_wdata_i ��Ϊ reg2_o ��ֵ;
	always @ (*) begin
        if(rst == `RstEnable) begin
            reg2_o <= `ZeroWord;
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

endmodule