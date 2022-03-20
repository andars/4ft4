SELF:=$(lastword $(MAKEFILE_LIST))
ROOT=$(realpath $(dir $(SELF))/../..)

TOPLEVEL_LANG = verilog
_VERILOG_SOURCES = wb_system.v rom.v ram.v \
                   alu.v datapath.v \
                   pc_stack.v \
                   cpu_control.v cpu.v
VERILOG_SOURCES = $(_VERILOG_SOURCES:%=$(ROOT)/%)

COMPILE_ARGS += -I$(ROOT)
COMPILE_ARGS += -DCOCOTB_SIM_WB_SYSTEM_TOP
COMPILE_ARGS += -DROM_FILE_BASE=\"\"

TOPLEVEL = wb_system
MODULE = tests
export PYTHONPATH:=$(dir $(SELF)):$(PYTHONPATH)

include $(shell cocotb-config --makefiles)/Makefile.sim
