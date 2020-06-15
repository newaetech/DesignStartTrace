set_property IOSTANDARD LVCMOS33 [get_ports *]

# CW305 clock and reset
create_clock -period 20.000 -name pll_clk1 -waveform {0.000 10.000} [get_nets pll_clk1]
create_clock -period 20.000 -name tio_clkin -waveform {0.000 10.000} [get_nets tio_clkin]
create_clock -period 20.000 -name swclk -waveform {0.000 10.000} [get_nets swclk]


# DUT input clock from PLL_CLK1:
set_property PACKAGE_PIN N13 [get_ports pll_clk1]
set_property PACKAGE_PIN N14 [get_ports tio_clkin]

# output clock to CW lite so it can use it for sampling: HS1 on 20-pin
set_property PACKAGE_PIN M16 [get_ports ext_clock]

# SW4 button on board:
set_property PACKAGE_PIN R1 [get_ports reset];

# JTAG:
set_property PULLUP true [get_ports nTRST]
set_property PULLDOWN true [get_ports TDI]


# Master clock frequencies derived from clock wizard

# Rename main clock for clarity:
create_generated_clock -name cpu_clk  [get_pins {m3_for_arty_a7_i/Clocks_and_Resets/clk_wiz_0/inst/mmcm_adv_inst/CLKOUT0} ]
# virtual clock:
create_clock -period 100.000 -name slow_out_clk

# UART has no timing requirements:
set untimed_od 0.5
set untimed_id 0.5
set_input_delay  -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports uart_rxd]
set_output_delay -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports uart_txd]

# Reset
set_input_delay  -clock [get_clocks cpu_clk] -add_delay $untimed_id [get_ports reset*]

# *****************************************************************************

# UART and trigger on 20-pin connector:
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { uart_txd}]; # IO1
set_property -dict { PACKAGE_PIN R16   IOSTANDARD LVCMOS33 } [get_ports { uart_rxd}]; # IO2
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports { trig_out }]; # IO4

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
set_property PACKAGE_PIN A12 [get_ports swv]
#set_property PACKAGE_PIN A14 [get_ports ]
#set_property PACKAGE_PIN A15 [get_ports ]
#set_property PACKAGE_PIN C12 [get_ports ]
#set_property PACKAGE_PIN B14 [get_ports ]
#set_property PACKAGE_PIN B16 [get_ports ]
#set_property PACKAGE_PIN C13 [get_ports ]

set_property PACKAGE_PIN C11 [get_ports { SWOTDO }]
set_property PACKAGE_PIN B12 [get_ports { TDI }]
set_property PACKAGE_PIN C14 [get_ports { nTRST }]
set_property PACKAGE_PIN A13 [get_ports swdio]
set_property PACKAGE_PIN B15 [get_ports swclk]

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

# --------------------------------------------------
# Remaining input delays
# --------------------------------------------------
set_input_delay  -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports TDI]
set_input_delay  -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports j16_sel]
set_input_delay  -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports k16_sel]
set_input_delay  -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports l14_sel]
set_input_delay  -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports k15_sel]
set_input_delay  -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports swdio]
set_input_delay  -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports nTRST]
# --------------------------------------------------
# Remaining output delays
# --------------------------------------------------
set_output_delay  -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports SWOTDO]
set_output_delay  -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports led1]
set_output_delay  -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports led2]
set_output_delay  -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports led3]
set_output_delay  -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports swdio]
set_output_delay  -clock [get_clocks slow_out_clk] -add_delay $untimed_id [get_ports trig_out]


