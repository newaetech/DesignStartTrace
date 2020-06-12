# -----------------------------------------------------------------------------
#  The confidential and proprietary information contained in this file may
#  only be used by a person authorised under and to the extent permitted
#  by a subsisting licensing agreement from ARM limited.
#
#             (C) COPYRIGHT 2018 ARM limited.
#                 ALL RIGHTS RESERVED
#
#  This entire notice must be reproduced on all copies of this file
#  and copies of this file may only be made by a person if such person is
#  permitted to do so under the terms of a subsisting license agreement
#  from ARM limited.
#
#       SVN Information
#
#       Checked In          : $Date$
#
#       Revision            : $Revision$
#
#       Release Information : Cortex-M3 DesignStart-r0p1-00rel0
#
# -----------------------------------------------------------------------------
#  Project : Cortex-M3 Arty A7 Example design with V2C-DAPLink adaptor board
#
#  Purpose : Constraints for M3 on Arty A7 board
#            IO standards and pull-ups
#            Timing constraints for IO.  
#            (Base clock frequencies defined by board file)
#
# -----------------------------------------------------------------------------

# --------------------------------------------------
# JTAG ports
# --------------------------------------------------

# JTAG connected to PMOD connector JC (nearest to device)
set_property PULLUP true [get_ports nTRST]
set_property PULLDOWN true [get_ports TDI]

set_property IOSTANDARD LVCMOS33 [get_ports nTRST]
set_property IOSTANDARD LVCMOS33 [get_ports TDI]
set_property IOSTANDARD LVCMOS33 [get_ports TDO[0]]

# --------------------------------------------------
# UART
# --------------------------------------------------
set_property IOSTANDARD LVCMOS33 [get_ports usb_uart_*]

# --------------------------------------------------
# DAPLink adaptor board
# --------------------------------------------------
set_property IOSTANDARD LVCMOS33 [get_ports DAPLink*]

# Shield pin 34, (DAPLink[8]), is used to detect of the DAPLink board is fitted, active low
# To allow the base board to correctly detect when the adaptor board is not fitted, pull this pin high
set_property PULLUP true [get_ports {DAPLink_tri_o[8]}]

# Shield pin 39, (DAPLink[13]), is used as an auxillary reset, active low
# To allow the base board to work when the DAPLink adaptor board is not fitted, pull this pin high
set_property PULLUP true [get_ports {DAPLink_tri_o[13]}]

# Shield pin 40, (DAPLink[14]), is the Serial Wire data, which can be tristate.  Needs a pull-up
set_property PULLUP true [get_ports {DAPLink_tri_o[14]}]

# Default drive strength is 12mA.  Set higher for QSPI clock.  Signal slugged due to 200R series resistors
# No great effect as RC network is frequency limiting signal
set_property DRIVE 16   [get_ports {DAPLink_tri_o[9]}]
set_property SLEW  FAST [get_ports {DAPLink_tri_o[9]}]

# Do same for DAPLink SPI clock
set_property DRIVE 16   [get_ports {DAPLink_tri_o[3]}]
set_property SLEW  FAST [get_ports {DAPLink_tri_o[3]}]

# As QSPI outputs are muxed together, remove the IOBUF property from each IO flop.
# This is because IOs go via a mux, so the flop cannot be placed in the IOB
# This removes critical warnings.  No effect on the design as the property was being ignored
set_property IOB FALSE [get_cells -hierarchical -regex .*daplink.*quad.*SCK_O_NE_4_FDRE_INST]


# *****************************************************************************
# Timing
# *****************************************************************************

# Overall timing derived from clock wizard

# --------------------------------------------------
# Clocks
# --------------------------------------------------

# Rename main clock for clarity
create_generated_clock -name cpu_clk  [get_pins {m3_for_arty_a7_i/Clocks_and_Resets/clk_wiz_0/inst/mmcm_adv_inst/CLKOUT0} ]
create_generated_clock -name qspi_clk [get_pins {m3_for_arty_a7_i/Clocks_and_Resets/clk_wiz_0/inst/mmcm_adv_inst/CLKOUT1} ]


