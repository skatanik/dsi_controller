
# (C) 2001-2019 Altera Corporation. All rights reserved.
# Your use of Altera Corporation's design tools, logic functions and 
# other software and tools, and its AMPP partner logic functions, and 
# any output files any of the foregoing (including device programming 
# or simulation files), and any associated documentation or information 
# are expressly subject to the terms and conditions of the Altera 
# Program License Subscription Agreement, Altera MegaCore Function 
# License Agreement, or other applicable license agreement, including, 
# without limitation, that your use is for the sole purpose of 
# programming logic devices manufactured by Altera and sold by Altera 
# or its authorized distributors. Please refer to the applicable 
# agreement for further details.

# ACDS 18.0 614 win32 2019.03.26.23:41:14

# ----------------------------------------
# vcsmx - auto-generated simulation script

# ----------------------------------------
# This script provides commands to simulate the following IP detected in
# your Quartus project:
#     top_level_system_tb
# 
# Altera recommends that you source this Quartus-generated IP simulation
# script from your own customized top-level script, and avoid editing this
# generated script.
# 
# To write a top-level shell script that compiles Altera simulation libraries 
# and the Quartus-generated IP in your project, along with your design and
# testbench files, copy the text from the TOP-LEVEL TEMPLATE section below
# into a new file, e.g. named "vcsmx_sim.sh", and modify text as directed.
# 
# You can also modify the simulation flow to suit your needs. Set the
# following variables to 1 to disable their corresponding processes:
# - SKIP_FILE_COPY: skip copying ROM/RAM initialization files
# - SKIP_DEV_COM: skip compiling the Quartus EDA simulation library
# - SKIP_COM: skip compiling Quartus-generated IP simulation files
# - SKIP_ELAB and SKIP_SIM: skip elaboration and simulation
# 
# ----------------------------------------
# # TOP-LEVEL TEMPLATE - BEGIN
# #
# # QSYS_SIMDIR is used in the Quartus-generated IP simulation script to
# # construct paths to the files required to simulate the IP in your Quartus
# # project. By default, the IP script assumes that you are launching the
# # simulator from the IP script location. If launching from another
# # location, set QSYS_SIMDIR to the output directory you specified when you
# # generated the IP script, relative to the directory from which you launch
# # the simulator. In this case, you must also copy the generated library
# # setup "synopsys_sim.setup" into the location from which you launch the
# # simulator, or incorporate into any existing library setup.
# #
# # Run Quartus-generated IP simulation script once to compile Quartus EDA
# # simulation libraries and Quartus-generated IP simulation files, and copy
# # any ROM/RAM initialization files to the simulation directory.
# #
# # - If necessary, specify any compilation options:
# #   USER_DEFINED_COMPILE_OPTIONS
# #   USER_DEFINED_VHDL_COMPILE_OPTIONS applied to vhdl compiler
# #   USER_DEFINED_VERILOG_COMPILE_OPTIONS applied to verilog compiler
# #
# source <script generation output directory>/synopsys/vcsmx/vcsmx_setup.sh \
# SKIP_ELAB=1 \
# SKIP_SIM=1 \
# USER_DEFINED_COMPILE_OPTIONS=<compilation options for your design> \
# USER_DEFINED_VHDL_COMPILE_OPTIONS=<VHDL compilation options for your design> \
# USER_DEFINED_VERILOG_COMPILE_OPTIONS=<Verilog compilation options for your design> \
# QSYS_SIMDIR=<script generation output directory>
# #
# # Compile all design files and testbench files, including the top level.
# # (These are all the files required for simulation other than the files
# # compiled by the IP script)
# #
# vlogan <compilation options> <design and testbench files>
# #
# # TOP_LEVEL_NAME is used in this script to set the top-level simulation or
# # testbench module/entity name.
# #
# # Run the IP script again to elaborate and simulate the top level:
# # - Specify TOP_LEVEL_NAME and USER_DEFINED_ELAB_OPTIONS.
# # - Override the default USER_DEFINED_SIM_OPTIONS. For example, to run
# #   until $finish(), set to an empty string: USER_DEFINED_SIM_OPTIONS="".
# #
# source <script generation output directory>/synopsys/vcsmx/vcsmx_setup.sh \
# SKIP_FILE_COPY=1 \
# SKIP_DEV_COM=1 \
# SKIP_COM=1 \
# TOP_LEVEL_NAME="'-top <simulation top>'" \
# QSYS_SIMDIR=<script generation output directory> \
# USER_DEFINED_ELAB_OPTIONS=<elaboration options for your design> \
# USER_DEFINED_SIM_OPTIONS=<simulation options for your design>
# #
# # TOP-LEVEL TEMPLATE - END
# ----------------------------------------
# 
# IP SIMULATION SCRIPT
# ----------------------------------------
# If top_level_system_tb is one of several IP cores in your
# Quartus project, you can generate a simulation script
# suitable for inclusion in your top-level simulation
# script by running the following command line:
# 
# ip-setup-simulation --quartus-project=<quartus project>
# 
# ip-setup-simulation will discover the Altera IP
# within the Quartus project, and generate a unified
# script which supports all the Altera IP within the design.
# ----------------------------------------
# ACDS 18.0 614 win32 2019.03.26.23:41:14
# ----------------------------------------
# initialize variables
TOP_LEVEL_NAME="top_level_system_tb"
QSYS_SIMDIR="./../../"
QUARTUS_INSTALL_DIR="C:/intelfpga_lite/18.0/quartus/"
SKIP_FILE_COPY=0
SKIP_DEV_COM=0
SKIP_COM=0
SKIP_ELAB=0
SKIP_SIM=0
USER_DEFINED_ELAB_OPTIONS=""
USER_DEFINED_SIM_OPTIONS="+vcs+finish+100"

