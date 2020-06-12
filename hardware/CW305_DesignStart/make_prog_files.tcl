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
#           Script to create bit and mcs files for Arty A7 board
#
#           Combines the original bit file, mmi file, and software elf to create
#           the full bitstream
#           Then converts full bitstream to mcs for download to the onboard flash
#
#           Can be run either in Vivado GUI TCL console, or else in batch mode
#           from command line
#           If run in Vivado TCL console, pwd needs to be set to root of project, 
#           in the same location as the bit file
# -----------------------------------------------------------------------------

# Input files
set mmi_file            "./m3.mmi"
set elf_file            "./bram_a7.elf"
set source_bit_file     "./CW305_DesignStart.runs/impl_1/CW305_designstart_top.bit"
set reference_bit_file  "./m3_for_arty_a7_reference.bit"

# Output files
set output_bit_file "CW305_DesignStart.bit"
set output_mcs_file "CW305_DesignStart.mcs"

# Enable to turn on debug
set updatemem_debug 0

# Assemble bit file that can be downloaded to device directly
# Combine the original bit file, mmi file, and software elf to create the full bitstream

# Delete target file
file delete -force $output_bit_file
file delete -force $output_mcs_file

# Determine if the user has built the project and has the target source file
# If not, then use the reference bit file shipped with the project
if { ![file exists $source_bit_file] } {
    puts "\n********************************************"
    puts "INFO - File $source_bit_file doesn't exist as project has not been built"
    puts "       Using $reference_bit_file instead\n"
    puts "********************************************/n"
    set source_bit_file $reference_bit_file
}

# Banner message to console as there is no output for a few seconds
puts "  Running updatemem ..."

if { $updatemem_debug } {
    set error [catch {exec updatemem --debug --force --meminfo $mmi_file --data $elf_file --bit $source_bit_file --proc dummy --out $output_bit_file} result]
} else {
    set error [catch {exec updatemem --force --meminfo $mmi_file --data $elf_file --bit $source_bit_file --proc dummy --out $output_bit_file} result]
}

# Print the stdout from updatemem
puts $result

# Updatemem returns 0 even when there is an error, so cannot trap on error.  Having deleted output file to start, then
# detect if it now exists, else exit.
if { ![file exists $output_bit_file] } {
    puts "ERROR - $output_bit_file not made"
    return -1
} else {
    puts "\n********************************************"
    puts "  $output_bit_file correctly generated"
    puts "********************************************\n"
}

# Create MCS file for base board QSPI flash memory
write_cfgmem -force -format MCS -size 16 -interface SPIx4 -loadbit " up 0 $output_bit_file" $output_mcs_file

# Check MCS was correctly made
if { ![file exists $output_mcs_file] } {
    puts "ERROR - $output_bit_file not made"
    return -1
} else {
    puts "\n********************************************"
    puts "  $output_mcs_file correctly generated"
    puts "********************************************\n"
}
