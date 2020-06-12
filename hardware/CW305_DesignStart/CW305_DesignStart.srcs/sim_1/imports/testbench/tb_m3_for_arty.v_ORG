//-----------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM limited.
//
//            (C) COPYRIGHT 2006-2018 ARM limited.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM limited.
//
//      SVN Information
//
//      Checked In          : $Date$
//
//      Revision            : $Revision$
//
//      Release Information : Cortex-M3 DesignStart-r0p1-00rel0
//-----------------------------------------------------------------------------
// Purpose :
//     Testbench for the M3 on Arty A7 board example design
//-----------------------------------------------------------------------------

// Uncomment this if the model for the Micron and Spansion QSPI devices has been downloaded
// and installed in the appropriate directory.  If this is not defined, the testbench will issue
// an error message if there are any attempts to read or write to the QSPI
// `define INCLUDE_QSPI_MODEL 1

// Uncomment this if a model of the DAPLink is fitted
`define INCLUDE_DAPLINK 1

// Uncomment if the DAPLink is fitted, but we want the on-board link to be not fitted
// This configuration supports the DAPLink hardware, but code runs from internal RAM
// If INCLUDE_DAPLINK is not defined, then this has no effect
`define DAPLINK_LINK_NF


`timescale 1 ps / 1 ps

module tb_m3_for_arty ();

    // Define input clock
    localparam CLK_PERIOD_12M  = 83334;
    localparam CLK_PERIOD_100M = 10000;
    localparam CLK_PERIOD_1M   = 1000000;

// Spartan version runs at 12MHz
// Artix version runs at 100MHz    
`ifdef ARTY_S7_TARGET
    localparam CLK_PERIOD_SYS  = CLK_PERIOD_12M;
`else
    localparam CLK_PERIOD_SYS  = CLK_PERIOD_100M;
`endif

    // Need clock at baud rate for uart_capture module
    localparam BAUD_RATE       = 230400;
//    localparam CLK_DIV_BAUD    = (BAUD_RATE)/22);     // 11 bits - 1 start, 8 data, 1 stop, 1 parity
// When baud set to 115200, period is 17280ns.  So 1728/2 = 864 @ 100MHz.
//    localparam CLK_DIV_BAUD    = 10416;     // Should be sum above, but measurement in sim results in this value; when 230400
    localparam CLK_DIV_BAUD    = 864;     // Should be sum above, but measurement in sim results in this value; when baud = 115200
    
    reg         clk_sys  = 1'b0;
    reg         clk_1m   = 1'b0;
    reg         clk_baud = 1'b0;
    reg         reset_n;
    reg         nTRST;
    wire        TDO;
    
    wire        uart_tx;
    wire        uart_rx;

    wire  [3:0] led_4bits_tri_io;
    wire [11:0] rgb_led_tri_io;
    reg   [7:0] push_buttons_SRL;
    reg   [3:0] dip_switches_4bits_tri_i;

    wire [15:0] DAPLink_tri_o;
    wire        qspi_flash_io0_io;
    wire        qspi_flash_io1_io;
    wire        qspi_flash_io2_io;
    wire        qspi_flash_io3_io;
    wire        qspi_flash_sck_io;
    wire        qspi_flash_ss_io;

    
    always #(CLK_PERIOD_SYS/2)  clk_sys  <= ~clk_sys;
    always #(CLK_PERIOD_1M/2)   clk_1m   <= ~clk_1m;
    // always #(CLK_PERIOD_BAUD/2) clk_baud <= ~clk_baud;

    // Integer will cover sufficient range for all baud rates
    integer baud_count = 0;
    always @(posedge clk_sys)
        if( baud_count == (CLK_DIV_BAUD/2)-1 )
        begin
            baud_count <= 0;
            clk_baud   <= ~clk_baud;
        end
        else
            baud_count <= baud_count + 1;
            
    // Period of toggling switches needs to increase when running from QSPI
    // as execution is so much slower
`ifdef INCLUDE_DAPLINK
    localparam SW_TOGGLE_RATE = 40000;
`else
    localparam SW_TOGGLE_RATE = 1000;