# ----------------------------------------
# overwrite variables - DO NOT MODIFY!
# This block evaluates each command line argument, typically used for 
# overwriting variables. An example usage:
#   sh <simulator>_setup.sh SKIP_SIM=1
for expression in "$@"; do
  eval $expression
  if [ $? -ne 0 ]; then
    echo "Error: This command line argument, \"$expression\", is/has an invalid expression." >&2
    exit $?
  fi
done

# ----------------------------------------
# initialize simulation properties - DO NOT MODIFY!
ELAB_OPTIONS=""
SIM_OPTIONS=""
if [[ `vcs -platform` != *"amd64"* ]]; then
  :
else
  :
fi

# ----------------------------------------
# create compilation libraries
mkdir -p ./libraries/work/
mkdir -p ./libraries/altera_common_sv_packages/
mkdir -p ./libraries/error_adapter_0/
mkdir -p ./libraries/timing_adapter_0/
mkdir -p ./libraries/avalon_st_adapter/
mkdir -p ./libraries/crosser/
mkdir -p ./libraries/rsp_mux_001/
mkdir -p ./libraries/rsp_mux/
mkdir -p ./libraries/rsp_demux_005/
mkdir -p ./libraries/rsp_demux_004/
mkdir -p ./libraries/rsp_demux/
mkdir -p ./libraries/cmd_mux_004/
mkdir -p ./libraries/cmd_mux/
mkdir -p ./libraries/cmd_demux_001/
mkdir -p ./libraries/cmd_demux/
mkdir -p ./libraries/nios2_gen2_0_data_master_limiter/
mkdir -p ./libraries/router_006/
mkdir -p ./libraries/router_002/
mkdir -p ./libraries/router_001/
mkdir -p ./libraries/router/
mkdir -p ./libraries/jtag_uart_0_avalon_jtag_slave_agent_rsp_fifo/
mkdir -p ./libraries/jtag_uart_0_avalon_jtag_slave_agent/
mkdir -p ./libraries/nios2_gen2_0_data_master_agent/
mkdir -p ./libraries/jtag_uart_0_avalon_jtag_slave_translator/
mkdir -p ./libraries/nios2_gen2_0_data_master_translator/
mkdir -p ./libraries/cpu/
mkdir -p ./libraries/rst_controller/
mkdir -p ./libraries/irq_mapper/
mkdir -p ./libraries/mm_interconnect_0/
mkdir -p ./libraries/sysid_qsys_0/
mkdir -p ./libraries/onchip_memory2_0/
mkdir -p ./libraries/nios2_gen2_0/
mkdir -p ./libraries/jtag_uart_0/
mkdir -p ./libraries/dsi_tx_controller_0/
mkdir -p ./libraries/avl_st_vid_2_st_0/
mkdir -p ./libraries/altpll_0/
mkdir -p ./libraries/alt_vip_cl_tpg_0/
mkdir -p ./libraries/top_level_system_inst_reset_bfm/
mkdir -p ./libraries/top_level_system_inst_clk_bfm/
mkdir -p ./libraries/top_level_system_inst/
mkdir -p ./libraries/altera_ver/
mkdir -p ./libraries/lpm_ver/
mkdir -p ./libraries/sgate_ver/
mkdir -p ./libraries/altera_mf_ver/
mkdir -p ./libraries/altera_lnsim_ver/
mkdir -p ./libraries/fiftyfivenm_ver/

