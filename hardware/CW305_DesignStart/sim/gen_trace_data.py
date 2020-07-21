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
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--seed", type=int, default=1)
parser.add_argument("--events", type=int, default=1)
parser.add_argument("--rules", type=int, default=1)
args = parser.parse_args()

random.seed(args.seed)

# initial value to make things line up:
time = 2

last_event_time = 0

rules = [0]*8


def sync_frame(n=1):
    inc_time(8*n)
    for i in range(n):
        mem.write('// sync frame:\n')
        # TODO: check whether sync frames start or finish with 7; also, allow for short frames
        #mem.write('7 f f f f f f f\n\n')
        mem.write('f f f f f f f 7\n\n')


def sw_trig():
    global last_event_time
    trig.write('%016x\n' % time)
    last_event_time = time + 2 # adjust for delays in the RTL


def random_frame(n=1, minlen=2, maxlen=16):
    total_nibbles = 0
    for i in range(n):
        nibbles = random.randrange(minlen, maxlen+1, 2)
        total_nibbles += nibbles
        mem.write('// random %d-nibble frame:\n' % nibbles)
        for j in range(nibbles):
            mem.write('%01x ' % (random.randrange(0,16)))
        mem.write('\n\n')
        sync_frame(random.randrange(0,4))
    inc_time(total_nibbles)


def gen_rule(rule=0, length=8):
    """
    rule: int, rule number to program to DUT
    length: int, number of bytes in rule (must be even)
    """
    assert length % 2 == 0
    global rules
    pattern = []
    for i in range(length):
        pattern.append(random.randrange(0,0x100))
    rules[rule] = pattern
    hexpattern = '0x'
    for x in pattern:
        hexpattern += '%02x' % x
    regs.write("write_match_rule(%d, 'h%s, %d);\n" % (rule, hexpattern[2:], length))


def match_frame(rule=0):
    """
    rule: int, rule number to use
    """
    global last_event_time
    global rules
    inc_time(len(rules[rule])*2)
    # generate the trace data:
    hexpattern = '0x'
    pattern = rules[rule]
    for x in pattern:
        hexpattern += '%02x' % x
    mem.write('// matching pattern, rule %d: %s (%s)\n' % (rule, pattern, hexpattern))
    for x in pattern:
        mem.write('%01x %01x ' % (x & 0xf, (x>>4) & 0xf))
    mem.write('\n\n')
    # log the expected match time:
    rule = 2**rule;
    matchtimes.write('%016x\n' % ((rule << 56) + time-last_event_time))
    last_event_time = time + 1 # adjust for delays in the RTL


def inc_time(nibbles):
    global time
    time += nibbles


# open output files that will be read by the Verilog testbench:
mem = open('tracedata.mem', 'w+')
regs = open('registers.v', 'w+')
matchtimes = open('matchtimes.mem', 'w+')
trig = open('swtrigtime.mem', 'w+')

# generate match rules:
for i in range(args.rules):
    gen_rule(rule=i, length=random.randrange(4,9,2))

# create trace data:
# lots of sync frames initially to allow all setup register writes to be done:
sync_frame(200)

# trigger + stuff:
sw_trig()
random_frame(random.randrange(0,20))
sync_frame(random.randrange(0,20))

for i in range(args.events):
    rule = random.randrange(0, args.rules)
    match_frame(rule)
    random_frame(random.randrange(0,20))

sync_frame(10)

# done:
mem.close()
regs.close()
trig.close()

# indicate there are no more matches:
matchtimes.write('%016x\n' % 0xffffffffffffffff)
matchtimes.close()

