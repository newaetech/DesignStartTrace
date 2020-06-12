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
#  Purpose : Constraints for M3 on Arty A7 board - Implementation phase only
#
# -----------------------------------------------------------------------------

# --------------------------------------------------
# JTAG ports
# --------------------------------------------------

# JTAG connected to PMOD connector JC (nearest to device)
# Pin-out is detailed below
# JC1_P.  JC[1]
set_property PACKAGE_PIN U12 [get_ports TDO[0]]
# JC1_N.  JC[2]
set_property PACKAGE_PIN V12 [get_ports TDI]
# JC2_P.  JC[3]
set_property PACKAGE_PIN V10 [get_ports nTRST]
# Note TCK is shared with SWCLK.  Therefore to drive JTAG, besides the pins above
# the user must also connect to shield pin IO41 = connector IOH pin 16.

# --------------------------------------------------
# UART
# Although the UART is defined as a board interface
# and the DAPLink port is the correct type
# Vivado will not recognise the connection
# So need to specify the actual UART pads and IO standards
# --------------------------------------------------
#  <pin index="94" name ="usb_uart_rxd" iostandard="LVCMOS33" loc="A9"/>
#  <pin index="95" name ="usb_uart_txd" iostandard="LVCMOS33" loc="D10"/>

set_property PACKAGE_PIN A9 [get_ports usb_uart_rxd]
set_property PACKAGE_PIN D10 [get_ports usb_uart_txd]

# --------------------------------------------------
# Define pins on Shield [41:26]
# Used for DAPLink adaptor board
# --------------------------------------------------

# From Digilent board file, part0_pins.xml
#  <pin index="74" name ="shield_dp26_dp41_tri_i_0" iostandard="LVCMOS33" loc="U11"/>
#  <pin index="75" name ="shield_dp26_dp41_tri_i_1" iostandard="LVCMOS33" loc="V16"/>
#  <pin index="76" name ="shield_dp26_dp41_tri_i_2" iostandard="LVCMOS33" loc="M13"/>
#  <pin index="77" name ="shield_dp26_dp41_tri_i_3" iostandard="LVCMOS33" loc="R10"/>
#  <pin index="78" name ="shield_dp26_dp41_tri_i_4" iostandard="LVCMOS33" loc="R11"/>
#  <pin index="79" name ="shield_dp26_dp41_tri_i_5" iostandard="LVCMOS33" loc="R13"/>
#  <pin index="80" name ="shield_dp26_dp41_tri_i_6" iostandard="LVCMOS33" loc="R15"/>
#  <pin index="81" name ="shield_dp26_dp41_tri_i_7" iostandard="LVCMOS33" loc="P15"/>
#  <pin index="82" name ="shield_dp26_dp41_tri_i_8" iostandard="LVCMOS33" loc="R16"/>
#  <pin index="83" name ="shield_dp26_dp41_tri_i_9" iostandard="LVCMOS33" loc="N16"/>
#  <pin index="84" name ="shield_dp26_dp41_tri_i_10" iostandard="LVCMOS33" loc="N14"/>
#  <pin index="85" name ="shield_dp26_dp41_tri_i_11" iostandard="LVCMOS33" loc="U17"/>
#  <pin index="86" name ="shield_dp26_dp41_tri_i_12" iostandard="LVCMOS33" loc="T18"/>
#  <pin index="87" name ="shield_dp26_dp41_tri_i_13" iostandard="LVCMOS33" loc="R18"/>
#  <pin index="88" name ="shield_dp26_dp41_tri_i_14" iostandard="LVCMOS33" loc="P18"/>
#  <pin index="89" name ="shield_dp26_dp41_tri_i_15" iostandard="LVCMOS33" loc="N17"/>

set_property PACKAGE_PIN U11 [get_ports {DAPLink_tri_o[0]}]
set_property PACKAGE_PIN V16 [get_ports {DAPLink_tri_o[1]}]
set_property PACKAGE_PIN M13 [get_ports {DAPLink_tri_o[2]}]
set_property PACKAGE_PIN R10 [get_ports {DAPLink_tri_o[3]}]
set_property PACKAGE_PIN R11 [get_ports {DAPLink_tri_o[4]}]
set_property PACKAGE_PIN R13 [get_ports {DAPLink_tri_o[5]}]
set_property PACKAGE_PIN R15 [get_ports {DAPLink_tri_o[6]}]
set_property PACKAGE_PIN P15 [get_ports {DAPLink_tri_o[7]}]
set_property PACKAGE_PIN R16 [get_ports {DAPLink_tri_o[8]}]
set_property PACKAGE_PIN N16 [get_ports {DAPLink_tri_o[9]}]
set_property PACKAGE_PIN N14 [get_ports {DAPLink_tri_o[10]}]
set_property PACKAGE_PIN U17 [get_ports {DAPLink_tri_o[11]}]
set_property PACKAGE_PIN T18 [get_ports {DAPLink_tri_o[12]}]
set_property PACKAGE_PIN R18 [get_ports {DAPLink_tri_o[13]}]
set_property PACKAGE_PIN P18 [get_ports {DAPLink_tri_o[14]}]
set_property PACKAGE_PIN N17 [get_ports {DAPLink_tri_o[15]}]


# Shield pin 41, (DAPLink[15]), is used for CS_CLK, (Serial Wire clock)
# As this is not a dedicated clock input pin, Vivado needs to set to allow use of this input as a clock
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {DAPLink_tri_o_IBUF[15]}]


# --------------------------------------------------
# Place output pin muxes near pins
# --------------------------------------------------
# REVISIT - remove as test for SWD
#create_pblock pblock_out_mux
#resize_pblock pblock_out_mux -add SLICE_X0Y0:SLICE_X1Y49
#add_cells_to_pblock pblock_out_mux [get_cells [list {m1_for_arty_a7_i/daplink_if_0/DAPLink_to_Arty_shield_0/shield_41_to_26[35]_INST_0}]]
#add_cells_to_pblock pblock_out_mux [get_cells [list {m1_for_arty_a7_i/daplink_if_0/DAPLink_to_Arty_shield_0/shield_41_to_26[36]_INST_0}]]
#add_cells_to_pblock pblock_out_mux [get_cells [list {m1_for_arty_a7_i/daplink_if_0/DAPLink_to_Arty_shield_0/shield_41_to_26_IOBUF[30]_inst_*}]]
#add_cells_to_pblock pblock_out_mux [get_cells [list {m1_for_arty_a7_i/daplink_if_0/DAPLink_to_Arty_shield_0/shield_41_to_26_IOBUF[31]_inst_*}]]
#add_cells_to_pblock pblock_out_mux [get_cells [list {m1_for_arty_a7_i/daplink_if_0/DAPLink_to_Arty_shield_0/shield_41_to_26_IOBUF[32]_inst_*}]]
#add_cells_to_pblock pblock_out_mux [get_cells [list {m1_for_arty_a7_i/daplink_if_0/DAPLink_to_Arty_shield_0/shield_41_to_26_IOBUF[33]_inst_*}]]


# --------------------------------------------------
# Configuration pins
# --------------------------------------------------
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]


# --------------------------------------------------
# Bitstream generation
# --------------------------------------------------
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]