# ----------------------------------------
# copy RAM/ROM files to simulation directory
if [ $SKIP_FILE_COPY -eq 0 ]; then
  cp -f $QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0_cpu_bht_ram.dat ./
  cp -f $QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0_cpu_bht_ram.hex ./
  cp -f $QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0_cpu_bht_ram.mif ./
  cp -f $QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0_cpu_dc_tag_ram.dat ./
  cp -f $QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0_cpu_dc_tag_ram.hex ./
  cp -f $QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0_cpu_dc_tag_ram.mif ./
  cp -f $QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0_cpu_ic_tag_ram.dat ./
  cp -f $QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0_cpu_ic_tag_ram.hex ./
  cp -f $QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0_cpu_ic_tag_ram.mif ./
  cp -f $QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0_cpu_ociram_default_contents.dat ./
  cp -f $QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0_cpu_ociram_default_contents.hex ./
  cp -f $QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0_cpu_ociram_default_contents.mif ./
  cp -f $QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0_cpu_rf_ram_a.dat ./
  cp -f $QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0_cpu_rf_ram_a.hex ./
  cp -f $QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0_cpu_rf_ram_a.mif ./
  cp -f $QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0_cpu_rf_ram_b.dat ./
  cp -f $QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0_cpu_rf_ram_b.hex ./
  cp -f $QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0_cpu_rf_ram_b.mif ./
fi

# ----------------------------------------
# compile device library files
if [ $SKIP_DEV_COM -eq 0 ]; then
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives.v"                 -work altera_ver      
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QUARTUS_INSTALL_DIR/eda/sim_lib/220model.v"                          -work lpm_ver         
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate.v"                             -work sgate_ver       
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf.v"                         -work altera_mf_ver   
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_lnsim.sv"                     -work altera_lnsim_ver
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QUARTUS_INSTALL_DIR/eda/sim_lib/fiftyfivenm_atoms.v"                 -work fiftyfivenm_ver 
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QUARTUS_INSTALL_DIR/eda/sim_lib/synopsys/fiftyfivenm_atoms_ncrypt.v" -work fiftyfivenm_ver 
fi