# --------------------------------------------------
# Input clocks
# --------------------------------------------------
# Support upto 20MHz SWD
set swclk_period 50.0
create_clock -period $swclk_period -name SWCLK [get_ports {DAPLink_tri_o[15]}]

# --------------------------------------------------
# Output clocks
# --------------------------------------------------

# Base QSPI
# Need full specification as quad_spi instance in DAPLink has same instance name
create_generated_clock -name base_qspi_clk -source [get_pins -hierarchical -filter {NAME =~ m3_for_arty_a7_i/axi_quad_spi_0/sck_o}] -divide_by 1 [get_ports qspi_flash_sck*]

# DAPLink QSPI clock is on shield pin 9.
create_generated_clock -name dap_qspi_clk  -source [get_pins -hierarchical -filter {NAME =~ *axi_xip_quad_spi_0/sck_o}] -divide_by 1 [get_ports {DAPLink_tri_o[9]}]

# DAPLink SPI clock is on shield pin 3.
create_generated_clock -name dap_spi_clk   -source [get_pins -hierarchical -filter {NAME =~ *axi_single_spi_0/sck_o}]   -divide_by 1 [get_ports {DAPLink_tri_o[3]}]

# --------------------------------------------------
# Virtual clocks
# --------------------------------------------------
create_clock -name slow_out_clk -period 100.0

# --------------------------------------------------
# Clock groups
# --------------------------------------------------


# Set asynchronous clocks
# This comamnd overrides all other timing settings, including the desired set_max_delay.  See forum post
# https://forums.xilinx.com/t5/Timing-Analysis/CDC-Constrains-set-clock-groups-precedes-set-max-delay/td-p/589843
# Therefore better to do set_false_paths where necessary, and set_max_delay where desired.
#set_clock_groups -name async_group -asynchronous -group {cpu_clk} \
#                                                 -group {qspi_clk base_qspi_clk dap_qspi_clk dap_spi_clk} \
#                                                 -group {SWCLK} \
#                                                 -group {slow_out_clk}

# REVISIT - replace with max_delay constraint
#set_false_path -from [get_clocks cpu_clk] -to [get_clocks -include_generated_clocks qspi_clk]
#set_false_path -from [get_clocks -include_generated_clocks qspi_clk] -to [get_clocks cpu_clk]

set_max_delay -from [get_clocks cpu_clk] -to [get_clocks -include_generated_clocks qspi_clk] -datapath_only 16.0
set_max_delay -from [get_clocks -include_generated_clocks qspi_clk] -to [get_clocks cpu_clk] -datapath_only 16.0
                                                 
# --------------------------------------------------
# Internal timings
# --------------------------------------------------
# The DAP is asynchronous to the CPU, (SWCLK and cpu_clk).
# However need to ensure that all signals pass across the relevant CDC structures quickly enough
# This should be within 2 cycles of the fastest clock, (cpu_clk).  This is currently 50MHz, ~20ns.
# We only wish to constrain the acutal datapath, we do not need to consider clock skew and jitter
# as these are asychronous clocks
# Set to be less that cpu_clk period for guaranteed transistion times.
set_max_delay -from [get_clocks cpu_clk] -to [get_clocks SWCLK]   -datapath_only 16.0
set_max_delay -from [get_clocks SWCLK]   -to [get_clocks cpu_clk] -datapath_only 16.0

# *****************************************************************************
# IO timings
# *****************************************************************************

# GPIO signal selecting between the two QSPI devices is static, remove timing from it to the outputs
# Were not able to correctly specify the launch flop as -from, so use the resultant net with -through
set_false_path -through [get_nets -hierarchical *qspi_sel] -to [get_clocks dap_qspi_clk]


# --------------------------------------------------
# DAPLink QSPI
# --------------------------------------------------

