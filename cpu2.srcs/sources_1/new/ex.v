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
// EX ģ���� ID/EX ģ��õ���
// ������ alusel_i������������ aluop_i��Դ������ reg1_i��Դ������ reg2_i��Ҫд��Ŀ�ļĴ�����ַ wd_i
//////////////////////////////////////////////////////////////////////////////////
`include "Define.v"

module ex(

	input wire										rst,
	
	//�͵�ִ�н׶ε���Ϣ
	input wire[`AluOpBus]         aluop_i,//3bit ִ�н׶�Ҫ���е����������
	input wire[`AluSelBus]        alusel_i,//8bit ִ�н׶�Ҫ���е������������
	input wire[`RegBus]           reg1_i,//Դ������1
	input wire[`RegBus]           reg2_i,//Դ������2
	input wire[`RegAddrBus]       wd_i,//ָ��ִ��Ҫд���Ŀ�ļĴ�����ַ 5bit
	input wire                    wreg_i,//�Ƿ���Ҫд���Ŀ�ļĴ���

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
	
	output reg[`RegAddrBus]       wd_o,//ִ�н׶ε�ָ������Ҫд���Ŀ�ļĴ�����ַ 5bit
	output reg                    wreg_o,//ִ�н׶ε�ָ�������Ƿ���Ҫд���Ŀ�ļĴ��� 1bit
	output reg[`RegBus]	    	   wdata_o,//ִ�н׶ε�ָ������Ҫд��Ŀ�ļĴ�����ֵ 32bit
	
	// ����ִ�н׶ε�ָ��� HI�� LO �Ĵ�����д��������
    output reg[`RegBus]           hi_o,
    output reg[`RegBus]           lo_o,
    output reg                    whilo_o,    
	
	// �����߼�����Ľ��
    output    wire[`RegBus] logicout,
    
    output    wire[`RegBus]           reg1_i_out
	
);

// �����߼�����Ľ��
	reg[`RegBus] logicout_real;
	
	// ������λ������
	reg[`RegBus] shiftres;
	
	reg[`RegBus] moveres;// �ƶ������Ľ��
    reg[`RegBus] HI;// ���� HI �Ĵ���������ֵ
    reg[`RegBus] LO;// ���� LO �Ĵ���������ֵ
	
	//һ������ aluop_i ָʾ�����������ͽ�������
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
	
	//��λ������
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

    //MFHI��MFLO��MOVN��MOVZָ��
	always @ (*) begin
		if(rst == `RstEnable) begin
	  	moveres <= `ZeroWord;
	  end else begin
	   moveres <= `ZeroWord;
	   case (aluop_i)
	   	`EXE_MFHI_OP:		begin
	   		moveres <= HI;// ����� mfhi ָ���ô�� HI ��ֵ��Ϊ�ƶ������Ľ��
	   	end
	   	`EXE_MFLO_OP:		begin
	   		moveres <= LO;// ����� mflo ָ���ô�� LO ��ֵ��Ϊ�ƶ������Ľ��
	   	end
	   	`EXE_MOVZ_OP:		begin
	   		moveres <= reg1_i;// ����� movz ָ���ô�� reg1_i ��ֵ��Ϊ�ƶ������Ľ��
	   	end
	   	`EXE_MOVN_OP:		begin
	   		moveres <= reg1_i;// ����� movn ָ���ô�� reg1_i ��ֵ��Ϊ�ƶ������Ľ��
	   	end
	   	default : begin
	   	end
	   endcase
	  end
	end	 

//���� alusel_i ָʾ���������ͣ�ѡ��һ����������Ϊ���ս��,�˴�ֻ���߼������� 
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
 
 //����� MTHI�� MTLO ָ���ô��Ҫ���� whilo_o�� hi_o�� lo_i ��ֵ
 
 //ȷ���Ƿ�Ҫд HI�� LO �Ĵ���������� mthi�� mtlo �Ĵ�������ô
 //Ҫд HI�� LO �Ĵ�����������������ź� whilo_o Ϊ WriteEnable
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
