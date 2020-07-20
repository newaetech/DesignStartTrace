LOGFILE=make.log
WAVEFORMAT=fst
SEED=1

all: testcase compile run

testcase:
	python3 gen_trace_data.py --seed $(SEED)

compile:
	iverilog -ccmdfile \
	-g2005-sv \
	-Wportbind \
	-Wselect-range \
	-I../hdl \
	-I../../phywhisperer/software/phywhisperer/firmware \

nofifo:
	iverilog -ccmdfile_nofifo \
	-g2005-sv \
	-Wportbind \
	-Wselect-range \
	-I../hdl \
	-I../../phywhisperer/software/phywhisperer/firmware \
	-DNOFIFO \

run:
	vvp -l$(LOGFILE) a.out -$(WAVEFORMAT)

clean:
	rm -f a.out
