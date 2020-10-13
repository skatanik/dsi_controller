set_global_assignment -entity "test" -library "lib_test" -name IP_TOOL_NAME "altera_gpio_lite"
set_global_assignment -entity "test" -library "lib_test" -name IP_TOOL_VERSION "18.0"
set_global_assignment -entity "test" -library "lib_test" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_test" -name SPD_FILE [file join $::quartus(sip_path) "test.spd"]

set_global_assignment -library "lib_test" -name MISC_FILE [file join $::quartus(sip_path) "test_sim/test.v"]
set_global_assignment -library "lib_test" -name MISC_FILE [file join $::quartus(sip_path) "test_sim/altera_gpio_lite/altera_gpio_lite.sv"]
