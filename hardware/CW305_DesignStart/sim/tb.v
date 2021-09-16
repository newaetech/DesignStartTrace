/* 
ChipWhisperer Artix Target - Example of connections between example registers
and rest of system.

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

`timescale 1ns / 1ns
`default_nettype none 

`include "defines_trace.v"
`include "defines_pw.v"

module tb();
    parameter pADDR_WIDTH = 21;
    parameter pBYTECNT_SIZE = 7;
    //parameter pUSB_CLOCK_PERIOD = 10;
    parameter pUSB_CLOCK_PERIOD = 42;
    parameter pPLL_CLOCK_PERIOD = 168;
    parameter pTRIGGER_CLOCK_PERIOD = 2;
    parameter pCAPTURE_RAW = 0;
    parameter pCAPTURE_NOW = 0;
    parameter pPATTERN_TRIG = 0;
    parameter pSWO_MODE = 0;
    parameter pSWO_DIV = 15;
    parameter pTRACE_CLOCK_SEL = 0;
    parameter pUSB_CLOCK_SEL = 0;
    parameter pLONGCORNER = 0;
    parameter pTIMESTAMPS_DISABLED = 0;
    parameter pMAX_TIMESTAMP = 'hFFFF;
    parameter pSEED = 1;
    parameter pTIMEOUT = 2560000;
    parameter pVERBOSE = 0;
    parameter pDUMP = 0;

    reg usb_clk;
    wire [7:0] usb_data;
    reg [7:0] usb_wdata;
    reg [pADDR_WIDTH-1:0] usb_addr;
    reg usb_rdn;
    reg usb_wrn;
    reg usb_cen;
    wire usb_spare0;
    reg usb_spare1;

    reg j16_sel;
    reg k16_sel;
    reg k15_sel;
    reg l14_sel;
    reg pushbutton;
    reg reset;
    reg pll_clk1;
    reg trigger_clk;
    wire tio_clkin;
    wire trig_out;
    wire target_clk;
    reg  trace_clk = 1'b0;

    wire led1;
    wire led2;
    wire led3;

    wire tio_trigger;
    wire tio_clkout;

    wire [3:0] userio_d;
    wire swo;

    int seed;
    int errors;
    int trace_generator_errors;
    int warnings;
    int i;
    int match_index;
    int raw_index;

    
    reg [31:0] write_data;

    assign target_clk = pll_clk1;  // shorthand for testbench

   reg [63:0] matchdata[0:2047];
   int cycle;
   int total_time;

   reg [31:0] read_data;
   reg [63:0] read_buffer_data;
   reg [63:0] expected_pattern_data;
   reg [63:0] expected_pattern_mask;
   reg [7:0] pattern_rule_id;
   reg [7:0] pattern_rule_bytes;
   reg [1:0] command;
   reg fifo_stat_empty;
   reg fifo_stat_underflow;
   reg fifo_stat_empty_threshold;
   reg fifo_stat_full;
   reg fifo_stat_overflow_blocked;
   reg fifo_stat_synchronized;
   reg [7:0] fifo_data;
   reg [7:0] fifo_timestamp;
   reg [7:0] expected_rule;
   reg [31:0] expected_time;
   reg [7:0] expected_byte;

   bit setup_done;
   bit in_sync;
   bit fast_fifo_mode;
   bit long_corner_seen;
   int sync_counter;
   reg [63:0] sync_data;
   int slop;
   reg [31:0] max_timestamp;

   wire trace_generator_done;

   // TODO: verify trigger timing
   always @(*) begin
      if (trig_out & !setup_done) begin
         errors += 1;
         $display("TESTBENCH ERROR: trigger seen before setup was complete! Increase number of initial sync frames.");
      end
   end


   initial begin
      seed = pSEED;
      setup_done = 0;
      errors = 0;
      warnings = 0;
      match_index = 0;
      $display("Running with seed=%0d", seed);
      $urandom(seed);
      $display("pTRACE_CLOCK_SEL    = %1d", pTRACE_CLOCK_SEL);
      $display("pUSB_CLOCK_SEL      = %1d", pUSB_CLOCK_SEL);
      $display("pSWO_MODE           = %1d", pSWO_MODE);
      $display("pPATTERN_TRIG       = %1d", pPATTERN_TRIG);
      $display("pCAPTURE_RAW        = %1d", pCAPTURE_RAW);
      
      if (pDUMP) begin
         $dumpfile("results/tb.fst");
         $dumpvars(0, tb);
      end
      usb_clk = 1'b1;
      pll_clk1 = 1'b1;

      usb_wdata = 0;
      usb_addr = 0;
      usb_rdn = 1;
      usb_wrn = 1;
      usb_cen = 1;
      usb_spare1 = 1;

      j16_sel = 0;
      k16_sel = 0;
      k15_sel = 0;
      l14_sel = 0;
      pushbutton = 1;
      reset = 0;
      pll_clk1 = 0;
      trigger_clk = 0;

      //#(pPLL_CLOCK_PERIOD*2) pushbutton = 0;
      //#(pPLL_CLOCK_PERIOD*2) pushbutton = 1;
      #(pUSB_CLOCK_PERIOD*10);

      write_byte(`MAIN_REG_SELECT, `REG_RESET_REG, 0, 8'h1);
      reset = 1;
      write_byte(`MAIN_REG_SELECT, `REG_RESET_REG, 0, 8'h0);
      reset = 0;

      $readmemh("matchtimes.mem", matchdata);

      //write_byte(`TRACE_REG_SELECT, `REG_TRACE_RESET_SYNC, 0, 8'h1);
      // TODO: temporary:
      write_byte(`TRACE_REG_SELECT, `REG_REVERSE_TRACEDATA, 0, 8'h0);

      // enable all patterns:
      write_byte(`TRACE_REG_SELECT, `REG_PATTERN_ENABLE, 0, 8'hff);

      write_byte(`MAIN_REG_SELECT, `REG_COUNTER_QUICK_START, 0, 8'h1);

      write_byte(`TRACE_REG_SELECT, `REG_RECORD_SYNCS, 0, 8'h0);

      $display("Writing match rules...");
      `include "registers.v"
      $display("done!");

      if (pPATTERN_TRIG) begin
         // trigger from trace:
         write_byte(`TRACE_REG_SELECT, `REG_SOFT_TRIG_ENABLE, 0, 8'h0);
         write_byte(`TRACE_REG_SELECT, `REG_SOFT_TRIG_PASSTHRU, 0, 8'h0);
         write_byte(`MAIN_REG_SELECT, `REG_TRIGGER_ENABLE, 0, 8'h1);
         write_byte(`TRACE_REG_SELECT, `REG_PATTERN_TRIG_ENABLE, 0, 1<<pattern_rule_id);
         /*
         case (pattern_rule_id)
            0: write_byte(`TRACE_REG_SELECT, `REG_PATTERN_TRIG_ENABLE, 0, 8'h01);
            1: write_byte(`TRACE_REG_SELECT, `REG_PATTERN_TRIG_ENABLE, 0, 8'h02);
            2: write_byte(`TRACE_REG_SELECT, `REG_PATTERN_TRIG_ENABLE, 0, 8'h01);
            3: write_byte(`TRACE_REG_SELECT, `REG_PATTERN_TRIG_ENABLE, 0, 8'h01);
            4: write_byte(`TRACE_REG_SELECT, `REG_PATTERN_TRIG_ENABLE, 0, 8'h01);
            5: write_byte(`TRACE_REG_SELECT, `REG_PATTERN_TRIG_ENABLE, 0, 8'h01);
            6: write_byte(`TRACE_REG_SELECT, `REG_PATTERN_TRIG_ENABLE, 0, 8'h01);
            7: write_byte(`TRACE_REG_SELECT, `REG_PATTERN_TRIG_ENABLE, 0, 8'h01);
         endcase
         */
      end
      else begin
         // use m3 trigger:
         write_byte(`TRACE_REG_SELECT, `REG_SOFT_TRIG_ENABLE, 0, 8'h1);
         write_byte(`TRACE_REG_SELECT, `REG_SOFT_TRIG_PASSTHRU, 0, 8'h1);
      end

      write_byte(`TRACE_REG_SELECT, `REG_CAPTURE_RAW, 0, pCAPTURE_RAW);

      // TODO: set these intelligently
      write_word(`MAIN_REG_SELECT, `REG_CAPTURE_LEN, 32'd20000);
      write_byte(`MAIN_REG_SELECT, `REG_COUNT_WRITES, 0, 8'h1);

      if (pSWO_MODE) begin
         write_byte(`TRACE_REG_SELECT, `REG_SWO_ENABLE, 0, 8'h1);
         write_byte(`TRACE_REG_SELECT, `REG_SWO_BITRATE_DIV, 0, pSWO_DIV);
      end

      write_byte(`MAIN_REG_SELECT, `REG_TIMESTAMPS_DISABLE, 0, pTIMESTAMPS_DISABLED);

      write_byte(`MAIN_REG_SELECT, `REG_CAPTURE_WHILE_TRIG, 0, 0);


      // don't make the max timestamp smaller than the short timestamp!
      if (pMAX_TIMESTAMP < 'h200) begin
          $display("pMAX_TIMESTAMP is too small!");
          errors += 1;
      end
      max_timestamp = $urandom_range('h200, pMAX_TIMESTAMP);
      $display("Setting max timestamp to %h", max_timestamp);
      write_word(`MAIN_REG_SELECT, `REG_MAX_TIMESTAMP, max_timestamp);

      if (pCAPTURE_NOW == 0)
         write_byte(`MAIN_REG_SELECT, `REG_ARM, 0, 8'h1);
      else
         write_byte(`MAIN_REG_SELECT, `REG_ARM, 0, 8'h3);

      if (pUSB_CLOCK_SEL)
         write_byte(`TRACE_REG_SELECT, `REG_FE_CLOCK_SEL, 0, 8'h2);
      else if (pTRACE_CLOCK_SEL)
         write_byte(`TRACE_REG_SELECT, `REG_FE_CLOCK_SEL, 0, 8'h1);
      else
         write_byte(`TRACE_REG_SELECT, `REG_FE_CLOCK_SEL, 0, 8'h0);

      setup_done = 1;

   end

   // DIY code coverage:
   initial begin
       long_corner_seen = 0;
       wait (setup_done);
       wait (U_dut.U_trace_top.U_fe_capture_main.long_corner);
       long_corner_seen = 1;
   end

   // maintain a cycle counter
   always @(posedge target_clk) begin
      if (reset == 1)
         cycle <= 0;
      else
         cycle <= cycle + 1;
   end

   // testbench generates data on target clock; synthesize the half-rate trace clock:
   always @ (posedge target_clk)
       trace_clk <= ~trace_clk;


   // timeout thread:
   initial begin
      #(pUSB_CLOCK_PERIOD*pTIMEOUT);
      errors += 1;
      $display("ERROR: global timeout");
      $display("SIMULATION FAILED (%0d errors).", errors);
      $finish;
   end


   // FIFO read thread:
   initial begin
      #10 wait(setup_done);
      match_index = 0;

      `ifdef CW305
         fast_fifo_mode = 0;
      `else
         if (pTIMESTAMPS_DISABLED)
            fast_fifo_mode = 1;
         else
            fast_fifo_mode = $urandom % 2;
      `endif
      if (fast_fifo_mode)
         $display("Using fast FIFO read mode");
      else
         $display("Using regular FIFO read mode");

      if (pPATTERN_TRIG && pCAPTURE_RAW) begin
         // in this case, the pattern bytes weren't written to a FIFO but we can retrieve them from a register:
         wait_fifo_not_empty();
         read_word(`TRACE_REG_SELECT, `REG_MATCHED_DATA, read_buffer_data);
         // this is a bit wonky, but since the pattern was generated from Python, it's easiest to verify
         // by reading it back:
         read_word(`TRACE_REG_SELECT, `REG_TRACE_PATTERN0+pattern_rule_id, expected_pattern_data);
         read_word(`TRACE_REG_SELECT, `REG_TRACE_MASK0+pattern_rule_id, expected_pattern_mask);
         if (expected_pattern_data != (expected_pattern_mask & read_buffer_data)) begin
            errors += 1;
            $display("ERROR on pattern match bytes.");
            $display("expected pattern: %h", expected_pattern_data);
            $display("expected mask:    %h", expected_pattern_mask);
            $display("read data:        %h", read_buffer_data);
         end
         match_index += pattern_rule_bytes;
      end

      total_time = 0;
      write_byte(`MAIN_REG_SELECT, `REG_FAST_FIFO_RD_EN, 0, {7'b0, fast_fifo_mode});
      while (matchdata[match_index] != 64'hFFFF_FFFF_FFFF_FFFF) begin
         read_fifo(fast_fifo_mode);
         while (command == `FE_FIFO_CMD_TIME) begin
            total_time += read_data[`FE_FIFO_TIME_START +: `FE_FIFO_FULLTIME_LEN];
            read_fifo(fast_fifo_mode);
         end

         total_time += read_data[`FE_FIFO_TIME_START +: `FE_FIFO_SHORTTIME_LEN];

         if (pCAPTURE_RAW == 0) begin // rules mode
            expected_rule = matchdata[match_index][63:56];
            expected_time = matchdata[match_index][55:0];
            if (command != `FE_FIFO_CMD_DATA) begin
               errors += 1;
               $display("ERROR at time %t: expected data command (%2b), got %2b", $time, `FE_FIFO_CMD_DATA, command);
            end
            if (fifo_data != expected_rule) begin
               errors += 1;
               $display("ERROR on match event %0d: expected match rule %0d, got %0d", match_index, expected_rule, fifo_data);
            end
            else
               $display("Correct rule on match event %0d", match_index);
            // now check timestamp -- exact in the case of trace, some slop allowed for SWO
            if (pSWO_MODE)
               slop = 5; // TODO: tie this into clock ratios?
            else
               slop = 0;
            // in pCAPTURE_NOW mode, we don't correctly predict the first timestamp, so skip checking it:
            if ( (total_time > expected_time + slop) || (total_time < expected_time - slop) ) begin
               errors += 1;
               $display("ERROR on match event %0d at time %t: expected timestamp %0d, got %0d", match_index, $time, expected_time, total_time);
            end
            match_index += 1;
            total_time = 0;
         end

         else begin // raw mode 
            if (command != `FE_FIFO_CMD_STAT) begin
               errors += 1;
               $display("ERROR at time %t: expected data command (%2b), got %2b", $time, `FE_FIFO_CMD_STAT, command);
            end
            expected_byte = matchdata[match_index][63:56];
            expected_time = matchdata[match_index][55:0];
            $display("Expected: %2h Got: %2h", expected_byte, fifo_data);

            if (fifo_data != expected_byte) begin
               // Ignore sync frames, which may be present. For now we assume these bytes are part
               // of sync frames, and we'll actually verify that later.
               if ( (fifo_data == 8'hff) || (fifo_data == 8'h7f) ) begin
                  //total_time += 1;
                  if (in_sync == 0) begin
                     sync_counter = 1;
                     sync_data = {56'h0, fifo_data};
                     in_sync = 1;
                  end
                  else begin
                     sync_counter += 1;
                     case (sync_counter)
                        2: sync_data[15:8]  = fifo_data;
                        3: sync_data[23:16] = fifo_data;
                        4: sync_data[31:24] = fifo_data;
                        5: sync_data[39:32] = fifo_data;
                        6: sync_data[47:40] = fifo_data;
                        7: sync_data[55:48] = fifo_data;
                        8: sync_data[63:56] = fifo_data;
                     endcase
                  end
               end
               else begin
                  $display("ERROR at time %t: expected raw byte %h, got %h", $time, expected_byte, fifo_data);
                  errors += 1;
                  match_index += 1;
               end
            end

            else begin
               if (pSWO_MODE)
                  slop = 2; // TODO: tie this into clock ratios?
               else
                  slop = 0;
               // in pCAPTURE_NOW mode, we don't correctly predict the first timestamp, so skip checking it:
               if ( ((total_time > expected_time + slop) || (total_time < expected_time - slop)) && (pTIMESTAMPS_DISABLED == 0) ) begin 
                  if (pCAPTURE_NOW && (match_index == 0)) begin
                     $display("info: skipping time check on first byte because pCAPTURE_NOW");
                  end
                  else begin
                     errors += 1;
                     $display("ERROR on match byte #%0d (byte=%0x) at time %t: expected timestamp %0d, got %0d", match_index, fifo_data, $time, expected_time, total_time);
                  end
                  total_time = 0;
               end
               else begin
                  //$display("good time on match byte #%0d (byte=%0x): %0d", match_index, fifo_data, expected_time);
                  total_time = 0;
               end

               if (in_sync == 1) begin
                  if (sync_counter % 2 != 0) begin
                     errors += 1;
                     $display("ERROR at time %t: observed unexpected number of sync bytes (%0d)", $time, sync_counter);
                  end
                  else begin
                  // verify that non-matching data are actually sync frames:
                     //$display("Sync data seen: counter = %d, contents = %8h", sync_counter, sync_data);
                     if (sync_counter > 12) begin
                        warnings += 1;
                        $display("WARNING at time %t: too much sync data seen! counter = %d, contents = %8h", $time, sync_counter, sync_data);
                     end
                     if ( (sync_data != 64'h0000_0000_7fff_7fff) &&
                          (sync_data != 64'h7fff_7fff_7fff_7fff) &&
                          (sync_data != 64'h7fff_ffff_7fff_ffff) &&
                          (sync_data != 64'h7fff_ffff_7fff_7fff) &&
                          (sync_data != 64'h7fff_7fff_7fff_ffff) &&
                          (sync_data != 64'hffff_7fff_7fff_ffff) &&
                          (sync_data != 64'h0000_0000_7fff_ffff) &&
                          (sync_data != 64'h0000_7fff_7fff_7fff) &&
                          (sync_data != 64'h0000_7fff_7fff_ffff) &&
                          (sync_data != 64'h0000_7fff_ffff_7fff) &&
                          (sync_data != 64'h0000_0000_0000_7fff) &&
                          (sync_data != 64'hffff_7fff_7fff_7fff) &&
                          (sync_data != 64'hffff_7fff_ffff_7fff) &&
                          (sync_data != 64'h7fff_7fff_ffff_7fff) ) begin
                        errors += 1;
                        $display("ERROR: non-sync data seen! counter = %d, contents = %8h", sync_counter, sync_data);
                     end
                  end
               end
               in_sync = 0;
               match_index += 1;
            end

         end

      end

      usb_cen = 1'b1; // fast FIFO read mode left this low

      #(pUSB_CLOCK_PERIOD*10);
      $display("All expected events processed. Waiting for trace generator to be done...");
      wait (trace_generator_done);
      $display("Trace generator done.");
      errors += trace_generator_errors;
      if (pLONGCORNER && long_corner_seen == 0) begin
          warnings += 1;
          $display("WARNING: no long corner observed (this can happen from time to time, but it shouldn't happen on every run!");
      end
      if (errors)
         $display("SIMULATION FAILED (%0d errors, %0d warnings).", errors, warnings);
      else
         $display("Simulation passed (%0d warnings).", warnings);
      $finish;

   end

   reg read_select;

   assign usb_data = read_select? 8'bz : usb_wdata;
   assign tio_clkin = pll_clk1;

   assign userio_d[2] = swo;

   always @(*) begin
      if (usb_wrn == 1'b0)
         read_select = 1'b0;
      else if (usb_rdn == 1'b0 || usb_spare1 == 1'b0)
         read_select = 1'b1;
   end


   `ifdef CW305
      `include "tb_cw305_reg_tasks.v"

   `else
      `include "tb_pw_reg_tasks.v"

   `endif



   task wait_fifo_empty;
      bit fifo_empty = 0;
      while (fifo_empty == 0) begin
         read_byte(`MAIN_REG_SELECT, `REG_SNIFF_FIFO_STAT, 0, fifo_empty);
      end
   endtask


   task wait_fifo_not_empty;
      bit fifo_empty = 1;
      read_byte(`MAIN_REG_SELECT, `REG_SNIFF_FIFO_STAT, 0, fifo_empty);
      while (fifo_empty == 1) begin
         read_byte(`MAIN_REG_SELECT, `REG_SNIFF_FIFO_STAT, 0, fifo_empty);
      end
   endtask


   task read_fifo;
      input fast_read;
      if (fast_read)
         fast_fifo_read(read_data);
      else begin
         wait_fifo_not_empty();
         read_word(`MAIN_REG_SELECT, `REG_SNIFF_FIFO_RD, read_data);
      end
      if (pTIMESTAMPS_DISABLED) begin
         command =                   `FE_FIFO_CMD_STAT;
         fifo_stat_empty =           0;
         fifo_stat_underflow =       0;
         fifo_stat_empty_threshold = 0;
         fifo_stat_full =            0;
         fifo_stat_overflow_blocked= 0;
         fifo_stat_synchronized =    0;
         fifo_data =                 read_data[7:0];
      end
      else begin
         read_data = {8'b0, read_data[31:8]};
         command =                   read_data[`FE_FIFO_CMD_START +: `FE_FIFO_CMD_BIT_LEN];
         fifo_stat_empty =           read_data[18+`FIFO_STAT_EMPTY];
         fifo_stat_underflow =       read_data[18+`FIFO_STAT_UNDERFLOW];
         fifo_stat_empty_threshold = read_data[18+`FIFO_STAT_EMPTY_THRESHOLD];
         fifo_stat_full =            read_data[18+`FIFO_STAT_FULL];
         fifo_stat_overflow_blocked= read_data[18+`FIFO_STAT_OVERFLOW_BLOCKED];
         fifo_stat_synchronized =    read_data[18+`FIFO_STAT_SYNC_FLAG];
         fifo_data =                 read_data[15:8];
      end
   endtask


   task fast_fifo_read;
      output [31:0] fifo_word;
      int i;
      int reads;
      reg [7:0] data;
      if (pTIMESTAMPS_DISABLED)
         reads = 1;
      else
         reads = 4;
      wait (usb_spare0);
      for (i = 0; i < reads; i = i + 1) begin
         @(posedge usb_clk);
         usb_spare1 = 0;
         usb_cen = 0;
         repeat (2) @(posedge usb_clk);
         usb_spare1 = 1;
         @(posedge usb_clk);
         #1 data = usb_data;
         fifo_word[i*8 +: 8] = data;
         //usb_cen = 1;
         repeat(2) @(posedge usb_clk);
      end
   endtask


   always #(pUSB_CLOCK_PERIOD/2) usb_clk = !usb_clk;
   always #(pPLL_CLOCK_PERIOD/2) pll_clk1 = !pll_clk1;
   always #(pTRIGGER_CLOCK_PERIOD/2) trigger_clk = !trigger_clk;

   wire #1 usb_rdn_out = usb_rdn;
   wire #1 usb_wrn_out = usb_wrn;
   wire #1 usb_cen_out = usb_cen;
   wire #1 usb_spare1_out = usb_spare1;

   `ifdef CW305
      CW305_designstart_top #(
          .pADDR_WIDTH        (pADDR_WIDTH),
          .pBYTECNT_SIZE      (pBYTECNT_SIZE)
      ) U_dut (
          // USB Interface
          .USB_clk            (usb_clk    ),
          .USB_Data           (usb_data   ),
          .USB_Addr           (usb_addr   ),
          .USB_nRD            (usb_rdn_out),
          .USB_nWE            (usb_wrn_out),
          .USB_nCS            (usb_cen_out),

          // Buttons/LEDs on Board
          .j16_sel            (j16_sel   ),
          .k16_sel            (k16_sel   ),
          .k15_sel            (k15_sel   ),
          .l14_sel            (l14_sel   ),
          //.resetn             (~reset    ),
          .resetn_pin         (1'b1      ),
          .led1               (led1      ),
          .led2               (led2      ),
          .led3               (led3      ),

          // PLL
          .pll_clk1           (pll_clk1),

          // 20-Pin Connector
          //.tio_trigger        (tio_trigger),
          //.tio_clkout         (tio_clkout ),
          .tio_clkin          (tio_clkin  ),
          .trig_out           (trig_out),

          .I_trigger_clk      (trigger_clk),
          .trace_generator_done (trace_generator_done),

          // unused here:
          .swclk              (1'b0),
          .TDI                (1'b0),
          .nTRST              (1'b0),
          .uart_rxd           (1'b0)
      );

   `else
      wire [3:0] TRACEDATA;
      wire [7:0] trace_data_sdr;
      wire m3_trig_out;

      tracewhisperer_top #(
          .pADDR_WIDTH        (8),
          .pBYTECNT_SIZE      (pBYTECNT_SIZE)
      ) U_dut (

          // USB Interface
          .USB_clk            (usb_clk    ),
          .USB_Data           (usb_data   ),
          .USB_Addr           (usb_addr[7:0]),
          .USB_nRD            (usb_rdn_out),
          .USB_nWE            (usb_wrn_out),
          .USB_nCS            (usb_cen_out),
          .USB_SPARE0         (usb_spare0 ),
          .USB_SPARE1         (usb_spare1_out ),

          // LEDs on Board
          .led1               (led1      ),
          .led2               (led2      ),
          .led3               (led3      ),

          // trace
          .TRCENA             (1'b1),
          .target_clk         (target_clk),
          .TRACEDATA          (TRACEDATA),
          .TRACECLOCK         (trace_clk),

          // userio (SWO)
          .userio_d           (userio_d),

          // 20-Pin Connector
          .trig_out           (trig_out),          // output to CW
          .target_trig_in     (m3_trig_out),       // input from target

          .I_trigger_clk      (trigger_clk),
          .I_trace_sdr        (trace_data_sdr)

      );

      tb_trace_generator #(
            .pSWO_MODE              (pSWO_MODE),
            .pSWO_DIV               (pSWO_DIV)
      ) U_tb_trace_generator
           (.target_clk             (target_clk),
            .swo_clk                (trigger_clk),
            .reset                  (reset),
            .trace_data_sdr         (trace_data_sdr),
            .TRACEDATA              (TRACEDATA),
            .swo                    (swo),
            .trig_out               (m3_trig_out),
            .done                   (trace_generator_done),
            .errors                 (trace_generator_errors)
           );

   `endif


endmodule

`default_nettype wire

