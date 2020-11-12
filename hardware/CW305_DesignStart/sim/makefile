LOGFILE=make.log
WAVEFORMAT=fst
SEED=1
RULES=8
EVENTS=3
CAPTURE_RAW=0
PATTERN_TRIG = 0
TIMEOUT=100000
DUMP=0

all: testcase compile run

testcase:
	python3 gen_trace_data.py --seed $(SEED) --rules $(RULES) --events $(EVENTS) \
	--raw $(CAPTURE_RAW) --patterntrig $(PATTERN_TRIG)

compile:
	iverilog -ccmdfile \
	-g2005-sv \
	-Wportbind \
	-Wselect-range \
	-I../hdl \
	-I../../phywhisperer/software/phywhisperer/firmware \
	-P tb.pDUMP=$(DUMP) \
	-P tb.pSEED=$(SEED) \
	-P tb.pCAPTURE_RAW=$(CAPTURE_RAW) \
	-P tb.pPATTERN_TRIG=$(PATTERN_TRIG) \
	-P tb.pTIMEOUT=$(TIMEOUT) \
	-DCW305 \

nofifo:
	iverilog -ccmdfile_nofifo \
	-g2005-sv \
	-Wportbind \
	-Wselect-range \
	-I../hdl \
	-I../../phywhisperer/software/phywhisperer/firmware \
	-DNOFIFO \
	-DCW305 \

traceonly:
	iverilog -ccmdfile_traceonly \
	-g2005-sv \
	-Wportbind \
	-Wselect-range \
	-I../hdl \
	-I../../phywhisperer/software/phywhisperer/firmware \

run:
	vvp -l$(LOGFILE) a.out -$(WAVEFORMAT)

clean:
	rm -f a.out
