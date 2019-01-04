`ifndef DSI_CORE
`define DSI_CORE

module dsi_core(
    /********* System clk and reset *********/
    input   wire                            sys_clk                             ,
    input   wire                            sys_rst_n                           ,

    /********* PHY clk and reset *********/
    input   wire                            phy_clk                             ,
    input   wire                            phy_rst_n                           ,

    /********* PIX fifo signals *********/
    input   wire  [31:0]                    pix_fifo_data                       ,
    input   wire                            pix_fifo_empty                      ,
    output  wire                            pix_fifo_read                       ,

    /********* cmd FIFO interface *********/
    input   wire  [31:0]                    usr_fifo_data                       ,
    input   wire                            usr_fifo_empty                      ,
    output  wire                            usr_fifo_read                       ,

    /********* Control inputs *********/
    input   wire                            lpm_enable                          ,   // 1: go to LPM after sending commands. 0: send blank packet after sending command or data
    input   wire                            user_cmd_transmission_mode          ,   // 0: data from user fifo is sent in HS mode; 1: data from user fifo is sent in LP mode.
    input   wire                            enable_EoT_sending                  ,
    input   wire                            streaming_enable                    ,
    input   wire [2:0]                      lines_number                        ,
    input   wire                            lines_enable                        ,
    input   wire                            clock_enable                        ,

    output  wire                            lines_ready                         ,
    output  wire                            clock_ready                         ,
    output  wire                            lines_active                        ,

    /********* timings registers *********/
    input   wire [15:0]                     horizontal_line_length              ,   // length in clk
    input   wire [15:0]                     horizontal_front_porch              ,   // length in pixels
    input   wire [15:0]                     horizontal_back_porch               ,   // length in pixels
    input   wire [15:0]                     pixels_in_line_number               ,   // length in pixels
    input   wire [15:0]                     vertical_active_lines_number        ,   // length in lines
    input   wire [15:0]                     vertical_front_porch_lines_number   ,   // length in lines
    input   wire [15:0]                     vertical_back_porch_lines_number    ,   // length in lines
    input   wire [15:0]                     lpm_length                          ,   // length in clk

    /********* Lanes *********/
    output  wire [31:0]                     hs_lane_output                      ,
    output  wire [3:0]                      hs_lane_enable                      ,
    output  wire [3:0]                      LP_p_output                         ,
    output  wire [3:0]                      LP_n_output                         ,
    output  wire [3:0]                      LP_enable                           ,

    /********* Clock output *********/
    output  wire                            clock_LP_p_output                   ,
    output  wire                            clock_LP_n_output                   ,
    output  wire                            clock_LP_enable                     ,
    output  wire [7:0]                      clock_hs_output                     ,
    output  wire                            clock_hs_enable
    );

logic [32:0] data_fifo_data;
logic [3:0]  data_fifo_write;
logic [3:0]  data_fifo_full;
logic [3:0]  data_fifo_empty;

packets_assembler packets_assembler_0(
    /********* Clock signals *********/
        .clk                                 (sys_clk                               ),
        .rst_n                               (sys_rst_n                             ),

    /********* lanes controller iface *********/
        .lanes_fifo_data                     (data_fifo_data                        ), // 32:9 - 3x8 data, 8 - lpm sign, 7:0 lane 0 data
        .lanes_fifo_write                    (data_fifo_write                       ),
        .lanes_fifo_full                     (data_fifo_full                        ),
        .lanes_fifo_empty                    (data_fifo_empty                       ),

    /********* pixel FIFO interface *********/
        .pix_fifo_data                       (pix_fifo_data                         ),
        .pix_fifo_empty                      (pix_fifo_empty                        ),
        .pix_fifo_read                       (pix_fifo_read                         ),

    /********* cmd FIFO interface *********/
        .usr_fifo_data                       (usr_fifo_data                         ),
        .usr_fifo_empty                      (usr_fifo_empty                        ),
        .usr_fifo_read                       (usr_fifo_read                         ),

    /********* Control inputs *********/
        .lpm_enable                          (lpm_enable                            ),   // 1: go to LPM after sending commands. 0: send blank packet after sending command or data
        .user_cmd_transmission_mode          (user_cmd_transmission_mode            ),   // 0: data from user fifo is sent in HS mode; 1: data from user fifo is sent in LP mode.
        .enable_EoT_sending                  (enable_EoT_sending                    ),
        .streaming_enable                    (streaming_enable                      ),
        .lines_number                        (lines_number                          ),

    /********* timings registers *********/
        .horizontal_line_length              (horizontal_line_length                ),   // length in clk
        .horizontal_front_porch              (horizontal_front_porch                ),   // length in pixels
        .horizontal_back_porch               (horizontal_back_porch                 ),   // length in pixels
        .pixels_in_line_number               (pixels_in_line_number                 ),   // length in pixels
        .vertical_active_lines_number        (vertical_active_lines_number          ),   // length in lines
        .vertical_front_porch_lines_number   (vertical_front_porch_lines_number     ),   // length in lines
        .vertical_back_porch_lines_number    (vertical_back_porch_lines_number      ),   // length in lines
        .lpm_length                          (lpm_length                            )    // length in clk

);

