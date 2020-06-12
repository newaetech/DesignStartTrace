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
#                             with V2C-DAPLink adaptor board
# -----------------------------------------------------------------------------
#  Purpose :
#           Script to get ITCM BRAM locations
#           MMI format from following two articles
#
# https://www.xilinx.com/support/answers/63041.html
# https://forums.xilinx.com/t5/Vivado-TCL-Community/export-BRAM-locations-into-MMI-file/td-p/771221
# -----------------------------------------------------------------------------

# Set MMI output file name
set mmi_file "m3.mmi"
set part     "xc7a100tftg256-2"

# Function to swap bits
proc swap_bits { bit } {

    if { $bit > 23 } {return [expr {24 + (31 - $bit)}]}
    if { $bit > 15 } {return [expr {16 + (23 - $bit)}]}
    if { $bit > 7  } {return [expr {8  + (15 - $bit)}]}
    return [expr {7 - $bit}]
}

# If run from batch file, will need to open project, then open the run
# open_run impl_1

# Find all the ITCM RAMs, place in a list
set itcm_ram [get_cells -hier -regexp {.*u_x_itcm.*ram_block_reg.*} -filter {REF_NAME =~ RAMB36E1}]

# Vivado appears to read the memories in their actual bit order
# However update_mem amongst its very many failings doesn't support endianness, even though you specify it in the file!
# It also pays no attention to the bit_lane definition, it does the conversion based on the order memories are defined
# in the file!  Not clear what the MMI file does achieve!

# So go through and reverse each block of 4 memories
if { [expr {[llength $itcm_ram] % 4}] != 0 } {
    puts "Error - Number of memories not divisible by 4"
    return -1
}

# Number of RAMs details memory size.  Each RAM is 32kb, so 4kB.
set itcm_size_bytes [expr {4096*[llength $itcm_ram]}]
puts "Instruction memory size $itcm_size_bytes"

# Currently only support memory sizes between 16kB, (one byte per mem), and 128kB, (one bit per mem)
if { ($itcm_size_bytes <= (4*4096)) || ($itcm_size_bytes > (32*4096)) } {
    puts "Error - Memory size of $itcm_size_bytes out of range"
    puts "        Script only supports memory sizes between 16kB and 128kB"
    return -1
}

# Create and open target mmi file
set fp [open $mmi_file {WRONLY CREAT TRUNC}]
if { $fp == 0 } {
    puts "Error - Unable to open $mmi_file for writing"
    return -1
}

# Write the file header
puts $fp "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
puts $fp "<MemInfo Version=\"1\" Minor=\"15\">"
puts $fp "    <Processor Endianness=\"ignored\" InstPath=\"dummy\">"
puts $fp "        <AddressSpace Name=\"m3_for_arty_a7_i.Cortex_M3_0.inst.u_x_itcm\" Begin=\"0\" End=\"[expr {$itcm_size_bytes-1}]\">"
puts $fp "            <BusBlock>"

# Create an array to put the location and top memory index into
array set mem_array {}

# Calculate the expected number of bits per memory
set mem_bits [expr {32/[llength $itcm_ram]}]

# set itcm_ram_reordered [list]

for {set i 0} {$i < [llength $itcm_ram]/4} {incr i} {
    set start     [expr {$i*4}]
    set end       [expr {($i*4)+3}]
    set new_list  [lreverse [lrange $itcm_ram [expr {$i*4}] [expr {($i*4)+3}]]]
#    puts "$start $end\n$new_list"
    # lreplace $itcm_ram [expr {$i*4}] [expr {($i*4)+3}] [lreverse [lrange $itcm_ram [expr {$i*4}] [expr {($i*4)+3}]]]


# puts $itcm_ram_reordered

    # For each entry display the location
    foreach ram $new_list {
        # Get the RAM location
        set loc_val [get_property LOC [get_cells $ram]]
        regexp -- {(RAMB36_)([0-9XY]+)} $loc_val full ram_name loc_xy

        # Get the nets driven by the D0 pins
        set data_bus [get_nets -of_objects [get_pins -filter {REF_PIN_NAME =~ DOADO*} -of [get_cells $ram]]]
        
        # Check number of bits is the same as that expected
        if { [llength $data_bus] != $mem_bits } {
            puts "Error - Number of data pins read, [llength $data_bus], does not equal expected memory bits, $mem_bits"
            return -1
        }

        # Number of pins connected to the memory sets the memory depth.
        set memory_depth [expr {(32768/[llength $data_bus])-1}]
        
        set idx_list [list]
        foreach entry $data_bus {
            # Filter the data_bus down to just the two index numbers
            set index [regexp -inline -- {[0-9]+} [regexp -inline -- {\[.*} [lindex $entry 0]]]
            lappend idx_list $index
        }
        
        # Sort the index list from highest to lowest
        set idx_list [lsort -decreasing -integer $idx_list]
        
        # Assign the highest and lowest bits for the range variables
        set index_low  [lindex $idx_list end]
        set index_high [lindex $idx_list 0]
        
        # Debug
        # puts $data_bus
        # puts $idx_list
        # puts "$index_high downto $index_low pos $loc_val"

        array set mem_array [list $index_high $loc_xy]
    }; # foreach
}; # for

    # Sort array into index order
    array set mem_array_sorted {}

    foreach entry [lsort [array names mem_array]] {
        # puts "$entry : $mem_array($entry)"
        array set mem_array_sorted [list $entry $mem_array($entry)]
    }
    
    foreach entry [array names mem_array_sorted] {
        # puts "$entry : $mem_array_sorted($entry)"
    }
    
    # MMI file needs to be in little endian format because update_mem doesn't actually use the endianness field
    # So first index is 7, next is 15, 23, 31.
    # Number of entries to write is 8/mem_bits.  Lower index is index_high - (mem_bits - 1)
    for {set top_idx 7} {$top_idx < 32} {incr top_idx 8} {
        for {set idx_high $top_idx} {$idx_high > ($top_idx-8)} {incr idx_high -$mem_bits} {
            # puts $idx_high
            set loc $mem_array_sorted($idx_high)
            set idx_low [expr {$idx_high - $mem_bits + 1}]
            
            if { $loc == "" } {
                puts "Error - No location entry for index $idx_high"
                return -1
            }
    
            # Write relevant XML
            puts $fp "                <BitLane MemType=\"RAMB36\" Placement=\"$loc\">"
            puts $fp "                    <DataWidth MSB=\"$idx_high\" LSB=\"$idx_low\"/>"
            puts $fp "                    <AddressRange Begin=\"0\" End=\"$memory_depth\"/>"
            puts $fp "                    <Parity ON=\"false\" NumBits=\"0\"/>"
            puts $fp "                </BitLane>"
        }
    }



# Write the file tail
puts $fp "            </BusBlock>"
puts $fp "        </AddressSpace>"
puts $fp "    </Processor>"
puts $fp "    <Config>"
puts $fp "        <Option Name=\"Part\" Val=\"$part\"/>"
puts $fp "    </Config>"
puts $fp "    <DRC>"
puts $fp "      <Rule Name=\"RDADDRCHANGE\" Val=\"false\"/>"
puts $fp "    </DRC>"
puts $fp "</MemInfo>"

# Close the output file
close $fp


# Useful facilities
# Get the bus as a list
# get_nets -hierarchical -regexp  {.*itcm.*doutA.*}
