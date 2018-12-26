`ifndef DSI_CORE
`define DSI_CORE

module dsi_core(
    /********* System clk and reset *********/
    input   wire                            sys_clk                                 ,
    input   wire                            sys_rst_n                               ,

    /********* PHY clk and reset *********/
    input   wire                            phy_clk                                 ,
    input   wire                            phy_rst_n                               ,

    /********* PIX fifo signals *********/

    /********* Registers signals *********/
    );

packets_assembler packets_assembler_0(
    /********* Clock signals *********/
        .clk                                 (),
        .rst_n                               (),

    /********* lanes controller iface *********/
        .lanes_fifo_data                     (), // 32:9 - 3x8 data, 8 - lpm sign, 7:0 lane 0 data
        .lanes_fifo_write                    (),
        .lanes_fifo_full                     (),
        .lanes_fifo_empty                    (),

        .lanes_controller_lines_active       (),

    /********* pixel FIFO interface *********/
        .pix_fifo_data                       (),
        .pix_fifo_empty                      (),
        .pix_fifo_read                       (),

    /********* cmd FIFO interface *********/
        .usr_fifo_data                       (),
        .usr_fifo_empty                      (),
        .usr_fifo_read                       (),

    /********* Control inputs *********/
        .lpm_enable                          (),   // 1: go to LPM after sending commands. 0: send blank packet after sending command or data
        .user_cmd_transmission_mode          (),   // 0: data from user fifo is sent in HS mode; 1: data from user fifo is sent in LP mode.
        .enable_EoT_sending                  (),
        .streaming_enable                    (),
        .lines_number                        (),
    /********* timings registers *********/
        .horizontal_line_length              (),   // length in clk
        .horizontal_front_porch              (),   // length in pixels
        .horizontal_back_porch               (),   // length in pixels
        .pixels_in_line_number               (),   // length in pixels
        .vertical_active_lines_number        (),   // length in lines
        .vertical_front_porch_lines_number   (),   // length in lines
        .vertical_back_porch_lines_number    (),   // length in lines
        .lpm_length                          ()    // length in clk

);

dsi_lanes_controller dsi_lanes_controller_0(
        /********* Clock signals *********/
        .clk_sys                 (), // serial data clock
        .rst_n                   (),

        /********* lanes controller iface *********/
//        input  wire        data_fifo_write_clk     ,
//        input  wire        data_fifo_write_rst_n   ,
//        input  wire [32:0] data_fifo_data          , // 32:9 - 3x8 data, 8 - lpm sign, 7:0 lane 0 data
//        input  wire [3:0]  data_fifo_write         ,
//        output wire [3:0]  data_fifo_full          ,
//        output wire [3:0]  data_fifo_empty         ,

        .lanes_fifo_data         (),
        .lanes_fifo_empty        (),

        .lanes_fifo_read         (),

        /********* Misc signals *********/
        .reg_lanes_number        (),
        .lines_enable            (),   // enable output buffers of LP lines
        .clock_enable            (),   // enable clock

        /********* Output signals *********/
        .lines_ready             (),
        .clock_ready             (),
        .lines_active            (),

        /********* Lanes *********/
        .hs_lane_output          (),
        .hs_lane_enable          (),
        .LP_p_output             (),
        .LP_n_output             (),
        .LP_enable               (),

        /********* Clock output *********/
        .clock_LP_p_output       (),
        .clock_LP_n_output       (),
        .clock_LP_enable         (),
        .clock_hs_output         (),
        .clock_hs_enable         ()
    );


endmodule // dsi_core

`endif