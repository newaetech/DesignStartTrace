# Arm DesignStart Tracing - script to generate simulated trace data, to 
# verify correct functioning of the trace FPGA code in simulation.
# 
# Copyright (c) 2020, NewAE Technology Inc.
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted without restriction. Note that modules within
# the project may have additional restrictions, please carefully inspect
# additional licenses.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# The views and conclusions contained in the software and documentation are those
# of the authors and should not be interpreted as representing official policies,
# either expressed or implied, of NewAE Technology Inc.

import random

# TODO: add random seed for repeatable randomization, time counter, expected trace match output

def sync_frame(n=1):
    inc_time(8)
    for i in range(n):
        mem.write('// sync frame:\n')
        # TODO: check whether sync frames start or finish with 7; also, allow for short frames
        #mem.write('7 f f f f f f f\n\n')
        mem.write('f f f f f f f 7\n\n')

def random_frame(n=1, minlen=1, maxlen=16):
    total_nibbles = 0
    for i in range(n):
        nibbles = random.randrange(minlen, maxlen)
        total_nibbles += nibbles
        mem.write('// random %d-nibble frame:\n' % nibbles)
        for j in range(nibbles):
            mem.write('%s ' % hex(random.randrange(0,15))[2:])
        mem.write('\n\n')
    inc_time(total_nibbles)

""" Hmm, no point in generating actual iaddr packets? TODO-remove?
def iaddr_match_frame(addr, traceidr=2):
    # documentation:
    # Trace formatter frame: ARM Coresight Architecture Specification v3.0 (ARM IHI 0029E)
    # I-sync packet: Embedded Trace Macrocell Architecture Specification, ETMv1.0 to ETMv3.5 (ARM IHI 0014Q)
    mem.write('// I-sync packet for address %s:\n' % addr)
    frame = []
    frame.append(1 + (traceidr << 1) # ID
    frame.append(8) # header
    # no context ID
    frame.append(0x20) # information byte
"""

def match_frame(payload, rule=0):
    """
    payload: list of bytes
    rule: int, rule number to program to DUT
    """
    inc_time(len(payload))
    # generate the trace data:
    hexpayload = '0x'
    for x in payload:
        hexpayload += hex(x)[2:]
    mem.write('// matching payload: %s (%s)\n' % (payload, hexpayload))
    for x in payload:
        mem.write('%s %s ' % (hex(x & 0xf)[2:], hex((x>>4) & 0xf)[2:]))
    mem.write('\n\n')
    # generate the register setup data:
    regs.write("write_match_rule(%d, 'h%s, %d);\n" % (rule, hexpayload[2:], len(payload)))
    # log the expected match time:
    # TODO


def inc_time(nibbles):
    #TODO
    pass


# open output files that will be read by the Verilog testbench:
mem = open('tracedata.mem', 'w+')
regs = open('registers.v', 'w+')
matchtimes = open('matchtimes.mem', 'w+')

# create trace data:
sync_frame(20)
match_frame([0xab,0x12,0x34,0x56])
random_frame(3)
sync_frame(10)

# done:
mem.close()
regs.close()
matchtimes.close()

