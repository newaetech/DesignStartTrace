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

module tb_trace_generator (
  input  wire trace_clk,
  input  wire swo_clk,
  input  wire reset,
  output reg  [3:0] TRACEDATA,
  output wire swo,
  output reg  trig_out
);

parameter pSWO_MODE = 0;
parameter pSWO_DIV = 15;

reg [15:0] i;
reg [3:0] tracedata [0:32767];
reg [63:0] trigtime [0:1];
reg [3:0] TRACEDATA_r;
reg swo_txin_trace;
reg swo_txin_trace_r;
reg  swo_txin;
wire [7:0] swo_tx_datain;

initial begin
   $readmemh("tracedata.mem", tracedata);
   $readmemh("swtrigtime.mem", trigtime);
end

always @(posedge trace_clk) begin
   if (reset) begin
      i <= 0;
      TRACEDATA <= 0;
      TRACEDATA_r <= 0;
      swo_txin_trace <= 0;
   end
   else begin
      i <= i + 1;
      TRACEDATA <= tracedata[i];
      TRACEDATA_r <= TRACEDATA;
      if (i == trigtime[0])
         trig_out <= 1'b1;
      else
         trig_out <= 1'b0;
      if (i[0])
         swo_txin_trace <= 1'b1;
      else
         swo_txin_trace <= 1'b0;
   end
end

/*
cdc_pulse U_swo_cdc (
   .reset_i       (reset),
   .src_clk       (trace_clk),
   .src_pulse     (swo_txin_trace),
   .dst_clk       (swo_clk),
   .dst_pulse     (swo_txin)
);
*/

always @(posedge swo_clk) begin
   swo_txin_trace_r <= swo_txin_trace;
   if (swo_txin_trace & ~swo_txin_trace_r)
      swo_txin <= 1'b1;
   else
      swo_txin <= 1'b0;

end


assign swo_tx_datain = {TRACEDATA, TRACEDATA_r};

uart_core U_uart_tx (
   .clk                      (swo_clk),
   .reset_n                  (~reset),
   // Configuration inputs
   .bit_rate                 (pSWO_DIV),
   .data_bits                (4'd8),
   .stop_bits                (2'd1),
   // External data interface
   .rxd                      (),
   .txd                      (swo),
   // UART Rx
   .rxd_syn                  (),
   .rxd_data                 (),
   .rxd_ack                  (1'b0),
   .rxd_state                (),
   // UART Tx (unused)
   .txd_syn                  (swo_txin),
   .txd_data                 (swo_tx_datain),
   .txd_ack                  ()
);


endmodule
`default_nettype wire
