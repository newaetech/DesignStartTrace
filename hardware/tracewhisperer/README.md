# TraceWhisperer

TraceWhisperer is a trace sniffer, originally developed for the CW305
DesignStart target, then ported to the PhyWhisperer-USB platform. The "trace"
we're talking about here is Coresight processor trace data (ETM, DWT, ITM)
that can be output by Arm Cortex processors via their parallel trace port or
SWO pin.

One target with the parallel trace port is our [K82F
target](https://rtfm.newae.com/Targets/UFO%20Targets/CW308T-K82/), but it
should be possible to use TraceWhisperer with any target that has a trace
port. Currently, TraceWhisperer supports 4-bit wide trace ports only, but
adding support for other widths should be fairly easy.

The SWO pin is more common -- you'll find it on our STM32 targets -- but its
bandwidth is much lower than the trace port.

The trace sniffer features and capabilities with TraceWhisperer are
basically the same as on the CW305 DesignStart platform. Some differences to
note:

* Since the PhyWhisperer FPGA is smaller than the CW305 FPGA, the largest
  FIFO that can fit here is 16K deep (allowing for up to 16Kbytes of trace
  data). If ILAs are required for debug and development, define TINYFIFO to
  free up BRAM resources.
* On CW305, the target and trace sniffer are co-located on the same FPGA,
  and so the trace port signals remain internal (not driving any external
  pins). On the PhyWhisperer, the trace data and clock come from an external
  chip, and this has two implications:
    1. Activity on the trace pins (and, to a lesser degree, SWO) adds
       significant noise to the side-channel power measurements. See [this
       note](trace_noise.md) for more information.
    2. Since parallel trace port data is DDR, the trace clock received by PhyWhisperer
       goes to a PLL which has a published minimum of 10 MHz, which means
       that the target clock must be at least 20 MHz.


To learn more, refer to the [DesignStartTrace README](../../README.md).

## Trace Port Connections

If using parallel trace, five pins must be connected from the trace target
to the front side 20-pin connector of PhyWhisperer-USB in order to supply it
with trace data:
- trace clock: to CK pin
- trace data[3]: to D7 pin
- trace data[2]: to D6 pin
- trace data[1]: to D5 pin
- trace data[0]: to D4 pin

If using SWO, three pins must be connected:
- SWDIO/TMS to D0 pin
- SWCLK/TCLK to D1 pin
- SWO/TDO to D2 pin

Additionally, if the target-generated trigger is to be used to trigger trace
collection, then the target trigger must be connected to the "PC" pin of the
20-pin connector on the side of PhyWhisperer-USB.

Finally, the target clock can be connected to the 'HS2" ping of the side 20-pin
connector. This is highly recommended for SWO mode, to allow for synchronous
trace data capture (see [clocks.md](clocks.md) for more information on this).
The target clock may also be used for parallel trace, although it does not
provide any advantages over the trace clock.

## Implementation Details
[This page](clocks.md) has details on internal clocking, which is needed to
understand the time relationship between power traces and debug traces.

[This page](FIFO_reads.md) has low-level details on how captured trace data
is stored and retrieved from the FPGA.



