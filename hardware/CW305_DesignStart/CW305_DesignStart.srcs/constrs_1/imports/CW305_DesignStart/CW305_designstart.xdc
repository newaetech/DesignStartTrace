set_property IOSTANDARD LVCMOS33 [get_ports *]

# Master clock frequencies derived from clock wizard
# Rename main clock for clarity:
create_clock -name cpu_clk -period 50 -waveform {0 25} [get_nets sys_clock]

# CW305 clock and reset
create_clock -period 50.000 -name pll_clk1 -waveform {0.000 20.000} [get_nets pll_clk1]
create_clock -period 50.000 -name tio_clkin -waveform {0.000 20.000} [get_nets tio_clkin]
create_clock -period 50.000 -name swclk -waveform {0.000 20.000} [get_nets swclk]
create_clock -period 10.000 -name usb_clk -waveform {0.000 5.000} [get_nets USB_clk]

create_generated_clock -name trigger_clk -master cpu_clk [get_pins U_trigger_clock/inst/mmcm_adv_inst/CLKOUT0]

set_clock_groups -asynchronous \
                 -group [get_clocks usb_clk] \
                 -group [get_clocks trigger_clk]

#set_clock_groups -asynchronous \
#                 -group [get_clocks usb_clk] \
#                 -group [get_clocks pll_clk1]
#
#set_clock_groups -asynchronous \
#                 -group [get_clocks trigger_clk] \
#                 -group [get_clocks pll_clk1]


# DUT input clock from PLL_CLK1:
set_property PACKAGE_PIN N13 [get_ports pll_clk1]
set_property PACKAGE_PIN N14 [get_ports tio_clkin]

# output clock to CW lite so it can use it for sampling: HS1 on 20-pin
set_property PACKAGE_PIN M16 [get_ports ext_clock]

# SW4 button on board:
set_property PACKAGE_PIN R1 [get_ports resetn_pin]

# JTAG:
set_property PULLUP true [get_ports nTRST]
set_property PULLDOWN true [get_ports TDI]



# virtual clock:
create_clock -period 100.000 -name slow_out_clk

create_clock -period 100 -name TRACECLK -waveform {0 50} [get_pins m3_for_arty_a7_i/Cortex_M3_0/inst/u_CORTEXM3INTEGRATION/u_cm3_tpiu/u_cm3_tpiu_trace_clk/trace_clk_reg/Q]


# UART has no timing requirements:
set_input_delay -clock [get_clocks slow_out_clk] -add_delay 0.500 [get_ports uart_rxd]
set_output_delay -clock [get_clocks slow_out_clk] -add_delay 0.500 [get_ports uart_txd]

# Reset
set_input_delay -clock [get_clocks cpu_clk] -add_delay 0.500 [get_ports resetn_pin*]

# *****************************************************************************

# UART and trigger on 20-pin connector:
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports uart_txd]
set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS33} [get_ports uart_rxd]
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS33} [get_ports trig_out]

# LEDs
set_property DRIVE 8 [get_ports led1]
set_property DRIVE 8 [get_ports led2]
set_property DRIVE 8 [get_ports led3]
set_property PACKAGE_PIN T2 [get_ports led1]
set_property PACKAGE_PIN T3 [get_ports led2]
set_property PACKAGE_PIN T4 [get_ports led3]

# DIP switches
set_property PACKAGE_PIN J16 [get_ports j16_sel]
set_property PACKAGE_PIN K16 [get_ports k16_sel]
set_property PACKAGE_PIN L14 [get_ports l14_sel]
set_property PACKAGE_PIN K15 [get_ports k15_sel]

# Debug on JP3:
# --------------------------------------------------
set_property PACKAGE_PIN B16 [get_ports swv]
set_property PACKAGE_PIN C13 [get_ports trig_out_dbg]
set_property PACKAGE_PIN D13 [get_ports m3_trig_out]

