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
  wire [31:0] buildtime;

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
  wire fe_clk;

  wire [6:0]     trig_drp_addr;
  wire           trig_drp_den;
  wire [15:0]    trig_drp_din;
  wire [15:0]    trig_drp_dout;
  wire           trig_drp_dwe;
  wire           trig_drp_reset;

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

   `elsif LINT

   `else 
     // in simulation we simply emulate the trace pins instead:
     assign ext_clock = sys_clock;
     tb_trace_generator #(
           .pSWO_MODE              (0)
     ) U_tb_trace_generator
          (.target_clk_trace       (sys_clock),
           .swo_clk                (1'b0),
           .reset                  (fpga_reset),
           .TRACEDATA              (TRACEDATA),
           .trig_out               (m3_trig_out),
           .done                   (trace_generator_done),
           .setup_done             (1'b0),
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
         .reset        (fpga_reset),
         .clk_in1      (fe_clk),
         .clk_out1     (trigger_clk),
         // Dynamic phase shift ports
         .psclk        (clk_usb_buf),
         .psen         (trigger_clk_psen),
         .psincdec     (trigger_clk_psincdec),
         .psdone       (trigger_clk_psdone),
         // Status and control signals
         .locked       (trigger_clk_locked),
         // Dynamic reconfiguration ports:
         .daddr        (trig_drp_addr),
         .dclk         (clk_usb_buf),
         .den          (trig_drp_den),
         .din          (trig_drp_din),
         .dout         (trig_drp_dout),
         .drdy         (),
         .dwe          (trig_drp_dwe)
      );
   `endif

   wire isout;
   wire usb_drive_data;
   wire [7:0] cmdfifo_din;
   wire [7:0] cmdfifo_dout_pre;
   //reg  [7:0] cmdfifo_dout_reg;
   wire [7:0] cmdfifo_dout;
   wire [pBYTECNT_SIZE-1:0]  reg_bytecnt;
   wire [7:0]   write_data;
   wire [7:0]   read_data;
   wire [7:0]   read_data_trace;
   wire [7:0]   read_data_trace_trigger_drp;
   wire [7:0]   read_data_main;
   wire         reg_read;
   wire         reg_write;
   wire         reg_addrvalid;

   wire         fifo_full;
   wire         fifo_overflow_blocked;
   wire [17:0]  fifo_in_data;
   wire         fifo_wr;
   wire         fifo_read;
   wire         fifo_flush;
   wire         reg_arm;
   wire         reg_arm_feclk;
   wire         clear_errors;
   wire [17:0]  fifo_out_data;
   wire [5:0]   fifo_status;
   wire         fifo_empty;
   wire         fifo_error_flag;
   wire         synchronized;


   assign USB_Data = isout ? cmdfifo_dout : 8'bZ;
   assign cmdfifo_din = USB_Data;
   //always @(posedge usb_clk)
   //   cmdfifo_dout_reg <= cmdfifo_dout_pre;
   //assign cmdfifo_dout = O_board_rev[3]? cmdfifo_dout_reg : cmdfifo_dout_pre;
   assign cmdfifo_dout = cmdfifo_dout_pre;


   wire [pADDR_WIDTH-pBYTECNT_SIZE-1:0]  reg_address;
   cw305_usb_reg_fe #(
      .pBYTECNT_SIZE    (pBYTECNT_SIZE)
   ) U_usb_reg_main (
      .rst              (fpga_reset),
      .usb_clk          (clk_usb_buf), 
      .usb_din          (cmdfifo_din), 
      .usb_dout         (cmdfifo_dout_pre), 
      .usb_rdn          (USB_nRD), 
      .usb_wrn          (USB_nWE),
      .usb_cen          (USB_nCS),
      .usb_addr         (USB_Addr),
      .usb_isout        (isout), 
      .I_drive_data     (usb_drive_data),
      .reg_address      (reg_address), 
      .reg_bytecnt      (reg_bytecnt), 
      .reg_datao        (write_data), 
      .reg_datai        (read_data),
      .reg_read         (reg_read), 
      .reg_write        (reg_write), 
      .reg_addrvalid    (reg_addrvalid)
   );

   trace_top #(
      .pBYTECNT_SIZE    (7),
      .pBUFFER_SIZE     (64),
      .pMATCH_RULES     (8)
   ) U_trace_top (
      .trace_clk_in     (1'b0),
      .target_clk       (ext_clock),
      .fe_clk           (fe_clk),
      .usb_clk          (clk_usb_buf),
      .reset_pin        (reset_pin),
      .fpga_reset       (fpga_reset),
      .I_fe_clock_count (count),
      .buildtime        (buildtime),
      .O_trace_en       (), // Husky only
      .O_trace_userio_dir (), // Husky only

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

      .USB_nCS          (USB_nCS  ),
      .O_data_available ( ), // unused
      .I_fast_fifo_rdn  (1'b1), // unused
      .O_led_select     (), // unused

      .usb_drive_data   (usb_drive_data),
      .reg_address      (reg_address[7:0]), 
      .reg_bytecnt      (reg_bytecnt), 
      .write_data       (write_data), 
      .read_data        (read_data),
      .reg_read         (reg_read), 
      .reg_write        (reg_write), 
      .reg_addrvalid    (reg_addrvalid),

      .arm              (arm),
      .capturing        (capturing),

      // FIFO interface:
      .fifo_full        (fifo_full),
      .fifo_overflow_blocked (fifo_overflow_blocked),
      .fifo_in_data     (fifo_in_data),
      .fifo_wr          (fifo_wr),
      .fifo_read        (fifo_read),
      .fifo_flush       (fifo_flush),
      .reg_arm          (reg_arm),
      .reg_arm_feclk    (reg_arm_feclk),
      .clear_errors     (clear_errors),
      .fifo_out_data    (fifo_out_data),
      .fifo_status      (fifo_status),
      .fifo_empty       (fifo_empty),
      .fifo_error_flag  (fifo_error_flag),

      // unused for CW305:
      .swo              (1'b0),
      .userio_d         (4'b0),
      .O_userio_pwdriven (),
      .O_userio_drive_data (),

      .trig_drp_addr    (trig_drp_addr ),
      .trig_drp_den     (trig_drp_den  ),
      .trig_drp_din     (trig_drp_din  ),
      .trig_drp_dout    (trig_drp_dout ),
      .trig_drp_dwe     (trig_drp_dwe  ),
      .trig_drp_reset   (trig_drp_reset),

      .synchronized     (synchronized)
   );


   `ifndef NOFIFO // for clean compilation
   fifo U_fifo (
      .reset_i                  (fpga_reset),
      .cwusb_clk                (clk_usb_buf),
      .fe_clk                   (fe_clk),

      .O_fifo_full              (fifo_full),
      .O_fifo_overflow_blocked  (fifo_overflow_blocked),
      .I_data                   (fifo_in_data),
      .I_wr                     (fifo_wr),

      .I_fifo_read              (fifo_read),
      .I_fifo_flush             (fifo_flush),
      .I_clear_read_flags       (reg_arm),
      .I_clear_write_flags      (reg_arm_feclk),
      .I_clear_errors           (clear_errors),

      .O_data                   (fifo_out_data),
      .O_fifo_status            (fifo_status),
      .O_fifo_empty             (fifo_empty),
      .O_error_flag             (fifo_error_flag),

      .I_custom_fifo_stat_flag  (synchronized)      
   );
   `endif


   `ifndef __ICARUS__
      USR_ACCESSE2 U_buildtime (
         .CFGCLK(),
         .DATA(buildtime),
         .DATAVALID()
      );
   `else
      assign buildtime = 0;
   `endif


endmodule
`default_nettype wire
