# DesignStartTrace

An Arm Coresight trace sniffer designed for use with the
[ChipWhisperer](https://github.com/newaetech/chipwhisperer) side channel
analysis platform.

DesignStartTrace allows you to leverage Arm trace technology to
**non-intrusively** learn what your target is doing at what time. You can
then combine this information with power traces collected by ChipWhisperer
hardware to facilitate and speed up your side-channel analysis.

## Examples
First, here's a few examples of what you can do with DesignStartTrace:

1. **Identify when a specific instruction is being executed.**
The ETM can generate trace packets when a specific PC value is reached. Here,
the target is executing AES, and trace packets are emitted at the start and
end of the ShiftRows operation:
![picture](images/aes_shiftrows.png)


2. **Identify functions or code segments with periodic PC sampling.**
The DWT can emit periodic PC samples. This allows you to easily visualize
and find functions on your power trace:
![picture](images/aes_annotate.png)


3. **Identify time leakage.** Non-intrusively and quickly check whether
sensitive code segments are time constant. Here we show the start of every
point addition in an ECC P-256 point multiplication. You can't see it here
because there's so many point additions, but there is in fact a significant
time variance in the length of each point addition, which could be useful
for a timing attack...
![picture](images/ecc_padd.png)


4. **Use any given trace packet as a power trace capture trigger.**
If inserting `trigger_high()` in your source code is a problem, this could
be the solution for you! Move the trigger anywhere you want, as many times
as you want, without ever having to recompile!


5. **Use any given trace packet as a time reference for fault attacks.**
Speed up evaluation of glitch-tolerant code by using trace to quickly get a
time reference to when sensitive code is executing. Again you could do this
without trace via `trigger_high()`, but this requires modifying source code
and recompiling -- unlike trace which is completely transparent and can be
enabled, disabled, or moved around without touching the source code at all.

Arm trace can generate **tons** of information about what your target is
doing. These examples are just scratching the surface of what's possible!


## Targets and Platforms
As its name implies, DesignStartTrace was first developed for the [Arm
DesignStart FPGA](https://developer.arm.com/ip-products/designstart/fpga)
platform, which is a free evaluation platform for Arm Cortex M1 and M3
processors. We ported the reference design to our
[CW305](https://rtfm.newae.com/Targets/CW305%20Artix%20FPGA/) side-channel
FPGA target board. Detailed instructions for porting are available here:
[https://github.com/newaetech/CW305-Arm-DesignStart](https://github.com/newaetech/CW305-Arm-DesignStart).

We then added trace sniffing logic to this to create "DesignStartTrace".
When implemented on our CW305 target board, this provides you with a Cortex
M3 along with our trace sniffing logic, co-located on the CW305's Xilinx
Artix 7 FPGA.  If you're already familiar with the ChipWhisperer target
framework, this target looks like any of our ChipWhisperer reference
targets, and so any existing target application can very easily be ported to
this platform and gain the power of trace.

If your target cannot be implemented on the CW305 platform, the trace
sniffing logic can also be implemented on the
[PhyWhisperer-USB](https://rtfm.newae.com/Tools/PhyWhisperer/). This can
support any target with a parallel trace port or SWO pin. Look to
[hardware/tracewhisperer](hardware/tracewhisperer) for this variant. This
platform provides all the same capabilities of trace, but with some gotchas
related to power trace noise which are discussed
[here](hardware/tracewhisperer/trace_noise.md).


## How it Works
The trace sniffer runs completely in hardware on the FPGA. It is basically
like PhyWhisperer-USB, but for trace. (In fact, about half of the Verilog
source code is shared with PhyWhisperer-USB.) Raw trace data is time-stamped
and stored internally in the FPGA. Up to 16Kbytes of trace data can be
stored. The cycle-accurate timestamping is what allows the collected trace
information to be usefully combined with power traces, as shown in the
examples above.


## How to Use It
If you're already familiar with ChipWhisperer, just add this to your
notebook:
```python
from chipwhisperer.capture.trace.TraceWhisperer import TraceWhisperer
trace = TraceWhisperer(target, scope)
```

and start having fun. This [example Jupyter
notebook](jupyter/TraceWhisperer.ipynb) shows a bunch of examples. This
notebook supports both CW305 and CW610 (PhyWhisperer) platforms. You'll need
ChipWhisperer capture hardware, and either a CW305, or a CW610, CW308, and
MK82F in order to run the notebook out-of-the-box.

Use `help(TraceWhisperer)` to see which methods are available.  At a low
level, trace is configured on the sniffing side via configuration and status
registers in the FPGA, all of which are accessible via the `fpga_read()` and
`fpga_write()` methods. On the target side, "There's More Than One Way To Do
It", but the method supported by `TraceWhisperer.py` uses additional
SimpleSerial commands to set the trace registers on the target.  See the
[simpleserial-trace](https://github.com/newaetech/chipwhisperer/blob/develop/hardware/victims/firmware/simpleserial-trace/simpleserial-trace.c)
example, which can easily be ported to any SimpleSerial target.


## Triggering
Once you've gone through the example notebook, read [this note on
triggering](triggering.md) to learn all the triggering options and
possibilities that are added by trace.


## Orbuculum
Raw trace data has somewhat complex layers of formatting. Fortunately,
[Orbuculum](https://github.com/orbcode/orbuculum) is a very nice open-source
trace parser which can be used to transform raw trace data into something
more useful.

For example, the raw trace data for two alternating matching PC addresses
looks like this, which is a bit of a mess to understand:
```
03 08 20 af 3a 00 00 84 
03 08 20 b3 3a 00 00 22 01 84 
03 08 20 af 3a 00 00 84 
03 08 20 b3 3a 45 00 00 01 84 
03 08 20 af 3a 00 00 84 
03 08 20 8a b2 3a 00 00 01 84 
03 08 20 af 3a 00 00 84 01 15 
03 08 20 b3 3a 00 00 84 
03 08 20 af 3a 00 00 22 01 84 
```

After feeding this through Orbuculum, you can clearly see the two
alternating addresses:
```
0x00003aae
0x00003ab2
0x00003aae
0x00003ab2
0x00003aae
0x00003ab2
0x00003aae
0x00003ab2
0x00003aae
```

(If you must know, section D4.2 of [ARM IHI
0029E](https://developer.arm.com/documentation/ihi0029/e/) will show you why
the raw trace data looks the way it does... don't say I didn't warn you!)