set_property PACKAGE_PIN C11 [get_ports SWOTDO]
set_property PACKAGE_PIN B12 [get_ports TDI]
set_property PACKAGE_PIN C14 [get_ports nTRST]
set_property PACKAGE_PIN A13 [get_ports swdio]
set_property PACKAGE_PIN B15 [get_ports swclk]

set_property PACKAGE_PIN B14 [get_ports {TRACEDATA[3]}]
set_property PACKAGE_PIN C12 [get_ports {TRACEDATA[2]}]
set_property PACKAGE_PIN A15 [get_ports {TRACEDATA[1]}]
set_property PACKAGE_PIN A14 [get_ports {TRACEDATA[0]}]
set_property PACKAGE_PIN C16 [get_ports TRCENA]
set_property PACKAGE_PIN A12 [get_ports TRACECLK_OUT]
#
#
####### USB Connector
set_property PACKAGE_PIN F5 [get_ports USB_clk]

set_property PACKAGE_PIN A7 [get_ports {USB_Data[0]}]
set_property PACKAGE_PIN B6 [get_ports {USB_Data[1]}]
set_property PACKAGE_PIN D3 [get_ports {USB_Data[2]}]
set_property PACKAGE_PIN E3 [get_ports {USB_Data[3]}]
set_property PACKAGE_PIN F3 [get_ports {USB_Data[4]}]
set_property PACKAGE_PIN B5 [get_ports {USB_Data[5]}]
set_property PACKAGE_PIN K1 [get_ports {USB_Data[6]}]
set_property PACKAGE_PIN K2 [get_ports {USB_Data[7]}]

set_property PACKAGE_PIN F4 [get_ports {USB_Addr[0]}]
set_property PACKAGE_PIN G5 [get_ports {USB_Addr[1]}]
set_property PACKAGE_PIN J1 [get_ports {USB_Addr[2]}]
set_property PACKAGE_PIN H1 [get_ports {USB_Addr[3]}]
set_property PACKAGE_PIN H2 [get_ports {USB_Addr[4]}]
set_property PACKAGE_PIN G1 [get_ports {USB_Addr[5]}]
set_property PACKAGE_PIN G2 [get_ports {USB_Addr[6]}]
set_property PACKAGE_PIN F2 [get_ports {USB_Addr[7]}]
set_property PACKAGE_PIN E1 [get_ports {USB_Addr[8]}]
set_property PACKAGE_PIN E2 [get_ports {USB_Addr[9]}]
set_property PACKAGE_PIN D1 [get_ports {USB_Addr[10]}]
set_property PACKAGE_PIN C1 [get_ports {USB_Addr[11]}]
set_property PACKAGE_PIN K3 [get_ports {USB_Addr[12]}]
set_property PACKAGE_PIN L2 [get_ports {USB_Addr[13]}]
set_property PACKAGE_PIN J3 [get_ports {USB_Addr[14]}]
set_property PACKAGE_PIN B2 [get_ports {USB_Addr[15]}]
set_property PACKAGE_PIN C7 [get_ports {USB_Addr[16]}]
set_property PACKAGE_PIN C6 [get_ports {USB_Addr[17]}]
set_property PACKAGE_PIN D6 [get_ports {USB_Addr[18]}]
set_property PACKAGE_PIN C4 [get_ports {USB_Addr[19]}]
set_property PACKAGE_PIN D5 [get_ports {USB_Addr[20]}]

set_property PACKAGE_PIN A4 [get_ports USB_nRD]
set_property PACKAGE_PIN C2 [get_ports USB_nWE]
set_property PACKAGE_PIN A3 [get_ports USB_nCS]
#set_property PACKAGE_PIN A2 [get_ports USB_nALE]

set_input_delay -clock usb_clk 2.0 [get_ports USB_nCS]
set_input_delay -clock usb_clk 2.0 [get_ports USB_nRD]
set_input_delay -clock usb_clk 2.0 [get_ports USB_nWE]
set_input_delay -clock usb_clk 2.0 [get_ports USB_Data]
set_input_delay -clock usb_clk 2.0 [get_ports USB_Addr]

