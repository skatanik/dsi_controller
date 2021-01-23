`ifndef DSI_TX_TOP
`define DSI_TX_TOP

module dsi_tx_top #(
    parameter LINE_WIDTH            = 640,
    parameter BITS_PER_PIXEL        = 8,
    parameter BLANK_TIME            = 100,
    parameter BLANK_TIME_HBP_ACT    = 100,
    parameter VSA_LINES_NUMBER      = 100,
    parameter VBP_LINES_NUMBER      = 100,
    parameter IMAGE_HEIGHT          = 100,
    parameter VFP_LINES_NUMBER      = 100
    ) (
    /********* System signals *********/
    input wire                      clk_sys                             ,
    input wire                      rst_sys_n                           ,

    input wire                      clk_phy                             ,
    input wire                      rst_phy_n                           ,

    input wire                      clk_hs_latch                        ,
    input wire                      clk_hs                              ,
    input wire                      clk_hs_clk                          ,
    input wire                      clk_hs_clk_latch                    ,

    output  wire                    irq                                 ,

    /********* Avalon-ST input *********/
    input   wire [31:0]             in_avl_st_data                      ,
    input   wire                    in_avl_st_valid                     ,
    input   wire                    in_avl_st_endofpacket               ,
    input   wire                    in_avl_st_startofpacket             ,
    output  wire                    in_avl_st_ready                     ,

    /********* Output interface *********/
    output  wire [3:0]              dphy_data_hs_out_p                  ,  // active
    output  wire [3:0]              dphy_data_hs_out_n                  ,  // unactive. do not connect
    output  wire [3:0]              dphy_data_lp_out_p                  ,
    output  wire [3:0]              dphy_data_lp_out_n                  ,

    output  wire                    dphy_clk_hs_out_p                   ,  // active
    output  wire                    dphy_clk_hs_out_n                   ,  // unactive. do not connect
    output  wire                    dphy_clk_lp_out_p                   ,
    output  wire                    dphy_clk_lp_out_n                   ,

    `ifdef SIMULATION
    output  wire                    dphy_clk_hs_out                     ,
    output  wire [3:0]              dphy_data_hs_out                    ,

    `endif

    /********* Avalon-MM iface *********/
    input   wire [4:0]              avl_mm_address                      ,

    input   wire                    avl_mm_read                         ,
    output  wire [31:0]             avl_mm_readdata                     ,
    output  wire [1:0]              avl_mm_response                     ,

    input   wire                    avl_mm_write                        ,
    input   wire [31:0]             avl_mm_writedata                    ,
    input   wire [3:0]              avl_mm_byteenable                   ,
    output  wire                    avl_mm_waitrequest

);

wire        packet_assembler_enable;
wire        lanes_enable;
wire        clk_out_enable;
wire        lanes_active_sync;
wire        lanes_active;
wire        send_cmd;
wire        send_cmd_sync;
wire [2:0]  lanes_number;
wire [23:0] cmd_packet;
wire        packet_assembler_enable_sync;
wire        lanes_enable_sync;
wire        clk_out_enable_sync;
wire [2:0]  lanes_number_sync;
wire [23:0] cmd_packet_sync;
wire        lanes_ready_set_sync;
wire        clk_ready_set_sync;
wire        pix_buffer_underflow_set;
wire        pix_buffer_underflow_set_sync;
wire        lanes_ready_set;
wire        clk_ready_set;

wire [7:0]  tlpx_timeout;
wire [7:0]  hs_prepare_timeout;
wire [7:0]  hs_exit_timeout;
wire [7:0]  hs_go_timeout;
wire [7:0]  hs_trail_timeout;

wire [7:0]  tlpx_timeout_sync;
wire [7:0]  hs_prepare_timeout_sync;
wire [7:0]  hs_exit_timeout_sync;
wire [7:0]  hs_go_timeout_sync;
wire [7:0]  hs_trail_timeout_sync;

