
################################################################
# This is a generated script based on design: m3_for_arty_a7
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2019.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_msg_id "BD_TCL-109" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source m3_for_arty_a7_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7a100tftg256-2
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name m3_for_arty_a7

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: Clocks_and_Resets
proc create_hier_cell_Clocks_and_Resets { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_Clocks_and_Resets() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir O -type clk clk_cpu
  create_bd_pin -dir O -from 0 -to 0 dbgresetn
  create_bd_pin -dir O -from 0 -to 0 -type rst interconnect_aresetn
  create_bd_pin -dir O locked
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn
  create_bd_pin -dir I -type clk sys_clock
  create_bd_pin -dir I -type rst sys_reset_n
  create_bd_pin -dir O -from 0 -to 0 sysresetn
  create_bd_pin -dir I sysresetreq

  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0 ]
  set_property -dict [ list \
   CONFIG.CLKIN1_JITTER_PS {833.33} \
   CONFIG.CLKIN2_JITTER_PS {833.33} \
   CONFIG.CLKOUT1_DRIVES {BUFGCE} \
   CONFIG.CLKOUT1_JITTER {130.958} \
   CONFIG.CLKOUT1_PHASE_ERROR {98.575} \
   CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100} \
   CONFIG.CLKOUT2_DRIVES {BUFGCE} \
   CONFIG.CLKOUT2_JITTER {151.636} \
   CONFIG.CLKOUT2_PHASE_ERROR {98.575} \
   CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {100.000} \
   CONFIG.CLKOUT2_USED {false} \
   CONFIG.CLKOUT3_DRIVES {BUFGCE} \
   CONFIG.CLKOUT4_DRIVES {BUFGCE} \
   CONFIG.CLKOUT5_DRIVES {BUFGCE} \
   CONFIG.CLKOUT6_DRIVES {BUFGCE} \
   CONFIG.CLKOUT7_DRIVES {BUFGCE} \
   CONFIG.CLK_IN1_BOARD_INTERFACE {sys_clock} \
   CONFIG.CLK_IN2_BOARD_INTERFACE {Custom} \
   CONFIG.FEEDBACK_SOURCE {FDBK_AUTO} \
   CONFIG.MMCM_CLKFBOUT_MULT_F {10.000} \
   CONFIG.MMCM_CLKIN1_PERIOD {10.000} \
   CONFIG.MMCM_CLKIN2_PERIOD {10.000} \
   CONFIG.MMCM_CLKOUT0_DIVIDE_F {10.000} \
   CONFIG.MMCM_CLKOUT1_DIVIDE {1} \
   CONFIG.MMCM_DIVCLK_DIVIDE {1} \
   CONFIG.NUM_OUT_CLKS {1} \
   CONFIG.RESET_BOARD_INTERFACE {Custom} \
   CONFIG.SECONDARY_SOURCE {Single_ended_clock_capable_pin} \
   CONFIG.USE_BOARD_FLOW {true} \
   CONFIG.USE_INCLK_SWITCHOVER {false} \
   CONFIG.USE_RESET {false} \
   CONFIG.USE_SAFE_CLOCK_STARTUP {true} \
 ] $clk_wiz_0

  # Create instance: i_inv_dbgresetn, and set properties
  set i_inv_dbgresetn [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 i_inv_dbgresetn ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
 ] $i_inv_dbgresetn

  # Create instance: i_inv_sysresetn1, and set properties
  set i_inv_sysresetn1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 i_inv_sysresetn1 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
 ] $i_inv_sysresetn1

  # Create instance: proc_sys_reset_base, and set properties
  set proc_sys_reset_base [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_base ]
  set_property -dict [ list \
   CONFIG.C_AUX_RST_WIDTH {1} \
   CONFIG.C_EXT_RST_WIDTH {1} \
 ] $proc_sys_reset_base

  # Create instance: xlconstant_8, and set properties
  set xlconstant_8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_8 ]

  # Create port connections
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins clk_cpu] [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins proc_sys_reset_base/slowest_sync_clk]
  connect_bd_net -net dcm_locked_1 [get_bd_pins locked] [get_bd_pins clk_wiz_0/locked] [get_bd_pins proc_sys_reset_base/dcm_locked]
  connect_bd_net -net i_inv_dbgresetn_Res [get_bd_pins dbgresetn] [get_bd_pins i_inv_dbgresetn/Res]
  connect_bd_net -net i_inv_sysresetn1_Res [get_bd_pins sysresetn] [get_bd_pins i_inv_sysresetn1/Res]
  connect_bd_net -net proc_sys_reset_base_interconnect_aresetn [get_bd_pins interconnect_aresetn] [get_bd_pins proc_sys_reset_base/interconnect_aresetn]
  connect_bd_net -net proc_sys_reset_base_mb_reset [get_bd_pins i_inv_dbgresetn/Op1] [get_bd_pins i_inv_sysresetn1/Op1] [get_bd_pins proc_sys_reset_base/mb_reset]
  connect_bd_net -net proc_sys_reset_base_peripheral_aresetn [get_bd_pins peripheral_aresetn] [get_bd_pins proc_sys_reset_base/peripheral_aresetn]
  connect_bd_net -net sys_clock_1 [get_bd_pins sys_clock] [get_bd_pins clk_wiz_0/clk_in1]
  connect_bd_net -net sys_reset_n [get_bd_pins sys_reset_n] [get_bd_pins proc_sys_reset_base/ext_reset_in]
  connect_bd_net -net sysresetreq_1 [get_bd_pins sysresetreq] [get_bd_pins proc_sys_reset_base/mb_debug_sys_rst]
  connect_bd_net -net xlconstant_8_dout [get_bd_pins proc_sys_reset_base/aux_reset_in] [get_bd_pins xlconstant_8/dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set CM3_CODE_AXI3 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 CM3_CODE_AXI3 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.PROTOCOL {AXI3} \
   ] $CM3_CODE_AXI3

  set gpio_rtl_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 gpio_rtl_0 ]

  set usb_uart [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 usb_uart ]


  # Create ports
  set CFGITCMEN [ create_bd_port -dir I -from 1 -to 0 -type data CFGITCMEN ]
  set JTAGNSW [ create_bd_port -dir O -type data JTAGNSW ]
  set JTAGTOP [ create_bd_port -dir O -type data JTAGTOP ]
  set M3_RESET_OUT [ create_bd_port -dir O -from 0 -to 0 M3_RESET_OUT ]
  set SWCLK [ create_bd_port -dir I -type clk SWCLK ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {20000000} \
 ] $SWCLK
  set SWDI [ create_bd_port -dir I -type data SWDI ]
  set SWDO [ create_bd_port -dir O -type data SWDO ]
  set SWDOEN [ create_bd_port -dir O -type data SWDOEN ]
  set SWV [ create_bd_port -dir O SWV ]
  set TDI [ create_bd_port -dir I TDI ]
  set TDO [ create_bd_port -dir O TDO ]
  set TRACECLK [ create_bd_port -dir O -type clk TRACECLK ]
  set TRACEDATA [ create_bd_port -dir O -from 3 -to 0 TRACEDATA ]
  set TRCENA [ create_bd_port -dir O TRCENA ]
  set ext_clock [ create_bd_port -dir O -type clk ext_clock ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {CM3_CODE_AXI3} \
 ] $ext_clock
  set locked [ create_bd_port -dir O locked ]
  set nTDOEN [ create_bd_port -dir O nTDOEN ]
  set nTRST [ create_bd_port -dir I nTRST ]
  set reset [ create_bd_port -dir I -type rst reset ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $reset
  set sys_clock [ create_bd_port -dir I -type clk sys_clock ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   CONFIG.PHASE {0.000} \
 ] $sys_clock

  # Create instance: Clocks_and_Resets
  create_hier_cell_Clocks_and_Resets [current_bd_instance .] Clocks_and_Resets

  # Create instance: Cortex_M3_0, and set properties
  set Cortex_M3_0 [ create_bd_cell -type ip -vlnv Arm.com:CortexM:CORTEXM3_AXI:1.1 Cortex_M3_0 ]
  set_property -dict [ list \
   CONFIG.DEBUG_LVL {3} \
   CONFIG.DTCM_SIZE {"0110"} \
   CONFIG.ITCM_INIT_FILE {bram_a7.hex} \
   CONFIG.ITCM_SIZE {"0110"} \
   CONFIG.TRACE_LVL {2} \
   CONFIG.WIC_PRESENT {false} \
 ] $Cortex_M3_0

  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]
  set_property -dict [ list \
   CONFIG.PROTOCOL {AXI4LITE} \
   CONFIG.SINGLE_PORT_BRAM {1} \
 ] $axi_bram_ctrl_0

  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0 ]
  set_property -dict [ list \
   CONFIG.C_ALL_OUTPUTS {1} \
   CONFIG.C_GPIO_WIDTH {1} \
 ] $axi_gpio_0

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.ENABLE_ADVANCED_OPTIONS {1} \
   CONFIG.M00_HAS_DATA_FIFO {0} \
   CONFIG.M00_HAS_REGSLICE {0} \
   CONFIG.M00_SECURE {0} \
   CONFIG.M01_HAS_DATA_FIFO {0} \
   CONFIG.M01_HAS_REGSLICE {3} \
   CONFIG.M01_SECURE {0} \
   CONFIG.M02_HAS_REGSLICE {3} \
   CONFIG.M02_SECURE {0} \
   CONFIG.M03_HAS_REGSLICE {3} \
   CONFIG.M04_HAS_REGSLICE {3} \
   CONFIG.M05_HAS_REGSLICE {3} \
   CONFIG.NUM_MI {3} \
   CONFIG.NUM_SI {1} \
   CONFIG.S00_HAS_REGSLICE {3} \
   CONFIG.S01_HAS_DATA_FIFO {1} \
   CONFIG.S01_HAS_REGSLICE {3} \
   CONFIG.SYNCHRONIZATION_STAGES {2} \
 ] $axi_interconnect_0

  # Create instance: axi_uartlite_0, and set properties
  set axi_uartlite_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0 ]
  set_property -dict [ list \
   CONFIG.C_BAUDRATE {38400} \
   CONFIG.C_S_AXI_ACLK_FREQ_HZ {20000000} \
   CONFIG.C_S_AXI_ACLK_FREQ_HZ_d {20} \
   CONFIG.UARTLITE_BOARD_INTERFACE {Custom} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_uartlite_0

  # Create instance: blk_mem_gen_0, and set properties
  set blk_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0 ]
  set_property -dict [ list \
   CONFIG.EN_SAFETY_CKT {false} \
 ] $blk_mem_gen_0

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {8} \
 ] $xlconcat_0

  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {1} \
 ] $xlconstant_1

  # Create instance: xlconstant_2, and set properties
  set xlconstant_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_2 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {1} \
 ] $xlconstant_2

  # Create instance: xlconstant_3, and set properties
  set xlconstant_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_3 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {1} \
 ] $xlconstant_3

  # Create instance: xlconstant_4, and set properties
  set xlconstant_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_4 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {1} \
 ] $xlconstant_4

  # Create instance: xlconstant_5, and set properties
  set xlconstant_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_5 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {1} \
 ] $xlconstant_5

  # Create instance: xlconstant_6, and set properties
  set xlconstant_6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_6 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {1} \
 ] $xlconstant_6

  # Create instance: xlconstant_7, and set properties
  set xlconstant_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_7 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {1} \
 ] $xlconstant_7

  # Create interface connections
  connect_bd_intf_net -intf_net Cortex_M3_0_CM3_CODE_AXI3 [get_bd_intf_ports CM3_CODE_AXI3] [get_bd_intf_pins Cortex_M3_0/CM3_CODE_AXI3]
  connect_bd_intf_net -intf_net Cortex_M3_0_CM3_SYS_AXI3 [get_bd_intf_pins Cortex_M3_0/CM3_SYS_AXI3] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_ports gpio_rtl_0] [get_bd_intf_pins axi_gpio_0/GPIO]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins axi_uartlite_0/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins axi_gpio_0/S_AXI] [get_bd_intf_pins axi_interconnect_0/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M02_AXI [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] [get_bd_intf_pins axi_interconnect_0/M02_AXI]
  connect_bd_intf_net -intf_net axi_uartlite_0_UART [get_bd_intf_ports usb_uart] [get_bd_intf_pins axi_uartlite_0/UART]

  # Create port connections
  connect_bd_net -net CFGITCMEN_1 [get_bd_ports CFGITCMEN] [get_bd_pins Cortex_M3_0/CFGITCMEN]
  connect_bd_net -net Clocks_and_Resets_dbgresetn [get_bd_pins Clocks_and_Resets/dbgresetn] [get_bd_pins Cortex_M3_0/DBGRESETn]
  connect_bd_net -net Clocks_and_Resets_locked [get_bd_ports locked] [get_bd_pins Clocks_and_Resets/locked]
  connect_bd_net -net Clocks_and_Resets_sysresetn [get_bd_ports M3_RESET_OUT] [get_bd_pins Clocks_and_Resets/sysresetn] [get_bd_pins Cortex_M3_0/SYSRESETn]
  connect_bd_net -net Cortex_M3_0_JTAGNSW [get_bd_ports JTAGNSW] [get_bd_pins Cortex_M3_0/JTAGNSW]
  connect_bd_net -net Cortex_M3_0_JTAGTOP [get_bd_ports JTAGTOP] [get_bd_pins Cortex_M3_0/JTAGTOP]
  connect_bd_net -net Cortex_M3_0_SWDO [get_bd_ports SWDO] [get_bd_pins Cortex_M3_0/SWDO]
  connect_bd_net -net Cortex_M3_0_SWDOEN [get_bd_ports SWDOEN] [get_bd_pins Cortex_M3_0/SWDOEN]
  connect_bd_net -net Cortex_M3_0_SWV [get_bd_ports SWV] [get_bd_pins Cortex_M3_0/SWV]
  connect_bd_net -net Cortex_M3_0_SYSRESETREQ [get_bd_pins Clocks_and_Resets/sysresetreq] [get_bd_pins Cortex_M3_0/SYSRESETREQ]
  connect_bd_net -net Cortex_M3_0_TDO [get_bd_ports TDO] [get_bd_pins Cortex_M3_0/TDO]
  connect_bd_net -net Cortex_M3_0_TRACECLK [get_bd_ports TRACECLK] [get_bd_pins Cortex_M3_0/TRACECLK]
  connect_bd_net -net Cortex_M3_0_TRACEDATA [get_bd_ports TRACEDATA] [get_bd_pins Cortex_M3_0/TRACEDATA]
  connect_bd_net -net Cortex_M3_0_TRCENA [get_bd_ports TRCENA] [get_bd_pins Cortex_M3_0/TRCENA]
  connect_bd_net -net Cortex_M3_0_nTDOEN [get_bd_ports nTDOEN] [get_bd_pins Cortex_M3_0/nTDOEN]
  connect_bd_net -net SWCLK_1 [get_bd_ports SWCLK] [get_bd_pins Cortex_M3_0/SWCLKTCK]
  connect_bd_net -net SWDI_1 [get_bd_ports SWDI] [get_bd_pins Cortex_M3_0/SWDITMS]
  connect_bd_net -net TDI_1 [get_bd_ports TDI] [get_bd_pins Cortex_M3_0/TDI]
  connect_bd_net -net axi_uartlite_0_interrupt [get_bd_pins axi_uartlite_0/interrupt] [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_ports ext_clock] [get_bd_pins Clocks_and_Resets/clk_cpu] [get_bd_pins Cortex_M3_0/HCLK] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins axi_gpio_0/s_axi_aclk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_0/M02_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_uartlite_0/s_axi_aclk]
  connect_bd_net -net nTRST_1 [get_bd_ports nTRST] [get_bd_pins Cortex_M3_0/nTRST]
  connect_bd_net -net proc_sys_reset_1_interconnect_aresetn [get_bd_pins Clocks_and_Resets/peripheral_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins axi_gpio_0/s_axi_aresetn] [get_bd_pins axi_uartlite_0/s_axi_aresetn]
  connect_bd_net -net proc_sys_reset_1_peripheral_aresetn [get_bd_pins Clocks_and_Resets/interconnect_aresetn] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_0/M02_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN]
  connect_bd_net -net reset_1 [get_bd_ports reset] [get_bd_pins Clocks_and_Resets/sys_reset_n]
  connect_bd_net -net sys_clock_1 [get_bd_ports sys_clock] [get_bd_pins Clocks_and_Resets/sys_clock]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins Cortex_M3_0/IRQ] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net xlconstant_1_dout [get_bd_pins xlconcat_0/In4] [get_bd_pins xlconstant_1/dout]
  connect_bd_net -net xlconstant_2_dout [get_bd_pins xlconcat_0/In1] [get_bd_pins xlconstant_2/dout]
  connect_bd_net -net xlconstant_3_dout [get_bd_pins xlconcat_0/In2] [get_bd_pins xlconstant_3/dout]
  connect_bd_net -net xlconstant_4_dout [get_bd_pins xlconcat_0/In3] [get_bd_pins xlconstant_4/dout]
  connect_bd_net -net xlconstant_5_dout [get_bd_pins xlconcat_0/In5] [get_bd_pins xlconstant_5/dout]
  connect_bd_net -net xlconstant_6_dout [get_bd_pins xlconcat_0/In6] [get_bd_pins xlconstant_6/dout]
  connect_bd_net -net xlconstant_7_dout [get_bd_pins xlconcat_0/In7] [get_bd_pins xlconstant_7/dout]

  # Create address segments
  create_bd_addr_seg -range 0x00010000 -offset 0x44A00000 [get_bd_addr_spaces Cortex_M3_0/CM3_CODE_AXI3] [get_bd_addr_segs CM3_CODE_AXI3/Reg] SEG_CM3_CODE_AXI3_Reg
  create_bd_addr_seg -range 0x00002000 -offset 0x60000000 [get_bd_addr_spaces Cortex_M3_0/CM3_SYS_AXI3] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] SEG_axi_bram_ctrl_0_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x40000000 [get_bd_addr_spaces Cortex_M3_0/CM3_SYS_AXI3] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] SEG_axi_gpio_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40100000 [get_bd_addr_spaces Cortex_M3_0/CM3_SYS_AXI3] [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg] SEG_axi_uartlite_0_Reg


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


