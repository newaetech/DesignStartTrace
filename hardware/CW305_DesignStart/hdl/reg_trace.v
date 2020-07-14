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

`default_nettype none
`timescale 1ns / 1ps
`include "defines.v"

module reg_trace #(
   parameter pADDR_WIDTH = 21,
   parameter pBYTECNT_SIZE = 7,
   parameter pBUFFER_SIZE = 64, // in bits
   parameter pMATCH_RULES = 8
)(
   input  wire         reset_i,

// Interface to cw305_usb_reg_fe:
   input  wire                                  usb_clk,
   input  wire [pADDR_WIDTH-1:pBYTECNT_SIZE]    reg_address,     // Address of register
   input  wire [pBYTECNT_SIZE-1:0]              reg_bytecnt,  // Current byte count
   output wire [7:0]                            read_data,       //
   input  wire [7:0]                            write_data,      //
   input  wire                                  reg_read,        // Read flag. One clock cycle AFTER this flag is high
                                                                 // valid data must be present on the read_data bus
   input  wire                                  reg_write,       // Write flag. When high on rising edge valid data is
                                                                 // present on write_data
   input  wire                                  reg_addrvalid,   // Address valid flag

// Interface to top level:
   output reg  [4:0]                            O_clksettings,

// Interface to trace_trigger:
   input  wire [pMATCH_RULES-1:0]               I_matching_pattern,
   input  wire [pBUFFER_SIZE-1:0]               I_matching_buffer,
   input  wire                                  I_synchronized,
   input  wire [pBUFFER_SIZE-1:0]               I_last_blurb,

   output reg  [pMATCH_RULES-1:0]               O_pattern_enable,
   output reg                                   O_trace_reset_sync,
   output reg  [2:0]                            O_trace_width,
   output reg                                   O_trig_toggle,
   output reg                                   O_trace_trig_enable,

   output reg  [pBUFFER_SIZE-1:0]               O_trace_pattern0,
   output reg  [pBUFFER_SIZE-1:0]               O_trace_pattern1,
   output reg  [pBUFFER_SIZE-1:0]               O_trace_pattern2,
   output reg  [pBUFFER_SIZE-1:0]               O_trace_pattern3,
   output reg  [pBUFFER_SIZE-1:0]               O_trace_pattern4,
   output reg  [pBUFFER_SIZE-1:0]               O_trace_pattern5,
   output reg  [pBUFFER_SIZE-1:0]               O_trace_pattern6,
   output reg  [pBUFFER_SIZE-1:0]               O_trace_pattern7,

   output reg  [pBUFFER_SIZE-1:0]               O_trace_mask0,
   output reg  [pBUFFER_SIZE-1:0]               O_trace_mask1,
   output reg  [pBUFFER_SIZE-1:0]               O_trace_mask2,
   output reg  [pBUFFER_SIZE-1:0]               O_trace_mask3,
   output reg  [pBUFFER_SIZE-1:0]               O_trace_mask4,
   output reg  [pBUFFER_SIZE-1:0]               O_trace_mask5,
   output reg  [pBUFFER_SIZE-1:0]               O_trace_mask6,
   output reg  [pBUFFER_SIZE-1:0]               O_trace_mask7,

   input  wire [7:0]                            I_trace_count0,
   input  wire [7:0]                            I_trace_count1,
   input  wire [7:0]                            I_trace_count2,
   input  wire [7:0]                            I_trace_count3,
   input  wire [7:0]                            I_trace_count4,
   input  wire [7:0]                            I_trace_count5,
   input  wire [7:0]                            I_trace_count6,
   input  wire [7:0]                            I_trace_count7

);


   wire [63:0] name = {8'h65, 8'h63, 8'h61, 8'h72, 8'h54, 8'h6d, 8'h72, 8'h41}; // ASCII for 'ArmTrace'
   wire [31:0] buildtime;
   reg  [7:0] reg_read_data;
   wire [7:0] rev = 8'h00;


   //////////////////////////////////
   // read logic:
   //////////////////////////////////
   always @(posedge usb_clk) begin
      if (reg_addrvalid && reg_read) begin
         case (reg_address)
            `REG_BUILDTIME:             reg_read_data <= buildtime[reg_bytecnt*8 +: 8];
            `REG_NAME:                  reg_read_data <= name[reg_bytecnt*8 +: 8];
            `REG_REV:                   reg_read_data <= rev;
            `REG_CLKSETTINGS:           reg_read_data[4:0] <= O_clksettings;

            `REG_PATTERN_ENABLE:        reg_read_data[pMATCH_RULES-1:0] <= O_pattern_enable;
            `REG_TRACE_RESET_SYNC:      reg_read_data[0] <= O_trace_reset_sync;
            `REG_TRACE_WIDTH:           reg_read_data[2:0] <= O_trace_width;
            `REG_TRIG_TOGGLE:           reg_read_data[0] <= O_trig_toggle;
            `REG_TRACE_TRIG_ENABLE:     reg_read_data[0] <= O_trace_trig_enable;

            `REG_MATCHING_PATTERN:      reg_read_data[pMATCH_RULES-1:0] <= I_matching_pattern;
            `REG_MATCHING_BUFFER:       reg_read_data <= I_matching_buffer[reg_bytecnt*8 +: 8];
            `REG_SYNCHRONIZED:          reg_read_data[0] <= I_synchronized;
            `REG_LAST_BLURB:            reg_read_data <= I_last_blurb[reg_bytecnt*8 +: 8];

            `REG_TRACE_PATTERN0:        reg_read_data <= O_trace_pattern0[reg_bytecnt*8 +: 8];
            `REG_TRACE_PATTERN1:        reg_read_data <= O_trace_pattern1[reg_bytecnt*8 +: 8];
            `REG_TRACE_PATTERN2:        reg_read_data <= O_trace_pattern2[reg_bytecnt*8 +: 8];
            `REG_TRACE_PATTERN3:        reg_read_data <= O_trace_pattern3[reg_bytecnt*8 +: 8];
            `REG_TRACE_PATTERN4:        reg_read_data <= O_trace_pattern4[reg_bytecnt*8 +: 8];
            `REG_TRACE_PATTERN5:        reg_read_data <= O_trace_pattern5[reg_bytecnt*8 +: 8];
            `REG_TRACE_PATTERN6:        reg_read_data <= O_trace_pattern6[reg_bytecnt*8 +: 8];
            `REG_TRACE_PATTERN7:        reg_read_data <= O_trace_pattern7[reg_bytecnt*8 +: 8];

            `REG_TRACE_MASK0:           reg_read_data <= O_trace_mask0[reg_bytecnt*8 +: 8];
            `REG_TRACE_MASK1:           reg_read_data <= O_trace_mask1[reg_bytecnt*8 +: 8];
            `REG_TRACE_MASK2:           reg_read_data <= O_trace_mask2[reg_bytecnt*8 +: 8];
            `REG_TRACE_MASK3:           reg_read_data <= O_trace_mask3[reg_bytecnt*8 +: 8];
            `REG_TRACE_MASK4:           reg_read_data <= O_trace_mask4[reg_bytecnt*8 +: 8];
            `REG_TRACE_MASK5:           reg_read_data <= O_trace_mask5[reg_bytecnt*8 +: 8];
            `REG_TRACE_MASK6:           reg_read_data <= O_trace_mask6[reg_bytecnt*8 +: 8];
            `REG_TRACE_MASK7:           reg_read_data <= O_trace_mask7[reg_bytecnt*8 +: 8];

            `REG_TRACE_COUNT0:          reg_read_data <= I_trace_count0;
            `REG_TRACE_COUNT1:          reg_read_data <= I_trace_count1;
            `REG_TRACE_COUNT2:          reg_read_data <= I_trace_count2;
            `REG_TRACE_COUNT3:          reg_read_data <= I_trace_count3;
            `REG_TRACE_COUNT4:          reg_read_data <= I_trace_count4;
            `REG_TRACE_COUNT5:          reg_read_data <= I_trace_count5;
            `REG_TRACE_COUNT6:          reg_read_data <= I_trace_count6;
            `REG_TRACE_COUNT7:          reg_read_data <= I_trace_count7;

         endcase
      end
      else
         reg_read_data <= 8'b0;
   end

   assign read_data = reg_read_data;


   //////////////////////////////////
   // write logic (USB clock domain):
   //////////////////////////////////
   always @(posedge usb_clk) begin
      if (reset_i) begin
         O_clksettings <= 0;
         O_pattern_enable <= 0;
         O_trace_reset_sync <= 0;
         O_trace_width <= 4;    // default to 4-lane operation, matching default FW setting
         O_trig_toggle <= 1;
         O_trace_trig_enable <= 0;
         O_trace_pattern0 <= 0;
         O_trace_pattern1 <= 0;
         O_trace_pattern2 <= 0;
         O_trace_pattern3 <= 0;
         O_trace_pattern4 <= 0;
         O_trace_pattern5 <= 0;
         O_trace_pattern6 <= 0;
         O_trace_pattern7 <= 0;
         O_trace_mask0 <= {pBUFFER_SIZE{1'b1}};
         O_trace_mask1 <= {pBUFFER_SIZE{1'b1}};
         O_trace_mask2 <= {pBUFFER_SIZE{1'b1}};
         O_trace_mask3 <= {pBUFFER_SIZE{1'b1}};
         O_trace_mask4 <= {pBUFFER_SIZE{1'b1}};
         O_trace_mask5 <= {pBUFFER_SIZE{1'b1}};
         O_trace_mask6 <= {pBUFFER_SIZE{1'b1}};
         O_trace_mask7 <= {pBUFFER_SIZE{1'b1}};
      end

      else begin
         if (reg_addrvalid && reg_write) begin
            case (reg_address)
               `REG_CLKSETTINGS:        O_clksettings <= write_data;

               `REG_PATTERN_ENABLE:     O_pattern_enable <= write_data[pMATCH_RULES-1:0];
               `REG_TRACE_RESET_SYNC:   O_trace_reset_sync <= write_data[0];
               `REG_TRACE_WIDTH:        O_trace_width <= write_data[2:0];
               `REG_TRIG_TOGGLE:        O_trig_toggle <= write_data[0];
               `REG_TRACE_TRIG_ENABLE:  O_trace_trig_enable <= write_data[0];

               `REG_TRACE_PATTERN0:     O_trace_pattern0[reg_bytecnt*8 +: 8] <= write_data;
               `REG_TRACE_PATTERN1:     O_trace_pattern1[reg_bytecnt*8 +: 8] <= write_data;
               `REG_TRACE_PATTERN2:     O_trace_pattern2[reg_bytecnt*8 +: 8] <= write_data;
               `REG_TRACE_PATTERN3:     O_trace_pattern3[reg_bytecnt*8 +: 8] <= write_data;
               `REG_TRACE_PATTERN4:     O_trace_pattern4[reg_bytecnt*8 +: 8] <= write_data;
               `REG_TRACE_PATTERN5:     O_trace_pattern5[reg_bytecnt*8 +: 8] <= write_data;
               `REG_TRACE_PATTERN6:     O_trace_pattern6[reg_bytecnt*8 +: 8] <= write_data;
               `REG_TRACE_PATTERN7:     O_trace_pattern7[reg_bytecnt*8 +: 8] <= write_data;

               `REG_TRACE_MASK0:        O_trace_mask0[reg_bytecnt*8 +: 8] <= write_data;
               `REG_TRACE_MASK1:        O_trace_mask1[reg_bytecnt*8 +: 8] <= write_data;
               `REG_TRACE_MASK2:        O_trace_mask2[reg_bytecnt*8 +: 8] <= write_data;
               `REG_TRACE_MASK3:        O_trace_mask3[reg_bytecnt*8 +: 8] <= write_data;
               `REG_TRACE_MASK4:        O_trace_mask4[reg_bytecnt*8 +: 8] <= write_data;
               `REG_TRACE_MASK5:        O_trace_mask5[reg_bytecnt*8 +: 8] <= write_data;
               `REG_TRACE_MASK6:        O_trace_mask6[reg_bytecnt*8 +: 8] <= write_data;
               `REG_TRACE_MASK7:        O_trace_mask7[reg_bytecnt*8 +: 8] <= write_data;
            endcase
         end
      end
   end

               /* TODO: CDC on inputs?
               `REG_MATCHING_PATTERN:   I_matching_pattern <= write_data[pMATCH_RULES-1:0];
               `REG_MATCHING_BUFFER:    I_matching_buffer[reg_bytecnt*8 +: 8] <= write_data;
               `REG_SYNCHRONIZED:       I_synchronized <= write_data;
               `REG_LAST_BLURB:         I_last_blurb[reg_bytecnt*8 +: 8] <= write_data;
                */

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