dsi_tx_regs dsi_tx_regs_0(

    /********* Sys iface *********/
    .clk                                (clk_sys                        ),   // Clock
    .rst_n                              (rst_sys_n                      ),   // Asynchronous reset active low

    .irq                                (irq                            ),

    /********* Avalon-MM iface *********/
    .avl_mm_addr                        (avl_mm_address                 ),

    .avl_mm_read                        (avl_mm_read                    ),
    .avl_mm_readdata                    (avl_mm_readdata                ),
    .avl_mm_response                    (avl_mm_response                ),

    .avl_mm_write                       (avl_mm_write                   ),
    .avl_mm_writedata                   (avl_mm_writedata               ),
    .avl_mm_byteenable                  (avl_mm_byteenable              ),

    .avl_mm_waitrequest                 (avl_mm_waitrequest             ),

    /********* Control signals *********/

    .packet_assembler_enable            (packet_assembler_enable        ),
    .lanes_enable                       (lanes_enable                   ),
    .clk_out_enable                     (clk_out_enable                 ),
    .lanes_number                       (lanes_number                   ),
    .send_cmd                           (send_cmd                       ),
    .cmd_packet                         (cmd_packet                     ),
    .lanes_active                       (lanes_active_sync              ),

    .tlpx_timeout                       (tlpx_timeout                   ),
    .hs_prepare_timeout                 (hs_prepare_timeout             ),
    .hs_exit_timeout                    (hs_exit_timeout                ),
    .hs_go_timeout                      (hs_go_timeout                  ),
    .hs_trail_timeout                   (hs_trail_timeout               ),

    .pix_buffer_underflow_set           (pix_buffer_underflow_set_sync  ),
    .lanes_ready_set                    (lanes_ready_set_sync           ),
    .clk_ready_set                      (clk_ready_set_sync             )
);

sync_2ff sync_assembler_enable(
    .clk_out               (clk_phy         ),    // Clock
    .data_in               (packet_assembler_enable),
    .data_out              (packet_assembler_enable_sync)
);

sync_2ff sync_lanes_enable(
    .clk_out               (clk_phy             ),    // Clock
    .data_in               (lanes_enable        ),
    .data_out              (lanes_enable_sync   )
);

sync_2ff sync_clk_enable(
    .clk_out               (clk_phy             ),    // Clock
    .data_in               (clk_out_enable      ),
    .data_out              (clk_out_enable_sync )
);

sync_2ff sync_send_cmd(
    .clk_out               (clk_phy             ),    // Clock
    .data_in               (send_cmd            ),
    .data_out              (send_cmd_sync       )
);

sync_2ff #(.WIDTH(3)) sync_lanes_number(
    .clk_out               (clk_phy             ),    // Clock
    .data_in               (lanes_number        ),
    .data_out              (lanes_number_sync   )
);

sync_2ff #(.WIDTH(24)) sync_cmd_packet(
    .clk_out               (clk_phy             ),    // Clock
    .data_in               (cmd_packet          ),
    .data_out              (cmd_packet_sync     )
);

sync_2ff sync_clk_ready(
    .clk_out               (clk_sys             ),    // Clock
    .data_in               (clk_ready_set       ),
    .data_out              (clk_ready_set_sync  )
);

sync_2ff sync_lanes_ready(
    .clk_out               (clk_sys                 ),    // Clock
    .data_in               (lanes_ready_set         ),
    .data_out              (lanes_ready_set_sync    )
);

sync_2ff sync_lanes_active(
    .clk_out               (clk_sys                 ),    // Clock
    .data_in               (lanes_active            ),
    .data_out              (lanes_active_sync       )
);

sync_2ff sync_pix_underflow(
    .clk_out               (clk_sys                         ),    // Clock
    .data_in               (pix_buffer_underflow_set        ),
    .data_out              (pix_buffer_underflow_set_sync   )
);

sync_2ff #(.WIDTH(8)) sync_tlpx_timeout(
    .clk_out               (clk_phy             ),    // Clock
    .data_in               (tlpx_timeout        ),
    .data_out              (tlpx_timeout_sync   )
);

sync_2ff #(.WIDTH(8)) sync_hs_prepare_timeout(
    .clk_out               (clk_phy             ),    // Clock
    .data_in               (hs_prepare_timeout        ),
    .data_out              (hs_prepare_timeout_sync   )
);

sync_2ff #(.WIDTH(8)) sync_hs_exit_timeout(
    .clk_out               (clk_phy             ),    // Clock
    .data_in               (hs_exit_timeout        ),
    .data_out              (hs_exit_timeout_sync   )
);

