module modulename(
    //* system signals
    input  logic                   clk                  ,
    input  logic                   rst                  ,

    //* external interface
    input  logic                   rxd                  ,
    output logic                   txd                  ,

    //* system interface
    input   wire [4:0]              ctrl_address        ,

    input   wire                    ctrl_read           ,
    output  wire [31:0]             ctrl_readdata       ,
    output  wire [1:0]              ctrl_response       ,

    input   wire                    ctrl_write          ,
    input   wire [31:0]             ctrl_writedata      ,
    input   wire [3:0]              ctrl_byteenable     ,
    output  wire                    ctrl_waitrequest    ,

    output logic                    irq
);


module uart #
(
    parameter DATA_WIDTH = 8
)
(
    input  wire                   clk,
    input  wire                   rst,

    /*
     * AXI input
     */
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,

    /*
     * AXI output
     */
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,

    /*
     * UART interface
     */
    input  wire                   rxd,
    output wire                   txd,

    /*
     * Status
     */
    output wire                   tx_busy,
    output wire                   rx_busy,
    output wire                   rx_overrun_error,
    output wire                   rx_frame_error,

    /*
     * Configuration
     */
    input  wire [15:0]            prescale

);
endmodule