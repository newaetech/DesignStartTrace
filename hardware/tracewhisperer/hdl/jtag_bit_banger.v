`default_nettype none
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NewAE
// Engineer: Jean-Pierre Thibault
// 
// Create Date: 
// Design Name: 
// Module Name: jtag_bit_banger
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module jtag_bit_banger #(
   parameter pPATTERN_WIDTH = 16
)(
   input  wire                          reset,
   input  wire                          clk,
   input  wire [pPATTERN_WIDTH-1:0]     pattern,
   input  wire                          go,
   input  wire [7:0]                    clk_div,
   output wire                          tms_out,
   output wire                          tck_out,
   output reg                           busy,
   output reg                           done
);

   reg          tck;
   reg          tms;
   reg  [7:0]   bit_counter;
   reg  [7:0]   clock_counter;

   always @(posedge clk) begin
      if (reset) begin
         busy <= 0;
         done <= 0;
         bit_counter <= 0;
         clock_counter <= 0;
         tms <= 1'bz;
         tck <= 1'bz;
      end

      else if (go && !busy && !done) begin
         busy <= 1'b1;
         done <= 1'b0;
         tck <= 1'b0;
         tms <= 1'b1;
      end

      else if (busy && (bit_counter <= pPATTERN_WIDTH)) begin
         if (clock_counter == clk_div) begin
            tck <= ~tck;
            clock_counter <= 0;
            if (tck) begin
               bit_counter <= bit_counter + 1;
               if (bit_counter == pPATTERN_WIDTH) begin
                  busy <= 1'b0;
                  done <= 1'b1;
                  tms <= 1'bz;
                  tck <= 1'bz;
               end
               else
                  tms <= pattern[bit_counter];
            end
         end
         else
            clock_counter <= clock_counter + 1;
      end

      else begin
         busy <= 0;
         done <= 0;
         bit_counter <= 0;
         clock_counter <= 0;
         tms <= 1'bz;
         tck <= 1'bz;
      end

   end

   assign tck_out = tck;
   assign tms_out = tms;

   `ifndef __ICARUS__
      PULLUP   TMS_PULLUP   (.O(tms_out));
      PULLDOWN TCK_PULLDOWN (.O(tck_out));
   `endif



endmodule

`default_nettype wire