# The signals to and from the DAPLink QSPI have 200R in series.  These slow the outputs
# Data is written out on the falling edge of dap_qspi_clk, read by QSPI on rising edge (output delay).
# Data is read out of QSPI on the falling edge, and read by the FPGA on the rising edge (input delay).
# Limiting factor is QSPI Tco of 8ns.
# Add extra 0.5ns to all times due to 200R and board connectors.
# QSPI data in, setup 1.5ns, hold of 2ns.
set dap_qspi_od_Tsu 2.0
set dap_qspi_od_Thd -2.5
set dap_qspi_id_Tco 8.5
set dap_qspi_id_Tho 2.0

set dap_qspi_ports [get_ports {{DAPLink_tri_o[4]} {DAPLink_tri_o[5]} {DAPLink_tri_o[6]} {DAPLink_tri_o[7]} {DAPLink_tri_o[10]}}]

# QSPI Q[3:0] & CS
set_input_delay  -clock [get_clocks dap_qspi_clk] -max -add_delay $dap_qspi_id_Tco $dap_qspi_ports
set_input_delay  -clock [get_clocks dap_qspi_clk] -min -add_delay $dap_qspi_id_Tho $dap_qspi_ports

set_output_delay -clock [get_clocks dap_qspi_clk] -max -add_delay $dap_qspi_od_Tsu $dap_qspi_ports
set_output_delay -clock [get_clocks dap_qspi_clk] -min -add_delay $dap_qspi_od_Thd $dap_qspi_ports

# --------------------------------------------------
# DAPLink SPI
# --------------------------------------------------

# The signals to and from the DAPLink SPI have 200R in series.  These slow the outputs
# Data is written out on the falling edge of dap_spi_clk, read by SPI on rising edge (output delay).
# Data is read out of SPI on the falling edge, and read by the FPGA on the rising edge (input delay).
# No values available as these will depend on the specific SDCard used.
# Use the same values as for the QSPI.
set dap_spi_od_Tsu 2.0
set dap_spi_od_Thd -2.5
set dap_spi_id_Tco 8.5
set dap_spi_id_Tho 2.0

# SPI CS, MISO & MOSI

# CS
set_output_delay -clock [get_clocks dap_spi_clk] -max -add_delay $dap_spi_od_Tsu [get_ports {DAPLink_tri_o[0]}]
set_output_delay -clock [get_clocks dap_spi_clk] -min -add_delay $dap_spi_od_Thd [get_ports {DAPLink_tri_o[0]}]

# MISO
set_input_delay  -clock [get_clocks dap_spi_clk] -max -add_delay $dap_spi_id_Tco [get_ports {DAPLink_tri_o[1]}]
set_input_delay  -clock [get_clocks dap_spi_clk] -min -add_delay $dap_spi_id_Tho [get_ports {DAPLink_tri_o[1]}]

# MOSI
set_output_delay -clock [get_clocks dap_spi_clk] -max -add_delay $dap_spi_od_Tsu [get_ports {DAPLink_tri_o[2]}]
set_output_delay -clock [get_clocks dap_spi_clk] -min -add_delay $dap_spi_od_Thd [get_ports {DAPLink_tri_o[2]}]


# --------------------------------------------------
# Base QSPI
# --------------------------------------------------

# Data is written out on the falling edge of dap_qspi_clk, read by QSPI on rising edge (output delay).
# Data is read out of QSPI on the falling edge, and read by the FPGA on the rising edge (input delay).
# Limiting factor is base QSPI Tco of 7ns.  Add extra 0.5ns for the board

set qspi_od_Tsu 2.5
set qspi_od_Thd -3.5
set qspi_id_Tco 7.5
set qspi_id_Tho 1.5

