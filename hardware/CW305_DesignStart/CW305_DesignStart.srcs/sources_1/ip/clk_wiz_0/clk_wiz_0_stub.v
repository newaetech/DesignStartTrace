// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
// Date        : Mon Dec 13 11:23:44 2021
// Host        : qed running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               W:/hardware/CW305_DesignStart/CW305_DesignStart.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0_stub.v
// Design      : clk_wiz_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tftg256-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_wiz_0(clk_out1, daddr, dclk, den, din, dout, drdy, dwe, psclk, 
  psen, psincdec, psdone, reset, locked, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="clk_out1,daddr[6:0],dclk,den,din[15:0],dout[15:0],drdy,dwe,psclk,psen,psincdec,psdone,reset,locked,clk_in1" */;
  output clk_out1;
  input [6:0]daddr;
  input dclk;
  input den;
  input [15:0]din;
  output [15:0]dout;
  output drdy;
  input dwe;
  input psclk;
  input psen;
  input psincdec;
  output psdone;
  input reset;
  output locked;
  input clk_in1;
endmodule
