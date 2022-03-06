VERILATOR ?= /home/andrew/verilator/bin/verilator

.PHONY: waves sim lint

ROM_BIN ?= ../build/ram/1.bin

CPU_FILES = cpu.v cpu_control.v pc_stack.v datapath.v alu.v
SYSTEM_FILES = $(CPU_FILES) system.v rom.v ram.v

waves: sim
	gtkwave waves.vcd -S signals.tcl #--rcvar 'do_initial_zoom_fit yes'

# TODO: fix rom sizing issues here - shell evaluated before rom changes?
sim: lint
	xxd -l4096 -p -c1 $(ROM_BIN) > rom.hex
	cat rom.hex
	iverilog -DROM_SIZE=$(firstword $(shell wc -l rom.hex)) tb_system.sv $(SYSTEM_FILES)
	./a.out

lint:
	$(VERILATOR) --lint-only --top-module system $(SYSTEM_FILES)

TEST_SOURCES := $(sort $(shell find ../tests -name '*.s' | grep -v -f skip.txt))
$(info skipping $(shell find ../tests -name '*.s' | grep -f skip.txt))
TEST_BINARIES := $(patsubst ../tests/%.s,../build/%.bin,$(TEST_SOURCES))
TEST_RUNS := $(patsubst ../build/%.bin,testruns/%.log,$(TEST_BINARIES))
TEST_HEX := $(patsubst testruns/%.log,testruns/%.hex,$(TEST_RUNS))
TEST_WAVES := $(patsubst testruns/%.log,testruns/%.waves,$(TEST_RUNS))
$(info $(TEST_SOURCES))
$(info "")
$(info $(TEST_BINARIES))
$(info "")
$(info $(TEST_RUNS))

$(TEST_HEX): testruns/%.hex: ../build/%.bin
	@echo "Generating hex for $*"
	mkdir -p $(@D)
	xxd -l4096 -p -c1 $(word 1,$^) > $@

$(TEST_RUNS): lint

.PHONY: $(TEST_RUNS)
$(TEST_RUNS): testruns/%.log: ../build/%.bin ../tests/%.s testruns/%.hex
	mkdir -p $(@D)
	iverilog -DROM_SIZE=$(firstword $(shell wc -l testruns/$*.hex)) tb_system.sv $(SYSTEM_FILES)
	cp $(word 3,$^) rom.hex
	./a.out > $@
	mv waves.vcd testruns/$*.vcd
	bash ./check.sh $(word 2,$^) $@ #|| (cat $@; echo "test $(word 2,$^) failed: $@"; exit 1)

.PHONY: $(TEST_WAVES)
$(TEST_WAVES): testruns/%.waves: |testruns/%.log
	gtkwave testruns/$*.vcd -S signals.tcl #--rcvar 'do_initial_zoom_fit yes'

.PHONY: test
test: $(TEST_RUNS)
