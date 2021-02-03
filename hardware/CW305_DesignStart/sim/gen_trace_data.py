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
parser.add_argument("--raw", type=int, default=0)
parser.add_argument("--patterntrig", type=int, default=0)
parser.add_argument("--capturenow", type=int, default=0)
parser.add_argument("--swo_mode", type=int, default=0)
parser.add_argument("--cw305", type=int, default=0)
args = parser.parse_args()

rawmode = args.raw
patterntrig = args.patterntrig
capturenow = args.capturenow

random.seed(args.seed)

# initial value to make things line up:
time = 0
last_event_time = 3
rules = [0]*8
first_event = True
recording = False
nibble_index = 0
match_index = 0

if args.swo_mode:
    multiplier = 4 # TODO: make this ratio of trace_clk : usb_clk
else:
    multiplier = 1

def write_command_length(command=0, length=0):
    length_lo = length & 15;
    length_hi = length >> 4;
    mem.write('%x %x %x\n' % (command, length_lo, length_hi))


def sync_frame(n=1, synctype='rand'):
    #global last_event_time
    global nibble_index
    global match_index
    if n == 0:
        return
    if synctype == 'rand':
        synctime = random.randrange(0,2)
    elif synctype == 'short':
        synctime = 0
    elif synctype == 'long':
        synctime = 1
    mem.write("// nibble index: %d; match index: %d\n" % (nibble_index, match_index))
    # in swo mode, do a single sync frame followed by nothing:
    if args.swo_mode:
        if synctime:
            mem.write('// long sync frame:\n')
            write_command_length(0, 8)
            mem.write('f f f f f f f 7\n\n')
            inc_time(8)
            nibble_index += 8 + 3
        else:
            mem.write('// short sync frame:\n')
            write_command_length(0, 4)
            mem.write('f f f 7\n\n')
            inc_time(4)
            nibble_index += 4 + 3
        inc_time(n)
        while n > 0:
            if n > 255:
                idles = 255
            else:
                idles = n
            mem.write('// idle:\n')
            write_command_length(1, idles)
            n = n - idles
    # in parallel trace mode, sync frames are constantly present:
    else:
        for i in range(n):
            if synctime:
                mem.write('// long sync frame:\n')
                write_command_length(0, 8)
                mem.write('f f f f f f f 7\n\n')
                inc_time(8)
                nibble_index += 8 + 3
            else:
                mem.write('// short sync frame:\n')
                write_command_length(0, 4)
                mem.write('f f f 7\n\n')
                inc_time(4)
                nibble_index += 4 + 3
    # Note that sync frames don't get checked, so they're not "events" as
    # far as the testbench is concerned, and so we don't touch
    # last_event_time here.


def sw_trig():
    global last_event_time
    global time
    #if args.cw305:
    #    actual_trigger_time = time
    #else: # account for the fact that in this case, the trigger pin is delayed one clock cycle
    #    actual_trigger_time = time - 1
    if capturenow:
        mem.write('\n// ** CAPTURE NOW TIME: %d **\n\n' % time)
    else:
        mem.write('\n// ** SW TRIGGER TIME: %d **\n\n' % time)
        trig.write('%016x\n' % time)
    # different delay adjustment based on mode; doesn't matter, just make it work!
    if capturenow:
        pass
    elif rawmode:
        last_event_time = time - 3
    else:
        last_event_time = time - 1


def random_frame(n=1, minlen=2, maxlen=15):
    global last_event_time
    global first_event
    global nibble_index
    global match_index
    if n == 0:
        return
    total_nibbles = 0
    for i in range(n):
        nibbles = random.randrange(minlen, maxlen+1, 2)
        total_nibbles += nibbles
        mem.write("// nibble index: %d; match index: %d\n" % (nibble_index, match_index))
        mem.write('// random %d-nibble frame:\n' % nibbles)
        write_command_length(0, nibbles)
        last_time = last_event_time
        for j in range(nibbles):
            # since the testbench isn't that smart, avoid starting with 0xff or 0x7f since that 
            # could be confused to be part of a sync frame:
            if j == 1:
                top = 7
            else:
                top = 16
            nibble = random.randrange(0,top)
            mem.write('%01x ' % nibble)
            if rawmode and recording:
                if j % 2:
                    inc_time(2)
                    if first_event and args.swo_mode:
                        adjust = 2
                        #first_event = False
                    elif first_event and args.cw305:
                        adjust = 1
                        #first_event = False
                    else:
                        adjust = 0
                    if first_event:
                        first_event = False
                        if not args.cw305 and not args.swo_mode:
                            adjust -= 1
                    matchtimes.write('%016x\n' % ((((nibble << 4) + lastnib) << 56) + (time-last_time+adjust)*multiplier))
                    last_time = time
                else:
                    lastnib = nibble
        mem.write('\n\n')
        nibble_index += nibbles + 3
        if recording:
            match_index += nibbles/2
        if rawmode and recording:
            last_event_time = time
        else:
            inc_time(nibbles)



