//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2014 leishangwen@163.com                       ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
// Module:  openmips_min_sopc_tb
// File:    openmips_min_sopc_tb.v
// Author:  Lei Silei
// E-mail:  leishangwen@163.com
// Description: openmips_min_sopc的testbench
// Revision: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.v"
`timescale 1ns/1ps

module openmips_min_sopc_tb();

  reg     CLOCK_50;
  reg     rst;
  
  wire[`InstBus] inst;
  
    // 输出寄存器 1、2、3、4 的值
  wire[`InstAddrBus] pc;
  wire[`RegBus] out_r1;
  wire[`RegBus] out_r2;
  wire[`RegBus] out_r3;
  wire[`RegBus] out_r4;
  wire[`RegBus] out_hi;
  wire[`RegBus] out_lo; 
  wire[`RegBus]           count_o;
  wire[`RegBus]           compare_o;
  wire[`RegBus]           status_o;
  
       
  initial begin
    CLOCK_50 = 1'b0;
    forever #10 CLOCK_50 = ~CLOCK_50;
  end
      
  initial begin
    rst = `RstEnable;
    #195 rst= `RstDisable;
    #10000 $stop;
  end
       
  openmips_min_sopc openmips_min_sopc0(
		.clk(CLOCK_50),
		.rst(rst),
		.inst(inst),
		.pc(pc),
        .out_r1(out_r1),
        .out_r2(out_r2),
        .out_r3(out_r3),
        .out_r4(out_r4),
        .out_hi(out_hi),
        .out_lo(out_lo),
        .count_o(count_o),
        .compare_o(compare_o),
        .status_o(status_o)
	);

endmodule