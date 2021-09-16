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
`include "defines_trace.v"

module reg_trace #(
   parameter pADDR_WIDTH = 21,
   parameter pBYTECNT_SIZE = 7,
   parameter pBUFFER_SIZE = 64, // in bits
   parameter pMATCH_RULES = 8
)(
   input  wire         reset_i,

// Interface to cw305_usb_reg_fe:
   input  wire                                  usb_clk,
   input  wire                                  uart_clk,
   //input  wire [pADDR_WIDTH-pBYTECNT_SIZE-1:0]  reg_address,     // Address of register
   input  wire [7:0]                            reg_address,  // Address of register
   input  wire [pBYTECNT_SIZE-1:0]              reg_bytecnt,  // Current byte count
   output reg  [7:0]                            read_data,       //
   input  wire [7:0]                            write_data,      //
   input  wire                                  reg_read,        // Read flag. One clock cycle AFTER this flag is high
                                                                 // valid data must be present on the read_data bus
   input  wire                                  reg_write,       // Write flag. When high on rising edge valid data is
                                                                 // present on write_data
   input  wire                                  reg_addrvalid,   // Address valid flag

// Interface to top level:
   output reg  [4:0]                            O_clksettings,
   output reg  [1:0]                            O_fe_clk_sel,

// Interface to trace_trigger:
   input  wire                                  I_synchronized,

   output reg  [pMATCH_RULES-1:0]               O_pattern_enable,
   output reg  [pMATCH_RULES-1:0]               O_pattern_trig_enable,
   output reg  [2:0]                            O_trace_width,
   output reg                                   O_soft_trig_passthru,
   output reg                                   O_soft_trig_enable,
   output reg                                   O_capture_raw,
   output reg                                   O_record_syncs,

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
   input  wire [7:0]                            I_trace_count7,

   input  wire [pBUFFER_SIZE-1:0]               I_matched_data,

   output reg                                   O_swo_enable,
   output reg  [7:0]                            O_swo_bitrate_div,
   output reg  [1:0]                            O_uart_stop_bits,
   output reg  [3:0]                            O_uart_data_bits,

   output reg                                   O_reverse_tracedata,
   output wire                                  O_reset_sync,

   output wire                                  selected

);


   wire [63:0] name = {8'h65, 8'h63, 8'h61, 8'h72, 8'h54, 8'h6d, 8'h72, 8'h41}; // ASCII for 'ArmTrace'
   reg  [7:0] reg_read_data;
   wire [7:0] rev = 8'h01;
   wire [63:0] trace_count;
   reg  reset_sync;
   reg  reset_sync_r;

   assign selected = reg_addrvalid & reg_address[7:6] == `TRACE_REG_SELECT;
   wire [5:0] address = reg_address[5:0];


   //////////////////////////////////
   // read logic:
   //////////////////////////////////

   always @(*) begin
      if (selected && reg_read) begin
         case (address)
            `REG_NAME:                  reg_read_data = name[reg_bytecnt*8 +: 8];
            `REG_REV:                   reg_read_data = rev;
            `REG_CLKSETTINGS:           reg_read_data = O_clksettings;

            `REG_PATTERN_ENABLE:        reg_read_data = O_pattern_enable;
            `REG_PATTERN_TRIG_ENABLE:   reg_read_data = O_pattern_trig_enable;
            `REG_TRACE_WIDTH:           reg_read_data = O_trace_width;
            `REG_SOFT_TRIG_PASSTHRU:    reg_read_data = O_soft_trig_passthru;
            `REG_SOFT_TRIG_ENABLE:      reg_read_data = O_soft_trig_enable;
            `REG_CAPTURE_RAW:           reg_read_data = O_capture_raw;

            `REG_SYNCHRONIZED:          reg_read_data = I_synchronized;

            `REG_TRACE_PATTERN0:        reg_read_data = O_trace_pattern0[reg_bytecnt*8 +: 8];
            `REG_TRACE_PATTERN1:        reg_read_data = O_trace_pattern1[reg_bytecnt*8 +: 8];
            `REG_TRACE_PATTERN2:        reg_read_data = O_trace_pattern2[reg_bytecnt*8 +: 8];
            `REG_TRACE_PATTERN3:        reg_read_data = O_trace_pattern3[reg_bytecnt*8 +: 8];
            `REG_TRACE_PATTERN4:        reg_read_data = O_trace_pattern4[reg_bytecnt*8 +: 8];
            `REG_TRACE_PATTERN5:        reg_read_data = O_trace_pattern5[reg_bytecnt*8 +: 8];
            `REG_TRACE_PATTERN6:        reg_read_data = O_trace_pattern6[reg_bytecnt*8 +: 8];
            `REG_TRACE_PATTERN7:        reg_read_data = O_trace_pattern7[reg_bytecnt*8 +: 8];

            `REG_TRACE_MASK0:           reg_read_data = O_trace_mask0[reg_bytecnt*8 +: 8];
            `REG_TRACE_MASK1:           reg_read_data = O_trace_mask1[reg_bytecnt*8 +: 8];
            `REG_TRACE_MASK2:           reg_read_data = O_trace_mask2[reg_bytecnt*8 +: 8];
            `REG_TRACE_MASK3:           reg_read_data = O_trace_mask3[reg_bytecnt*8 +: 8];
            `REG_TRACE_MASK4:           reg_read_data = O_trace_mask4[reg_bytecnt*8 +: 8];
            `REG_TRACE_MASK5:           reg_read_data = O_trace_mask5[reg_bytecnt*8 +: 8];
            `REG_TRACE_MASK6:           reg_read_data = O_trace_mask6[reg_bytecnt*8 +: 8];
            `REG_TRACE_MASK7:           reg_read_data = O_trace_mask7[reg_bytecnt*8 +: 8];

            `REG_TRACE_COUNT:           reg_read_data = trace_count[reg_bytecnt*8 +: 8];

            `REG_RECORD_SYNCS:          reg_read_data = O_record_syncs;
            `REG_MATCHED_DATA:          reg_read_data = I_matched_data[reg_bytecnt*8 +: 8];

            `REG_SWO_ENABLE:            reg_read_data = O_swo_enable;
            `REG_SWO_BITRATE_DIV:       reg_read_data = O_swo_bitrate_div;
            `REG_UART_STOP_BITS:        reg_read_data = O_uart_stop_bits;
            `REG_UART_DATA_BITS:        reg_read_data = O_uart_data_bits;

            `REG_REVERSE_TRACEDATA:     reg_read_data = O_reverse_tracedata;
            `REG_FE_CLOCK_SEL:          reg_read_data = O_fe_clk_sel;

            default:                    reg_read_data = 0;

         endcase
      end
      else
         reg_read_data = 0;
   end


   // Register output read data to ease timing. If you need data one clock
   // cycle earlier, simply remove this stage.
   always @(posedge usb_clk)
      read_data <= reg_read_data;

   assign trace_count = {I_trace_count0,
                         I_trace_count1,
                         I_trace_count2,
                         I_trace_count3,
                         I_trace_count4,
                         I_trace_count5,
                         I_trace_count6,
                         I_trace_count7};


   //////////////////////////////////
   // write logic (USB clock domain):
   //////////////////////////////////
   always @(posedge usb_clk) begin
      if (reset_i) begin
         O_clksettings <= 0;
         O_pattern_enable <= 0;
         O_pattern_trig_enable <= 0;
         O_trace_width <= 4;    // default to 4-lane operation, matching default FW setting
         O_soft_trig_passthru <= 1;
         O_soft_trig_enable <= 1;
         O_capture_raw <= 1;
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
         O_swo_bitrate_div <= 7;
         O_swo_enable <= 0;
         O_uart_stop_bits <= 1;
         O_uart_data_bits <= 8;
         O_record_syncs <= 0;
         O_reverse_tracedata <= 1; // TODO: change default to 0 later
         O_fe_clk_sel <= 0;
         reset_sync <= 0;
         reset_sync_r <= 0;
      end

      else begin
         if (selected && reg_write) begin
            case (address)
               `REG_CLKSETTINGS:        O_clksettings <= write_data;

               `REG_PATTERN_ENABLE:     O_pattern_enable <= write_data[pMATCH_RULES-1:0];
               `REG_PATTERN_TRIG_ENABLE:O_pattern_trig_enable <= write_data[pMATCH_RULES-1:0];
               `REG_TRACE_WIDTH:        O_trace_width <= write_data[2:0];
               `REG_SOFT_TRIG_PASSTHRU: O_soft_trig_passthru <= write_data[0];
               `REG_SOFT_TRIG_ENABLE:   O_soft_trig_enable <= write_data[0];
               `REG_CAPTURE_RAW:        O_capture_raw <= write_data[0];
               `REG_RECORD_SYNCS:       O_record_syncs <= write_data[0];

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
               `REG_SWO_ENABLE:         O_swo_enable <= write_data[0];
               `REG_SWO_BITRATE_DIV:    O_swo_bitrate_div <= write_data;
               `REG_UART_STOP_BITS:     O_uart_stop_bits <= write_data[1:0];
               `REG_UART_DATA_BITS:     O_uart_data_bits <= write_data[3:0];
               `REG_REVERSE_TRACEDATA:  O_reverse_tracedata <= write_data[0];
               `REG_FE_CLOCK_SEL:       O_fe_clk_sel <= write_data[1:0];

            endcase
         end

         // RESYNC register is special:
         if (selected && reg_write && (address == `REG_TRACE_RESET_SYNC))
            reset_sync <= 1'b1;
         else 
            reset_sync <= 1'b0;
         reset_sync_r <= reset_sync;

      end
   end

   assign O_reset_sync = reset_sync & ~reset_sync_r;

               /* TODO: CDC on inputs?
               `REG_MATCHING_PATTERN:   I_matching_pattern <= write_data[pMATCH_RULES-1:0];
               `REG_MATCHING_BUFFER:    I_matching_buffer[reg_bytecnt*8 +: 8] <= write_data;
               `REG_SYNCHRONIZED:       I_synchronized <= write_data;
               `REG_LAST_BLURB:         I_last_blurb[reg_bytecnt*8 +: 8] <= write_data;
                */



   `ifdef ILA_REG_TRACE

       ila_2 U_reg_ila (
	.clk            (usb_clk),                      // input wire clk
	.probe0         (reg_address[7:0]),             // input wire [7:0]  probe0  
	.probe1         (reg_bytecnt),                  // input wire [6:0]  probe1 
	.probe2         (read_data),                    // input wire [7:0]  probe2 
	.probe3         (write_data),                   // input wire [7:0]  probe3 
	.probe4         (reg_read),                     // input wire [0:0]  probe4 
	.probe5         (reg_write),                    // input wire [0:0]  probe5 
	.probe6         (reg_addrvalid),                // input wire [0:0]  probe6 
	.probe7         (reg_read_data),                // input wire [7:0]  probe7 
	.probe8         (selected),                     // input wire [0:0]  probe8 
	.probe9         (O_pattern_enable)              // input wire [7:0]  probe9
       );


   `endif

endmodule

`default_nettype wire
