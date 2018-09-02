`timescale 1ns/1ps
module dsi_lane_controller_tb();

bit clk_sys;
bit clk_serdes;
bit clk_serdes_clk;
bit clk_latch;
bit rst_n;
logic [31:0]   iface_write_data = 0;
logic [4:0]    iface_write_strb = 0;
logic [3:0]    iface_write_rqst = 0;
logic [3:0]    iface_last_word = 0;
logic          iface_data_rqst = 0;
logic [1:0]    reg_lanes_number = 3;
logic          lines_enable = 0;
logic          clock_enable = 0;
logic          lines_ready;
logic          clock_ready;
logic          data_underflow_error;
logic  [3:0]   hs_lane_output;
logic  [3:0]   LP_p_output;
logic  [3:0]   LP_n_output;
logic  [3:0]   clock_LP_p_output;
logic  [3:0]   clock_LP_n_output;
logic  [3:0]   clock_hs_output;

dsi_lanes_controller dsi_lanes_controller_0(
.clk_sys                    (clk_sys                ),
.clk_serdes                 (clk_serdes             ),
.clk_serdes_clk             (clk_serdes_clk         ),
.clk_latch                  (clk_latch              ),
.rst_n                      (rst_n                  ),
.iface_write_data           (iface_write_data       ),
.iface_write_strb           (iface_write_strb       ),
.iface_write_rqst           (iface_write_rqst       ),
.iface_last_word            (iface_last_word        ),
.iface_data_rqst            (iface_data_rqst        ),
.reg_lanes_number           (reg_lanes_number       ),
.lines_enable               (lines_enable           ),
.clock_enable               (clock_enable           ),
.lines_ready                (lines_ready            ),
.clock_ready                (clock_ready            ),
.data_underflow_error       (data_underflow_error   ),
.hs_lane_output             (hs_lane_output         ),
.LP_p_output                (LP_p_output            ),
.LP_n_output                (LP_n_output            ),
.clock_LP_p_output          (clock_LP_p_output      ),
.clock_LP_n_output          (clock_LP_n_output      ),
.clock_hs_output            (clock_hs_output        )
);

initial begin
clk_sys             = 0;
clk_latch           = 0;
clk_serdes          = 0;
clk_serdes_clk      = 0;
rst_n               = 0;

#100
wait(10) @(posedge clk_sys)
rst_n = 1;
end

always
    #5 clk_sys = ~clk_sys;

always
begin
    #7 clk_latch = 1;
    #3 clk_latch = ~clk_latch;
end

always
    #0.625 clk_serdes      = ~clk_serdes;

always
    #0.625 clk_serdes_clk  = ~clk_serdes_clk;

endmodule