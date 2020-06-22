//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
//Date        : Sun Jun 14 23:14:24 2020
//Host        : qed running 64-bit major release  (build 9200)
//Command     : generate_target m3_for_arty_a7_wrapper.bd
//Design      : m3_for_arty_a7_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module m3_for_arty_a7_wrapper
   (CFGITCMEN,
    CM3_CODE_AXI3_araddr,
    CM3_CODE_AXI3_arburst,
    CM3_CODE_AXI3_arcache,
    CM3_CODE_AXI3_arlen,
    CM3_CODE_AXI3_arlock,
    CM3_CODE_AXI3_arprot,
    CM3_CODE_AXI3_arready,
    CM3_CODE_AXI3_arsize,
    CM3_CODE_AXI3_aruser,
    CM3_CODE_AXI3_arvalid,
    CM3_CODE_AXI3_awaddr,
    CM3_CODE_AXI3_awburst,
    CM3_CODE_AXI3_awcache,
    CM3_CODE_AXI3_awlen,
    CM3_CODE_AXI3_awlock,
    CM3_CODE_AXI3_awprot,
    CM3_CODE_AXI3_awready,
    CM3_CODE_AXI3_awsize,
    CM3_CODE_AXI3_awuser,
    CM3_CODE_AXI3_awvalid,
    CM3_CODE_AXI3_bready,
    CM3_CODE_AXI3_bresp,
    CM3_CODE_AXI3_bvalid,
    CM3_CODE_AXI3_rdata,
    CM3_CODE_AXI3_rlast,
    CM3_CODE_AXI3_rready,
    CM3_CODE_AXI3_rresp,
    CM3_CODE_AXI3_rvalid,
    CM3_CODE_AXI3_wdata,
    CM3_CODE_AXI3_wlast,
    CM3_CODE_AXI3_wready,
    CM3_CODE_AXI3_wstrb,
    CM3_CODE_AXI3_wvalid,
    JTAGNSW,
    JTAGTOP,
    M3_RESET_OUT,
    SWCLK,
    SWDI,
    SWDO,
    SWDOEN,
    SWV,
    TDI,
    TDO,
    TRACECLK,
    TRACEDATA,
    TRCENA,
    ext_clock,
    gpio_rtl_0_tri_o,
    locked,
    nTDOEN,
    nTRST,
    reset,
    sys_clock,
    usb_uart_rxd,
    usb_uart_txd);
  input [1:0]CFGITCMEN;
  output [31:0]CM3_CODE_AXI3_araddr;
  output [1:0]CM3_CODE_AXI3_arburst;
  output [3:0]CM3_CODE_AXI3_arcache;
  output [3:0]CM3_CODE_AXI3_arlen;
  output [1:0]CM3_CODE_AXI3_arlock;
  output [2:0]CM3_CODE_AXI3_arprot;
  input CM3_CODE_AXI3_arready;
  output [2:0]CM3_CODE_AXI3_arsize;
  output [0:0]CM3_CODE_AXI3_aruser;
  output CM3_CODE_AXI3_arvalid;
  output [31:0]CM3_CODE_AXI3_awaddr;
  output [1:0]CM3_CODE_AXI3_awburst;
  output [3:0]CM3_CODE_AXI3_awcache;
  output [3:0]CM3_CODE_AXI3_awlen;
  output [1:0]CM3_CODE_AXI3_awlock;
  output [2:0]CM3_CODE_AXI3_awprot;
  input CM3_CODE_AXI3_awready;
  output [2:0]CM3_CODE_AXI3_awsize;
  output [0:0]CM3_CODE_AXI3_awuser;
  output CM3_CODE_AXI3_awvalid;
  output CM3_CODE_AXI3_bready;
  input [1:0]CM3_CODE_AXI3_bresp;
  input CM3_CODE_AXI3_bvalid;
  input [31:0]CM3_CODE_AXI3_rdata;
  input CM3_CODE_AXI3_rlast;
  output CM3_CODE_AXI3_rready;
  input [1:0]CM3_CODE_AXI3_rresp;
  input CM3_CODE_AXI3_rvalid;
  output [31:0]CM3_CODE_AXI3_wdata;
  output CM3_CODE_AXI3_wlast;
  input CM3_CODE_AXI3_wready;
  output [3:0]CM3_CODE_AXI3_wstrb;
  output CM3_CODE_AXI3_wvalid;
  output JTAGNSW;
  output JTAGTOP;
  output [0:0]M3_RESET_OUT;
  input SWCLK;
  input SWDI;
  output SWDO;
  output SWDOEN;
  output SWV;
  input TDI;
  output TDO;
  output TRACECLK;
  output [3:0]TRACEDATA;
  output TRCENA;
  output ext_clock;
  output [0:0]gpio_rtl_0_tri_o;
  output locked;
  output nTDOEN;
  input nTRST;
  input reset;
  input sys_clock;
  input usb_uart_rxd;
  output usb_uart_txd;

  wire [1:0]CFGITCMEN;
  wire [31:0]CM3_CODE_AXI3_araddr;
  wire [1:0]CM3_CODE_AXI3_arburst;
  wire [3:0]CM3_CODE_AXI3_arcache;
  wire [3:0]CM3_CODE_AXI3_arlen;
  wire [1:0]CM3_CODE_AXI3_arlock;
  wire [2:0]CM3_CODE_AXI3_arprot;
  wire CM3_CODE_AXI3_arready;
  wire [2:0]CM3_CODE_AXI3_arsize;
  wire [0:0]CM3_CODE_AXI3_aruser;
  wire CM3_CODE_AXI3_arvalid;
  wire [31:0]CM3_CODE_AXI3_awaddr;
  wire [1:0]CM3_CODE_AXI3_awburst;
  wire [3:0]CM3_CODE_AXI3_awcache;
  wire [3:0]CM3_CODE_AXI3_awlen;
  wire [1:0]CM3_CODE_AXI3_awlock;
  wire [2:0]CM3_CODE_AXI3_awprot;
  wire CM3_CODE_AXI3_awready;
  wire [2:0]CM3_CODE_AXI3_awsize;
  wire [0:0]CM3_CODE_AXI3_awuser;
  wire CM3_CODE_AXI3_awvalid;
  wire CM3_CODE_AXI3_bready;
  wire [1:0]CM3_CODE_AXI3_bresp;
  wire CM3_CODE_AXI3_bvalid;
  wire [31:0]CM3_CODE_AXI3_rdata;
  wire CM3_CODE_AXI3_rlast;
  wire CM3_CODE_AXI3_rready;
  wire [1:0]CM3_CODE_AXI3_rresp;
  wire CM3_CODE_AXI3_rvalid;
  wire [31:0]CM3_CODE_AXI3_wdata;
  wire CM3_CODE_AXI3_wlast;
  wire CM3_CODE_AXI3_wready;
  wire [3:0]CM3_CODE_AXI3_wstrb;
  wire CM3_CODE_AXI3_wvalid;
  wire JTAGNSW;
  wire JTAGTOP;
  wire [0:0]M3_RESET_OUT;
  wire SWCLK;
  wire SWDI;
  wire SWDO;
  wire SWDOEN;
  wire SWV;
  wire TDI;
  wire TDO;
  wire TRACECLK;
  wire [3:0]TRACEDATA;
  wire TRCENA;
  wire ext_clock;
  wire [0:0]gpio_rtl_0_tri_o;
  wire locked;
  wire nTDOEN;
  wire nTRST;
  wire reset;
  wire sys_clock;
  wire usb_uart_rxd;
  wire usb_uart_txd;

  m3_for_arty_a7 m3_for_arty_a7_i
       (.CFGITCMEN(CFGITCMEN),
        .CM3_CODE_AXI3_araddr(CM3_CODE_AXI3_araddr),
        .CM3_CODE_AXI3_arburst(CM3_CODE_AXI3_arburst),
        .CM3_CODE_AXI3_arcache(CM3_CODE_AXI3_arcache),
        .CM3_CODE_AXI3_arlen(CM3_CODE_AXI3_arlen),
        .CM3_CODE_AXI3_arlock(CM3_CODE_AXI3_arlock),
        .CM3_CODE_AXI3_arprot(CM3_CODE_AXI3_arprot),
        .CM3_CODE_AXI3_arready(CM3_CODE_AXI3_arready),
        .CM3_CODE_AXI3_arsize(CM3_CODE_AXI3_arsize),
        .CM3_CODE_AXI3_aruser(CM3_CODE_AXI3_aruser),
        .CM3_CODE_AXI3_arvalid(CM3_CODE_AXI3_arvalid),
        .CM3_CODE_AXI3_awaddr(CM3_CODE_AXI3_awaddr),
        .CM3_CODE_AXI3_awburst(CM3_CODE_AXI3_awburst),
        .CM3_CODE_AXI3_awcache(CM3_CODE_AXI3_awcache),
        .CM3_CODE_AXI3_awlen(CM3_CODE_AXI3_awlen),
        .CM3_CODE_AXI3_awlock(CM3_CODE_AXI3_awlock),
        .CM3_CODE_AXI3_awprot(CM3_CODE_AXI3_awprot),
        .CM3_CODE_AXI3_awready(CM3_CODE_AXI3_awready),
        .CM3_CODE_AXI3_awsize(CM3_CODE_AXI3_awsize),
        .CM3_CODE_AXI3_awuser(CM3_CODE_AXI3_awuser),
        .CM3_CODE_AXI3_awvalid(CM3_CODE_AXI3_awvalid),
        .CM3_CODE_AXI3_bready(CM3_CODE_AXI3_bready),
        .CM3_CODE_AXI3_bresp(CM3_CODE_AXI3_bresp),
        .CM3_CODE_AXI3_bvalid(CM3_CODE_AXI3_bvalid),
        .CM3_CODE_AXI3_rdata(CM3_CODE_AXI3_rdata),
        .CM3_CODE_AXI3_rlast(CM3_CODE_AXI3_rlast),
        .CM3_CODE_AXI3_rready(CM3_CODE_AXI3_rready),
        .CM3_CODE_AXI3_rresp(CM3_CODE_AXI3_rresp),
        .CM3_CODE_AXI3_rvalid(CM3_CODE_AXI3_rvalid),
        .CM3_CODE_AXI3_wdata(CM3_CODE_AXI3_wdata),
        .CM3_CODE_AXI3_wlast(CM3_CODE_AXI3_wlast),
        .CM3_CODE_AXI3_wready(CM3_CODE_AXI3_wready),
        .CM3_CODE_AXI3_wstrb(CM3_CODE_AXI3_wstrb),
        .CM3_CODE_AXI3_wvalid(CM3_CODE_AXI3_wvalid),
        .JTAGNSW(JTAGNSW),
        .JTAGTOP(JTAGTOP),
        .M3_RESET_OUT(M3_RESET_OUT),
        .SWCLK(SWCLK),
        .SWDI(SWDI),
        .SWDO(SWDO),
        .SWDOEN(SWDOEN),
        .SWV(SWV),
        .TDI(TDI),
        .TDO(TDO),
        .TRACECLK(TRACECLK),
        .TRACEDATA(TRACEDATA),
        .TRCENA(TRCENA),
        .ext_clock(ext_clock),
        .gpio_rtl_0_tri_o(gpio_rtl_0_tri_o),
        .locked(locked),
        .nTDOEN(nTDOEN),
        .nTRST(nTRST),
        .reset(reset),
        .sys_clock(sys_clock),
        .usb_uart_rxd(usb_uart_rxd),
        .usb_uart_txd(usb_uart_txd));
endmodule
