# TraceWhisperer

TraceWhisperer is a trace sniffer, originally developed for the CW305
DesignStart target, then ported to the PhyWhisperer-USB platform. The "trace"
we're talking about here is Coresight processor trace data (ETM, DWT, ITM)
that can be output by Arm Cortex processors via their parallel trace port.
One target with this trace port is our [K82F
target](https://rtfm.newae.com/Targets/UFO%20Targets/CW308T-K82/), but it
should be possible to use TraceWhisperer with any target that has a trace
port. 

Currently, TraceWhisperer supports 4-bit wide trace ports only, but adding
support for other widths should be fairly easy.

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
    1. Activity on the trace pins adds significant noise to the side-channel
       power measurements. See [this note](trace_noise.md) for more
       information.
    2. Since trace data is DDR, the trace clock received by PhyWhisperer
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
ChipWhisperer connector on the side of PhyWhisperer-USB.

## Implementation Details
[This page](FIFO_reads.md) has low-level details on how captured trace data
is stored and retrieved from the FPGA.

