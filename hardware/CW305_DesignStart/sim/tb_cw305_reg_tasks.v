task write_byte;
   input [1:0] block;
   input [pADDR_WIDTH-pBYTECNT_SIZE-1:0] address;
   input [pBYTECNT_SIZE-1:0] subbyte;
   input [7:0] data;
   @(posedge usb_clk);
   usb_addr = {block, address[5:0], subbyte};
   usb_wdata = data;
   usb_wrn = 0;
   @(posedge usb_clk);
   usb_cen = 0;
   @(posedge usb_clk);
   usb_cen = 1;
   @(posedge usb_clk);
   usb_wrn = 1;
endtask


task read_byte;
   input [1:0] block;
   input [pADDR_WIDTH-pBYTECNT_SIZE-1:0] address;
   input [pBYTECNT_SIZE-1:0] subbyte;
   output [7:0] data;
   @(posedge usb_clk);
   usb_addr = {block, address[5:0], subbyte};
   @(posedge usb_clk);
   usb_rdn = 0;
   usb_cen = 0;
   @(posedge usb_clk);
   usb_cen = 1;
   #1 data = usb_data;
   repeat(2) @(posedge usb_clk);
   usb_rdn = 1;
   repeat(2) @(posedge usb_clk);
endtask


task write_word;
   input [1:0] block;
   input [pADDR_WIDTH-pBYTECNT_SIZE-1:0] address;
   input [31:0] data;
   int subbyte;
   for (subbyte = 0; subbyte < 4; subbyte = subbyte + 1)
      write_byte(block, address, subbyte, data[subbyte*8 +: 8]);
   if (pVERBOSE)
      $display("Write %0h", data);
endtask


task read_word;
   input [1:0] block;
   input [pADDR_WIDTH-pBYTECNT_SIZE-1:0] address;
   output [31:0] data;
   int subbyte;
   for (subbyte = 0; subbyte < 4; subbyte = subbyte + 1)
      read_byte(block, address, subbyte, data[subbyte*8 +: 8]);
   if (pVERBOSE)
      $display("Read %0h", data);
endtask


task write_match_rule;
   input [7:0] rule;
   input [63:0] pattern;
   input [7:0] bytes;
   input pattern_trigger_rule;
   int subbyte;
   reg [pADDR_WIDTH-pBYTECNT_SIZE-1:0] pattern_address, mask_address;
   reg [63:0] mask;
   pattern_address = `REG_TRACE_PATTERN0 + rule;
   mask_address = `REG_TRACE_MASK0 + rule;
   if (pattern_trigger_rule) begin
      pattern_rule_id = rule;
      pattern_rule_bytes = bytes;
   end
   // TODO: allow for other mask settings?
   case (bytes)
      1: mask = 64'h0000_0000_0000_00ff;
      2: mask = 64'h0000_0000_0000_ffff;
      3: mask = 64'h0000_0000_00ff_ffff;
      4: mask = 64'h0000_0000_ffff_ffff;
      5: mask = 64'h0000_00ff_ffff_ffff;
      6: mask = 64'h0000_ffff_ffff_ffff;
      7: mask = 64'h00ff_ffff_ffff_ffff;
      8: mask = 64'hffff_ffff_ffff_ffff;
   endcase
   for (subbyte = 0; subbyte < 8; subbyte = subbyte + 1) begin
      write_byte(`TRACE_REG_SELECT, pattern_address, subbyte, pattern[(7-subbyte)*8 +: 8]);
      write_byte(`TRACE_REG_SELECT, mask_address, subbyte, mask[(7-subbyte)*8 +: 8]);
   end
endtask


