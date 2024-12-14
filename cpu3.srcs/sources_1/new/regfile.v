//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/07 11:43:55
// Design Name: 
// Module Name: regfile
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
// ����׶Σ�����ȡ����ָ��������룺����Ҫ���е��������ͣ��Լ���������Ĳ�����������׶ΰ��� Regfile��ID �� ID/EX ����ģ�顣
// regfileģ�飬ʵ���� 32 �� 32 λͨ�������Ĵ���������ͬʱ���������Ĵ����Ķ�������һ���Ĵ�����д����
// ��д�׶���ʵ��ʵ����regfileģ��
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module regfile(

	input wire										clk,
	input wire										rst,
	
	//д�˿�
    input wire                            we,//дʹ���ź�
    input wire[`RegAddrBus]                waddr,//Ҫд��ļĴ�����ַ
    input wire[`RegBus]                    wdata,//Ҫд�������
    
    //���˿�1
    input wire                            re1,//��һ�����Ĵ����˿ڶ�ʹ���ź�
    input wire[`RegAddrBus]                raddr1,//��һ�����Ĵ����˿�Ҫ��ȡ�ļĴ����ĵ�ַ
    output reg[`RegBus]                rdata1,//��һ�����Ĵ����˿�����ļĴ���ֵ
    
    //���˿�2
    input wire                            re2,//�ڶ������Ĵ����˿ڶ�ʹ���ź�
    input wire[`RegAddrBus]                raddr2,//�ڶ������Ĵ����˿�Ҫ��ȡ�ļĴ����ĵ�ַ
    output reg[`RegBus]                 rdata2,//�ڶ������Ĵ����˿�����ļĴ���ֵ
	
    // ����Ĵ��� 1��2��3��4 ��ֵ
    output wire[`RegBus] out_r1,
    output wire[`RegBus] out_r2,
    output wire[`RegBus] out_r3,
    output wire[`RegBus] out_r4
	
);

	reg[`RegBus]  regs[0:`RegNum-1];

	always @ (posedge clk) begin
		if (rst == `RstDisable) begin
			if((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin
				regs[waddr] <= wdata;
			end
		end
	end
	
	always @ (*) begin
		if(rst == `RstEnable) begin
			  rdata1 <= `ZeroWord;
	  end else if(raddr1 == `RegNumLog2'h0) begin
	  		rdata1 <= `ZeroWord;
	  end else if((raddr1 == waddr) && (we == `WriteEnable) //������Խ���������ָ�������������⣬�ɼ��鼮P110
	  	            && (re1 == `ReadEnable)) begin//�����һ�����Ĵ����˿�Ҫ��ȡ��Ŀ��Ĵ�����Ҫд���Ŀ�ļĴ�����ͬһ���Ĵ�������ôֱ�ӽ�Ҫд���ֵ��Ϊ��һ�����Ĵ����˿ڵ����
	  	  rdata1 <= wdata;
	  end else if(re1 == `ReadEnable) begin
	      rdata1 <= regs[raddr1];
	  end else begin
	      rdata1 <= `ZeroWord;
	  end
	end

	always @ (*) begin//һ��Ҫ�����raddr1��raddr2�����仯����ô���������µ�ַ��Ӧ�ļĴ�����ֵ
		if(rst == `RstEnable) begin
			  rdata2 <= `ZeroWord;
	  end else if(raddr2 == `RegNumLog2'h0) begin
	  		rdata2 <= `ZeroWord;
	  end else if((raddr2 == waddr) && (we == `WriteEnable) 
	  	            && (re2 == `ReadEnable)) begin
	  	  rdata2 <= wdata;
	  end else if(re2 == `ReadEnable) begin
	      rdata2 <= regs[raddr2];
	  end else begin
	      rdata2 <= `ZeroWord;
	  end
	end
	
	// ���ָ���Ĵ�����ֵ ���ڵ���
    assign out_r1 = regs[1]; // ����Ĵ��� 1 ��ֵ
    assign out_r2 = regs[2]; // ����Ĵ��� 2 ��ֵ
    assign out_r3 = regs[3]; // ����Ĵ��� 3 ��ֵ
    assign out_r4 = regs[4]; // ����Ĵ��� 4 ��ֵ

endmodule