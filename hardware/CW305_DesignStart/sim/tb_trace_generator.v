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
  input  wire target_clk,
  input  wire swo_clk,
  input  wire reset,
  output reg  [3:0] TRACEDATA,
  output reg [7:0] trace_data_sdr,
  output wire swo,
  output reg  trig_out,
  output reg  done,
  output int  errors,
  input  wire setup_done
);

parameter pSWO_MODE = 0;
parameter pSWO_DIV = 16'd15;


reg [31:0] i;
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

int command;
int num_nibbles;
int j;
int tot_nibbles;

initial begin
   done = 0;
   i = 0;
   TRACEDATA = 0;
   swo_txin_trace = 0;
   trig_out = 0;
   tot_nibbles = 0;
   errors = 0;
   @ (negedge reset);
   @ (posedge target_clk);
   command = 0;
   while (command != 2) begin
      command = tracedata[i];
      i = i + 1;
      num_nibbles = tracedata[i];
      i = i + 1;
      num_nibbles += (tracedata[i] << 4);
      i = i + 1;
      //$display("Got command: %d, nibbles: %d, i: %d", command, num_nibbles, i);
      if (command == 0) begin
         if (num_nibbles %2) begin
             errors += 1;
             $display("TRACE GENERATOR ERROR: odd number of nibbles, this shouldn't happen");
         end
         for (j = 0; j < num_nibbles; j = j + 2)  begin
            @ (posedge target_clk);
            TRACEDATA_r = TRACEDATA;
            TRACEDATA = tracedata[i+j];
            trace_data_sdr = {tracedata[i+j+1], tracedata[i+j]};
            swo_txin_trace = 1'b0;
            @ (posedge target_clk);
            TRACEDATA_r = TRACEDATA;
            TRACEDATA = tracedata[i+j+1];
            swo_txin_trace = 1'b1;
         end
         i = i + num_nibbles;
         tot_nibbles = tot_nibbles + num_nibbles;
      end
      else if (command == 1) begin
         repeat (num_nibbles) @ (posedge target_clk);
         swo_txin_trace = 1'b0;
         tot_nibbles = tot_nibbles + num_nibbles;
      end
      else if (command == 2) begin
         $display("Info: done processing tracedata.mem.");
         done = 1;
      end
      else begin
         $display("ERROR: unexpected command %d (i=%d)", command, i);
         @ (posedge target_clk);
      end

      if (tot_nibbles == trigtime[0])
         #1 trig_out = 1;
      else
         trig_out = 0;
   end
end


always @(posedge swo_clk) begin
   swo_txin_trace_r <= swo_txin_trace;
   if (swo_txin_trace & ~swo_txin_trace_r)
      swo_txin <= 1'b1;
   else
      swo_txin <= 1'b0;

end


assign swo_tx_datain = {TRACEDATA, TRACEDATA_r};

wire txd_ack;
reg swo_txin_r;
always @(posedge swo_clk)
    swo_txin_r <= swo_txin;

initial begin
    if (pSWO_MODE) begin
        wait (setup_done);
        wait (swo_txin_r ^ txd_ack);
        errors += 1;
        $display("TRACE GENERATOR ERROR: tripping over ourselves on SWO generation. Bad combination of clock rates?");
    end
end



uart_core U_uart_tx (
   .clk                      (swo_clk),
   .reset_n                  (~reset),
   // Configuration inputs
   .bit_rate                 (pSWO_DIV),
   .data_bits                (4'd8),
   .stop_bits                (2'd1),
   // External data interface
   .rxd                      (1'b1),
   .txd                      (swo),
   // UART Rx (unused)
   .rxd_syn                  (),
   .rxd_data                 (),
   .rxd_ack                  (1'b0),
   .rxd_state                (),
   // UART Tx
   .txd_syn                  (swo_txin),
   .txd_data                 (swo_tx_datain),
   .txd_ack                  (txd_ack)
);


endmodule
`default_nettype wire
