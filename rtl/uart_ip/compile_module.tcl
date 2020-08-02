puts [pwd]

vlog -v -incr -work work $defines $include_dir "$file_path/uart_regs.v"
vlog -v -incr -work work $defines $include_dir "$file_path/uart_wrapper.v"
vlog -v -incr -work work $defines $include_dir "$file_path/verilog-uart/rtl/uart.v"
vlog -v -incr -work work $defines $include_dir "$file_path/verilog-uart/rtl/uart_rx.v"
vlog -v -incr -work work $defines $include_dir "$file_path/verilog-uart/rtl/uart_tx.v"
