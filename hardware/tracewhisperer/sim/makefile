LOGFILE=make.log
EXEFILE=a.out
RUNDIR=rundir
WAVEFORMAT=fst
SEED=1
RULES=8
EVENTS=3
CAPTURE_RAW = 0
CAPTURE_NOW = 0
PATTERN_TRIG = 0
SWO_MODE = 0
SWO_DIV = 3
USB_CLOCK_PERIOD = 12
TARGET_CLOCK_TRACE_PERIOD = 168
TARGET_CLOCK_SWO_PERIOD = 0
TRIGGER_CLOCK_PERIOD = 0
TRACE_CLOCK_SEL = 0
USB_CLOCK_SEL = 0
LONGCORNER = 0
TIMESTAMPS_DISABLED = 0
MAX_TIMESTAMP = 65535
TIMEOUT= 30000
DUMP=0


all: testcase compile run

testcase:
	python3 ../../CW305_DesignStart/sim/gen_trace_data.py --seed $(SEED) --rules $(RULES) --events $(EVENTS) \
	--raw $(CAPTURE_RAW) --patterntrig $(PATTERN_TRIG) --swo_mode $(SWO_MODE) --capturenow $(CAPTURE_NOW) \
	--longcorner $(LONGCORNER) --traceclock $(TRACE_CLOCK_SEL) --usb_clock_period $(USB_CLOCK_PERIOD) \
	--target_clock_trace_period $(TARGET_CLOCK_TRACE_PERIOD) \
	--target_clock_swo_period $(TARGET_CLOCK_SWO_PERIOD) \
	--usb_clock_sel $(USB_CLOCK_SEL) --rundir $(RUNDIR)

compile:
	iverilog -ccmdfile \
	-g2005-sv \
	-Wportbind \
	-Wselect-range \
	-I$(RUNDIR) \
	-I../../CW305_DesignStart/hdl \
	-I../../phywhisperer/software/phywhisperer/firmware \
	-P tb.pDUMP=$(DUMP) \
	-P tb.pSEED=$(SEED) \
	-P tb.pSWO_MODE=$(SWO_MODE) \
	-P tb.pSWO_DIV=$(SWO_DIV) \
	-P tb.pUSB_CLOCK_PERIOD=$(USB_CLOCK_PERIOD) \
	-P tb.pTARGET_CLOCK_TRACE_PERIOD=$(TARGET_CLOCK_TRACE_PERIOD) \
	-P tb.pTARGET_CLOCK_SWO_PERIOD=$(TARGET_CLOCK_SWO_PERIOD) \
	-P tb.pTRIGGER_CLOCK_PERIOD=$(TRIGGER_CLOCK_PERIOD) \
	-P tb.pTRACE_CLOCK_SEL=$(TRACE_CLOCK_SEL) \
	-P tb.pUSB_CLOCK_SEL=$(USB_CLOCK_SEL) \
	-P tb.pLONGCORNER=$(LONGCORNER) \
	-P tb.pCAPTURE_RAW=$(CAPTURE_RAW) \
	-P tb.pPATTERN_TRIG=$(PATTERN_TRIG) \
	-P tb.pTIMEOUT=$(TIMEOUT) \
	-P tb.pCAPTURE_NOW=$(CAPTURE_NOW) \
	-P tb.pTIMESTAMPS_DISABLED=$(TIMESTAMPS_DISABLED) \
	-P tb.pMAX_TIMESTAMP=$(MAX_TIMESTAMP) \
	-o $(RUNDIR)/$(EXEFILE) \

nofifo:
	iverilog -ccmdfile_nofifo \
	-g2005-sv \
	-Wportbind \
	-Wselect-range \
	-I../../CW305_DesignStart/hdl \
	-I../../phywhisperer/software/phywhisperer/firmware \
	-DNOFIFO \

lint:
	verilator --lint-only -Wall \
	-Wno-PINCONNECTEMPTY \
	-f cmdfile_nofifo \
	-I../../CW305_DesignStart/hdl \
	-I../../phywhisperer/software/phywhisperer/firmware \
	-D__ICARUS__ \
	-DNOFIFO \
	--top-module tracewhisperer_top \
	2>&1 | tee lint.out \

nofifo_swo_only:
	iverilog -ccmdfile_swo_only_nofifo \
	-g2005-sv \
	-Wportbind \
	-Wselect-range \
	-I../../CW305_DesignStart/hdl \
	-I../../phywhisperer/software/phywhisperer/firmware \
	-DNOFIFO \

run:
	cd $(RUNDIR) && vvp -l../$(LOGFILE) $(EXEFILE) -$(WAVEFORMAT)

clean:
	rm -f a.out run_*/*.vvp
