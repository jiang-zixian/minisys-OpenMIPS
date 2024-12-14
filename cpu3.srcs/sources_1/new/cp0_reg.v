//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/08 20:37:39
// Design Name: 
// Module Name: cp0_reg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Description:ʵ����CP0�е�һЩ�Ĵ����������У�count��compare��status��
//             cause��EPC��config��PrId
//OpenMIPS ֻʵ���� CP0 �е� Count�� Compare�� Status�� Cause�� EPC�� PRId�� Config
//7 ���Ĵ������� 7 ���Ĵ����е� PRId�� Config ������д��
//////////////////////////////////////////////////////////////////////

`include "defines.v"

module cp0_reg(

	input wire						clk,
	input wire						rst,
	
	
	input wire                    we_i,//�Ƿ�ҪдCP0�еļĴ���
	input wire[4:0]               waddr_i,//Ҫд��CP0�мĴ����ĵ�ַ
	input wire[4:0]               raddr_i,//Ҫ��ȡ��CP0�мĴ����ĵ�ַ
	input wire[`RegBus]           data_i,//Ҫд��CP0�мĴ���������
	
	input wire[31:0]              excepttype_i,//���յ��쳣����
	input wire[5:0]               int_i,
	input wire[`RegBus]           current_inst_addr_i,//�����쳣��ָ���ַ
	input wire                    is_in_delayslot_i,//�����쳣��ָ���Ƿ����ӳٲ�ָ��
	
	output reg[`RegBus]           data_o,//��CP0��ĳ���Ĵ����ж�����ֵ
	output reg[`RegBus]           count_o,//Count�Ĵ�����ֵ
	output reg[`RegBus]           compare_o,//Compare�Ĵ�����ֵ
	output reg[`RegBus]           status_o,//Status�Ĵ�����ֵ
	output reg[`RegBus]           cause_o,//Cause�Ĵ�����ֵ
	output reg[`RegBus]           epc_o,//EPC�Ĵ�����ֵ
	output reg[`RegBus]           config_o,//Config�Ĵ�����ֵ
	output reg[`RegBus]           prid_o,//PRId�Ĵ�����ֵ
	
	output reg                   timer_int_o    //�Ƿ��ж�ʱ�жϷ���
	
);

	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
		//����Ϊ����ֵ�ĳ�ʼ��
			count_o <= `ZeroWord;
			compare_o <= `ZeroWord;
			//status�Ĵ�����CUΪ0001����ʾЭ������CP0����
			status_o <= 32'b00010000000000000000000000000000;
			cause_o <= `ZeroWord;
			epc_o <= `ZeroWord;
			//config�Ĵ�����BEΪ1����ʾBig-Endian��MTΪ00����ʾû��MMU
			//Config �Ĵ����ĳ�ʼֵ������ BE �ֶ�Ϊ 1����ʾ�����ڴ��ģʽ��MSB��
			config_o <= 32'b00000000000000001000000000000000;
			//��������L����Ӧ����0x48��������0x1���������ͣ��汾����1.0
			prid_o <= 32'b00000000010011000000000100000010;
            timer_int_o <= `InterruptNotAssert;
		end else begin
		  count_o <= count_o + 1 ;//count�Ĵ�����ֵ��ÿ��ʱ�����ڼ�1
		  cause_o[15:10] <= int_i;//Cause�ĵ�10~15bit�����ⲿ�ж�����
		
		  //�� Compare �Ĵ�����Ϊ 0���� Count �Ĵ�����ֵ���� Compare �Ĵ�����ֵʱ��
          //������ź� timer_int_o ��Ϊ 1����ʾʱ���жϷ���
			if(compare_o != `ZeroWord && count_o == compare_o) begin
				timer_int_o <= `InterruptAssert;
			end
					
			if(we_i == `WriteEnable) begin
				case (waddr_i) 
					`CP0_REG_COUNT:		begin
						count_o <= data_i;
					end
					`CP0_REG_COMPARE:	begin
						compare_o <= data_i;
						//count_o <= `ZeroWord;
                        timer_int_o <= `InterruptNotAssert;
					end
					`CP0_REG_STATUS:	begin
						status_o <= data_i;
					end
					`CP0_REG_EPC:	begin
						epc_o <= data_i;
					end
					`CP0_REG_CAUSE:	begin
					  //cause�Ĵ���ֻ��IP[1:0]��IV��WP�ֶ��ǿ�д��
						cause_o[9:8] <= data_i[9:8];
						cause_o[23] <= data_i[23];
						cause_o[22] <= data_i[22];
					end					
				endcase  //case addr_i
			end

			case (excepttype_i)
				32'h00000001:		begin//�ⲿ�ж�
//				���λ���ӳٲ��У���ô���� EPC �Ĵ���Ϊ��һ��ָ��ĵ�ַ�� Status �Ĵ�����
//                BD �ֶ�Ϊ 1����֮������ EPC �Ĵ���Ϊ�����쳣ָ��ĵ�ַ�� Status �Ĵ����� BD �ֶ�Ϊ 0��
//                ���⣬���� Status �Ĵ����� EXL �ֶ�Ϊ 1����ʾ�����쳣�����жϽ�ֹ��������� Cause
//                �Ĵ����� ExcCode �ֶ�Ϊ 5'b00000����ʾ�쳣ԭ�����жϣ�
					if(is_in_delayslot_i == `InDelaySlot ) begin
						epc_o <= current_inst_addr_i - 4 ;
						cause_o[31] <= 1'b1;
					end else begin
					  epc_o <= current_inst_addr_i;
					  cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00000;
					
				end
				32'h00000008:		begin//syscall
					if(status_o[1] == 1'b0) begin
						if(is_in_delayslot_i == `InDelaySlot ) begin
							epc_o <= current_inst_addr_i - 4 ;
							cause_o[31] <= 1'b1;
						end else begin
					  	epc_o <= current_inst_addr_i;
					  	cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01000;			
				end
				32'h0000000a:		begin//��Чָ���쳣
					if(status_o[1] == 1'b0) begin
						if(is_in_delayslot_i == `InDelaySlot ) begin
							epc_o <= current_inst_addr_i - 4 ;
							cause_o[31] <= 1'b1;
						end else begin
					  	epc_o <= current_inst_addr_i;
					  	cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01010;					
				end
				32'h0000000d:		begin//�����쳣
					if(status_o[1] == 1'b0) begin
						if(is_in_delayslot_i == `InDelaySlot ) begin
							epc_o <= current_inst_addr_i - 4 ;
							cause_o[31] <= 1'b1;
						end else begin
					  	epc_o <= current_inst_addr_i;
					  	cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01101;					
				end
				32'h0000000c:		begin//����쳣
					if(status_o[1] == 1'b0) begin
						if(is_in_delayslot_i == `InDelaySlot ) begin
							epc_o <= current_inst_addr_i - 4 ;
							cause_o[31] <= 1'b1;
						end else begin
					  	epc_o <= current_inst_addr_i;
					  	cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01100;					
				end				
				32'h0000000e:   begin//�쳣����ָ��eret
					status_o[1] <= 1'b0;
				end
				default:				begin
				end
			endcase			
			
		end    //if
	end      //always
			
			
//�� CP0 �мĴ����Ķ�����			
	always @ (*) begin
		if(rst == `RstEnable) begin
			data_o <= `ZeroWord;
		end else begin
				case (raddr_i) 
					`CP0_REG_COUNT:		begin
						data_o <= count_o ;
					end
					`CP0_REG_COMPARE:	begin
						data_o <= compare_o ;
					end
					`CP0_REG_STATUS:	begin
						data_o <= status_o ;
					end
					`CP0_REG_CAUSE:	begin
						data_o <= cause_o ;
					end
					`CP0_REG_EPC:	begin
						data_o <= epc_o ;
					end
					`CP0_REG_PrId:	begin
						data_o <= prid_o ;
					end
					`CP0_REG_CONFIG:	begin
						data_o <= config_o ;
					end	
					default: 	begin
					end			
				endcase  //case addr_i			
		end    //if
	end      //always

endmodule