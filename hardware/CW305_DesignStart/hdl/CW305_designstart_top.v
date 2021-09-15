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

`timescale 1 ns / 1 ps
`default_nettype none

module CW305_designstart_top #(
  parameter pBYTECNT_SIZE = 7,
  parameter pADDR_WIDTH = 21,
  parameter pBUFFER_SIZE = 64,
  parameter pMATCH_RULES = 8
)(
  // clocks and resets:
  input  wire resetn_pin,
  input  wire tio_clkin,
  input  wire pll_clk1,
  output wire ext_clock,

  // for simulation only:
  `ifdef __ICARUS__
  input wire  I_trigger_clk,
  output wire trace_generator_done,
  `endif

  // debug:
  inout  wire swdio,
  input  wire swclk,
  input  wire TDI,
  inout  wire SWOTDO,
  input  wire nTRST,
  output wire swv,
  output wire TRACECLK_OUT,
  output wire TRCENA,
  output wire [3:0] TRACEDATA,

  // switches:
  input  wire j16_sel,  // clock source select
  input  wire k16_sel,  // unused
  input  wire l14_sel,  // unused
  input  wire k15_sel,  // unused

  // uart:
  input  wire uart_rxd,
  output wire uart_txd,

  // CW trigger:
  output wire trig_out,
  output wire trig_out_dbg,
  output wire m3_trig_out,

  // CW305 USB:
  input wire          USB_clk,
  inout wire [7:0]    USB_Data,
  input wire [pADDR_WIDTH-1:0] USB_Addr,
  input wire          USB_nRD,
  input wire          USB_nWE,
  input wire          USB_nCS,

  // leds:
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
  wire tdo;
  wire m3_reset_out;
  wire swotdo;
  wire nTDOEN;
  wire TRACECLK;

  wire trace_trig_out;
  wire soft_trig_passthru;

  wire reset_pin = !resetn_pin;
  wire fpga_reset;

  wire trigger_clk;
  wire trigger_clk_locked;
  wire trigger_clk_psen;
  wire trigger_clk_psincdec;
  wire trigger_clk_psdone;

  wire arm;
  wire capturing;

  assign swdio = SWDOEN ? SWDO : 1'bz;
  assign SWDI = swdio;

  reg [22:0] count;

  always @(posedge ext_clock) begin
     if (trig_out == 1'b0) // disable counter during capture to minimize noise
        count <= count + 1;
  end

  assign led1 = count[22];              // clock alive
  assign led2 = arm;
  assign led3 = capturing;

  assign trig_out = soft_trig_passthru? m3_trig_out : trace_trig_out;
  assign trig_out_dbg = soft_trig_passthru? m3_trig_out : trace_trig_out;

  // controls where program is fetched from:
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
        .nTDOEN                 (nTDOEN),
        .SWV                    (swv),
        .nTRST                  (nTRST),
        .reset                  (~fpga_reset),
        .sys_clock              (sys_clock),
        .ext_clock              (ext_clock),
        .gpio_rtl_0_tri_o       (m3_trig_out),
        .usb_uart_rxd           (uart_rxd),
        .usb_uart_txd           (uart_txd),
        .CFGITCMEN              (cfg),
        .M3_RESET_OUT           (m3_reset_out),
        .TRCENA                 (TRCENA),
        .TRACECLK               (TRACECLK),
        .TRACEDATA              (TRACEDATA),

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

  `else 
     // in simulation we simply emulate the trace pins instead:
     assign ext_clock = sys_clock;
     tb_trace_generator #(
           .pSWO_MODE              (0)
     ) U_tb_trace_generator
          (.target_clk             (sys_clock),
           .swo_clk                (1'b0),
           .reset                  (fpga_reset),
           .TRACEDATA              (TRACEDATA),
           .trig_out               (m3_trig_out),
           .done                   (trace_generator_done),
           .swo                    ()
          );
  `endif


    // choose and buffer input clock based on J16 dip switch:
  `ifndef __ICARUS__
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
  `else
    assign sys_clock = j16_sel? pll_clk1 : tio_clkin;
  `endif



  // JTAG or SW: multiplexing of other pins is handled by the M3 core, but the
  // SWO/TDO mux logic was left for us to handle:
  assign swotdo = JTAGNSW? tdo : swv;

  `ifndef __ICARUS__
  OBUF #(
         .DRIVE (12),                  // Specify the output drive strength
         .IOSTANDARD ("DEFAULT")       // Specify the I/O standard
        )
  OBUF_inst (
         .O (SWOTDO),
         .I (swotdo)
        ); 
     
  `else
  assign SWOTDO = swotdo;
  `endif


  `ifndef __ICARUS__
  ODDR TRACECLK_ODDR (
     .Q(TRACECLK_OUT),   // 1-bit DDR output
     .C(TRACECLK),   // 1-bit clock input
     .CE(1'b1), // 1-bit clock enable input
     .D1(1'b1), // 1-bit data input (positive edge)
     .D2(1'b0), // 1-bit data input (negative edge)
     .R(1'b0),   // 1-bit reset
     .S(1'b0)    // 1-bit set
  );
  `else
  assign TRACECLK_OUT = TRACECLK;
  `endif


  wire clk_usb_buf;

   `ifdef __ICARUS__
      assign clk_usb_buf = USB_clk;
   `else
      IBUFG U_usb_clk_buf (
           .O(clk_usb_buf),
           .I(USB_clk) );
   `endif

   `ifdef __ICARUS__
      assign trigger_clk = I_trigger_clk;
      assign trigger_clk_locked = 1'b1;
      assign trigger_clk_psdone = 1'b1;
   `else
       clk_wiz_0 U_trigger_clock (
         .reset        (reset),
         .clk_in1      (fe_clk),
         .clk_out1     (trigger_clk),
         // Dynamic phase shift ports
         .psclk        (clk_usb_buf),
         .psen         (trigger_clk_psen),
         .psincdec     (trigger_clk_psincdec),
         .psdone       (trigger_clk_psdone),
         // Status and control signals
         .locked       (trigger_clk_locked)
      );
   `endif


   trace_top #(
      .pBYTECNT_SIZE    (7),
      .pADDR_WIDTH      (21),
      .pBUFFER_SIZE     (64),
      .pMATCH_RULES     (8)
   ) U_trace_top (
      .trace_clk_in     (1'b0),
      .target_clk       (ext_clock),
      .fe_clk           (),
      .usb_clk          (clk_usb_buf),
      .reset_pin        (reset_pin),
      .fpga_reset       (fpga_reset),

      .trigger_clk          (trigger_clk),
      .trigger_clk_locked   (trigger_clk_locked),
      .trigger_clk_psen     (trigger_clk_psen    ),
      .trigger_clk_psincdec (trigger_clk_psincdec),
      .trigger_clk_psdone   (trigger_clk_psdone  ),

      .trace_data       (TRACEDATA),
      .O_trace_trig_out (trace_trig_out),
      .m3_trig          (m3_trig_out),
      .O_soft_trig_passthru (soft_trig_passthru),

      `ifdef __ICARUS__
      .I_trace_sdr      (8'b0),
      `endif

      .USB_Data         (USB_Data ),
      .USB_Addr         (USB_Addr ),
      .USB_nRD          (USB_nRD  ),
      .USB_nWE          (USB_nWE  ),
      .USB_nCS          (USB_nCS  ),
      .O_data_available ( ), // unused
      .I_fast_fifo_rdn  (1'b1), // unused

      .O_board_rev      (),     // used for PhyWhisperer platform only

      .arm              (arm),
      .capturing        (capturing),

      // unused for CW305:
      .swo              (1'b0),
      .userio_d         (4'b0),
      .O_userio_pwdriven (),
      .O_userio_drive_data (),

      .synchronized     ()
   );


endmodule
`default_nettype wire
