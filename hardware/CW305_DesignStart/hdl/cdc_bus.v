`default_nettype none
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NewAE
// Engineer: Jean-Pierre Thibault
// 
// Create Date: 
// Design Name: 
// Module Name: cdc_bus
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


module cdc_bus #(
   parameter pDATA_WIDTH = 8,
   parameter pSYNC_STAGES = 2
)(
   input  wire                          reset_i,
   input  wire                          clear_error,
   input  wire                          src_clk,
   input  wire                          src_pulse,
   input  wire [pDATA_WIDTH-1:0]        src_data,
   output reg                           src_overflow,
   input  wire                          dst_clk,
   output reg                           dst_pulse,
   output wire [pDATA_WIDTH-1:0]        dst_data
);

   (* ASYNC_REG = "TRUE" *) reg  [pSYNC_STAGES-1:0] req_pipe;
   (* ASYNC_REG = "TRUE" *) reg  [pSYNC_STAGES-1:0] ack_pipe;
   (* ASYNC_REG = "TRUE" *) reg  [pDATA_WIDTH-1:0] dst_data_reg;
   (* ASYNC_REG = "TRUE" *) reg  [pDATA_WIDTH-1:0] transfer_data;
   reg  src_req;
   reg  dst_req;
   reg  dst_req_r;
   reg  src_ack;
   wire busy;
   reg  valid_data;
   reg  src_pulse_r;
   reg  src_outstanding;

   assign dst_data = dst_data_reg;

   // monitor for too-slow CDC:
   always @(posedge src_clk) begin
       if (reset_i) begin
           src_pulse_r <= 1'b0;
           src_outstanding <= 1'b0;
           src_overflow <= 1'b0;
       end
       else begin
           src_pulse_r <= src_pulse;
           if (src_pulse && ~src_pulse_r && ~src_outstanding)
               src_outstanding <= 1'b1;
           else if (src_ack)
               src_outstanding <= 1'b0;

           if (src_pulse && ~src_pulse_r && src_outstanding)
               src_overflow <= 1'b1;
           else if (clear_error)
               src_overflow <= 1'b0;

       end
   end

   always @(posedge src_clk) begin
      if (reset_i) begin
         src_ack <= 0;
         ack_pipe <= 0;
         src_req <= 0;
         transfer_data <= 0;
         valid_data <= 0;
      end
      else begin
         {src_ack, ack_pipe} <= {ack_pipe, dst_req};

         if (~busy & valid_data)
            src_req <= 1'b1;
         else if (src_ack)
            src_req <= 1'b0;

         if (~busy & src_pulse & !valid_data) begin
            valid_data <= 1'b1;
            transfer_data <= src_data;
         end
         else if (src_ack)
            valid_data <= 1'b0;

      end
   end

   assign busy = src_req | src_ack;

   always @(posedge dst_clk) begin
      if (reset_i) begin
         dst_req_r <= 0;
         dst_req <= 0;
         req_pipe <= 0;
         dst_pulse <= 0;
         dst_data_reg <= 0;
      end
      else begin
         {dst_req_r, dst_req, req_pipe} <= {dst_req, req_pipe, src_req};
         if (~dst_req_r & dst_req) begin
            dst_pulse <= 1;
            dst_data_reg <= transfer_data;
         end
         else
            dst_pulse <= 0;
      end
   end

endmodule

`default_nettype wire
