VERILATOR ?= /home/andrew/verilator/bin/verilator

.PHONY: cpu-sim lint

CPU_FILES = cpu.v cpu_control.v pc_stack.v
SYSTEM_FILES = $(CPU_FILES) system.v rom.v

sim: lint
	iverilog tb_system.sv $(SYSTEM_FILES)
	./a.out
	gtkwave waves.vcd -S signals.tcl #--rcvar 'do_initial_zoom_fit yes'

lint:
	$(VERILATOR) --lint-only --top-module system $(SYSTEM_FILES)


