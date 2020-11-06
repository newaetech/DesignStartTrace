//////////////////////////////////////////////////////////////////////////////////
// Company: NewAE
// Engineer: Jean-Pierre Thibaut
// 
// Create Date: 
// Design Name: 
// Module Name: fe_capture_trace
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Front-end module, ARM trace-specific logic.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`default_nettype none
`include "defines_trace.v"

module fe_capture_trace #(
    parameter pBUFFER_SIZE = 64, // in bits
    parameter pTIMESTAMP_FULL_WIDTH = 16,
    parameter pTIMESTAMP_SHORT_WIDTH = 8,
    parameter pMATCH_RULES = 8
)(
    input  wire usb_clk,
    input  wire reset,
    input  wire swo_clk,

    /* FRONT END CONNECTIONS */
    input  wire trace_clk,
    input  wire [3:0] trace_data,

    /* SWO */
    input  wire I_swo_data_ready,
    input  wire [7:0] I_swo_data,

    /* GENERIC FRONT END CONNECTIONS */
    output wire O_event,
    output wire [1:0] O_data_cmd,
    input  wire [pTIMESTAMP_FULL_WIDTH-1:0] I_fifo_time,
    input  wire [1:0] I_fifo_command,
    input  wire I_fifo_wr,
    input  wire I_capturing,
    output wire [15:0] O_max_short_timestamp,

    /* REGISTER CONNECTIONS */
    output wire O_fifo_fe_status,
    input  wire [2:0] I_trace_width, // supported values: 1/2/4
    input  wire I_reset_sync,
    input  wire I_capture_raw,
    input  wire I_record_syncs,
    input  wire [pMATCH_RULES-1:0] I_pattern_enable,
    input  wire [pMATCH_RULES-1:0] I_pattern_trig_enable,
    input  wire I_soft_trig_enable,
    input  wire I_arm,
    input  wire I_swo_enable,

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
    output reg  [pBUFFER_SIZE-1:0] O_matched_data,

    /* FIFO CONNECTIONS */
    output reg [17:0] O_fifo_data,
    output reg  O_fifo_wr,

    /* TRIGGER CONNECTIONS */
    output wire O_trigger_match,
    input  wire m3_trig

    /* PATTERN MATCHER CONNECTIONS
    output wire [7:0] O_pm_data,
    output wire O_pm_data_valid */

);

   reg [pBUFFER_SIZE-1:0] buffer;
   wire [pBUFFER_SIZE-1:0] revbuffer;
   reg  synchronized;
   reg  [2:0] valid_count;
   reg  word_count;
   reg  [2:0] trace_width_r;
   wire valid_buffer;   
   wire revbuffer_all_syncframes;
   wire revbuffer_stop_syncframes;
   reg recording;

   wire match;
   wire [pMATCH_RULES-1:0] match_bits;
   reg  [pMATCH_RULES-1:0] match_bits_r;
   reg  [pMATCH_RULES-1:0] match_rule;
   wire [pBUFFER_SIZE-1:0] pattern[pMATCH_RULES-1:0];
   wire [pBUFFER_SIZE-1:0] mask[pMATCH_RULES-1:0];
   reg  m3_trig_r;
   reg  capturing_r;

   (* ASYNC_REG = "TRUE" *) reg capture_raw;
   wire [7:0] swo_data_reg;

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


   assign O_fifo_fe_status = synchronized;
   assign O_event = capture_raw? recording & valid_buffer : match;
   assign O_data_cmd = capture_raw? `FE_FIFO_CMD_STAT : `FE_FIFO_CMD_DATA;
   assign O_max_short_timestamp = 2**`FE_FIFO_SHORTTIME_LEN-1;

   assign O_trigger_match = I_arm && 
                         ( (m3_trig & !m3_trig_r & I_soft_trig_enable) ||
                           (|(match_bits & I_pattern_trig_enable)  & !(|(match_bits_r & I_pattern_trig_enable)) ));


   wire swo_data_ready_traceclk;
   reg swo_data_ready_traceclk_r;


   cdc_bus #(
      .pDATA_WIDTH   (8)
   ) U_swo_cdc (
      .reset_i       (reset),
      .src_clk       (swo_clk),
      .src_pulse     (I_swo_data_ready),
      .src_data      (I_swo_data),
      .dst_clk       (trace_clk),
      .dst_pulse     (swo_data_ready_traceclk),
      .dst_data      (swo_data_reg)
   );

   wire [7:0] swo_buf_in = {swo_data_reg[0],
                            swo_data_reg[1],
                            swo_data_reg[2],
                            swo_data_reg[3],
                            swo_data_reg[4],
                            swo_data_reg[5],
                            swo_data_reg[6],
                            swo_data_reg[7]};
   // shift trace data into buffer:
   always @(posedge trace_clk) begin
      if (reset)
         buffer <= 0;
      else if (I_swo_enable) begin
         swo_data_ready_traceclk_r <= swo_data_ready_traceclk;
         if (swo_data_ready_traceclk) begin
            buffer <= {buffer[pBUFFER_SIZE-9:0], swo_buf_in};
         end
      end
      else begin // parallel trace port
         if (I_trace_width == 3'd4)
            buffer <= {buffer[pBUFFER_SIZE-5:0], trace_data[0], trace_data[1], trace_data[2], trace_data[3]};
         else if (I_trace_width == 3'd2)
            buffer <= {buffer[pBUFFER_SIZE-3:0], trace_data[0], trace_data[1]};
         else
            buffer <= {buffer[pBUFFER_SIZE-2:0], trace_data[0]};
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
   always @(posedge trace_clk) begin
      if (reset) begin
         synchronized <= 1'b0;
         valid_count <= 4'b0;
         trace_width_r <= 3'b0;
      end
      else begin
         if (I_swo_enable)
            synchronized <= 1'b1;
         else begin
            trace_width_r <= I_trace_width;
            // allow synchronization to be re-established when trace width is
            // changed (or forced manually):
            if (I_reset_sync || (I_trace_width != trace_width_r)) begin
               synchronized <= 1'b0;
               valid_count <= 4'd0;
            end
            // this catches both half and full sync frames:
            else if (~synchronized && 
                     (revbuffer[pBUFFER_SIZE-1-:16] == 16'h7fff) && 
                     (revbuffer[7:0] == 8'hff) // shorthand to ensure that buffer is full of sync frames
                    ) begin        // TODO: hmm, above seems dangerously incomplete...
               synchronized <= 1'b1;
               valid_count <= 4'd1;
            end
            else if (synchronized)
               valid_count <= valid_count + 1; // overflow ok and expected
         end
      end
   end

   // valid_buffer is high when the buffer is byte-aligned: every 2 cycles when
   // I_trace_width = 4, every 4 cycles when I_trace_width is 2, and every 8
   // cycles when I_trace_width is 1.
   assign valid_buffer = synchronized && ( I_swo_enable?  swo_data_ready_traceclk_r :
                                           (I_trace_width == 1)? (valid_count % 8 == 0) :
                                           (I_trace_width == 2)? (valid_count % 4 == 0) :
                                           (I_trace_width == 4)? (valid_count % 2 == 0) : 1'b0);

   /* NOTE-TODO: These below are to accomodate any mix of short and long sync frames, which leads to
   a VERY large number of combinations; these lists are likely not exhaustive. Decided instead 
   // thanks to short/long sync frames there are lots of permutations! :-/
   // Note this list doesn't need to be exhaustive; if we're missing combinations,
   // it just means that extra sync data will get recorded (possibly in ways that are hard
   // to parse, i.e. partial sync frames)
   assign revbuffer_all_syncframes =  (revbuffer == 64'h7fff_7fff_7fff_7fff) ||
                                      (revbuffer == 64'hff7f_ff7f_ff7f_ff7f) ||
                                      (revbuffer == 64'h7fff_ffff_7fff_ffff) ||
                                      (revbuffer == 64'hff7f_ffff_ff7f_ffff) ||
                                      (revbuffer == 64'hffff_7fff_ffff_7fff) ||
                                      (revbuffer == 64'hffff_ff7f_ffff_ff7f) ||

                                      (revbuffer == 64'h7fff_7fff_ffff_7fff) ||
                                      (revbuffer == 64'hff7f_ff7f_ffff_ff7f) ||
                                      (revbuffer == 64'h7fff_7fff_7fff_ffff) ||
                                      (revbuffer == 64'hffff_7fff_7fff_ffff) ||
                                      (revbuffer == 64'h7fff_ffff_7fff_7fff) ||
                                      (revbuffer == 64'hff7f_ff7f_ff7f_ffff) ||
                                      (revbuffer == 64'hffff_7fff_7fff_7fff) ||
                                      (revbuffer == 64'hffff_ff7f_ff7f_ff7f) ||
                                      (revbuffer == 64'hffff_ff7f_ff7f_ffff);

   // thankfully there are fewer permutations for the stopping condition, because we must stop at
   // a specific time in order to not truncate when we stop recording:
   assign revbuffer_stop_syncframes = (revbuffer == 64'hff7f_ff7f_ff7f_ff7f) ||
                                      (revbuffer == 64'hff7f_ffff_ff7f_ffff) ||
                                      (revbuffer == 64'hff7f_ff7f_ffff_7fff) ||
                                      (revbuffer == 64'hff7f_ffff_ff7f_ff7f) ||
                                      (revbuffer == 64'hffff_ff7f_ff7f_ffff) ||
                                      (revbuffer == 64'hffff_ff7f_ffff_ff7f) ||
                                      (revbuffer == 64'hffff_ff7f_ff7f_ff7f) ||
                                      (revbuffer == 64'hff7f_ff7f_ff7f_ffff);
   */

   assign revbuffer_all_syncframes =  (revbuffer == 64'h7fff7fff7fff7fff) ||
                                      (revbuffer == 64'hff7fff7fff7fff7f) ||
                                      (revbuffer == 64'h7fffffff7fffffff) ||
                                      (revbuffer == 64'hff7fffffff7fffff) ||
                                      (revbuffer == 64'hffff7fffffff7fff) ||
                                      (revbuffer == 64'hffffff7fffffff7f) ||

                                      (revbuffer == 64'h7fff7fff7fffffff) ||
                                      (revbuffer == 64'hff7fff7fff7fffff) ||
                                      (revbuffer == 64'hffff7fff7fff7fff) ||
                                      (revbuffer == 64'hffffff7fff7fff7f) ||
                                      (revbuffer == 64'h7fffffff7fff7fff) ||
                                      (revbuffer == 64'hff7fffffff7fff7f) ||
                                      (revbuffer == 64'hffff7fffffff7fff) ||
                                      (revbuffer == 64'hffffff7fffffff7f) ||
                                      (revbuffer == 64'h7fff7fffffff7fff) ||
                                      (revbuffer == 64'hff7fff7fffffff7f);


   assign revbuffer_stop_syncframes = (revbuffer == 64'hff7f_ff7f_ff7f_ff7f) ||
                                      (revbuffer == 64'hff7f_ffff_ff7f_ffff);


   // Filter out *most* sync frames. When buffer isn't full of sync frames, start pushing out
   // data for capture, and stop once the buffer is full of sync frames again.
   // NOTE: if pBUFFER_SIZE changes, this needs to change too. Can't think of a
   // better way to do this short of more complex parsing logic.
   always @(posedge trace_clk) begin
      if (reset) begin
         recording <= 1'b0;
         //prepare_to_stop <= 1'b0;
      end

      else if (valid_buffer) begin
         // Stop recording when we see only sync frames. This is a bit convoluted,
         // by necessity in order to avoid stopping recording in a way that misses the last byte
         // of a sync frame and leads to output that may be hard/impossible to parse:
         if (revbuffer_stop_syncframes || !capturing_r)
            recording <= 1'b0;
         else if (!revbuffer_all_syncframes || I_record_syncs)
            recording <= 1'b1;
         /* TODO: alternative mechanism, clean up later:
         if (prepare_to_stop && revbuffer_syncframes) begin
            prepare_to_stop <= 1'b0;
            recording <= 1'b0;
         end
         else if (!prepare_to_stop && revbuffer_syncframes) begin
            prepare_to_stop <= 1'b1;
         end
         else begin
            prepare_to_stop <= 1'b0;
            recording <= 1'b1;
         end
         */
      end

   end


   // look for match:
   generate 
      for (i = 0; i < pMATCH_RULES; i = i + 1) begin
         // qualifying with capturing_r only would prevent using pattern match as a trigger event:
         assign match_bits[i] = ((revbuffer & mask[i]) == (pattern[i] & mask[i])) && I_pattern_enable[i] && valid_buffer && (capturing_r || I_pattern_trig_enable[i]);
      end
   endgenerate 

   assign match = |match_bits;


    // Some addditional delay is required in case a long timestamp needs to be issued.
    // TODO: look if this can be reduced?
    always @ (posedge trace_clk) begin
       if (reset) begin
          match_bits_r <= 0;
          m3_trig_r <= 0;
          match_rule <= 0;
          capturing_r <= 0;
          O_matched_data <= 0;
       end
       else begin
          m3_trig_r <= m3_trig;
          match_bits_r <= match_bits;
          capturing_r <= I_capturing;
          if (match) begin
             match_rule <= match_bits;
             O_matched_data <= revbuffer;
          end
       end
    end


   // FIFO write logic.
   // note: could maybe get away with combinatorial logic here?
   always @(posedge trace_clk) begin
      if (reset) begin
         O_fifo_wr <= 1'b0;
         O_fifo_data <= 0;
         capture_raw <= 1'b0;
      end
      else begin
         capture_raw <= I_capture_raw;
         if (I_fifo_wr) begin
            O_fifo_wr <= 1'b1;
            O_fifo_data[`FE_FIFO_CMD_START +: `FE_FIFO_CMD_BIT_LEN] <= I_fifo_command;
            case (I_fifo_command)
               `FE_FIFO_CMD_DATA: begin
                  O_fifo_data[`FE_FIFO_TIME_START +: `FE_FIFO_SHORTTIME_LEN] <= I_fifo_time[`FE_FIFO_SHORTTIME_LEN-1:0];
                  O_fifo_data[`FE_FIFO_DATA_START +: `FE_FIFO_DATA_LEN] <= match_rule;
               end
               `FE_FIFO_CMD_STAT: begin
                  O_fifo_data[`FE_FIFO_TIME_START +: `FE_FIFO_SHORTTIME_LEN] <= I_fifo_time[`FE_FIFO_SHORTTIME_LEN-1:0];
                  if (I_swo_enable)
                     O_fifo_data[`FE_FIFO_DATA_START +: `FE_FIFO_DATA_LEN] <= revbuffer[55-:`FE_FIFO_DATA_LEN];
                  else
                     // TODO: will need to adjust line below for different trace widths
                     O_fifo_data[`FE_FIFO_DATA_START +: `FE_FIFO_DATA_LEN] <= revbuffer[43-:`FE_FIFO_DATA_LEN];
               end
               `FE_FIFO_CMD_TIME: begin
                  O_fifo_data[`FE_FIFO_TIME_START +: `FE_FIFO_FULLTIME_LEN] <= I_fifo_time;
               end
            endcase
         end
         else
            O_fifo_wr <= 1'b0;
      end
   end

   // count rule matches:
   always @(posedge trace_clk) begin
      if (reset) begin
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


   `ifdef ILA_TRACE
       ila_trace1 I_trace_ila (
          .clk          (trace_clk),            // input wire clk
          .probe0       (recording),            // input wire [0:0]  probe0  
          .probe1       (O_event),              // input wire [0:0]  probe1 
          .probe2       (trace_data),           // input wire [3:0]  probe2 
          .probe3       (I_trace_width),        // input wire [2:0]  probe3 
          .probe4       (synchronized),         // input wire [0:0]  probe4 
          .probe5       (valid_buffer),         // input wire [0:0]  probe5 
          .probe6       (O_trigger_match),      // input wire [0:0]  probe6 
          .probe7       (match_bits      ),     // input wire [7:0]  probe7 
          .probe8       (revbuffer      ),      // input wire [63:0] probe8 
          .probe9       (O_fifo_data),          // input wire [17:0] probe9 
          .probe10      (O_fifo_wr)             // input wire [0:0]  probe10 
       );
   `endif


endmodule
`default_nettype wire
