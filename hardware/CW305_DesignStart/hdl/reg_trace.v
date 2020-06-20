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
   parameter pBYTECNT_SIZE = 7
)(
   input  wire         reset_i,

// Interface to reg_main_cwlite:
   input  wire         usb_clk,
   input  wire [pADDR_WIDTH-1:pBYTECNT_SIZE] reg_address,     // Address of register
   input  wire [pBYTECNT_SIZE-1:0]  reg_bytecnt,  // Current byte count
   output wire [7:0]   read_data,       //
   input  wire [7:0]   write_data,      //
   input  wire         reg_read,        // Read flag. One clock cycle AFTER this flag is high
                                        // valid data must be present on the read_data bus
   input  wire         reg_write,       // Write flag. When high on rising edge valid data is
                                        // present on write_data
   input  wire         reg_addrvalid    // Address valid flag
);


   wire [31:0] buildtime;
   reg  [7:0] reg_read_data;
   reg  [31:0] reg_test;

   wire [7:0] rev = 8'h00;

   // ASCII: ArmTrace
   wire [63:0] name = {8'h65, 8'h63, 8'h61, 8'h72, 8'h54, 8'h6d, 8'h72, 8'h41};

   // read logic:
   always @(posedge usb_clk) begin
      if (reg_addrvalid && reg_read) begin
         case (reg_address)
            `REG_BUILDTIME: reg_read_data <= buildtime[reg_bytecnt*8 +: 8];
            `REG_NAME: reg_read_data <= name[reg_bytecnt*8 +: 8];
            `REG_REV: reg_read_data <= rev;
            `REG_TEST: reg_read_data <= reg_test[reg_bytecnt*8 +: 8];
         endcase
      end
      else
         reg_read_data <= 8'b0;
   end

   assign read_data = reg_read_data;


   // write logic (USB clock domain):
   always @(posedge usb_clk) begin
      if (reset_i) begin
         reg_test <= 0;
      end
      else begin
         if (reg_addrvalid && reg_write) begin
            case (reg_address)
               `REG_TEST: reg_test[reg_bytecnt*8 +: 8] <= write_data;
            endcase
         end
      end
   end


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
