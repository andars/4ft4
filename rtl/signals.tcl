set signals [list]

lappend signals "clock"
lappend signals "sync"
lappend signals "cycle_counter"
lappend signals "data"
lappend signals "reset"
lappend signals "accumulator"
lappend signals "carry"
lappend signals "two_word"
lappend signals "tb_system.dut.cpu.pc_stack.\\program_counters\[0\]\[11:0\]"
lappend signals "tb_system.dut.cpu.pc_stack.\\program_counters\[1\]\[11:0\]"
lappend signals "tb_system.dut.cpu.pc_stack.\\program_counters\[2\]\[11:0\]"
lappend signals "tb_system.dut.cpu.pc_stack.\\program_counters\[3\]\[11:0\]"
lappend signals "tb_system.dut.cpu.pc_stack.index"
lappend signals "tb_system.dut.cpu.datapath.\\registers\[0\]\[3:0\]"
lappend signals "tb_system.dut.cpu.datapath.\\registers\[1\]\[3:0\]"
lappend signals "tb_system.dut.cpu.datapath.\\registers\[2\]\[3:0\]"
lappend signals "tb_system.dut.cpu.datapath.\\registers\[3\]\[3:0\]"
lappend signals "tb_system.dut.cpu.datapath.\\registers\[4\]\[3:0\]"
lappend signals "tb_system.dut.cpu.datapath.\\registers\[5\]\[3:0\]"
lappend signals "tb_system.dut.cpu.datapath.\\registers\[6\]\[3:0\]"
lappend signals "tb_system.dut.cpu.datapath.\\registers\[7\]\[3:0\]"
lappend signals "tb_system.dut.cpu.datapath.\\registers\[8\]\[3:0\]"
lappend signals "tb_system.dut.cpu.datapath.\\registers\[9\]\[3:0\]"
lappend signals "tb_system.dut.cpu.datapath.\\registers\[10\]\[3:0\]"
lappend signals "tb_system.dut.cpu.datapath.\\registers\[11\]\[3:0\]"
lappend signals "tb_system.dut.cpu.datapath.\\registers\[12\]\[3:0\]"
lappend signals "tb_system.dut.cpu.datapath.\\registers\[13\]\[3:0\]"
lappend signals "tb_system.dut.cpu.datapath.\\registers\[14\]\[3:0\]"
lappend signals "tb_system.dut.cpu.datapath.\\registers\[15\]\[3:0\]"
lappend signals "tb_system.dut.cpu.datapath.take_branch"

set num_added [ gtkwave::addSignalsFromList $signals ]

gtkwave::setBaselineMarker 30
gtkwave::setMarker 190
gtkwave::/View/Define_Time_Ruler_Marks
gtkwave::/View/Show_Grid
gtkwave::setBaselineMarker -1
gtkwave::setMarker -1
