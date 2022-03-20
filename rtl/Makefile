VERILATOR ?= /home/andrew/verilator/bin/verilator

.PHONY: waves sim lint

ROM_BIN ?= ../build/ram/1.bin

CPU_FILES = cpu.v cpu_control.v pc_stack.v datapath.v alu.v
SYSTEM_FILES = $(CPU_FILES) system.v rom.v ram.v
WB_SYSTEM_FILES = $(CPU_FILES) wb_system.v ram.v rom.v

waves: sim
	gtkwave waves.vcd -S signals.tcl #--rcvar 'do_initial_zoom_fit yes'

# TODO: fix rom sizing issues here - shell evaluated before rom changes?
sim: lint
	xxd -l4096 -p -c1 $(ROM_BIN) > rom.hex
	cat rom.hex
	awk 'BEGIN{c=0} NR%256==0{++c}{print $0 > "rom_"c".hex"}' rom.hex
	iverilog -DROM_SIZE=$(firstword $(shell wc -l rom.hex)) tb_system.sv $(SYSTEM_FILES)
	./a.out

LINT_OPTS = -Wall -Wno-PINCONNECTEMPTY

#TODO: clean up these warnings
LINT_OPTS += -Wno-UNUSED -Wno-UNDRIVEN -DROM_FILE_BASE=\"rom.hex\"
LINT_OPTS += --unroll-count 256

lint:
	$(VERILATOR) --lint-only --top-module system $(SYSTEM_FILES)
	$(VERILATOR) $(LINT_OPTS) --lint-only --top-module wb_system wb_system.v $(SYSTEM_FILES)
	$(VERILATOR) -DNO_TRISTATE --lint-only --top-module system $(SYSTEM_FILES)
	$(VERILATOR) $(LINT_OPTS) -DNO_TRISTATE --lint-only --top-module wb_system wb_system.v $(SYSTEM_FILES)

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
	iverilog -DNO_TRISTATE -DROM_SIZE=$(firstword $(shell wc -l testruns/$*.hex)) tb_system.sv $(SYSTEM_FILES)
	cp $(word 3,$^) rom.hex
	split -d -a 1 -l 256 --additional-suffix=".hex" rom.hex "rom_"
	./a.out > $@
	mv waves.vcd testruns/$*.vcd
	bash ./check.sh $(word 2,$^) $@ #|| (cat $@; echo "test $(word 2,$^) failed: $@"; exit 1)

.PHONY: $(TEST_WAVES)
$(TEST_WAVES): testruns/%.waves: |testruns/%.log
	gtkwave testruns/$*.vcd -S signals.tcl #--rcvar 'do_initial_zoom_fit yes'

.PHONY: test
test: $(TEST_RUNS)

_out/%_0.hex: %.s
	../as.py $< _out/$*.s.o
	xxd -l4096 -p -c1 _out/$*.s.o > $@.full
	split -d -a 1 -l 256 --additional-suffix=".hex" $@.full "_out/$*_"

define ICE40_RULES
_out/$(strip $1).bin: _out/$(strip $1).asc _out/$(strip $1)_timing.txt
	icepack $$< $$@

_out/$(strip $1)_timing.txt: _out/$(strip $1).asc
	icetime -d up5k -c 12 -mtr $$@ $$<

_out/$(strip $1).asc: _out/$(strip $1).json $(strip $1)-pins.pcf
	nextpnr-ice40 -ql _out/$(strip $1).nplog --up5k --package sg48 --freq 12 --asc $$@ --pcf $(strip $1)-pins.pcf --pcf-allow-unconstrained --json $$<

_out/$(strip $1).json: $2 _out/icebreaker_top_0.hex | $3
	yosys -DNO_TRISTATE -DNO_RAM_RESET -DROM_CAPACITY=128 -DROM_FILE_BASE=\"_out/icebreaker_top\" -ql _out/$(strip $1).yslog -p 'synth_ice40 -top $(strip $1) -json $$@' $2
endef

ICEBREAKER_TOP_FILES = $(WB_SYSTEM_FILES) icebreaker_top.v spoke/uart.v spoke/uart_wb_master.v

$(eval $(call ICE40_RULES, icebreaker_top, $(ICEBREAKER_TOP_FILES), lint))
