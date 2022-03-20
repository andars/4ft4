SELF:=$(lastword $(MAKEFILE_LIST))
ROOT=$(realpath $(dir $(SELF))/../..)

TOPLEVEL_LANG = verilog
_VERILOG_SOURCES = icebreaker_top.v \
                   wb_system.v rom.v ram.v \
                   alu.v datapath.v \
                   pc_stack.v \
                   cpu_control.v cpu.v \
                   spoke/uart.v spoke/uart_wb_master.v
VERILOG_SOURCES = $(_VERILOG_SOURCES:%=$(ROOT)/%)

TOPLEVEL = icebreaker_top
MODULE = tests
export PYTHONPATH:=$(dir $(SELF)):$(PYTHONPATH)

COMPILE_ARGS += -I$(ROOT)
COMPILE_ARGS += -DCOCOTB_SIM_ICEBREAKER_TOP
COMPILE_ARGS += -DROM_FILE_BASE=\"$(dir $(SELF))/rom\"

include $(shell cocotb-config --makefiles)/Makefile.sim
