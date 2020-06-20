LOGFILE=make.log
WAVEFORMAT=fst

all: compile run

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
