COMPILE_SRC := $(wildcard *.v) $(wildcard *.sv)
INCLUDE_DIR := -I../../common/

all: compile sim

compile:
	iverilog \
	$(COMPILE_SRC) \
	$(INCLUDE_DIR) \
	-g2012 \
	-o sim_out



sim:
	vvp sim_out
