LOGFILE=make.log
EXEFILE=a.out
RUNDIR=rundir
WAVEFORMAT=fst
SEED=1
RULES=8
EVENTS=3
CAPTURE_RAW=0
CAPTURE_NOW = 0
PATTERN_TRIG = 0
SWO_MODE = 0
TRACE_CLOCK_SEL = 0
USB_CLOCK_PERIOD = 12
TARGET_CLOCK_TRACE_PERIOD = 168
TARGET_CLOCK_SWO_PERIOD = 10
TRIGGER_CLOCK_PERIOD = 10
MAX_TIMESTAMP = 65535
TIMEOUT=100000
DUMP=0

all: testcase compile run

testcase:
	python3 gen_trace_data.py --seed $(SEED) --rules $(RULES) --events $(EVENTS) \
	--raw $(CAPTURE_RAW) --patterntrig $(PATTERN_TRIG) --swo_mode $(SWO_MODE) --cw305 1 --capturenow $(CAPTURE_NOW) \
	--rundir $(RUNDIR)

compile:
	iverilog -ccmdfile \
	-g2005-sv \
	-Wportbind \
	-Wselect-range \
	-I$(RUNDIR) \
	-I../hdl \
	-P tb.pDUMP=$(DUMP) \
	-P tb.pSEED=$(SEED) \
	-P tb.pCAPTURE_RAW=$(CAPTURE_RAW) \
	-P tb.pPATTERN_TRIG=$(PATTERN_TRIG) \
	-P tb.pTIMEOUT=$(TIMEOUT) \
        -P tb.pCAPTURE_NOW=$(CAPTURE_NOW) \
        -P tb.pMAX_TIMESTAMP=$(MAX_TIMESTAMP) \
	-P tb.pUSB_CLOCK_PERIOD=$(USB_CLOCK_PERIOD) \
	-P tb.pTARGET_CLOCK_TRACE_PERIOD=$(TARGET_CLOCK_TRACE_PERIOD) \
	-P tb.pTARGET_CLOCK_SWO_PERIOD=$(TARGET_CLOCK_SWO_PERIOD) \
	-P tb.pSWO_MODE=$(SWO_MODE) \
	-P tb.pTRACE_CLOCK_SEL=$(TRACE_CLOCK_SEL) \
	-P tb.pTRIGGER_CLOCK_PERIOD=$(TRIGGER_CLOCK_PERIOD) \
	-DCW305 \
	-o $(RUNDIR)/$(EXEFILE) \

nofifo:
	iverilog -ccmdfile_nofifo \
	-g2005-sv \
	-Wportbind \
	-Wselect-range \
	-I../hdl \
	-DNOFIFO \
	-DLINT \
	-DCW305 \

lint:
	verilator --lint-only -Wall \
	-Wno-PINCONNECTEMPTY \
	-f cmdfile_nofifo \
	-I../hdl \
	-D__ICARUS__ \
	-DNOFIFO \
	-DCW305 \
	-DLINT \
	--top-module CW305_designstart_top \
	2>&1 | tee lint.out \

traceonly:
	iverilog -ccmdfile_traceonly \
	-g2005-sv \
	-Wportbind \
	-Wselect-range \
	-I../hdl \

run:
	cd $(RUNDIR) && vvp -l../$(LOGFILE) $(EXEFILE) -$(WAVEFORMAT)

clean:
	rm -f a.out
