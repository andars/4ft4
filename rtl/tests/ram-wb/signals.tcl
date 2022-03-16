set signals [list]

lappend signals "clock"
lappend signals "reset"
lappend signals "cycle"
lappend signals "wb_cyc_i"
lappend signals "wb_strobe_i"
lappend signals "wb_we_i"
lappend signals "wb_addr_i"
lappend signals "wb_data_i"
lappend signals "wb_data_o"
lappend signals "memory\[0\]\[3:0\]"
lappend signals "memory\[1\]\[3:0\]"
lappend signals "memory\[16\]\[3:0\]"
lappend signals "status\[0\]\[3:0\]"
lappend signals "status\[1\]\[3:0\]"
lappend signals "status\[2\]\[3:0\]"

set num_added [ gtkwave::addSignalsFromList $signals ]
