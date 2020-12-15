LOGFILE=make.log
WAVEFORMAT=fst
SEED=1
RULES=8
EVENTS=3
CAPTURE_RAW=0
CAPTURE_NOW = 0
PATTERN_TRIG = 0
SWO_MODE = 0
TIMESTAMPS_DISABLED = 0
TIMEOUT= 100000
DUMP=0

all: testcase compile run

testcase:
	python3 ../../CW305_DesignStart/sim/gen_trace_data.py --seed $(SEED) --rules $(RULES) --events $(EVENTS) \
	--raw $(CAPTURE_RAW) --patterntrig $(PATTERN_TRIG) --swo_mode $(SWO_MODE) --capturenow $(CAPTURE_NOW)

compile:
	iverilog -ccmdfile \
	-g2005-sv \
	-Wportbind \
	-Wselect-range \
	-I../../CW305_DesignStart/hdl \
	-I../../phywhisperer/software/phywhisperer/firmware \
	-P tb.pDUMP=$(DUMP) \
	-P tb.pSEED=$(SEED) \
	-P tb.pSWO_MODE=$(SWO_MODE) \
	-P tb.pCAPTURE_RAW=$(CAPTURE_RAW) \
	-P tb.pPATTERN_TRIG=$(PATTERN_TRIG) \
	-P tb.pTIMEOUT=$(TIMEOUT) \
        -P tb.pCAPTURE_NOW=$(CAPTURE_NOW) \
        -P tb.pTIMESTAMPS_DISABLED=$(TIMESTAMPS_DISABLED) \

nofifo:
	iverilog -ccmdfile_nofifo \
	-g2005-sv \
	-Wportbind \
	-Wselect-range \
	-I../../CW305_DesignStart/hdl \
	-I../../phywhisperer/software/phywhisperer/firmware \
	-DNOFIFO \

nofifo_swo_only:
	iverilog -ccmdfile_swo_only_nofifo \
	-g2005-sv \
	-Wportbind \
	-Wselect-range \
	-I../../CW305_DesignStart/hdl \
	-I../../phywhisperer/software/phywhisperer/firmware \
	-DNOFIFO \


run:
	vvp -l$(LOGFILE) a.out -$(WAVEFORMAT)

clean:
	rm -f a.out