# read data will be grabbed one cycle later so no need to constrain:
set_output_delay -clock usb_clk 0.0 [get_ports USB_Data]
set_false_path -to [get_ports USB_Data]


# TODO: sort out later, may lead to SWD debugging issues?
# (required because otherwise P+R fails with "Poor placement for routing between an IO pin and BUFG")
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets swclk_IBUF]
# --------------------------------------------------
# Configuration pins
# --------------------------------------------------
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# --------------------------------------------------
# Bitstream generation
# --------------------------------------------------
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]


# quasi-static control signals:
set_false_path -from [get_pins U_trace_top/U_reg_trace/O_reverse_tracedata*/C] -to [all_registers]
set_false_path -from [get_pins U_trace_top/U_reg_main/reg_timestamps_disable_reg/C] -to [all_registers]

set_false_path -from [get_pins U_trace_top/U_reg_trace/O_trace_mask*_reg*/C] -to [all_registers]
set_false_path -from [get_pins U_trace_top/U_reg_trace/O_trace_pattern*_reg*/C] -to [all_registers]
set_false_path -from [get_pins U_trace_top/U_reg_trace/O_pattern_trig_enable_reg*/C] -to [all_registers]
set_false_path -from [get_pins U_trace_top/U_reg_trace/O_soft_trig_enable_reg*/C] -to [all_registers]
set_false_path -from [get_pins U_trace_top/U_reg_trace/O_pattern_enable_reg*/C] -to [all_registers]
set_false_path -from [get_pins U_trace_top/U_fe_capture_trace/synchronized_reg/C] -to [get_pins U_trace_top/U_reg_trace/read_data_reg*/D]
set_false_path -from [get_pins U_trace_top/U_fe_capture_trace/synchronized_reg/C] -to [get_pins U_trace_top/U_reg_main/read_data_reg*/D]
set_false_path -from [get_pins U_trace_top/U_fe_capture_trace/O_matched_data_reg*/C] -to [get_pins U_trace_top/U_reg_trace/read_data_reg*/D]
set_false_path -from [get_pins U_trace_top/U_fe_capture_trace/O_trace_count*_reg*/C] -to [get_pins U_trace_top/U_reg_trace/read_data_reg*/D]

set_false_path -from [get_pins U_trace_top/U_reg_main/reg_counter_quick_start_reg/C] -to [all_registers]
set_false_path -from [get_pins U_trace_top/U_reg_main/reg_trigger_delay_reg*/C] -to [all_registers]
set_false_path -from [get_pins U_trace_top/U_reg_main/reg_trigger_width_reg*/C] -to [all_registers]
set_false_path -from [get_pins U_trace_top/U_reg_main/reg_num_triggers_reg*/C] -to [all_registers]
set_false_path -from [get_pins U_trace_top/U_reg_main/reg_trigger_enable_reg/C] -to [all_registers]
set_false_path -from [get_pins U_trace_top/U_reg_main/reg_capture_len_reg*/C] -to [all_registers]
set_false_path -from [get_pins U_trace_top/U_reg_main/reg_count_writes_reg/C] -to [all_registers]
set_false_path -from [get_pins U_trace_top/U_reg_main/reg_capture_while_trig_reg/C] -to [all_registers]
set_false_path -from [get_pins U_trace_top/U_reg_main/reg_max_timestamp_reg*/C] -to [all_registers]

set_false_path -from [get_pins U_trace_top/U_reg_trace/O_trace_width_reg*/C] -to [all_registers]
set_false_path -from [get_pins U_trace_top/U_reg_trace/O_capture_raw_reg/C] -to [all_registers]
set_false_path -from [get_pins U_trace_top/U_reg_trace/O_record_syncs_reg/C] -to [all_registers]

set_false_path -from [get_pins U_trace_top/U_reg_main/reg_reset_reg/C] -to [all_registers]

