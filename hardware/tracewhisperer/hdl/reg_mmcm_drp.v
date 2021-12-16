`timescale 1 ns / 1 ps
`default_nettype none

/***********************************************************************
This file is part of the ChipWhisperer Project. See www.newae.com for more
details, or the codebase at http://www.chipwhisperer.com

Copyright (c) 2021, NewAE Technology Inc. All rights reserved.
Author: Jean-Pierre Thibault <jpthibault@newae.com>

  chipwhisperer is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  chipwhisperer is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Lesser General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with chipwhisperer.  If not, see <http://www.gnu.org/licenses/>.
*************************************************************************/

module reg_mmcm_drp #(
   parameter pBYTECNT_SIZE = 7,
   parameter pDRP_ADDR = 0,
   parameter pDRP_DATA = 1,
   parameter pDRP_RESET = 2
)(
   input  wire         reset_i,
   input  wire         clk_usb,
   input  wire [7:0]   reg_address,  // Address of register
   input  wire [pBYTECNT_SIZE-1:0]  reg_bytecnt,  // Current byte count
   input  wire [7:0]   reg_datai,    // Data to write
   output wire [7:0]   reg_datao,    // Data to read
   input  wire         reg_read,     // Read flag
   input  wire         reg_write,    // Write flag
   input  wire         selected,

   output reg  [6:0]   drp_addr,
   output reg          drp_den,
   output reg  [15:0]  drp_din,
   input  wire [15:0]  drp_dout,
   output reg          drp_dwe,
   output reg          drp_reset
); 


// DRP usage:
// Writes: push write data to DRP data, then write DRP_ADDR with MSB set.
// Reads: write DRP_ADDR with MSB clear, then obtain read data from DRP_DATA.


   reg [7:0] reg_datao_reg;
   assign reg_datao = reg_datao_reg;
   wire [5:0] address = reg_address[5:0];

   always @(*) begin
      if (selected && reg_read) begin
         case (address)
           pDRP_ADDR: reg_datao_reg = {1'b0, drp_addr};
           pDRP_DATA: reg_datao_reg = drp_dout[reg_bytecnt[0]*8 +: 8];
           default: reg_datao_reg = 0;
         endcase
      end
      else
         reg_datao_reg = 0;
   end  

   always @(posedge clk_usb) begin
      if (reset_i) begin
         drp_dwe <= 1'b0;
         drp_den <= 1'b0;
         drp_reset <= 1'b0;
      end
      else begin
         if (selected && reg_write) begin
            if (address == pDRP_ADDR) begin
               drp_addr <= reg_datai[6:0];
               drp_den <= 1'b1;
               // DRP write:
               if (reg_datai[7])
                  drp_dwe <= 1'b1;
               // DRP read:
               else
                  drp_dwe <= 1'b0;
            end

            else begin
               drp_dwe <= 1'b0;
               drp_den <= 1'b0;
               if (address == pDRP_DATA)
                  drp_din[reg_bytecnt[0]*8 +: 8] <= reg_datai;
               else if (address == pDRP_RESET)
                  drp_reset <= reg_datai[0];
            end

         end

         else begin
            drp_dwe <= 1'b0;
            drp_den <= 1'b0;
         end

      end
   end


   `ifdef ILA_DRP
       ila_drp U_ila_drp (
	      .clk            (clk_usb),      // input wire clk
	      .probe0         (drp_addr),     // input wire [6:0]  probe0  
	      .probe1         (drp_den),      // input wire [0:0]  probe1 
	      .probe2         (drp_din),      // input wire [15:0] probe2 
	      .probe3         (drp_dout),     // input wire [15:0] probe3 
	      .probe4         (drp_dwe),      // input wire [0:0]  probe4 

	      .probe5         (selected),     // input wire [0:0]  probe4 
	      .probe6         (reg_read),     // input wire [0:0]  probe4 
	      .probe7         (reg_write),    // input wire [0:0]  probe4 
	      .probe8         (reg_bytecnt),  // input wire [6:0]  probe4 
	      .probe9         (reg_datai)     // input wire [6:0]  probe4 
       );
   `endif


endmodule
`default_nettype wire
