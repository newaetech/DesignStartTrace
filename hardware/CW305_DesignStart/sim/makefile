LOGFILE=make.log
WAVEFORMAT=fst
SEED=1
RULES=8
EVENTS=3
DUMP=0

all: testcase compile run

testcase:
	python3 gen_trace_data.py --seed $(SEED) --rules $(RULES) --events $(EVENTS)

compile:
	iverilog -ccmdfile \
	-g2005-sv \
	-Wportbind \
	-Wselect-range \
	-I../hdl \
	-I../../phywhisperer/software/phywhisperer/firmware \
	-P tb.pDUMP=$(DUMP) \

nofifo:
	iverilog -ccmdfile_nofifo \
	-g2005-sv \
	-Wportbind \
	-Wselect-range \
	-I../hdl \
	-I../../phywhisperer/software/phywhisperer/firmware \
	-DNOFIFO \

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