`endif

    
    // Release resets on appropriate clock edges
    initial
    begin
        reset_n                  = 1'b0;
        nTRST                    = 1'b0;
        push_buttons_SRL         = 8'h01;
        dip_switches_4bits_tri_i = 4'b0;
        
        // Baud rate clock is slowest, so ensure circuits reset by that properly
        repeat (3)   @(posedge clk_baud) begin end;
        @(negedge clk_baud) begin end;
        repeat (500) @(posedge clk_sys) begin end;
        reset_n = 1'b1;
        repeat (100) @(posedge clk_sys) begin end;
        nTRST   = 1'b1;
        while( led_4bits_tri_io == 4'hf )
            repeat (50) @(posedge clk_sys) begin end;
        
        repeat (SW_TOGGLE_RATE) @(posedge clk_sys) begin end;
        // On each push of a button, tristate LED will change colour
        // For each DIP switch, respective single LED will light
        repeat(20) begin
            repeat (SW_TOGGLE_RATE) @(posedge clk_sys) begin end;
            push_buttons_SRL         = {push_buttons_SRL[6:0], push_buttons_SRL[7]};
            dip_switches_4bits_tri_i = dip_switches_4bits_tri_i + 1;
        end
    end

    // LEDs are driven by tri-state.  Add pull-ups
    pullup i_led_4bits_pu[3:0] (led_4bits_tri_io);
    pullup i_led_tri_pu[11:0]  (rgb_led_tri_io);
    
    // Create 100 cycle delayed loopback on UART
    // Default start-up value of uart_rx is 1'b1
    localparam UART_DELAY = 100;
    reg [UART_DELAY-1:0] uart_pipe = {UART_DELAY{1'b1}};
    
    always @(posedge clk_baud)
        uart_pipe <= {uart_pipe[UART_DELAY-2:0], uart_tx};
        
    assign uart_rx = uart_pipe[UART_DELAY-1];

    // To mirror the operation when the DAPLink is not fitted, pull the detect line high
    // To mimic daplink fitted, pull the line low
    // DAPLink also has it's own reset, drive this when fitted
    // Leave other pins floating to see if X's propogate throught the simulation.
`ifdef INCLUDE_DAPLINK

    // Allow possibility of running code from BRAM rather than DAPLink QSPI
    // Partiucularly useful in simulation for speed.
    // Mirrors the effect of not having the DAPLink present link fitted 
    // DAPLink fittedn
    `ifndef DAPLINK_LINK_NF
        assign DAPLink_tri_o[8] = 1'b0;
    `endif

    // DAPLink reset
    reg daplink_srstn = 1'b0;
    
    initial
        // Hold reset for 10us
        // This needs to be longer than the period in the Cypress QSPI model, (3e8)
        #4e8 daplink_srstn = 1'b1;
        
    assign DAPLink_tri_o[13] = daplink_srstn;
    
    // DAPLink supports SerialWire access, (SW).  Generate dummy inputs to ensure they propogate correctly.
    // Use 1MHz clock for SerialWire clock.
    assign DAPLink_tri_o[15] = clk_1m;
    // Divide clock by 4 as a dummy data in signal
    reg [1:0] sw_di;
    always @(posedge clk_1m)
        if ( ~daplink_srstn )
            sw_di <= 0;
        else
            sw_di <= sw_di + 1;

    // Pulse input low every 4th cycle
    assign DAPLink_tri_o[14] = ~(sw_di == 2'b11);
`endif    

    // DAPLink signals are pulled up by the FPGA IO
    pullup(DAPLink_tri_o[8]);
    pullup(DAPLink_tri_o[13]);
    
    // Instantiate appropriate DUT
`ifdef ARTY_S7_TARGET
    m3_for_arty_s7 DUT (
`else
    m3_for_arty_a7_wrapper DUT (
`endif
        // Clocks and reset
        .reset                      (reset_n),      // Negative reset.  Poorly labelled in board file
        .sys_clock                  (clk_sys),
        // Debug
        .nTRST                      (nTRST),
        .TDI                        (1'b0),
        .TDO                        (TDO),

        // Uart
        .usb_uart_rxd               (uart_rx),
        .usb_uart_txd               (uart_tx),

        // Push buttons
        .push_buttons_4bits_tri_i   ({push_buttons_SRL[6], push_buttons_SRL[4],push_buttons_SRL[2],push_buttons_SRL[0]}),
        .dip_switches_4bits_tri_i   (dip_switches_4bits_tri_i),

        // LEDs
        .led_4bits_tri_io           (led_4bits_tri_io),
        .rgb_led_tri_io             (rgb_led_tri_io),
        
        // Quad SPI flash
        .qspi_flash_io0_io          (qspi_flash_io0_io),
        .qspi_flash_io1_io          (qspi_flash_io1_io),
        .qspi_flash_io2_io          (qspi_flash_io2_io),
        .qspi_flash_io3_io          (qspi_flash_io3_io),
        .qspi_flash_sck_io          (qspi_flash_sck_io),
        .qspi_flash_ss_io           (qspi_flash_ss_io),

        // Optional DAPLink interface
        .DAPLink_tri_o              (DAPLink_tri_o)
    );


    // --------------------------------------------------------------------------------
    // UART output capture
    // --------------------------------------------------------------------------------
    // UART output is directed to DAPLink board when fitted, (and the link present )

    cmsdk_uart_capture   u_cmsdk_uart_capture(
        .RESETn               (reset_n),
        .CLK                  (clk_baud),
        .RXD                  ((DAPLink_tri_o[8]) ? uart_tx : DAPLink_tri_o[11]),
        .DEBUG_TESTER_ENABLE  (),
        .SIMULATIONEND        (),           // This signal set to 1 at the end of simulation.
        .AUXCTRL              ()
    );

`ifdef INCLUDE_QSPI_MODEL

    wire [31:0] Vcc; 

    // For the Arty board, Vcc=3v3
    // Vcc value is defined in mV.
    assign Vcc='d3300;

    N25Qxxx i_qspi (
        .S          (qspi_flash_ss_io),
        .C_         (qspi_flash_sck_io),
        .HOLD_DQ3   (qspi_flash_io3_io),
        .DQ0        (qspi_flash_io0_io),
        .DQ1        (qspi_flash_io1_io),
        .Vcc        (Vcc),
        .Vpp_W_DQ2  (qspi_flash_io2_io)
    );
    
    // If we have the QSPI model, and DAPLink, then include the QSPI XIP memory
    // This can be initialised with the code
    `ifdef INCLUDE_DAPLINK
    
        // DAPLink uses Cypress Semi S25FL128S device
        s25fl128s #(
            .UserPreload    (1),
            .mem_file_name  ("qspi_a7.hex"),
            .otp_file_name  ("none")
        ) i_qspi_xip (
            // Data Inputs/Outputs
            .SI             (DAPLink_tri_o[4]),
            .SO             (DAPLink_tri_o[5]),
            // Controls
            .SCK            (DAPLink_tri_o[9]),
            .CSNeg          (DAPLink_tri_o[10]),
            .RSTNeg         (DAPLink_tri_o[13]),
            .WPNeg          (DAPLink_tri_o[6]),
            .HOLDNeg        (DAPLink_tri_o[7])
        );

        // Xilinx QSPI does not configure Spansion, (Cypress), QSPI for operation
        // It requires user to have pre-programmed device to Quad mode, (config reg[1])
        // See Xilinx Datasheet for QSPI controller, page 57
        // DAPLink boards are supplied with the QSPI pre-programmed to Quad mode.
        // Simulate this by forcing the QSPI model internal signal
        initial
            force i_qspi_xip.QUAD = 1'b1;
    `else
        always @(DAPLink_tri_o[10])
            if (DAPLink_tri_o[10] == 1'b0) $error("Access to DAPLink QSPI will fail due to no model in testbench" );

    `endif // INCLUDE_DAPLINK

`else
    always @(qspi_flash_ss_io)
        if (qspi_flash_ss_io == 1'b0) $error("Access to Baseboard QSPI will fail due to no model in testbench" );

`endif

endmodule : tb_m3_for_arty
