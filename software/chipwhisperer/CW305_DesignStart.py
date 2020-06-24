#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# Copyright (c) 2020, NewAE Technology Inc
# All rights reserved.
#
# Find this and more at newae.com - this file is part of the chipwhisperer
# project, http://www.chipwhisperer.com . ChipWhisperer is a registered
# trademark of NewAE Technology Inc in the US & Europe.
#
#    This file is part of chipwhisperer.
#
#    chipwhisperer is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    chipwhisperer is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Lesser General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with chipwhisperer.  If not, see <http://www.gnu.org/licenses/>.
#=================================================
import logging
import time
import re
from .CW305 import CW305, CW305_USB
from chipwhisperer.common.utils import util

class CW305_DesignStart(CW305):

    """ CW305 Arm DesignStart target object.

    This class contains the public API for the CW305 hardware.
    To connect to the CW305, the easiest method is::

        import chipwhisperer as cw
        scope = cw.scope()
        target = cw.target(scope,
                targets.CW305_DesignStart, bsfile=<valid FPGA bitstream file>)

    Note that connecting to the CW305 includes programming the CW305 FPGA.
    For more help about CW305 settings, try help() on this CW305 submodule:

       * target.pll
    """


    _name = "ChipWhisperer CW305 (Artix-7)"


    def __init__(self):
        super().__init__()
        # should be sufficient; TODO-check:
        self._clksleeptime = 200
        self.slurp_defines()


    def set_ss(self, ss):
        self.ss = ss


    def slurp_defines(self):
        """ Parse Verilog defines file so we can access register and bit
        definitions by name and avoid 'magic numbers'.
        """
        self.verilog_define_matches = 0
        # TODO-later: move defines file to package:
        # defines_file = pkg_resources.resource_filename('phywhisperer', 'firmware/defines.v')
        defines_file = '../hardware/CW305_DesignStart/hdl/defines.v'
        defines = open(defines_file, 'r')
        define_regex_base  =   re.compile(r'`define')
        define_regex_radix =   re.compile(r'`define\s+?(\w+).+?\'([bdh])([0-9a-fA-F]+)')
        define_regex_noradix = re.compile(r'`define\s+?(\w+?)\s+?(\d+?)')
        for define in defines:
            if define_regex_base.search(define):
                match = define_regex_radix.search(define)
                if match:
                    self.verilog_define_matches += 1
                    if match.group(2) == 'b':
                        radix = 2
                    elif match.group(2) == 'h':
                        radix = 16
                    else:
                        radix = 10
                    setattr(self, match.group(1), int(match.group(3),radix))
                else:
                    match = define_regex_noradix.search(define)
                    if match:
                        self.verilog_define_matches += 1
                        setattr(self, match.group(1), int(match.group(2),10))
                    else:
                        logging.warning("Couldn't parse line: %s", define)
        # make sure everything is cool:
        assert self.verilog_define_matches == 36, "Trouble parsing Verilog defines file (%s): didn't find the right number of defines." % defines_file
        defines.close()



    def simpleserial_write(self, cmd, data, printresult=False):
        """TODO-document!
        """
        self.ss.simpleserial_write(cmd, data)
        if printresult:
            time.sleep(0.1)
            print(self.ss.read().split('\n')[0])


    def set_comp0(self, data, printresult=False):
        """Set the Cortex DWT->COMP0 register

        Args:
            data (string): 8-character hex string, value to write to COMP0 (e.g. '1000F004')
        """
        self.ss.simpleserial_write('s', util.hexStrToByteArray(data))
        time.sleep(0.1)
        if printresult:
            print(self.ss.read().split('\n')[0])


    def get_comp0(self):
        """Reads the Cortex DWT->COMP0 register

        """
        self.ss.simpleserial_write('g', bytearray(4))
        time.sleep(0.1)
        return self.ss.read().split('\n')[0][1:]


    def set_pattern_match(self, index, pattern, mask=[0xff]*8):
        """Sets pattern match and mask parameters

        Args:
            index: match index [0-7]
            pattern: list of 8-bit integers, pattern match value
            mask: list of 8-bit integers, pattern mask value

        """
        self.fpga_write(self.REG_TRACE_PATTERN0+index, pattern)
        self.fpga_write(self.REG_TRACE_MASK0+index, mask)


    def synced(self):
        """Checks that trace trigger module is synchronized.


        """
        assert self.fpga_read(self.REG_SYNCHRONIZED, 1)[0] == 1, 'Not synchronized!'


    def get_trace_match_address(self):
        """Returns the address portion of a PC match.

        """
        raw = self.fpga_read(self.REG_MATCHING_BUFFER, 7)
        # first check that the matching packet is PC match packet:
        assert raw[:3].tolist() == [5, 8, 32], "Hmm, this doesn't look like a PC match?"
        return (raw[-1] << 24) + (raw[-2] << 16) + (raw[-3] << 8) + raw[-4]



    # TODO or remove or pass to SS?
    def simpleserial_read(self, cmd, pay_len, end='\n', timeout=250, ack=True):
        """Not defined for this target.
        """
        logging.warning('Why are you calling simpleserial_read???')


    # TODO or remove or pass to SS?
    def is_done(self):
        return False


    def fpga_write(self, addr, data):
        """Write to an FPGA register.

        Args:
            addr (int): Address to write to
            data (list): Data to write to addr
        """
        # change word address to byte address;
        addr = addr << 7
        return self._naeusb.cmdWriteMem(addr, data)


    def fpga_read(self, addr, readlen=4):
        """Read from an FPGA register.

        Args:
            addr (int): Address to read from
            readlen (int): Length of data to read

        Returns:
            Requested data as a list
        """
        # change word address to byte address;
        addr = addr << 7
        data = self._naeusb.cmdReadMem(addr, readlen)
        return data


    def get_fpga_buildtime(self):
        """Returns date and time when FPGA bitfile was generated.
        """
        # TODO: slurp
        raw = self.fpga_read(addr=0x0, readlen=4)
        # definitions: Xilinx XAPP1232
        day = raw[3] >> 3
        month = ((raw[3] & 0x7) << 1) + (raw[2] >> 7)
        year = ((raw[2] >> 1) & 0x3f) + 2000
        hour = ((raw[2] & 0x1) << 4) + (raw[1] >> 4)
        minute = ((raw[1] & 0xf) << 2) + (raw[0] >> 6)
        return "FPGA build time: {}/{}/{}, {}:{}".format(month, day, year, hour, minute)


    def get_fw_buildtime(self):
        """Returns date and time when target FW was compiled.
        """
        self.ss.simpleserial_write('i', b'')
        time.sleep(0.1)
        print(self.ss.read().split('\n')[0])


    def get_target_name(self):
        """Returns project-specific 'name' embedded in target bitfile
        """
        nameb = self.fpga_read(0x1, 8)
        names = ''
        for i in nameb:
            names += hex(i)[2:]
        return bytearray.fromhex(names).decode()
        


    # TODO:
    def capture_trace(self, scope):
        pass

    # TODO:
    def go(self):
        pass



