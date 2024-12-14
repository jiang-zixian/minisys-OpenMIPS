//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/10 15:42:24
// Design Name: 
// Module Name: openmips_min_sopc
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
//////////////////////////////////////////////////////////////////////

`include "defines.v"

module openmips_min_sopc(

	input	wire										clk,
	input wire										rst,
	output wire[`InstBus] inst,
	
	// 输出寄存器 1、2、3、4 的值
	output wire[`InstAddrBus] pc,
    output wire[`RegBus] out_r1,
    output wire[`RegBus] out_r2,
    output wire[`RegBus] out_r3,
    output wire[`RegBus] out_r4,
    output wire[`RegBus] out_hi,
    output wire[`RegBus] out_lo,
    output wire[`RegBus]           count_o,
    output wire[`RegBus]           compare_o,
    output wire[`RegBus]           status_o
	
);

  //连接指令存储器
  wire[`InstAddrBus] inst_addr;
  //wire[`InstBus] inst;
  wire rom_ce;
  wire mem_we_i;
  wire[`RegBus] mem_addr_i;
  wire[`RegBus] mem_data_i;
  wire[`RegBus] mem_data_o;
  wire[3:0] mem_sel_i; 
  wire mem_ce_i;   
  wire[5:0] int;
  wire timer_int;
 
  //assign int = {5'b00000, timer_int, gpio_int, uart_int};
  assign int = {5'b00000, timer_int};//时钟中断输出作为一个中断输入

 openmips openmips0(
		.clk(clk),
		.rst(rst),
	    .rom_data_i(inst),
	    .pc(pc),
	    .out_r1(out_r1),
        .out_r2(out_r2),
        .out_r3(out_r3),
        .out_r4(out_r4),
        .hi(out_hi),
        .lo(out_lo),
        .count_o(count_o),
        .compare_o(compare_o),
        .status_o(status_o),
	    
		.rom_addr_o(inst_addr),
		.rom_ce_o(rom_ce),

        .int_i(int),//中断输入

		.ram_we_o(mem_we_i),
		.ram_addr_o(mem_addr_i),
		.ram_sel_o(mem_sel_i),
		.ram_data_o(mem_data_i),
		.ram_data_i(mem_data_o),
		.ram_ce_o(mem_ce_i),
		
		.timer_int_o(timer_int)		//时钟中断输出	
	
	);
	
	inst_rom inst_rom0(
		.ce(rom_ce),
		.addr(inst_addr),
		.inst(inst)	
	);

	data_ram data_ram0(
		.clk(clk),
		.ce(mem_ce_i),
		.we(mem_we_i),
		.addr(mem_addr_i),
		.sel(mem_sel_i),
		.data_i(mem_data_i),
		.data_o(mem_data_o)	
	);

endmodule