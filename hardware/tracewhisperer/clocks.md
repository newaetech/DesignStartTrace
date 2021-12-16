# TraceWhisperer Clocking

In order to overlay debug trace information onto power traces, the
relationship between the two different time bases must be understood.

With the usual synchronous clocking of the target, there are only two
options for the power trace: samples are either 4x per clock cycle or 1x per
clock cycle. Simple enough.

For debug traces, it can be a bit more complicated. 

The parallel trace case is simple: the parallel trace data can be clocked by
either the trace clock or the target clock. In either case, this is
synchronous to the clock used for power samples, so the timing relationship
between power samples and trace data is straightforward.

The SWO case can be more complicated. Ideally, the target clock is used as
the front-end clock; in this case we have the same situation as the parallel
trace case. But if for some reason the target clock cannot be used, we need
to use the 96 MHz USB clock.

Since the front-end clock is no longer directly tied to the target sampling
clock, the relationship between those two clocks must be calculated.  [This
notebook](https://github.com/newaetech/DesignStartTrace/blob/master/jupyter/TraceWhisperer.ipynb)
shows a worked-out example of calculating the relationship between the
collected trace debug timestamps and the power trace.

This figure shows how clocks are managed internally in the PhyWhisperer:
![picture](images/tracewhisperer_clocks.svg)

