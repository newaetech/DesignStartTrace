/* 
Copyright (c) 2020, NewAE Technology Inc.
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

module tracewhisperer_top #(
  parameter pBYTECNT_SIZE = 7,
  parameter pADDR_WIDTH = 8,
  parameter pBUFFER_SIZE = 64,
  parameter pMATCH_RULES = 8
)(
  // clocks and resets:
  input  wire reset,

  // for simulation only:
  `ifdef __ICARUS__
  input wire  I_trigger_clk,
  input wire  I_trace_clk,
  `endif

  // CW trigger:
  output wire trig_out,
  output wire mcx_trig,

  // host USB:
  input wire          USB_clk,
  inout wire [7:0]    USB_Data,
  input wire [pADDR_WIDTH-1:0] USB_Addr,
  input wire          USB_nRD,
  input wire          USB_nWE,
  input wire          USB_nCS,
  input wire          USB_SPARE1,

  // trace:
  input wire          TRCENA,
  input wire          TRACECLOCK,
  input wire [3:0]    TRACEDATA,

  // target trigger:
  input wire          target_trig_in,

  // debug:
  output wire         trace_clk_locked,
  output wire         synchronized,

  // leds:
  output wire led1,
  output wire led2,
  output wire led3,

  output wire reset_dbg // TODO-debug only
);

  wire arm;
  wire capturing;
  wire trace_clk;

  reg [22:0] count;

  assign reset_dbg = reset;

  always @(posedge trace_clk) begin
     if (reset)
        count <= 23'b0;
     else if (trig_out == 1'b0) // disable counter during capture to minimize noise
        count <= count + 1;
  end

  assign led1 = count[22];              // clock alive
  assign led2 = arm;
  assign led3 = capturing;

  assign mcx_trig = trig_out;

  wire clk_usb_buf;

   `ifdef __ICARUS__
      assign clk_usb_buf = USB_clk;
   `else
      IBUFG U_usb_clk_buf (
           .O(clk_usb_buf),
           .I(USB_clk) );
   `endif


   trace_top #(
      .pBYTECNT_SIZE    (pBYTECNT_SIZE),
      .pADDR_WIDTH      (pADDR_WIDTH),
      .pBUFFER_SIZE     (pBUFFER_SIZE),
      .pMATCH_RULES     (pMATCH_RULES)
   ) U_trace_top (
      .trace_clk_in     (TRACECLOCK),
      .trace_clk_out    (trace_clk),
      .usb_clk          (clk_usb_buf),
      .reset            (reset    ),
                                  
      .trace_data       (TRACEDATA),
      .O_trace_trig_out (trig_out),
      .m3_trig          (target_trig_in),

      `ifdef __ICARUS__
      .I_trigger_clk    (I_trigger_clk),
      .I_trace_clk      (I_trace_clk),
      `endif
                                  
      .USB_Data         (USB_Data ),
      .USB_Addr         (USB_Addr ),
      .USB_nRD          (USB_nRD  ),
      .USB_nWE          (USB_nWE  ),
      .USB_nCS          (USB_nCS  ),
      .USB_SPARE1       (USB_SPARE1 ),

      /* TODO: needed?
      .trace_psen      (psen),
      .trace_psincdec  (psincdec),
      .trace_psdone    (psdone),
      */

      .arm              (arm),
      .capturing        (capturing),

      .trace_clk_locked (trace_clk_locked),
      .synchronized     (synchronized)
   );


endmodule
`default_nettype wire
