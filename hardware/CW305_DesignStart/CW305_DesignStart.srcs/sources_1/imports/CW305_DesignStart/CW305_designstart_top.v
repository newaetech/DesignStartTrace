/* 
Copyright (c) 2019-2020, NewAE Technology Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted without restriction. Note that modules within
the project may have additional restrictions, please carefully inspect
additional licenses.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies,
either expressed or implied, of NewAE Technology Inc.
*/

`timescale 1 ps / 1 ps
`default_nettype none

module CW305_designstart_top (
  inout  wire swdio,
  input  wire swclk,
  input  wire TDI,
  inout  wire SWOTDO,
  input  wire nTRST,
  input  wire reset,
  input  wire tio_clkin,
  input  wire pll_clk1,
  input  wire j16_sel,
  input  wire k16_sel,  // unused
  input  wire l14_sel,  // unused
  input  wire k15_sel,  // unused

  output wire ext_clock,
  output wire trig_out,
  input  wire uart_rxd,
  output wire uart_txd,
  output wire led1,
  output wire led2,
  output wire led3
);

  wire sys_clock;
  wire SWDI;
  wire SWDO;
  wire SWDOEN;
  wire JTAGTOP;
  wire JTAGNSW;
  wire swv;
  wire tdo;
  wire m3_reset_out;
  wire swotdo;
  wire nTDOEN;

  assign swdio = SWDOEN ? SWDO : 1'bz;
  assign SWDI = swdio;

  reg [22:0] count;

  always @(posedge ext_clock or negedge reset) begin
     if (!reset)
        count <= 23'b0;
     else if (trig_out == 1'b0) // disable counter during capture to minimize noise
        count <= count + 1;
  end

  assign led1 = count[22];              // clock alive
  assign led2 = ~m3_reset_out;                 // TODO-temp debug
  assign led3 = uart_rxd ^ uart_txd;    // UART activity

  // saved bitfile: auxreset was 1'b1, CFMDFGD was 2'b10
  // WORKS! K16 = 1 (auxrst = 1);
  //        L14 = 0, K15 = 1 (cfg = 2'b01)
  //wire [1:0] cfg = {l14_sel, k15_sel};
  wire [1:0] cfg = 2'b01;


  `ifndef __ICARUS__
  m3_for_arty_a7 m3_for_arty_a7_i
       (.SWCLK                  (swclk),
        .SWDI                   (SWDI),
        .SWDO                   (SWDO),
        .SWDOEN                 (SWDOEN),
        .JTAGTOP                (JTAGTOP),
        .JTAGNSW                (JTAGNSW),
        .TDI                    (TDI),
        .TDO                    (tdo),
        .SWV                    (swv),
        .nTRST                  (nTRST),
        .reset                  (reset),
        .sys_clock              (sys_clock),
        .ext_clock              (ext_clock),
        .gpio_rtl_0_tri_o       (trig_out),
        //.gpio_rtl_0_tri_o       (), // TODO-temp debug
        .usb_uart_rxd           (uart_rxd),
        .usb_uart_txd           (uart_txd),

        // connect to DIP switches to get right setting...
        .CFGITCMEN              (cfg),
        .M3_RESET_OUT           (m3_reset_out),
        .locked                 (),

        // unused AXI port inputs:
        .CM3_CODE_AXI3_arready  (1'b0),
        .CM3_CODE_AXI3_awready  (1'b0),
        .CM3_CODE_AXI3_bresp    (2'b0),
        .CM3_CODE_AXI3_bvalid   (1'b0),
        .CM3_CODE_AXI3_rdata    (32'b0),
        .CM3_CODE_AXI3_rlast    (1'b0),
        .CM3_CODE_AXI3_rresp    (2'b0),
        .CM3_CODE_AXI3_rvalid   (1'b0),
        .CM3_CODE_AXI3_wready   (1'b0),

        // unused AXI port outputs:
        .CM3_CODE_AXI3_araddr   (),
        .CM3_CODE_AXI3_arburst  (),
        .CM3_CODE_AXI3_arcache  (),
        .CM3_CODE_AXI3_arlen    (),
        .CM3_CODE_AXI3_arlock   (),
        .CM3_CODE_AXI3_arprot   (),
        .CM3_CODE_AXI3_arsize   (),
        .CM3_CODE_AXI3_aruser   (),
        .CM3_CODE_AXI3_arvalid  (),
        .CM3_CODE_AXI3_awaddr   (),
        .CM3_CODE_AXI3_awburst  (),
        .CM3_CODE_AXI3_awcache  (),
        .CM3_CODE_AXI3_awlen    (),
        .CM3_CODE_AXI3_awlock   (),
        .CM3_CODE_AXI3_awprot   (),
        .CM3_CODE_AXI3_awsize   (),
        .CM3_CODE_AXI3_awuser   (),
        .CM3_CODE_AXI3_awvalid  (),
        .CM3_CODE_AXI3_bready   (),
        .CM3_CODE_AXI3_rready   (),
        .CM3_CODE_AXI3_wdata    (),
        .CM3_CODE_AXI3_wlast    (),
        .CM3_CODE_AXI3_wstrb    (),
        .CM3_CODE_AXI3_wvalid   ()
       );
  `endif


    // choose and buffer input clock based on J16 dip switch:
    BUFGCTRL CCLK_MUX (
       .O                       (sys_clock),    // Clock output
       .CE0                     (1'b1),         // Clock enable input for I0
       .CE1                     (1'b1),         // Clock enable input for I1
       .I0                      (pll_clk1),     // Primary clock
       .I1                      (tio_clkin),    // Secondary clock
       .IGNORE0                 (1'b1),         // Clock ignore input for I0
       .IGNORE1                 (1'b1),         // Clock ignore input for I1
       .S0                      (~j16_sel),     // Clock select for I0
       .S1                      (j16_sel)       // Clock select for I1
    );



  assign swotdo = nTDOEN? swv : tdo;
  OBUF #(
         .DRIVE (12),                  // Specify the output drive strength
         .IOSTANDARD ("DEFAULT")       // Specify the I/O standard
        )
  OBUF_inst (
         .O (SWOTDO),
         .I (swotdo)
        ); 
     


endmodule
`default_nettype wire
