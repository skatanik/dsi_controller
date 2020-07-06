`ifndef DSI_TX_PIXEL_BUFFER
`define DSI_TX_PIXEL_BUFFER

module dsi_tx_pixel_buffer #(
    parameter NOT_EMPTY_TRESHOLD = 640, // bytes
    parameter FIFO_DEPTH         = 1024

    ) (
    /********* System interface *********/
    input wire          clk             ,    // Clock
    input wire          rst_n           ,  // Asynchronous reset active low

    input wire          clk_phy         ,    // Clock
    input wire          rst_phy_n       ,  // Asynchronous reset active low

    /********* Avalon-ST Sink *********/
    input   wire [31:0]             avl_st_in_data                      ,
    input   wire                    avl_st_in_valid                     ,
    input   wire                    avl_st_in_endofpacket               ,
    input   wire                    avl_st_in_startofpacket             ,
    output  wire                    avl_st_in_ready                     ,

    /********* Output interface *********/
    output  wire [31:0]             fifo_data                           ,
    output  wire                    fifo_not_empty                      ,
    output  wire                    fifo_line_ready                     ,
    input   wire                    fifo_read_ack
);

wire        fifo_write;
wire        fifo_full;
wire        fifo_empty;
wire        fifo_read;
wire [31:0] fifo_data_in;
wire [31:0] fifo_data_out;
wire [9:0]  fifo_usedw;
wire [9:0]  fifo_wrusedw;

reg fifo_line_ready_reg;
reg fifo_not_full;

always @(posedge clk_phy or negedge rst_phy_n)
    if(!rst_phy_n)  fifo_line_ready_reg <= 1'b0;
    else            fifo_line_ready_reg <= fifo_usedw >= (NOT_EMPTY_TRESHOLD >> 2);

always @(posedge clk or negedge rst_n)
    if(!rst_n)          fifo_not_full <= 1'b0;
    else                fifo_not_full <= fifo_wrusedw < (FIFO_DEPTH - 64);

assign avl_st_in_ready  = fifo_not_full;
assign fifo_write       = avl_st_in_ready & avl_st_in_valid;
assign fifo_data_in     = avl_st_in_data;

assign fifo_data        = fifo_data_out;
assign fifo_not_empty   = !fifo_empty;
assign fifo_line_ready  = fifo_line_ready_reg;
assign fifo_read        = fifo_read_ack;

/********* FIFO 32xFIFO_DEPTH *********/
`ifdef ALTERA
altera_generic_fifo #(
    .WIDTH      (32     ),
    .DEPTH      (FIFO_DEPTH   ),
    .DC_FIFO    (1      ),
    .SHOWAHEAD  (1      )
    )altera_generic_fifo_0 (
    .aclr       (!rst_n             ),
    .rdclk      (clk_phy            ),
    .wrclk      (clk                ),
    .data       (fifo_data_in       ),
    .rdreq      (fifo_read          ),
    .wrreq      (fifo_write         ),
    .rdempty    (fifo_empty         ),
    .q          (fifo_data_out      ),
    .wrfull     (fifo_full          ),
    .rdusedw    (fifo_usedw         ),
    .wrusedw    (fifo_wrusedw       )
    );

`elsif XILINX

`endif

endmodule


`endif