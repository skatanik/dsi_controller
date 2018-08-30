module dsi_lanes_controller
    (
        /********* Clock signals *********/
        input wire          clk_sys             , // serial data clock
        input wire          clk_serdes          , // logic clock = clk_hs/8
        input wire          clk_serdes_clk      , // logic clock = clk_hs/8 + 90dgr phase shift
        input wire          clk_latch           , // clk_sys, duty cycle 15%
        input wire          rst_n               ,

        /********* Fifo signals *********/

        // host should set iface_write_rqst, and at the same time set iface_write_data to the first data.
        // Then on every iface_data_rqst Host should change data. When it comes to the last data piece Host should set iface_last_word.
        input wire [31:0]   iface_write_data    ,
        input wire [4:0]    iface_write_strb    , // iface_write_strb[4] - mode flag. 0 - hs, 1 - lp
        input wire [3:0]    iface_write_rqst    ,
        input wire [3:0]    iface_last_word     ,

        output wire         iface_data_rqst     ,

        /********* Misc signals *********/

        input wire [1:0]    reg_lanes_number


        /********* Output signals *********/

    );

/********************************************************************
    Module makes data preload in order to know when the last data comes.
    size of preload data is 2 fifo wide words.
********************************************************************/

/********************************************************************
                DSI lanes instances
********************************************************************/
logic [3:0]     dsi_start_rqst;
logic [3:0]     dsi_fin_rqst;
logic [3:0]     dsi_data_rqst;
logic [3:0]     dsi_active;
logic [3:0]     dsi_serial_hs_output;
logic [3:0]     dsi_LP_p_output;
logic [3:0]     dsi_LP_n_output;
logic [31:0]    dsi_inp_data;

genvar i;

generate
for(i = 0; i < 4; i = i + 1)
    dsi_lane_full dsi_lane_(
        .clk_sys            (clk_sys                        ), // serial data clock
        .clk_serdes         (clk_serdes                     ), // logic clock = clk_hs/8
        .clk_latch          (clk_latch                      ), // clk_sys, duty cycle 15%
        .rst_n              (rst_n                          ),

        .start_rqst         (dsi_start_rqst[i]              ),
        .fin_rqst           (dsi_fin_rqst[i]                ),
        .inp_data           (dsi_inp_data[i*8 + 7 : i*8]    ),

        .data_rqst          (dsi_data_rqst[i]               ),
        .active             (dsi_active[i]                  ),

        .serial_hs_output   (dsi_serial_hs_output[i]        ),
        .LP_p_output        (dsi_LP_p_output[i]             ),
        .LP_n_output        (dsi_LP_n_output[i]             )
    );
endgenerate

/********************************************************************
        CLK lane
********************************************************************/
logic     dsi_start_rqst_clk;
logic     dsi_fin_rqst_clk;
logic     dsi_active_clk;
logic     dsi_serial_hs_output_clk;
logic     dsi_LP_p_output_clk;
logic     dsi_LP_n_output_clk;

dsi_lane_full dsi_lane_clk(
        .clk_sys            (clk_sys                        ), // serial data clock
        .clk_serdes         (clk_serdes_clk                 ), // logic clock = clk_hs/8
        .clk_latch          (clk_latch                      ), // clk_sys, duty cycle 15%
        .rst_n              (rst_n                          ),

        .start_rqst         (dsi_start_rqst_clk             ),
        .fin_rqst           (dsi_fin_rqst_clk               ),
        .inp_data           (8'hAA                          ),

        .active             (dsi_active_clk                 ),

        .serial_hs_output   (dsi_serial_hs_output_clk       ),
        .LP_p_output        (dsi_LP_p_output_clk            ),
        .LP_n_output        (dsi_LP_n_output_clk            )
    );


endmodule