def gen_rule(rule=0, length=8, patterntrig=0):
    """
    rule: int, rule number to program to DUT
    length: int, number of bytes in rule (must be even)
    """
    assert length % 2 == 0
    global rules
    pattern = []
    for i in range(length):
        # since the testbench isn't that smart, avoid starting with 0xff or 0x7f since that 
        # could be confused to be part of a sync frame:
        if i == 0:
            top = 0x7f
        else:
            top = 0x100
        pattern.append(random.randrange(0,top))
    rules[rule] = pattern
    hexpattern = '0x'
    for x in pattern:
        hexpattern += '%02x' % x
    regs.write("write_match_rule(%d, 'h%s, %d, %d);\n" % (rule, hexpattern[2:], length, patterntrig))


def match_frame(rule=0):
    """
    rule: int, rule number to use
    """
    # TODO: check for recording, because later we want to call this before trigger
    global last_event_time
    global rules
    global first_event
    global nibble_index
    global match_index
    # generate the trace data:
    hexpattern = '0x'
    pattern = rules[rule]
    for x in pattern:
        hexpattern += '%02x' % x
    mem.write("// nibble index: %d; match index: %d\n" % (nibble_index, match_index))
    mem.write('// matching pattern, rule %d: %s (%s)\n' % (rule, pattern, hexpattern))
    write_command_length(0, len(pattern)*2)
    last_time = last_event_time

    for x in pattern:
        mem.write('%01x %01x ' % (x & 0xf, (x>>4) & 0xf))
        if rawmode:
            inc_time(2)
            if first_event and args.swo_mode:
                adjust = 2
                #first_event = False
            elif first_event and args.cw305:
                adjust = 1
                #first_event = False
            else:
                adjust = 0
            if first_event:
                first_event = False
                if not args.cw305 and not args.swo_mode:
                    adjust -= 1
            matchtimes.write('%016x\n' % ((x << 56) + (time-last_time+adjust)*multiplier))
            last_time = time
    mem.write('\n\n')
    nibble_index += len(pattern)*2 + 3
    if recording:
        match_index += len(pattern)

    if not rawmode:
        inc_time(len(rules[rule])*2)
        rule = 2**rule;
        if first_event and args.swo_mode:
            adjust = 2
            #first_event = False
        elif first_event and args.cw305:
            adjust = 1
            #first_event = False
        else:
            adjust = 0
        if first_event:
            first_event = False
            if not args.cw305 and not args.swo_mode:
                adjust -= 1

        matchtimes.write('%016x\n' % ((rule << 56) + (time-last_event_time+adjust)*multiplier))

    last_event_time = time


def inc_time(nibbles):
    global time
    time += nibbles


# open output files that will be read by the Verilog testbench:
mem = open('tracedata.mem', 'w+')
regs = open('registers.v', 'w+')
matchtimes = open('matchtimes.mem', 'w+')
trig = open('swtrigtime.mem', 'w+')

# generate match rules:
if patterntrig:
    trig_rule = random.randrange(0,args.rules)
for i in range(args.rules):
    if patterntrig and trig_rule == i:
        gen_rule(rule=i, length=random.randrange(4,9,2), patterntrig=1)
    else:
        gen_rule(rule=i, length=random.randrange(4,9,2), patterntrig=0)

# create trace data:
# lots of sync frames initially to allow all setup register writes to be done:
# (plus some non-sync frames that shouldn't be recorded)
if args.swo_mode:
    sync_frame(200)
else:
    sync_frame(40)
if (capturenow):
    recording = True
random_frame(random.randrange(2,10))
# TODO: add some random non-triggering match frame
sync_frame(random.randrange(8,16))

# trigger + stuff:
recording = True

if patterntrig:
    match_frame(trig_rule)
    if rawmode:
        last_event_time = time - 3
    else:
        last_event_time = time - 1
    for i in range(args.events):
        sync_frame(random.randrange(0,80))
        random_frame(random.randrange(0,20))
        sync_frame(random.randrange(0,4))
    sync_frame(10)

else:
    sw_trig()
    sync_frame(100)
    sync_frame(random.randrange(2,4))
    random_frame(random.randrange(0,20))
    sync_frame(random.randrange(0,20))
    for i in range(args.events):
        rule = random.randrange(0, args.rules)
        match_frame(rule)
        sync_frame(random.randrange(0,80))
        random_frame(random.randrange(0,20))
        sync_frame(random.randrange(0,4))
    sync_frame(10)

# done:
mem.write("// Done\n2 0 0\n");
mem.close()
regs.close()
trig.close()

# indicate there are no more matches:
matchtimes.write('%016x\n' % 0xffffffffffffffff)
matchtimes.close()

