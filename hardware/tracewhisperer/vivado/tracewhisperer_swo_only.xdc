set_property IOSTANDARD LVCMOS33 [get_ports *]

create_clock -period 10.400 -name usb_clk -waveform {0.000 5.200} [get_nets USB_clk]


# reset from USB_SPARE0:
set_property PACKAGE_PIN K3 [get_ports reset]


# Master clock frequencies derived from clock wizard

# virtual clock:
create_clock -period 100.000 -name slow_out_clk


# Reset
set_input_delay -clock [get_clocks usb_clk] -add_delay 0.500 [get_ports reset*]

# *****************************************************************************

# LEDs
set_property DRIVE 8 [get_ports led2]
set_property DRIVE 8 [get_ports led3]
set_property PACKAGE_PIN D2 [get_ports led2]
set_property PACKAGE_PIN A2 [get_ports led3]

# this one is actually on 20-pin connector: PD pin
set_property PACKAGE_PIN M3 [get_ports led1]

# front connector:
# userio_d[3:0]:
set_property PACKAGE_PIN P13 [get_ports {userio_d[0]}]
set_property PACKAGE_PIN M12 [get_ports {userio_d[1]}]
set_property PACKAGE_PIN P12 [get_ports {userio_d[2]}]
set_property PACKAGE_PIN N11 [get_ports {userio_d[3]}]

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

set_property PACKAGE_PIN M13 [get_ports mcx_trig]

# No spec for these, seems sensible:
set_input_delay -clock usb_clk 2.0 [get_ports USB_nCS]
set_input_delay -clock usb_clk 2.0 [get_ports USB_nRD]
set_input_delay -clock usb_clk 2.0 [get_ports USB_nWE]
set_input_delay -clock usb_clk 2.0 [get_ports USB_Data]
set_input_delay -clock usb_clk 2.0 [get_ports USB_Addr]
set_input_delay -clock usb_clk 2.0 [get_ports USB_SPARE1]

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

set_input_delay -clock [get_clocks usb_clk] -add_delay 1.000 [get_ports target_trig_in]

# Unconstrain the userio_d inputs:
set_input_delay -clock [get_clocks usb_clk] -add_delay 0.000 [get_ports {userio_d[0]}]
set_input_delay -clock [get_clocks usb_clk] -add_delay 0.000 [get_ports {userio_d[1]}]
set_input_delay -clock [get_clocks usb_clk] -add_delay 0.000 [get_ports {userio_d[2]}]
set_input_delay -clock [get_clocks usb_clk] -add_delay 0.000 [get_ports {userio_d[3]}]
set_false_path -from [get_ports {userio_d[0]}]
set_false_path -from [get_ports {userio_d[1]}]
set_false_path -from [get_ports {userio_d[2]}]
set_false_path -from [get_ports {userio_d[3]}]


# quasi-static control signals:
set_false_path -from [get_pins U_trace_top/U_reg_trace/O_swo_bitrate_div_reg*/C] -to [all_registers]
set_false_path -from [get_pins U_trace_top/U_reg_trace/O_uart_stop_bits_reg*/C] -to [all_registers]
set_false_path -from [get_pins U_trace_top/U_reg_trace/O_uart_data_bits_reg*/C] -to [all_registers]
set_false_path -from [get_pins U_trace_top/U_reg_trace/O_reverse_tracedata*/C] -to [all_registers]
set_false_path -from [get_pins U_trace_top/U_reg_main/reg_board_rev_reg*/C] -to [all_registers]

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
set_false_path -from [get_pins U_trace_top/U_reg_trace/O_trace_width_reg*/C] -to [all_registers]
set_false_path -from [get_pins U_trace_top/U_reg_trace/O_capture_raw_reg/C] -to [all_registers]
set_false_path -from [get_pins U_trace_top/U_reg_trace/O_record_syncs_reg/C] -to [all_registers]

set_false_path -from [get_port reset] -to [all_registers]
set_false_path -from [get_port target_trig_in] -to [all_registers]

# CDC related exceptions:
set_false_path -to [get_pins U_trace_top/U_fifo/fifo_full_pipe_reg[0]/D]
set_false_path -to [get_pins U_trace_top/U_fifo/fifo_overflow_blocked_pipe_reg[0]/D]
set_false_path -to [get_pins U_trace_top/reg_arm_pipe_reg[0]/D]
set_false_path -to [get_pins U_trace_top/U_fe_capture_main/arm_pipe_reg[0]/D]
set_false_path -from [get_pins U_trace_top/*/*_cdc/dst_req_reg/C] -to [get_pins U_trace_top/*/*_cdc/ack_pipe_reg[0]/D]
set_false_path -from [get_pins U_trace_top/*/*_cdc/src_req_reg/C] -to [get_pins U_trace_top/*/*_cdc/req_pipe_reg[0]/D]

# should we?
set_false_path -from [get_pins U_trace_top/U_fe_capture_trace/U_swo_cdc/transfer_data_reg*/C] -to [get_pins U_trace_top/U_fe_capture_trace/U_swo_cdc/dst_data_reg_reg*/D]


# --------------------------------------------------
# Remaining output delays
# --------------------------------------------------
# These are quasi-static and don't need constraints, so let's just prevent 'no output delay' warnings:
set_output_delay -clock [get_clocks usb_clk] 0.0 [get_ports led1]
set_output_delay -clock [get_clocks usb_clk] 0.0 [get_ports led2]
set_output_delay -clock [get_clocks usb_clk] 0.0 [get_ports led3]
set_output_delay -clock [get_clocks usb_clk] 0.0 [get_ports mcx_trig]
set_output_delay -clock [get_clocks usb_clk] 0.0 [get_ports trig_out]
set_output_delay -clock [get_clocks usb_clk] 0.0 [get_ports userio_d[0]]
set_output_delay -clock [get_clocks usb_clk] 0.0 [get_ports userio_d[1]]
set_output_delay -clock [get_clocks usb_clk] 0.0 [get_ports userio_d[2]]
set_output_delay -clock [get_clocks usb_clk] 0.0 [get_ports userio_d[3]]

set_false_path -to [get_ports led1]
set_false_path -to [get_ports led2]
set_false_path -to [get_ports led3]
set_false_path -to [get_ports mcx_trig]
set_false_path -to [get_ports trig_out]
set_false_path -to [get_ports userio_d[0]]
set_false_path -to [get_ports userio_d[1]]
set_false_path -to [get_ports userio_d[2]]
set_false_path -to [get_ports userio_d[3]]

# read data will be grabbed one cycle later so no need to constrain:
set_output_delay -clock usb_clk 0.0 [get_ports USB_Data]
set_false_path -to [get_ports USB_Data]


set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_usb_buf_BUFG]