# CDC related exceptions:
set_false_path -to [get_pins U_trace_top/U_fifo/fifo_full_pipe_reg[0]/D]
set_false_path -to [get_pins U_trace_top/U_fifo/fifo_overflow_blocked_pipe_reg[0]/D]
set_false_path -to [get_pins U_trace_top/reg_arm_pipe_reg[0]/D]
set_false_path -to [get_pins U_trace_top/U_fe_capture_main/arm_pipe_reg[0]/D]
set_false_path -from [get_pins U_trace_top/*/*_cdc/dst_req_reg/C] -to [get_pins U_trace_top/*/*_cdc/ack_pipe_reg[0]/D]
set_false_path -from [get_pins U_trace_top/*/*_cdc/src_req_reg/C] -to [get_pins U_trace_top/*/*_cdc/req_pipe_reg[0]/D]



# --------------------------------------------------
# Remaining input delays
# --------------------------------------------------
set_input_delay -clock [get_clocks slow_out_clk] -add_delay 0.500 [get_ports TDI]
set_input_delay -clock [get_clocks slow_out_clk] -add_delay 0.500 [get_ports j16_sel]
set_input_delay -clock [get_clocks slow_out_clk] -add_delay 0.500 [get_ports k16_sel]
set_input_delay -clock [get_clocks slow_out_clk] -add_delay 0.500 [get_ports l14_sel]
set_input_delay -clock [get_clocks slow_out_clk] -add_delay 0.500 [get_ports k15_sel]
set_input_delay -clock [get_clocks slow_out_clk] -add_delay 0.500 [get_ports swdio]
set_input_delay -clock [get_clocks slow_out_clk] -add_delay 0.500 [get_ports nTRST]
# --------------------------------------------------
# Remaining output delays
# --------------------------------------------------
set_output_delay -clock [get_clocks slow_out_clk] -add_delay 0.500 [get_ports SWOTDO]
set_output_delay -clock [get_clocks slow_out_clk] -add_delay 0.500 [get_ports swdio]
set_output_delay -clock [get_clocks slow_out_clk] -add_delay 0.500 [get_ports swv]

set_output_delay -clock [get_clocks cpu_clk] -add_delay 3.000 [get_ports {TRACEDATA[3]}]
set_output_delay -clock [get_clocks cpu_clk] -add_delay 3.000 [get_ports {TRACEDATA[2]}]
set_output_delay -clock [get_clocks cpu_clk] -add_delay 3.000 [get_ports {TRACEDATA[1]}]
set_output_delay -clock [get_clocks cpu_clk] -add_delay 3.000 [get_ports {TRACEDATA[0]}]
set_output_delay -clock [get_clocks cpu_clk] -add_delay 3.000 [get_ports TRACECLK_OUT]

# These are quasi-static and don't need constraints, so let's just prevent 'no output delay' warnings:
set_output_delay -clock [get_clocks cpu_clk] 0.0 [get_ports led1]
set_output_delay -clock [get_clocks cpu_clk] 0.0 [get_ports led2]
set_output_delay -clock [get_clocks cpu_clk] 0.0 [get_ports led3]
set_output_delay -clock [get_clocks cpu_clk] 0.0 [get_ports ext_clock]
set_output_delay -clock [get_clocks cpu_clk] 0.0 [get_ports TRCENA]
set_output_delay -clock [get_clocks cpu_clk] 0.0 [get_ports trig_out]
set_output_delay -clock [get_clocks cpu_clk] 0.0 [get_ports m3_trig_out]
set_output_delay -clock [get_clocks cpu_clk] 0.0 [get_ports trig_out_dbg]
set_false_path -to [get_ports led1]
set_false_path -to [get_ports led2]
set_false_path -to [get_ports led3]
set_false_path -to [get_ports ext_clock]
set_false_path -to [get_ports TRCENA]
set_false_path -to [get_ports trig_out]
set_false_path -to [get_ports m3_trig_out]
set_false_path -to [get_ports trig_out_dbg]


#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets USB_nRD]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets USB_nWE]

set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_usb_buf_BUFG]
