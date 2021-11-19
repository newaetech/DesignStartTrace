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
	-I../../phywhisperer/software/phywhisperer/firmware \
	-P tb.pDUMP=$(DUMP) \
	-P tb.pSEED=$(SEED) \
	-P tb.pCAPTURE_RAW=$(CAPTURE_RAW) \
	-P tb.pPATTERN_TRIG=$(PATTERN_TRIG) \
	-P tb.pTIMEOUT=$(TIMEOUT) \
        -P tb.pCAPTURE_NOW=$(CAPTURE_NOW) \
        -P tb.pMAX_TIMESTAMP=$(MAX_TIMESTAMP) \
	-DCW305 \
	-o $(RUNDIR)/$(EXEFILE) \

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
	cd $(RUNDIR) && vvp -l../$(LOGFILE) $(EXEFILE) -$(WAVEFORMAT)

clean:
	rm -f a.out
