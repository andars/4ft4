SELF:=$(lastword $(MAKEFILE_LIST))
ROOT=$(realpath $(dir $(SELF))/../..)

TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(ROOT)/rom.v

TOPLEVEL = rom
MODULE = tests
export PYTHONPATH:=$(dir $(SELF)):$(PYTHONPATH)

COMPILE_ARGS += -DCOCOTB_SIM_ROM_TOP

include $(shell cocotb-config --makefiles)/Makefile.sim
