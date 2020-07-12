LOGFILE=make.log
WAVEFORMAT=fst

all: testcase compile run

testcase:
	python3 gen_trace_data.py

compile:
	iverilog -ccmdfile \
	-g2005-sv \
	-Wportbind \
	-Wselect-range \
	-I../hdl \

run:
	vvp -l$(LOGFILE) a.out -$(WAVEFORMAT)

clean:
	rm -f a.out
