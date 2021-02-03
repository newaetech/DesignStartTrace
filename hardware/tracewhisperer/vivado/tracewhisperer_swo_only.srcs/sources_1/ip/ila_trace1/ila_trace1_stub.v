// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
// Date        : Thu Sep  3 13:13:55 2020
// Host        : qed running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               w:/hardware/tracewhisperer/vivado/tracewhisperer.srcs/sources_1/ip/ila_trace1/ila_trace1_stub.v
// Design      : ila_trace1
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7s15ftgb196-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "ila,Vivado 2019.1" *)
module ila_trace1(clk, probe0, probe1, probe2, probe3, probe4, probe5, 
  probe6, probe7, probe8, probe9, probe10)
/* synthesis syn_black_box black_box_pad_pin="clk,probe0[0:0],probe1[0:0],probe2[3:0],probe3[2:0],probe4[0:0],probe5[0:0],probe6[0:0],probe7[7:0],probe8[63:0],probe9[17:0],probe10[0:0]" */;
  input clk;
  input [0:0]probe0;
  input [0:0]probe1;
  input [3:0]probe2;
  input [2:0]probe3;
  input [0:0]probe4;
  input [0:0]probe5;
  input [0:0]probe6;
  input [7:0]probe7;
  input [63:0]probe8;
  input [17:0]probe9;
  input [0:0]probe10;
endmodule
