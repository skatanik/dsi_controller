module uart_wrapper(
    //* system signals
    input  wire                     clk                  ,
    input  wire                     rst                  ,

    //* external interface
    input  wire                     rxd                  ,
    output wire                     txd                  ,

    //* system interface
    input   wire [7:0]              ctrl_address        ,

    input   wire                    ctrl_read           ,
    output  wire [31:0]             ctrl_readdata       ,
    output  wire [1:0]              ctrl_response       ,

    input   wire                    ctrl_write          ,
    input   wire [31:0]             ctrl_writedata      ,
    input   wire [3:0]              ctrl_byteenable     ,
    output  wire                    ctrl_waitrequest    ,

    output  wire                    irq
);

wire [8-1:0]    data_tx;
wire            data_tx_wr;
wire            data_tx_ack;
wire [8-1:0]    data_rx;
wire            data_rx_ready;
wire            data_rx_ack;
wire [15:0]     prescale;
wire            tx_busy;
wire            rx_busy;
wire            rx_overrun_error;
wire            rx_frame_error;

uart_regs uart_regs_0(

    /********* Sys iface *********/
    .clk                            (clk                ),   // Clock
    .rst_n                          (rst_n              ),   // Asynchronous reset active low

    .irq                            (irq                ),

    /********* Avalon-MM iface *********/
    .avl_mm_addr                    (ctrl_address     ),

    .avl_mm_read                    (ctrl_read        ),
    .avl_mm_readdata                (ctrl_readdata    ),
    .avl_mm_response                (ctrl_response    ),

    .avl_mm_write                   (ctrl_write       ),
    .avl_mm_writedata               (ctrl_writedata   ),
    .avl_mm_byteenable              (ctrl_byteenable  ),

    .avl_mm_waitrequest             (ctrl_waitrequest ),

    /********* Control signals *********/

    .data_tx                        (data_tx            ),
    .data_tx_wr                     (data_tx_wr         ),
    .data_tx_ack                    (data_tx_ack        ),

    .data_rx                        (data_rx            ),
    .data_rx_ready                  (data_rx_ready      ),
    .data_rx_ack                    (data_rx_ack        ),

    .prescale                       (prescale           ),
    .tx_busy                        (tx_busy            ),
    .rx_busy                        (rx_busy            ),
    .rx_overrun_error               (rx_overrun_error   ),
    .rx_frame_error                 (rx_frame_error     )
);


uart #(
    .DATA_WIDTH(8)
)uart_0
(
    .clk            (clk                    ),
    .rst            (rst_n                 ),

    /*
     * AXI input
     */
    .s_axis_tdata   (data_tx                ),
    .s_axis_tvalid  (data_tx_wr             ),
    .s_axis_tready  (data_tx_ack            ),

    /*
     * AXI output
     */
    .m_axis_tdata   (data_rx                ),
    .m_axis_tvalid  (data_rx_ready          ),
    .m_axis_tready  (data_rx_ack            ),

    /*
     * UART interface
     */
    .rxd            (rxd                    ),
    .txd            (txd                    ),

    /*
     * Status
     */
    .tx_busy            (tx_busy            ),
    .rx_busy            (rx_busy            ),
    .rx_overrun_error   (rx_overrun_error   ),
    .rx_frame_error     (rx_frame_error     ),

    /*
     * Configuration
     */
    .prescale           (prescale           )

);
endmodule