# ----------------------------------------
# compile design files in correct order
if [ $SKIP_COM -eq 0 ]; then
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/verbosity_pkg.sv"                                                        -work altera_common_sv_packages                   
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_mm_interconnect_0_avalon_st_adapter_error_adapter_0.sv" -work error_adapter_0                             
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_avalon_st_adapter_timing_adapter_0.sv"                  -work timing_adapter_0                            
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_avalon_st_adapter_timing_adapter_0_fifo.sv"             -work timing_adapter_0                            
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_mm_interconnect_0_avalon_st_adapter.v"                  -work avalon_st_adapter                           
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/altera_avalon_st_handshake_clock_crosser.v"                              -work crosser                                     
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/altera_avalon_st_clock_crosser.v"                                        -work crosser                                     
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/altera_avalon_st_pipeline_base.v"                                        -work crosser                                     
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/altera_std_synchronizer_nocut.v"                                         -work crosser                                     
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_mm_interconnect_0_rsp_mux_001.sv"                       -work rsp_mux_001                                 
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/altera_merlin_arbitrator.sv"                                             -work rsp_mux_001                                 
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_mm_interconnect_0_rsp_mux.sv"                           -work rsp_mux                                     
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/altera_merlin_arbitrator.sv"                                             -work rsp_mux                                     
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_mm_interconnect_0_rsp_demux_005.sv"                     -work rsp_demux_005                               
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_mm_interconnect_0_rsp_demux_004.sv"                     -work rsp_demux_004                               
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_mm_interconnect_0_rsp_demux.sv"                         -work rsp_demux                                   
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_mm_interconnect_0_cmd_mux_004.sv"                       -work cmd_mux_004                                 
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/altera_merlin_arbitrator.sv"                                             -work cmd_mux_004                                 
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_mm_interconnect_0_cmd_mux.sv"                           -work cmd_mux                                     
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/altera_merlin_arbitrator.sv"                                             -work cmd_mux                                     
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_mm_interconnect_0_cmd_demux_001.sv"                     -work cmd_demux_001                               
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_mm_interconnect_0_cmd_demux.sv"                         -work cmd_demux                                   
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/altera_merlin_traffic_limiter.sv"                                        -work nios2_gen2_0_data_master_limiter            
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/altera_merlin_reorder_memory.sv"                                         -work nios2_gen2_0_data_master_limiter            
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/altera_avalon_sc_fifo.v"                                                 -work nios2_gen2_0_data_master_limiter            
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/altera_avalon_st_pipeline_base.v"                                        -work nios2_gen2_0_data_master_limiter            
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_mm_interconnect_0_router_006.sv"                        -work router_006                                  
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_mm_interconnect_0_router_002.sv"                        -work router_002                                  
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_mm_interconnect_0_router_001.sv"                        -work router_001                                  
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_mm_interconnect_0_router.sv"                            -work router                                      
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/altera_avalon_sc_fifo.v"                                                 -work jtag_uart_0_avalon_jtag_slave_agent_rsp_fifo
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/altera_merlin_slave_agent.sv"                                            -work jtag_uart_0_avalon_jtag_slave_agent         
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/altera_merlin_burst_uncompressor.sv"                                     -work jtag_uart_0_avalon_jtag_slave_agent         
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/altera_merlin_master_agent.sv"                                           -work nios2_gen2_0_data_master_agent              
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/altera_merlin_slave_translator.sv"                                       -work jtag_uart_0_avalon_jtag_slave_translator    
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/altera_merlin_master_translator.sv"                                      -work nios2_gen2_0_data_master_translator         
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0_cpu.vo"                                    -work cpu                                         
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0_cpu_debug_slave_sysclk.v"                  -work cpu                                         
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0_cpu_debug_slave_tck.v"                     -work cpu                                         
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0_cpu_debug_slave_wrapper.v"                 -work cpu                                         
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0_cpu_mult_cell.v"                           -work cpu                                         
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0_cpu_test_bench.v"                          -work cpu                                         
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/altera_reset_controller.v"                                               -work rst_controller                              
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/altera_reset_synchronizer.v"                                             -work rst_controller                              
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_avalon_st_adapter.v"                                    -work avalon_st_adapter                           
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_irq_mapper.sv"                                          -work irq_mapper                                  
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_mm_interconnect_0.v"                                    -work mm_interconnect_0                           
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_sysid_qsys_0.v"                                         -work sysid_qsys_0                                
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_onchip_memory2_0.v"                                     -work onchip_memory2_0                            
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_nios2_gen2_0.v"                                         -work nios2_gen2_0                                
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_jtag_uart_0.v"                                          -work jtag_uart_0                                 
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/altera_generic_fifo.v"                                                   -work dsi_tx_controller_0                         
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/avalon_mm_manager.v"                                                     -work dsi_tx_controller_0                         
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/crc_modules.v"                                                           -work dsi_tx_controller_0                         
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/sync_2ff.v"                                                              -work dsi_tx_controller_0                         
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/dphy_tx_hs_lane.sv"                                                      -work dsi_tx_controller_0                         
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/dphy_tx_lane_full.sv"                                                    -work dsi_tx_controller_0                         
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/dphy_tx_lanes_controller.sv"                                             -work dsi_tx_controller_0                         
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/dsi_tx_packets_assembler.v"                                              -work dsi_tx_controller_0                         
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/dsi_tx_pixel_buffer.v"                                                   -work dsi_tx_controller_0                         
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/dsi_tx_regs.v"                                                           -work dsi_tx_controller_0                         
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/dsi_tx_top.v"                                                            -work dsi_tx_controller_0                         
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/fifo_to_lane_bridge.sv"                                                  -work dsi_tx_controller_0                         
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/altera_gpio_lite.sv"                                                     -work dsi_tx_controller_0                         
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/bidir.v"                                                                 -work dsi_tx_controller_0                         
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/gpio.v"                                                                  -work dsi_tx_controller_0                         
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/lvds_soft.v"                                                             -work dsi_tx_controller_0                         
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/lvds_soft_0002.v"                                                        -work dsi_tx_controller_0                         
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/avalon_st_video_2_avalon_st.v"                                           -work avl_st_vid_2_st_0                           
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_altpll_0.vo"                                            -work altpll_0                                    
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system_alt_vip_cl_tpg_0.v"                                     -work alt_vip_cl_tpg_0                            
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/altera_avalon_reset_source.sv"                                           -work top_level_system_inst_reset_bfm             
  vlogan +v2k -sverilog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/altera_avalon_clock_source.sv"                                           -work top_level_system_inst_clk_bfm               
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/submodules/top_level_system.v"                                                      -work top_level_system_inst                       
  vlogan +v2k $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/top_level_system_tb/simulation/top_level_system_tb.v"                                                                                                                
fi

# ----------------------------------------
# elaborate top level design
if [ $SKIP_ELAB -eq 0 ]; then
  vcs -lca -t ps $ELAB_OPTIONS $USER_DEFINED_ELAB_OPTIONS $TOP_LEVEL_NAME
fi

# ----------------------------------------
# simulate
if [ $SKIP_SIM -eq 0 ]; then
  ./simv $SIM_OPTIONS $USER_DEFINED_SIM_OPTIONS
fi
