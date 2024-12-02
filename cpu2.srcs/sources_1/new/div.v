`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/02 20:00:36
// Design Name: 
// Module Name: div
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
`include "Define.v"

module div(

	input	wire					clk,
	input wire						rst,
	
	input wire                    signed_div_i,//�Ƿ��з��ų�����1��ʾΪ�з��ų���
	input wire[31:0]              opdata1_i,//������ 32bit
	input wire[31:0]		   				opdata2_i,//���� 32bit
	input wire                    start_i,//�Ƿ�ʼ��������
	input wire                    annul_i,//�Ƿ�ȡ���������㣬1��ʾȡ����������
	
	output reg[63:0]             result_o,//���������� 64bit
	output reg			             ready_o//���������Ƿ����
);

	wire[32:0] div_temp;
	reg[5:0] cnt;
	reg[64:0] dividend;
	reg[1:0] state;
	reg[31:0] divisor;	 
	reg[31:0] temp_op1;
	reg[31:0] temp_op2;
	
//dividend �ĵ� 32 λ������Ǳ��������м������� k �ε���������ʱ�� dividend[k:0]
//����ľ��ǵ�ǰ�õ����м����� dividend[31:k+1]����ľ��Ǳ������л�û�в�������
//�����ݣ� dividend �� 32 λ��ÿ�ε���ʱ�ı����������� dividend[63:32]����ͼ 7-16
//�е� minuend�� divisor ����ͼ 7-16 �еĳ��� n���˴����еľ��� minuend-n ���㣬��
//�������� div_temp ��	
	assign div_temp = {1'b0,dividend[63:32]} - {1'b0,divisor};

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			state <= `DivFree;
			ready_o <= `DivResultNotReady;
			result_o <= {`ZeroWord,`ZeroWord};
		end else begin
		  case (state)
		  //******************* DivFree ״̬ ***********************
          //�����������
          //��1����ʼ�������㣬������Ϊ 0����ô���� DivByZero ״̬
          //��2����ʼ�������㣬�ҳ�����Ϊ 0����ô���� DivOn ״̬����ʼ�� cnt Ϊ 0����
          // �����з��ų������ұ��������߳���Ϊ������ô�Ա��������߳���ȡ���롣
          // �������浽 divisor �У��������������λ���浽 dividend �ĵ� 32 λ��
          // ׼�����е�һ�ε���
          //��3��û�п�ʼ�������㣬���� ready_o Ϊ DivResultNotReady������
          // result_o Ϊ 0
          //***********************************************************
		  	`DivFree:			begin               //DivFree״̬
		  		if(start_i == `DivStart && annul_i == 1'b0) begin
		  			if(opdata2_i == `ZeroWord) begin
		  				state <= `DivByZero;
		  			end else begin
		  				state <= `DivOn;
		  				cnt <= 6'b000000;
		  				if(signed_div_i == 1'b1 && opdata1_i[31] == 1'b1 ) begin
		  					temp_op1 = ~opdata1_i + 1;// ������ȡ����
		  				end else begin
		  					temp_op1 = opdata1_i;
		  				end
		  				if(signed_div_i == 1'b1 && opdata2_i[31] == 1'b1 ) begin
		  					temp_op2 = ~opdata2_i + 1;// ����ȡ����
		  				end else begin
		  					temp_op2 = opdata2_i;
		  				end
		  				dividend <= {`ZeroWord,`ZeroWord};
              dividend[32:1] <= temp_op1;
              divisor <= temp_op2;
             end
          end else begin
						ready_o <= `DivResultNotReady;
						result_o <= {`ZeroWord,`ZeroWord};
				  end          	
		  	end
		  	//******************* DivByZero ״̬ ********************
          //������� DivByZero ״̬����ôֱ�ӽ��� DivEnd ״̬�������������ҽ��Ϊ 0
          //***********************************************************
		  	`DivByZero:		begin               //DivByZero״̬
         	dividend <= {`ZeroWord,`ZeroWord};
          state <= `DivEnd;		 		
		  	end
		  	//******************* DivOn ״̬ ***********************
          //�����������
          //��1����������ź� annul_i Ϊ 1����ʾ������ȡ���������㣬��ô DIV ģ��ֱ
          // �ӻص� DivFree ״̬��
          //��2����� annul_i Ϊ 0���� cnt ��Ϊ 32����ô��ʾ���̷���û�н�������ʱ
          // ���������� div_temp Ϊ������ô�˴ε�������� 0���ο�ͼ 7-16����
          // ��������� div_temp Ϊ������ô�˴ε�������� 1���ο�ͼ 7-16�� dividend
          // �����λ����ÿ�εĵ��������ͬʱ���� DivOn ״̬�� cnt �� 1��
          //��3����� annul_i Ϊ 0���� cnt Ϊ 32����ô��ʾ���̷�������������з���
          // �������ұ�����������һ��һ������ô�����̷��Ľ��ȡ���룬�õ����յ�
          // ������˴����̡�������Ҫȡ���롣�̱����� dividend �ĵ� 32 λ������
          // ������ dividend �ĸ� 32 λ��ͬʱ���� DivEnd ״̬��
          //***********************************************************
		  	`DivOn:				begin               //DivOn״̬
		  		if(annul_i == 1'b0) begin
		  			if(cnt != 6'b100000) begin
               if(div_temp[32] == 1'b1) begin
               //��� div_temp[32]Ϊ 1����ʾ��minuend-n�����С�� 0��
               //�� dividend ������һλ�������ͽ���������û�в��������
               //���λ���뵽��һ�ε����ı������У�ͬʱ�� 0 ׷�ӵ��м���
                  dividend <= {dividend[63:0] , 1'b0};
               end else begin
               //��� div_temp[32]Ϊ 0����ʾ��minuend-n��������ڵ�
               //�� 0���������Ľ���뱻������û�в���������λ���뵽��
               //һ�ε����ı������У�ͬʱ�� 1 ׷�ӵ��м���
                  dividend <= {div_temp[31:0] , dividend[31:0] , 1'b1};
               end
               cnt <= cnt + 1;
             end else begin
               if((signed_div_i == 1'b1) && ((opdata1_i[31] ^ opdata2_i[31]) == 1'b1)) begin
                  dividend[31:0] <= (~dividend[31:0] + 1);
               end
               if((signed_div_i == 1'b1) && ((opdata1_i[31] ^ dividend[64]) == 1'b1)) begin              
                  dividend[64:33] <= (~dividend[64:33] + 1);
               end
               state <= `DivEnd;
               cnt <= 6'b000000;            	
             end
		  		end else begin
		  			state <= `DivFree;
		  		end	
		  	end
		  	//******************* DivEnd ״̬ ***********************
              //������������� result_o �Ŀ���� 64 λ����� 32 λ�洢�������� 32 λ�洢�̣�
              //��������ź� ready_o Ϊ DivResultReady����ʾ����������Ȼ��ȴ� EX ģ��
              //���� DivStop �źţ��� EX ģ������ DivStop �ź�ʱ�� DIV ģ��ص� DivFree
              //״̬
              //**********************************************************
		  	`DivEnd:			begin               //DivEnd״̬
        	result_o <= {dividend[64:33], dividend[31:0]};  
          ready_o <= `DivResultReady;
          if(start_i == `DivStop) begin
          	state <= `DivFree;
						ready_o <= `DivResultNotReady;
						result_o <= {`ZeroWord,`ZeroWord};       	
          end		  	
		  	end
		  endcase
		end
	end
    
endmodule		