set_input_delay  -clock [get_clocks base_qspi_clk] -max -add_delay $qspi_id_Tco [get_ports qspi_flash_io?_io]
set_input_delay  -clock [get_clocks base_qspi_clk] -min -add_delay $qspi_id_Tho [get_ports qspi_flash_io?_io]
set_input_delay  -clock [get_clocks base_qspi_clk] -max -add_delay $qspi_id_Tco [get_ports qspi_flash_ss*]
set_input_delay  -clock [get_clocks base_qspi_clk] -min -add_delay $qspi_id_Tho [get_ports qspi_flash_ss*]

set_output_delay -clock [get_clocks base_qspi_clk] -max -add_delay $qspi_od_Tsu [get_ports qspi_flash_io?_io]
set_output_delay -clock [get_clocks base_qspi_clk] -min -add_delay $qspi_od_Thd [get_ports qspi_flash_io?_io]
set_output_delay -clock [get_clocks base_qspi_clk] -max -add_delay $qspi_od_Tsu [get_ports qspi_flash_ss*]
set_output_delay -clock [get_clocks base_qspi_clk] -min -add_delay $qspi_od_Thd [get_ports qspi_flash_ss*]


# --------------------------------------------------
# Debug signals
# --------------------------------------------------

# Large input Tsu, as clock insertion delay is a lot shorter than datapath input delay.
set sw_in_tsu 8
set sw_in_max_delay [expr {$swclk_period - $sw_in_tsu}]
set sw_in_th  -1
set sw_out_tsu 5
set sw_out_th  -5

set debug_od 5.0
set debug_id 5.0

# SWDIO
# SWDIO is driven at both ends by posedge clk.  The clock is sourced from the DAPLink board  
# For input signals it could be either side of rising edge
# For output signals need to ensure the whole round trip is less than the period
set_input_delay  -clock [get_clocks SWCLK] -add_delay -max $sw_in_max_delay [get_ports {DAPLink_tri_o[14]}]
set_input_delay  -clock [get_clocks SWCLK] -add_delay -min $sw_in_th        [get_ports {DAPLink_tri_o[14]}]
set_output_delay -clock [get_clocks SWCLK] -add_delay -max $sw_out_tsu      [get_ports {DAPLink_tri_o[14]}]
set_output_delay -clock [get_clocks SWCLK] -add_delay -min $sw_out_th       [get_ports {DAPLink_tri_o[14]}]

# JTAG
# Note, these are optional ports and may be removed from the build
set_input_delay  -clock [get_clocks SWCLK] -add_delay $debug_id [get_ports TDI]
set_input_delay  -clock [get_clocks SWCLK] -add_delay $debug_id [get_ports nTRST]
set_output_delay -clock [get_clocks SWCLK] -add_delay $debug_od [get_ports TDO*]

# --------------------------------------------------
# Untimed ports
# --------------------------------------------------
# Following ports have no timing requirement to any output or on-board clock.
# Set to small delays to give timing closure
set untimed_od 0.5
set untimed_id 0.5

# Use a virtual slow clock for the untimed IO
# UART
set_input_delay  -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports usb_uart_rxd]
set_input_delay  -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports {DAPLink_tri_o[12]}]
set_output_delay -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports usb_uart_txd]
set_output_delay -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports {DAPLink_tri_o[11]}]

# Switch inputs
set_input_delay  -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports dip_switches*]
set_input_delay  -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports push_buttons*]

# Reset
set_input_delay  -clock [get_clocks cpu_clk] -add_delay $untimed_id [get_ports reset*]
# Prevent reset from timing from cpu_clk to qspi_clk
set_false_path -from [get_ports reset*] -to [get_clocks qspi_clk]

# DAPLink_fitted
set_input_delay  -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports {DAPLink_tri_o[8]}]
# nSRST
set_input_delay  -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports {DAPLink_tri_o[13]}]

# Output LEDs
set_input_delay  -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports led_4bits*]
set_input_delay  -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports rgb_led*]
set_output_delay -clock [get_clocks slow_out_clk] -add_delay $untimed_od [get_ports led_4bits*]
set_output_delay -clock [get_clocks slow_out_clk] -add_delay $untimed_od [get_ports rgb_led*]

