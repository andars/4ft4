VERILATOR ?= /home/andrew/verilator/bin/verilator

.PHONY: waves sim lint

CPU_FILES = cpu.v cpu_control.v pc_stack.v datapath.v
SYSTEM_FILES = $(CPU_FILES) system.v rom.v

waves: sim
	gtkwave waves.vcd -S signals.tcl #--rcvar 'do_initial_zoom_fit yes'

sim: lint
	iverilog tb_system.sv $(SYSTEM_FILES)
	./a.out

lint:
	$(VERILATOR) --lint-only --top-module system $(SYSTEM_FILES)


