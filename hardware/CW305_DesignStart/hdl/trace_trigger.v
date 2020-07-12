//////////////////////////////////////////////////////////////////////////////////
// Company: NewAE
// Engineer: Jean-Pierre Thibault
// 
// Create Date: 
// Design Name: 
// Module Name: reg_trace
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Register block for trace module. To be paired with
// cw305_usb_reg_fe.v.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps
`default_nettype none

module trace_trigger #(
   parameter pBUFFER_SIZE = 64, // in bits
   parameter pMATCH_RULES = 8
)(
  input  wire TRACECLK,
  input  wire [3:0] TRACEDATA,
  input  wire TRCENA, // TODO- need to use it?
  input  wire reset,
  input  wire [pMATCH_RULES-1:0] I_pattern_enable,
  input  wire I_toggle,
  input  wire I_reset_sync,
  input  wire [2:0] I_trace_width, // supported values: 1/2/4
  input  wire [pBUFFER_SIZE-1:0] I_pattern0, 
  input  wire [pBUFFER_SIZE-1:0] I_pattern1,
  input  wire [pBUFFER_SIZE-1:0] I_pattern2,
  input  wire [pBUFFER_SIZE-1:0] I_pattern3,
  input  wire [pBUFFER_SIZE-1:0] I_pattern4,
  input  wire [pBUFFER_SIZE-1:0] I_pattern5,
  input  wire [pBUFFER_SIZE-1:0] I_pattern6,
  input  wire [pBUFFER_SIZE-1:0] I_pattern7,
  input  wire [pBUFFER_SIZE-1:0] I_mask0,
  input  wire [pBUFFER_SIZE-1:0] I_mask1,
  input  wire [pBUFFER_SIZE-1:0] I_mask2,
  input  wire [pBUFFER_SIZE-1:0] I_mask3,
  input  wire [pBUFFER_SIZE-1:0] I_mask4,
  input  wire [pBUFFER_SIZE-1:0] I_mask5,
  input  wire [pBUFFER_SIZE-1:0] I_mask6,
  input  wire [pBUFFER_SIZE-1:0] I_mask7,
  output reg  [7:0] O_trace_count0,
  output reg  [7:0] O_trace_count1,
  output reg  [7:0] O_trace_count2,
  output reg  [7:0] O_trace_count3,
  output reg  [7:0] O_trace_count4,
  output reg  [7:0] O_trace_count5,
  output reg  [7:0] O_trace_count6,
  output reg  [7:0] O_trace_count7,
  output reg  [pMATCH_RULES-1:0] O_matching_pattern,
  output reg  [pBUFFER_SIZE-1:0] O_matching_buffer,
  output reg  [pBUFFER_SIZE-1:0] O_last_blurb,
  output reg  O_trace_trig_out,
  // debug only ports:
  output wire [pBUFFER_SIZE-1:0] O_buffer,
  output wire [pBUFFER_SIZE-1:0] O_revbuffer,
  output wire O_valid_buffer, 
  output wire O_synchronized, // TODO: when pBUFFER_SIZE was increased to 64, this output
                                // (which is only really needed for debug) started to cause
                                // "multiple driver" errors... so commented out for now :-( Best
                                // guess for root cause is improper CDC?
  output wire [2:0] O_blurb_count,
  output wire O_blurb_ready
);


   reg [pBUFFER_SIZE-1:0] buffer;
   wire [pBUFFER_SIZE-1:0] revbuffer;
   reg  synchronized;
   reg  [2:0] valid_count;
   wire valid_buffer;   
   reg  [2:0] trace_width_r;

   wire match;
   wire [pMATCH_RULES-1:0] match_bits;
   reg  [pMATCH_RULES-1:0] match_bits_prev;
   wire [pBUFFER_SIZE-1:0] pattern[pMATCH_RULES-1:0];
   wire [pBUFFER_SIZE-1:0] mask[pMATCH_RULES-1:0];

   reg [2:0] blurb_count;
   reg blurb_ready;

   assign mask[0] = I_mask0;
   assign mask[1] = I_mask1;
   assign mask[2] = I_mask2;
   assign mask[3] = I_mask3;
   assign mask[4] = I_mask4;
   assign mask[5] = I_mask5;
   assign mask[6] = I_mask6;
   assign mask[7] = I_mask7;

   assign pattern[0] = I_pattern0;
   assign pattern[1] = I_pattern1;
   assign pattern[2] = I_pattern2;
   assign pattern[3] = I_pattern3;
   assign pattern[4] = I_pattern4;
   assign pattern[5] = I_pattern5;
   assign pattern[6] = I_pattern6;
   assign pattern[7] = I_pattern7;

   // debug only:
   assign O_revbuffer = revbuffer;
   assign O_buffer = buffer;
   assign O_valid_buffer = valid_buffer;
   assign O_synchronized = synchronized;
   assign O_blurb_count = blurb_count;
   assign O_blurb_ready = blurb_ready;


   // shift trace data into buffer:
   always @(posedge TRACECLK) begin
      if (reset)
         buffer <= 0;
      else begin
         if (I_trace_width == 3'd4)
            buffer <= {buffer[pBUFFER_SIZE-5:0], TRACEDATA[0], TRACEDATA[1], TRACEDATA[2], TRACEDATA[3]};
         else if (I_trace_width == 3'd2)
            buffer <= {buffer[pBUFFER_SIZE-3:0], TRACEDATA[0], TRACEDATA[1]};
         else
            buffer <= {buffer[pBUFFER_SIZE-2:0], TRACEDATA[0]};
         `ifdef DEBUG 
            $display("%h", revbuffer);
         `endif
      end
   end


   // fix endianness:
   genvar i;
   generate 
      for (i = 0; i < pBUFFER_SIZE; i = i + 1) begin
         assign revbuffer[i] = buffer[pBUFFER_SIZE-1-i];
      end
   endgenerate 


   // Use sync packets to synchronize ourselves:
   always @(posedge TRACECLK) begin
      if (reset) begin
         synchronized <= 1'b0;
         valid_count <= 3'b0;
         trace_width_r <= 3'b0;
      end
      else begin
         trace_width_r <= I_trace_width;
         // allow synchronization to be re-established when trace width is
         // changed (or forced manually):
         if (I_reset_sync || (I_trace_width != trace_width_r)) begin
            synchronized <= 1'b0;
            valid_count <= 3'd0;
         end
         // this catches both half and full sync frames:
         else if (~synchronized && (revbuffer[pBUFFER_SIZE-1-:16] == 16'h7fff)) begin
            synchronized <= 1'b1;
            valid_count <= 3'd1;
         end
         else if (synchronized)
            valid_count <= valid_count + 1; // overflow ok and expected
      end
   end

   // valid_buffer is high when the buffer is byte-aligned: every 2 cycles when
   // I_trace_width = 4, every 4 cycles when I_trace_width is 2, and every 8
   // cycles when I_trace_width is 1.
   assign valid_buffer = synchronized && ( (I_trace_width == 1)? (valid_count % 8 == 0) :
                                           (I_trace_width == 2)? (valid_count % 4 == 0) :
                                           (I_trace_width == 4)? (valid_count % 2 == 0) : 1'b0);

   // look for match:
   // TODO-maybe: add a rule which looks for ITM print of <given byte>?
   generate 
      for (i = 0; i < pMATCH_RULES; i = i + 1) begin
         assign match_bits[i] = ((revbuffer & mask[i]) == (pattern[i] & mask[i])) && I_pattern_enable[i] && valid_buffer;
      end
   endgenerate 

   assign match = |match_bits;

   // generate trigger signal:
   always @(posedge TRACECLK) begin
      if (reset) begin
         O_trace_trig_out <= 1'b0;
         O_matching_pattern <= 8'b0;
         O_matching_buffer <= 0;
         match_bits_prev <= 8'b0;
         O_trace_count0 <= 0;
         O_trace_count1 <= 0;
         O_trace_count2 <= 0;
         O_trace_count3 <= 0;
         O_trace_count4 <= 0;
         O_trace_count5 <= 0;
         O_trace_count6 <= 0;
         O_trace_count7 <= 0;
      end

      else begin
         // Regular operation: on a match, invert trigger
         if (I_toggle) begin
            if (match)
               O_trace_trig_out <= !O_trace_trig_out;
         end

         // Pulse operation: on a match, pulse trigger
         else if (~I_toggle) begin
            if (match)
               O_trace_trig_out <= 1'b1;
            else
               O_trace_trig_out <= 1'b0;
         end

         if (match) begin
            match_bits_prev <= match_bits;
            //O_matching_pattern <= {match_bits, match_bits_prev}; // TODO: why look at match_bits_prev?
            O_matching_pattern <= match_bits;
            O_matching_buffer <= revbuffer;
         end

         if (match_bits[0]) O_trace_count0 = O_trace_count0 + 1;
         if (match_bits[1]) O_trace_count1 = O_trace_count1 + 1;
         if (match_bits[2]) O_trace_count2 = O_trace_count2 + 1;
         if (match_bits[3]) O_trace_count3 = O_trace_count3 + 1;
         if (match_bits[4]) O_trace_count4 = O_trace_count4 + 1;
         if (match_bits[5]) O_trace_count5 = O_trace_count5 + 1;
         if (match_bits[6]) O_trace_count6 = O_trace_count6 + 1;
         if (match_bits[7]) O_trace_count7 = O_trace_count7 + 1;

      end

   end

   // Look for start of a "blurb": anything that's not a half or full sync frame,
   // or a buffer matching one of the rules.
   // When the start of the blurb is about to shift out of the buffer, take
   // the snapshot.
   // TODO: if pBUFFER_SIZE changes, this needs to change too. Can't think of a
   // better way to do this short of more complex parsing logic.
   always @(posedge TRACECLK) begin
      if (reset) begin
         O_last_blurb <= 0;
         blurb_count <= 3'b0;
         blurb_ready <= 1'b0;
      end
      else if (valid_buffer) begin

         // wait until we see nothing but sync frames before arming:
         if ( (revbuffer == 64'h7fff_7fff_7fff_7fff) || (revbuffer == 64'h7fff_ffff_7fff_ffff) ) begin
            blurb_ready <= 1'b1;
            blurb_count <= 3'b0;
         end

         // abort recording a blurb if it matches a rule:
         else if (match) begin
            blurb_ready <= 1'b0;
            blurb_count <= 3'b0;
         end

         else if (blurb_count == 3'd7) begin
            O_last_blurb <= revbuffer;
            blurb_count <= 3'b0;
            blurb_ready <= 1'b0;
         end

         // start when we *don't* see only sync frames:
         else if ( (revbuffer != 64'h7fff_7fff_7fff_7fff) &&
                   (revbuffer != 64'hff7f_ff7f_ff7f_ff7f) &&
                   (revbuffer != 64'h7fff_ffff_7fff_ffff) &&
                   (revbuffer != 64'hff7f_ffff_ff7f_ffff) &&
                   (revbuffer != 64'hffff_7fff_ffff_7fff) &&
                   (revbuffer != 64'hffff_ff7f_ffff_ff7f) &&
                   (blurb_ready == 1'b1) ) begin
            blurb_count <= blurb_count + 1;
         end

      end
   end


endmodule

`default_nettype wire