logic [35:0]  lanes_fifo_data;
logic [3:0]   lanes_fifo_empty;
logic [3:0]   lanes_fifo_read;

genvar i;
generate
for(i = 0; i < 4; i = i + 1) begin : lanes_fifo
    lane_fifo_9x32  lane_fifo_inst (
    .aclr           (sys_rst_n                          ),
    .data           (wr_fifo_data[i*8 + 7 : i*8]        ),
    .wrclk          (sys_clk                            ),
    .wrreq          (data_fifo_write[i]                 ),
    .wrfull         (data_fifo_full[i]                  ),
    .wempty         (data_fifo_empty[i]                 ),
    .rdreq          (lanes_fifo_read[i]                 ),
    .q              (lanes_fifo_data[i*8 + 7 : i*8]     ),
    .rdempty        (lanes_fifo_empty[i]                ),
    .rdclk          (phy_clk                            )
    );
    end // lanes_fifo

endgenerate

assign wr_fifo_data     = {1'b0, data_fifo_data[32:25], 1'b0, data_fifo_data[24:17], 1'b0, data_fifo_data[16:9], data_fifo_data[8:0]};

logic reg_lanes_number_sync;
logic lines_enable_sync;
logic clock_enable_sync;
logic lines_ready_sync;
logic clock_ready_sync;
logic lines_active_sync;

sync_2ff #(.WIDTH(4)) sync_lanes_number
(
    .clk_out    (phy_clk                    ),
    .data_in    (lines_number               ),
    .data_out   (reg_lanes_number_sync      )
);

sync_2ff #(.WIDTH(1)) sync_lanes_enable
(
    .clk_out    (phy_clk                    ),
    .data_in    (lines_enable               ),
    .data_out   (lines_enable_sync          )
);

sync_2ff #(.WIDTH(1)) sync_clock_enable
(
    .clk_out    (phy_clk                    ),
    .data_in    (clock_enable               ),
    .data_out   (clock_enable_sync          )
);

sync_2ff #(.WIDTH(1)) sync_clock_enable
(
    .clk_out    (sys_clk                    ),
    .data_in    (lines_ready_sync           ),
    .data_out   (lines_ready                )
);

sync_2ff #(.WIDTH(1)) sync_clock_enable
(
    .clk_out    (sys_clk                    ),
    .data_in    (clock_ready_sync           ),
    .data_out   (clock_ready                )
);

sync_2ff #(.WIDTH(1)) sync_clock_enable
(
    .clk_out    (sys_clk                    ),
    .data_in    (lines_active_sync          ),
    .data_out   (lines_active               )
);

dsi_lanes_controller dsi_lanes_controller_0(
        /********* Clock signals *********/
        .clk_phy                 (phy_clk                   ), // serial data clock
        .rst_n                   (phy_rst_n                 ),

        /********* lanes controller iface *********/

        .lanes_fifo_data         (lanes_fifo_data           ),
        .lanes_fifo_empty        (lanes_fifo_empty          ),

        .lanes_fifo_read         (lanes_fifo_read           ),

        /********* Misc signals *********/
        .reg_lanes_number        (reg_lanes_number_sync     ),
        .lines_enable            (lines_enable_sync         ),   // enable output buffers of LP lines
        .clock_enable            (clock_enable_sync         ),   // enable clock

        /********* Output signals *********/
        .lines_ready             (lines_ready_sync          ),
        .clock_ready             (clock_ready_sync          ),
        .lines_active            (lines_active_sync         ),

        /********* Lanes *********/
        .hs_lane_output          (hs_lane_output            ),
        .hs_lane_enable          (hs_lane_enable            ),
        .LP_p_output             (LP_p_output               ),
        .LP_n_output             (LP_n_output               ),
        .LP_enable               (LP_enable                 ),

        /********* Clock output *********/
        .clock_LP_p_output       (clock_LP_p_output         ),
        .clock_LP_n_output       (clock_LP_n_output         ),
        .clock_LP_enable         (clock_LP_enable           ),
        .clock_hs_output         (clock_hs_output           ),
        .clock_hs_enable         (clock_hs_enable           )
    );


endmodule // dsi_core

`endif