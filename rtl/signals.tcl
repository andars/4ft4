set signals [list]
lappend signals "clock"
lappend signals "sync"
lappend signals "cycle_counter"
lappend signals "data"
lappend signals "reset"
set num_added [ gtkwave::addSignalsFromList $signals ]
