set_property IOSTANDARD LVCMOS33 [get_ports *]

create_clock -period 100.000 -name TRACECLOCK -waveform {0.000 50.000} [get_nets TRACECLOCK]
create_clock -period 10.000 -name usb_clk -waveform {0.000 5.000} [get_nets USB_clk]

create_generated_clock -name trigger_clk [get_pins U_trace_top/U_trigger_clock/inst/mmcm_adv_inst/CLKOUT0]
create_generated_clock -name trace_clk [get_pins U_trace_top/U_trace_clock/inst/mmcm_adv_inst/CLKOUT0]

set_clock_groups -asynchronous \
                 -group [get_clocks usb_clk] \
                 -group [get_clocks trigger_clk]

set_clock_groups -asynchronous \
                 -group [get_clocks usb_clk] \
                 -group [get_clocks trace_clk]

set_clock_groups -asynchronous \
                 -group [get_clocks trigger_clk] \
                 -group [get_clocks trace_clk]


# reset from USB_SPARE0:
set_property PACKAGE_PIN K3 [get_ports reset]


# Master clock frequencies derived from clock wizard

# virtual clock:
create_clock -period 100.000 -name slow_out_clk

# Reset
set_input_delay -clock [get_clocks trace_clk] -add_delay 0.500 [get_ports reset*]

# *****************************************************************************

# LEDs
set_property DRIVE 8 [get_ports led2]
set_property DRIVE 8 [get_ports led3]
set_property PACKAGE_PIN D2 [get_ports led2]
set_property PACKAGE_PIN A2 [get_ports led3]

# this one is actually on 20-pin connector: PD pin
set_property PACKAGE_PIN M3 [get_ports led1]

# front connector:
# userio_d[0] through [7]:
set_property PACKAGE_PIN P13 [get_ports reset_dbg]
# N/C set_property PACKAGE_PIN P13 [get_ports ]
# N/C set_property PACKAGE_PIN M12 [get_ports ]
# TDO set_property PACKAGE_PIN P12 [get_ports ]
# nRESET set_property PACKAGE_PIN N11 [get_ports ]

set_property PACKAGE_PIN M10 [get_ports TRACEDATA[3]]
set_property PACKAGE_PIN N10 [get_ports TRACEDATA[2]]
set_property PACKAGE_PIN P10 [get_ports TRACEDATA[1]]
set_property PACKAGE_PIN N11 [get_ports TRACEDATA[0]]

# userio_clk:
set_property PACKAGE_PIN G11 [get_ports TRACECLOCK]

# USB:
set_property PACKAGE_PIN D1 [get_ports USB_clk]
set_property PACKAGE_PIN N4 [get_ports {USB_Data[7]}]
set_property PACKAGE_PIN P5 [get_ports {USB_Data[6]}]
set_property PACKAGE_PIN B5 [get_ports {USB_Data[5]}]
set_property PACKAGE_PIN J2 [get_ports {USB_Data[4]}]
set_property PACKAGE_PIN J1 [get_ports {USB_Data[3]}]
set_property PACKAGE_PIN H3 [get_ports {USB_Data[2]}]
set_property PACKAGE_PIN A5 [get_ports {USB_Data[1]}]
set_property PACKAGE_PIN B6 [get_ports {USB_Data[0]}]

# order as per schematic:
#set_property PACKAGE_PIN J3  [get_ports USB_Addr[7] ]
#set_property PACKAGE_PIN P4  [get_ports USB_Addr[6] ]
#set_property PACKAGE_PIN P3  [get_ports USB_Addr[5] ]
#set_property PACKAGE_PIN H2  [get_ports USB_Addr[4] ]
#set_property PACKAGE_PIN H1  [get_ports USB_Addr[3] ]
#set_property PACKAGE_PIN G1  [get_ports USB_Addr[2] ]
#set_property PACKAGE_PIN L2  [get_ports USB_Addr[1] ]
#set_property PACKAGE_PIN L1  [get_ports USB_Addr[0] ]

# corrected order:
set_property PACKAGE_PIN J3 [get_ports {USB_Addr[5]}]
set_property PACKAGE_PIN P4 [get_ports {USB_Addr[4]}]
set_property PACKAGE_PIN P3 [get_ports {USB_Addr[3]}]
set_property PACKAGE_PIN H2 [get_ports {USB_Addr[2]}]
set_property PACKAGE_PIN H1 [get_ports {USB_Addr[1]}]
set_property PACKAGE_PIN G1 [get_ports {USB_Addr[0]}]
set_property PACKAGE_PIN L1 [get_ports {USB_Addr[6]}]
set_property PACKAGE_PIN L2 [get_ports {USB_Addr[7]}]

set_property PACKAGE_PIN B3 [get_ports USB_nRD]
set_property PACKAGE_PIN B2 [get_ports USB_nWE]
set_property PACKAGE_PIN A3 [get_ports USB_nCS]

set_property PACKAGE_PIN A4 [get_ports USB_SPARE1]

# 20-pin connector:
set_property PACKAGE_PIN P2 [get_ports trig_out]

# borrow PC pin:
set_property PACKAGE_PIN M1 [get_ports target_trig_in]

# borrow SCK pin:
set_property PACKAGE_PIN M2 [get_ports trace_clk_locked]

# borrow MOSI pin:
set_property PACKAGE_PIN F2 [get_ports synchronized]

set_property PACKAGE_PIN M13 [get_ports mcx_trig]

set_input_delay -clock usb_clk 2.0 [get_ports USB_nCS]
set_input_delay -clock usb_clk 2.0 [get_ports USB_nRD]
set_input_delay -clock usb_clk 2.0 [get_ports USB_nWE]
set_input_delay -clock usb_clk 2.0 [get_ports USB_Data]
set_input_delay -clock usb_clk 2.0 [get_ports USB_Addr]

set_output_delay -clock usb_clk 1.0 [get_ports USB_Data]

# --------------------------------------------------
# Configuration pins
# --------------------------------------------------
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# --------------------------------------------------
# Bitstream generation
# --------------------------------------------------
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]

# --------------------------------------------------
# Remaining input delays
# --------------------------------------------------
set_input_delay -clock [get_clocks TRACECLOCK] -add_delay 1.000 [get_ports {TRACEDATA[3]}]
set_input_delay -clock [get_clocks TRACECLOCK] -add_delay 1.000 [get_ports {TRACEDATA[2]}]
set_input_delay -clock [get_clocks TRACECLOCK] -add_delay 1.000 [get_ports {TRACEDATA[1]}]
set_input_delay -clock [get_clocks TRACECLOCK] -add_delay 1.000 [get_ports {TRACEDATA[0]}]
# TODO: more?


# --------------------------------------------------
# Remaining output delays
# --------------------------------------------------
# TODO?


#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets USB_nRD]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets USB_nWE]

set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_usb_buf_BUFG]