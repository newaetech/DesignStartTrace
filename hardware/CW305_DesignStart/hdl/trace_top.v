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

module trace_top #(
  parameter pBYTECNT_SIZE = 7,
  parameter pADDR_WIDTH = 21,
  parameter pBUFFER_SIZE = 64,
  parameter pMATCH_RULES = 8
)(
  input  wire trace_clk,
  input  wire usb_clk,
  input  wire reset,

  // trace:
  input  wire TRCENA,
  input  wire [3:0] TRACEDATA,
  output wire O_trace_trig_out,
  output wire O_trace_trig_enable,

  // USB:
  inout wire [7:0]    USB_Data,
  input wire [pADDR_WIDTH-1:0] USB_Addr,
  input wire          USB_nRD,
  input wire          USB_nWE,
  input wire          USB_nCS

);


   wire isout;
   wire [7:0] cmdfifo_din;
   wire [7:0] cmdfifo_dout;
   wire [pADDR_WIDTH-1:pBYTECNT_SIZE]  reg_address;
   wire [pBYTECNT_SIZE-1:0]  reg_bytecnt;
   wire [7:0]   write_data;
   wire [7:0]   read_data;
   wire         reg_read;
   wire         reg_write;
   wire         reg_addrvalid;


   assign USB_Data = isout ? cmdfifo_dout : 8'bZ;
   assign cmdfifo_din = USB_Data;

   cw305_usb_reg_fe #(
      .pBYTECNT_SIZE    (pBYTECNT_SIZE)
   ) U_usb_reg_main (
      .rst              (reset),
      .usb_clk          (usb_clk), 
      .usb_din          (cmdfifo_din), 
      .usb_dout         (cmdfifo_dout), 
      .usb_rdn          (USB_nRD), 
      .usb_wrn          (USB_nWE),
      .usb_cen          (USB_nCS),
      .usb_alen         (1'b0),
      .usb_addr         (USB_Addr),
      .usb_isout        (isout), 
      .reg_address      (reg_address), 
      .reg_bytecnt      (reg_bytecnt), 
      .reg_datao        (write_data), 
      .reg_datai        (read_data),
      .reg_read         (reg_read), 
      .reg_write        (reg_write), 
      .reg_addrvalid    (reg_addrvalid)
   );


   wire [4:0] clksettings; // TODO-later
   wire [pMATCH_RULES-1:0] matching_pattern;
   wire [pBUFFER_SIZE-1:0] matching_buffer;
   wire synchronized;
   wire [pBUFFER_SIZE-1:0] last_blurb;

   wire [pMATCH_RULES-1:0] pattern_enable;
   wire trace_reset_sync;
   wire [2:0] trace_width;
   wire trig_toggle;

   wire [pBUFFER_SIZE-1:0] trace_pattern0;
   wire [pBUFFER_SIZE-1:0] trace_pattern1;
   wire [pBUFFER_SIZE-1:0] trace_pattern2;
   wire [pBUFFER_SIZE-1:0] trace_pattern3;
   wire [pBUFFER_SIZE-1:0] trace_pattern4;
   wire [pBUFFER_SIZE-1:0] trace_pattern5;
   wire [pBUFFER_SIZE-1:0] trace_pattern6;
   wire [pBUFFER_SIZE-1:0] trace_pattern7;

   wire [pBUFFER_SIZE-1:0] trace_mask0;
   wire [pBUFFER_SIZE-1:0] trace_mask1;
   wire [pBUFFER_SIZE-1:0] trace_mask2;
   wire [pBUFFER_SIZE-1:0] trace_mask3;
   wire [pBUFFER_SIZE-1:0] trace_mask4;
   wire [pBUFFER_SIZE-1:0] trace_mask5;
   wire [pBUFFER_SIZE-1:0] trace_mask6;
   wire [pBUFFER_SIZE-1:0] trace_mask7;

   wire [7:0] trace_count0;
   wire [7:0] trace_count1;
   wire [7:0] trace_count2;
   wire [7:0] trace_count3;
   wire [7:0] trace_count4;
   wire [7:0] trace_count5;
   wire [7:0] trace_count6;
   wire [7:0] trace_count7;


   wire [pBUFFER_SIZE-1:0] revbuffer;
   wire valid_buffer;
   wire [2:0] blurb_count;
   wire blurb_ready;


   reg_trace #(
      .pADDR_WIDTH              (pADDR_WIDTH),
      .pBYTECNT_SIZE            (pBYTECNT_SIZE),
      .pBUFFER_SIZE             (pBUFFER_SIZE),
      .pMATCH_RULES             (pMATCH_RULES)
   ) U_reg_pw (
      .reset_i                  (reset), 
      .usb_clk                  (usb_clk), 
      .reg_address              (reg_address), 
      .reg_bytecnt              (reg_bytecnt), 
      .read_data                (read_data), 
      .write_data               (write_data),
      .reg_read                 (reg_read), 
      .reg_write                (reg_write), 
      .reg_addrvalid            (reg_addrvalid),

      .O_clksettings            (clksettings),

      .I_matching_pattern       (matching_pattern),
      .I_matching_buffer        (matching_buffer ),
      .I_synchronized           (synchronized    ),
      .I_last_blurb             (last_blurb      ),

      .O_pattern_enable         (pattern_enable  ),
      .O_trace_reset_sync       (trace_reset_sync),
      .O_trace_width            (trace_width     ),
      .O_trig_toggle            (trig_toggle     ),
      .O_trace_trig_enable      (O_trace_trig_enable),

      .O_trace_pattern0         (trace_pattern0  ),
      .O_trace_pattern1         (trace_pattern1  ),
      .O_trace_pattern2         (trace_pattern2  ),
      .O_trace_pattern3         (trace_pattern3  ),
      .O_trace_pattern4         (trace_pattern4  ),
      .O_trace_pattern5         (trace_pattern5  ),
      .O_trace_pattern6         (trace_pattern6  ),
      .O_trace_pattern7         (trace_pattern7  ),

      .O_trace_mask0            (trace_mask0     ),
      .O_trace_mask1            (trace_mask1     ),
      .O_trace_mask2            (trace_mask2     ),
      .O_trace_mask3            (trace_mask3     ),
      .O_trace_mask4            (trace_mask4     ),
      .O_trace_mask5            (trace_mask5     ),
      .O_trace_mask6            (trace_mask6     ),
      .O_trace_mask7            (trace_mask7     ),

      .I_trace_count0           (trace_count0    ),
      .I_trace_count1           (trace_count1    ),
      .I_trace_count2           (trace_count2    ),
      .I_trace_count3           (trace_count3    ),
      .I_trace_count4           (trace_count4    ),
      .I_trace_count5           (trace_count5    ),
      .I_trace_count6           (trace_count6    ),
      .I_trace_count7           (trace_count7    )
   );


   trace_trigger #(
      .pBUFFER_SIZE             (pBUFFER_SIZE),
      .pMATCH_RULES             (pMATCH_RULES)
   ) U_trace_trigger (
      .TRACECLK                 (trace_clk),
      .TRACEDATA                (TRACEDATA),
      .TRCENA                   (TRCENA),
      .reset                    (reset),
      .I_pattern_enable         (pattern_enable  ),
      .I_toggle                 (trig_toggle     ),
      .I_reset_sync             (trace_reset_sync),
      .I_trace_width            (trace_width     ),
      .I_pattern0               (trace_pattern0  ),
      .I_pattern1               (trace_pattern1  ),
      .I_pattern2               (trace_pattern2  ),
      .I_pattern3               (trace_pattern3  ),
      .I_pattern4               (trace_pattern4  ),
      .I_pattern5               (trace_pattern5  ),
      .I_pattern6               (trace_pattern6  ),
      .I_pattern7               (trace_pattern7  ),
      .I_mask0                  (trace_mask0     ),
      .I_mask1                  (trace_mask1     ),
      .I_mask2                  (trace_mask2     ),
      .I_mask3                  (trace_mask3     ),
      .I_mask4                  (trace_mask4     ),
      .I_mask5                  (trace_mask5     ),
      .I_mask6                  (trace_mask6     ),
      .I_mask7                  (trace_mask7     ),
      .O_trace_count0           (trace_count0    ),
      .O_trace_count1           (trace_count1    ),
      .O_trace_count2           (trace_count2    ),
      .O_trace_count3           (trace_count3    ),
      .O_trace_count4           (trace_count4    ),
      .O_trace_count5           (trace_count5    ),
      .O_trace_count6           (trace_count6    ),
      .O_trace_count7           (trace_count7    ),
      .O_matching_pattern       (matching_pattern),
      .O_matching_buffer        (matching_buffer ),
      .O_last_blurb             (last_blurb      ),
      .O_trace_trig_out         (O_trace_trig_out),

     // debug only ports:
      .O_buffer                 (),
      .O_revbuffer              (revbuffer),
      .O_valid_buffer           (valid_buffer),
      .O_synchronized           (synchronized),
      .O_blurb_count            (blurb_count),
      .O_blurb_ready            (blurb_ready)
   );


   `ifdef ILA_REG
       ila_reg I_reg_ila (
          .clk          (usb_clk),              // input wire clk
          .probe0       (USB_Data),             // input wire [7:0]  probe0  
          .probe1       (USB_Addr),             // input wire [7:0]  probe1 
          .probe2       (USB_nRD),              // input wire [0:0]  probe2 
          .probe3       (USB_nWE),              // input wire [0:0]  probe3 
          .probe4       (USB_nCS),              // input wire [0:0]  probe4 
          .probe5       (1'b0),                 // input wire [0:0]  probe5 
          .probe6       (reg_address),          // input wire [5:0]  probe6 
          .probe7       (reg_bytecnt),          // input wire [6:0]  probe7 
          .probe8       (write_data),           // input wire [7:0]  probe8 
          .probe9       (read_data),            // input wire [15:0] probe9 
          .probe10      (reg_read),             // input wire [0:0]  probe10 
          .probe11      (reg_write),            // input wire [0:0]  probe11 
          .probe12      (reg_addrvalid),        // input wire [0:0]  probe12 
          .probe13      (32'b0)                 // input wire [31:0] probe13 
       );
   `endif

   `ifdef ILA_TRACE
       ila_trace1 I_trace_ila (
          .clk          (trace_clk),            // input wire clk
          .probe0       (TRCENA),               // input wire [0:0]  probe0  
          .probe1       (TRACECLK),             // input wire [0:0]  probe1 
          .probe2       (TRACEDATA),            // input wire [3:0]  probe2 
          .probe3       (trace_width),          // input wire [2:0]  probe3 
          .probe4       (blurb_count),          // input wire [2:0]  probe4 
          .probe5       (blurb_ready),          // input wire [0:0]  probe5 
          .probe6       (valid_buffer),         // input wire [0:0]  probe6 
          .probe7       (matching_pattern),     // input wire [7:0]  probe7 
          .probe8       (matching_buffer),      // input wire [63:0] probe8 
          .probe9       (last_blurb),           // input wire [63:0] probe9 
          .probe10      (revbuffer),            // input wire [63:0] probe10 
          .probe11      (synchronized)          // input wire [0:0]  probe11 
       );
   `endif


endmodule
`default_nettype wire