sync_2ff #(.WIDTH(8)) sync_hs_go_timeout(
    .clk_out               (clk_phy             ),    // Clock
    .data_in               (hs_go_timeout        ),
    .data_out              (hs_go_timeout_sync   )
);

sync_2ff #(.WIDTH(8)) sync_hs_trail_timeout(
    .clk_out               (clk_phy             ),    // Clock
    .data_in               (hs_trail_timeout        ),
    .data_out              (hs_trail_timeout_sync   )
);

wire [31:0]             fifo_data;
wire                    fifo_not_empty;
wire                    fifo_line_ready;
wire                    fifo_read_ack;

dsi_tx_pixel_buffer #(
    .NOT_EMPTY_TRESHOLD (LINE_WIDTH*BITS_PER_PIXEL/8),
    .FIFO_DEPTH         (1024)
    ) dsi_tx_pixel_buffer_0 (
    /********* System interface *********/
    .clk                        (clk_sys                    ),    // Clock
    .rst_n                      (rst_sys_n                  ),  // Asynchronous reset active low

    .clk_phy                    (clk_phy                    ),
    .rst_phy_n                  (rst_phy_n                  ),

    /********* Avalon-ST Sink *********/
    .avl_st_in_data             (in_avl_st_data             ),
    .avl_st_in_valid            (in_avl_st_valid            ),
    .avl_st_in_endofpacket      (in_avl_st_endofpacket      ),
    .avl_st_in_startofpacket    (in_avl_st_startofpacket    ),
    .avl_st_in_ready            (in_avl_st_ready            ),

    /********* Output interface *********/
    .fifo_data                  (fifo_data                  ),
    .fifo_not_empty             (fifo_not_empty             ),
    .fifo_line_ready            (fifo_line_ready            ),
    .fifo_read_ack              (fifo_read_ack              )
);

wire [32:0]             phy_data;
wire [3:0]              phy_write;
wire [3:0]              phy_full;

dsi_tx_packets_assembler #(
    .LINE_WIDTH         (LINE_WIDTH         ),
    .BITS_PER_PIXEL     (BITS_PER_PIXEL     ),
    .BLANK_TIME         (BLANK_TIME         ),
    .BLANK_TIME_HBP_ACT (BLANK_TIME_HBP_ACT ),
    .VSA_LINES_NUMBER   (VSA_LINES_NUMBER   ),
    .VBP_LINES_NUMBER   (VBP_LINES_NUMBER   ),
    .ACT_LINES_NUMBER   (IMAGE_HEIGHT       ),
    .VFP_LINES_NUMBER   (VFP_LINES_NUMBER   )

    ) dsi_tx_packets_assembler_0 (
    /********* System interface *********/
    .clk                        (clk_phy                            ),  // Clock. The same as in PHY
    .rst_n                      (rst_phy_n                          ),  // Asynchronous reset active low

    /********* Input FIFO interface *********/
    .fifo_data                  (fifo_data                          ), // data should be already packed
    .fifo_not_empty             (fifo_not_empty                     ),
    .fifo_line_ready            (fifo_line_ready                    ),
    .fifo_read_ack              (fifo_read_ack                      ),

    /********* PHY interface *********/
    .phy_data                   (phy_data                           ),
    .phy_write                  (phy_write                          ),
    .phy_full                   (phy_full                           ),

    /********* Control signals *********/
    .enable                     (packet_assembler_enable_sync       ),
    .send_cmd                   (send_cmd_sync                      ),
    .lanes_number               (lanes_number_sync                  ),
    .cmd_packet                 (cmd_packet_sync                    ),
    .pix_buffer_underflow_set   (pix_buffer_underflow_set           )
);

wire [8:0]              lanes_fifo_data_0;
wire [23:0]             lanes_fifo_data_1;
wire [35:0]             lanes_fifo_data;
wire [3:0]              lanes_fifo_empty;
wire [3:0]              lanes_fifo_read;

`ifdef ALTERA
altera_generic_fifo #(
    .WIDTH      (9),
    .DEPTH      (32),
    .DC_FIFO    (0),
    .SHOWAHEAD  (1)
    ) fifo_9x32(
    .aclr           (!rst_phy_n                                                     ),
    .data           ({phy_data[32], phy_data[7:0]}  ),
    .rdclk          (clk_phy                                                        ),
    .rdreq          (lanes_fifo_read[0]                                             ),
    .wrreq          (phy_write[0]                                                   ),
    .q              (lanes_fifo_data_0 ),
    .empty          (lanes_fifo_empty[0]                                            ),
    .full           (phy_full[0]                                                    )
);

`else

