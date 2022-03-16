set signals [list]

lappend signals "clock"
lappend signals "reset"
lappend signals "cycle"
lappend signals "cyc_i"
lappend signals "strobe_i"
lappend signals "we_i"
lappend signals "addr_i"
lappend signals "data_i"
lappend signals "data_o"
lappend signals "memory\[0\]\[3:0\]"
lappend signals "memory\[1\]\[3:0\]"
lappend signals "memory\[16\]\[3:0\]"
lappend signals "status\[0\]\[3:0\]"
lappend signals "status\[1\]\[3:0\]"
lappend signals "status\[2\]\[3:0\]"

set num_added [ gtkwave::addSignalsFromList $signals ]