fifo_9x32 fifo_9x32_inst (
  .clk      (clk_phy                            ), // input clk
  `ifdef SPARTAN7
  .srst     (!rst_phy_n                         ), // input rst
  `else
  .rst     (!rst_phy_n                         ), // input rst
  `endif
  .din      ({phy_data[32], phy_data[7:0]}      ), // input [8 : 0] din
  .wr_en    (phy_write[0]                       ), // input wr_en
  .rd_en    (lanes_fifo_read[0]                 ), // input rd_en
  .dout     (lanes_fifo_data_0                  ), // output [8 : 0] dout
  .full     (phy_full[0]                        ), // output full
  .empty    (lanes_fifo_empty[0]                ) // output empty
);

`endif

assign lanes_fifo_data[8:0] = lanes_fifo_data_0;

genvar i;

generate
    for (i = 1; i < 4; i = i + 1) begin: lanes_fifo
`ifdef ALTERA

    altera_generic_fifo #(
        .WIDTH      (8),
        .DEPTH      (32),
        .DC_FIFO    (0),
        .SHOWAHEAD  (1)
        ) fifo_8x32_inst(
        .aclr           (!rst_phy_n                                                     ),
        .data           (phy_data[i*8+:8]   ),
        .rdclk          (clk_phy                                                        ),
        .rdreq          (lanes_fifo_read[i]                                             ),
        .wrreq          (phy_write[i]                                                   ),
        .q              (lanes_fifo_data_1[(i-1)*8+:8] ),
        .empty          (lanes_fifo_empty[i]                                            ),
        .full           (phy_full[i]                                                    )
    );

`else

    fifo_9x32 fifo_9x32_inst (
    .clk    (clk_phy                        ), // input clk
    `ifdef SPARTAN7
    .srst   (!rst_phy_n                     ), // input rst
    `else
    .rst   (!rst_phy_n                     ), // input rst
    `endif
    .din    ({1'b0, phy_data[i*8+:8]}       ), // input [8 : 0] din
    .wr_en  (phy_write[i]                   ), // input wr_en
    .rd_en  (lanes_fifo_read[i]             ), // input rd_en
    .dout   (lanes_fifo_data_1[(i-1)*8+:8]  ), // output [8 : 0] dout
    .full   (phy_full[i]                    ), // output full
    .empty  (lanes_fifo_empty[i]            ) // output empty
    );

`endif
    assign lanes_fifo_data[i*9+:9] = {1'b0, lanes_fifo_data_1[(i-1)*8+:8]};

    end
endgenerate

wire [3:0]  data_lp_enable;
wire        clk_lp_enable;
wire [31:0] hs_lane_output_bus;
wire [7:0]  clock_hs_output_bus;

wire [3:0]  LP_p_output;
wire [3:0]  LP_n_output;
wire        clock_LP_p_output;
wire        clock_LP_n_output;

dphy_tx_lanes_controller dsi_lanes_controller_0
    (
    /********* Clock signals *********/
    .clk_phy                    (clk_phy                    ), // serial data clock
    .rst_n                      (rst_phy_n                  ),

    /********* lanes controller iface *********/
    .lanes_fifo_data            (lanes_fifo_data            ),
    .lanes_fifo_empty           (lanes_fifo_empty           ),

    .lanes_fifo_read            (lanes_fifo_read            ),

    /********* Misc signals *********/

    .reg_lanes_number           (lanes_number_sync          ),
    .lines_enable               (lanes_enable_sync          ),   // enable output buffers of LP lines
    .clock_enable               (clk_out_enable_sync        ),   // enable clock

    /********* Output signals *********/
    .lines_ready                (lanes_ready_set            ),
    .clock_ready                (clk_ready_set              ),
    .lines_active               (lanes_active               ),

    .tlpx_timeout               (tlpx_timeout_sync          ),
    .hs_prepare_timeout         (hs_prepare_timeout_sync    ),
    .hs_exit_timeout            (hs_exit_timeout_sync       ),
    .hs_go_timeout              (hs_go_timeout_sync         ),
    .hs_trail_timeout           (hs_trail_timeout_sync      ),

    /********* Lanes *********/
    .hs_lane_output             (hs_lane_output_bus         ),
    .hs_lane_enable             (),
    .LP_p_output                (LP_p_output                ),
    .LP_n_output                (LP_n_output                ),
    .LP_enable                  (data_lp_enable             ),

    /********* Clock output *********/
    .clock_LP_p_output          (clock_LP_p_output          ),
    .clock_LP_n_output          (clock_LP_n_output          ),
    .clock_LP_enable            (clk_lp_enable              ),
    .clock_hs_output            (clock_hs_output_bus        ),
    .clock_hs_enable            ()

    );

/********* Primitives instanciation *********/

/********* CLK lane *********/
`ifdef ALTERA

wire clk_lvds_out;

lvds_soft lvds_clk(
        .tx_inclock     (clk_hs_clk                     ),   //   tx_inclock.tx_inclock
        .tx_syncclock   (clk_hs_clk_latch                   ), // tx_syncclock.tx_syncclock
        .tx_in          (clock_hs_output_bus            ),        //        tx_in.tx_in
        .tx_out         (clk_lvds_out                   )        //       tx_out.tx_out
    );

`ifdef MIPI_TX_TRI_STATED_HS_OUTPUTS


wire clk_lvds_out_n_temp;
wire clk_lvds_out_p_temp;
wire clk_lvds_out_n;
wire clk_lvds_out_p;

assign clk_lvds_out_n_temp = clk_lvds_out;
assign clk_lvds_out_p_temp = ~clk_lvds_out;

gpio gpio_clk_p(
        .din            (clk_lvds_out_p_temp       ),       //       din.export
        .pad_out        (clk_lvds_out_p     ),   //   pad_out.export
        .oe             (!clk_lp_enable     )         //        oe.export
    );

gpio gpio_clk_n(
        .din            (clk_lvds_out_n_temp       ),       //       din.export
        .pad_out        (clk_lvds_out_n     ),   //   pad_out.export
        .oe             (!clk_lp_enable     )         //        oe.export
    );

assign dphy_clk_hs_out_p = clk_lvds_out_p;
assign dphy_clk_hs_out_n = clk_lvds_out_n;

`else

assign dphy_clk_hs_out_p = clk_lvds_out;
assign dphy_clk_hs_out_n = 1'b0;

`endif

assign dphy_clk_lp_out_p = clk_lp_enable ? clock_LP_p_output : 1'bZ;
assign dphy_clk_lp_out_n = clk_lp_enable ? clock_LP_n_output : 1'bZ;

`ifdef MODELING
    assign dphy_clk_hs_out = clk_lvds_out;
`endif

/********* Data lanes *********/

wire [3:0] data_lvds_out;
wire [3:0] data_lvds_out_n_temp;
wire [3:0] data_lvds_out_p_temp;
wire [3:0] data_lvds_out_n;
wire [3:0] data_lvds_out_p;

generate
    for (i = 0; i < 4; i = i + 1) begin:lanes_lvds

        lvds_soft lvds_data(
                .tx_inclock     (clk_hs                         ),   //   tx_inclock.tx_inclock
                .tx_syncclock   (clk_hs_latch                   ), // tx_syncclock.tx_syncclock
                .tx_in          (hs_lane_output_bus[i*8+:8]     ),        //        tx_in.tx_in
                .tx_out         (data_lvds_out[i]               )        //       tx_out.tx_out
            );
`ifdef MIPI_TX_TRI_STATED_HS_OUTPUTS

    assign data_lvds_out_p_temp[i] = data_lvds_out[i];
    assign data_lvds_out_n_temp[i] = ~data_lvds_out[i];

        gpio gpio_data_p(
                .din            (data_lvds_out_p_temp[i]   ),       //       din.export
                .pad_out        (data_lvds_out_p[i] ),   //   pad_out.export
                .oe             (!data_lp_enable[i] )         //        oe.export
            );

        gpio gpio_data_n(
                .din            (data_lvds_out_n_temp[i]   ),       //       din.export
                .pad_out        (data_lvds_out_n[i] ),   //   pad_out.export
                .oe             (!data_lp_enable[i] )         //        oe.export
            );

        assign dphy_data_hs_out_p[i] = data_lvds_out_p[i];
        assign dphy_data_hs_out_n[i] = data_lvds_out_n[i];

`else
        assign dphy_data_hs_out_p[i] = data_lvds_out[i];
        assign dphy_data_hs_out_n[i] = 1'b0;
`endif

        assign dphy_data_lp_out_p[i] = data_lp_enable[i] ? LP_p_output[i] : 1'bZ;
        assign dphy_data_lp_out_n[i] = data_lp_enable[i] ? LP_n_output[i] : 1'bZ;

        `ifdef MODELING
            assign dphy_data_hs_out[i] = data_lvds_out[i];
        `endif

    end
endgenerate

`else

/* CLK */
wire hs_clock_en;
wire hs_clock_out;

`ifndef SPARTAN7

OBUFT #(
      .DRIVE(12),   // Specify the output drive strength
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW") // Specify the output slew rate
   ) OBUFT_LP_P (
      .O(dphy_clk_lp_out_p  ),     // Buffer output (connect directly to top-level port)
      .I(clock_LP_p_output  ),     // Buffer input
      .T(~clk_lp_enable      )      // 3-state enable input
   );

OBUFT #(
      .DRIVE(12),   // Specify the output drive strength
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW") // Specify the output slew rate
   ) OBUFT_LP_N (
      .O(dphy_clk_lp_out_n  ),     // Buffer output (connect directly to top-level port)
      .I(clock_LP_n_output  ),     // Buffer input
      .T(~clk_lp_enable      )      // 3-state enable input
   );

lvds_soft_x clk_lane(
		.rst                (!rst_phy_n             ),   // tx_inclock.rst
		.tx_clock_logic     (clk_phy                ),   // tx_inclock.tx_inclock
		.tx_clock_io        (clk_hs_clk             ),      // tx_syncclock.tx_syncclock
		.tx_clock_strobe    (clk_hs_clk_latch       ),  // tx_syncclock.tx_syncclock
		.tx_en              (clk_lp_enable         ),  // tx_syncclock.tx_syncclock
		.tx_in              (clock_hs_output_bus    ),            // tx_in.tx_in
		.tx_out_p           (dphy_clk_hs_out_p        ),            // tx_out.tx_out
		.tx_out_n           (dphy_clk_hs_out_n        )         // tx_out.tx_out_en
	);

/* Data */
wire [3:0] hs_data_en;
wire [3:0] hs_data_out;

generate
for (i = 0; i < 4; i = i + 1) begin:lanes_dphy

OBUFT #(
      .DRIVE(12),   // Specify the output drive strength
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW") // Specify the output slew rate
   ) OBUFT_DATA_LP_P (
      .O    (dphy_data_lp_out_p[i]  ),     // Buffer output (connect directly to top-level port)
      .I    (LP_p_output[i]         ),     // Buffer input
      .T    (~data_lp_enable[i]      )      // 3-state enable input
   );

OBUFT #(
      .DRIVE(12),   // Specify the output drive strength
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW") // Specify the output slew rate
   ) OBUFT_DATA_LP_N (
      .O    (dphy_data_lp_out_n[i]  ),     // Buffer output (connect directly to top-level port)
      .I    (LP_n_output[i]         ),     // Buffer input
      .T    (~data_lp_enable[i]      )      // 3-state enable input
   );

lvds_soft_x data_lane(
		.rst                (!rst_phy_n                 ),   // tx_inclock.rst
		.tx_clock_logic     (clk_phy                    ),   // tx_inclock.tx_inclock
		.tx_clock_io        (clk_hs                     ),      // tx_syncclock.tx_syncclock
		.tx_clock_strobe    (clk_hs_latch               ),  // tx_syncclock.tx_syncclock
		.tx_en              (data_lp_enable[i]         ),  // tx_syncclock.tx_syncclock
		.tx_in              (hs_lane_output_bus[i*8+:8] ),            // tx_in.tx_in
		.tx_out_p           (dphy_data_hs_out_p[i]            ),            // tx_out.tx_out
		.tx_out_n           (dphy_data_hs_out_n[i]            )         // tx_out.tx_out_en
	);

end
endgenerate

`endif

`endif

endmodule

`endif