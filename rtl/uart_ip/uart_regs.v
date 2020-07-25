`ifndef UART_REGS
`define UART_REGS

module uart_regs (

    /********* Sys iface *********/
    input   wire                                clk                             ,   // Clock
    input   wire                                rst_n                           ,   // Asynchronous reset active low

    output  wire                                irq                             ,

    /********* Avalon-MM iface *********/
    input   wire [4:0]                          avl_mm_addr                     ,

    input   wire                                avl_mm_read                     ,
    output  wire [31:0]                         avl_mm_readdata                 ,
    output  wire [1:0]                          avl_mm_response                 ,

    input   wire                                avl_mm_write                    ,
    input   wire [31:0]                         avl_mm_writedata                ,
    input   wire [3:0]                          avl_mm_byteenable               ,

    output  wire                                avl_mm_waitrequest              ,

    /********* Control signals *********/

    output  wire [8-1:0]                        data_tx                         ,
    output  wire                                data_tx_wr                      ,
    input   wire                                data_tx_ack                     ,

    input   wire [8-1:0]                        data_rx                         ,
    input   wire                                data_rx_ready                   ,
    output  wire                                data_rx_ack                     ,

    output  wire [15:0]                         prescale                        ,
    input   wire                                tx_busy                         ,
    input   wire                                rx_busy                         ,
    input   wire                                rx_overrun_error                ,
    input   wire                                rx_frame_error
);

localparam REGISTERS_NUMBER     = 6;
localparam ADDR_WIDTH           = 5;
localparam MEMORY_MAP           = {
                                    5'h14,
                                    5'h10,
                                    5'h0C,
                                    5'h08,
                                    5'h04,
                                    5'h00
                                    };

wire [REGISTERS_NUMBER - 1 : 0] sys_read_req;
wire                            sys_read_ready;
wire [31:0]                     sys_read_data;
wire [1:0]                      sys_read_resp;
wire                            sys_write_ready;
wire [REGISTERS_NUMBER - 1 : 0] sys_write_req;
wire [3:0]                      sys_write_strb;
wire [31:0]                     sys_write_data;

avalon_mm_manager  #(
        .REGISTERS_NUMBER (REGISTERS_NUMBER     ),
        .ADDR_WIDTH       (ADDR_WIDTH           ),
        .MEMORY_MAP       (MEMORY_MAP           )
    ) avalon_mm_manager_0 (

    .clk                     (clk                           ),
    .rst_n                   (rst_n                         ),

    /********* Avalon MM Slave iface *********/
    .avl_mm_addr             (avl_mm_addr                   ),

    .avl_mm_read             (avl_mm_read                   ),
    .avl_mm_readdata         (avl_mm_readdata               ),
    .avl_mm_response         (avl_mm_response               ),

    .avl_mm_write            (avl_mm_write                  ),
    .avl_mm_writedata        (avl_mm_writedata              ),
    .avl_mm_byteenable       (avl_mm_byteenable             ),

    .avl_mm_waitrequest      (avl_mm_waitrequest            ),

    /********* sys iface *********/
    .sys_read_req            (sys_read_req                  ),
    .sys_read_ready          (sys_read_ready                ),
    .sys_read_data           (sys_read_data                 ),
    .sys_read_resp           (sys_read_resp                 ),

    .sys_write_ready         (sys_write_ready               ),
    .sys_write_req           (sys_write_req                 ),
    .sys_write_strb          (sys_write_strb                ),
    .sys_write_data          (sys_write_data                )
);


/********* Registers *********/
wire [31:0]  uart_reg_cr;
wire [31:0]  uart_reg_isr;
wire [31:0]  uart_reg_ier;
wire [31:0]  uart_reg_rxd;
wire [31:0]  uart_reg_txd;
wire [31:0]  uart_reg_prscr;

/********* write signals *********/
wire uart_reg_cr_w;
wire uart_reg_isr_w;
wire uart_reg_ier_w;
wire uart_reg_rxd_w;
wire uart_reg_txd_w;
wire uart_reg_prscr_w;

assign uart_reg_cr_w             = sys_write_req[0];
assign uart_reg_isr_w            = sys_write_req[1];
assign uart_reg_ier_w            = sys_write_req[2];
assign uart_reg_rxd_w            = sys_write_req[3];
assign uart_reg_txd_w            = sys_write_req[4];
assign uart_reg_prscr_w          = sys_write_req[5];

/********* Read signals *********/
wire uart_reg_cr_r;
wire uart_reg_isr_r;
wire uart_reg_ier_r;
wire uart_reg_rxd_r;
wire uart_reg_txd_r;
wire uart_reg_prscr_r;

assign uart_reg_cr_r        = sys_read_req[0];
assign uart_reg_isr_r       = sys_read_req[1];
assign uart_reg_ier_r       = sys_read_req[2];
assign uart_reg_rxd_r       = sys_read_req[3];
assign uart_reg_txd_r       = sys_read_req[4];
assign uart_reg_prscr_r     = sys_read_req[5];

/********* IRQ *********/
reg irq_reg;

always @(posedge clk or negedge rst_n)
    if(!rst_n)      irq_reg <= 1'b0;
    else            irq_reg <= |(uart_reg_isr & uart_reg_ier);

assign irq = irq_reg;

/********* Read regs *********/

wire  [31:0]    reg_read;
reg  [31:0]     reg_read_reg;
reg             read_ack;

always @(posedge clk or negedge rst_n)
    if(!rst_n)      reg_read_reg <= 32'b0;
    else            reg_read_reg <= reg_read;

always @(posedge clk or negedge rst_n)
    if(!rst_n)      read_ack <= 1'b0;
    else            read_ack <= |sys_read_req & (!read_ack);

assign sys_read_data    = reg_read_reg;
assign sys_read_ready   = read_ack;
assign sys_read_resp    = 2'b0;
assign reg_read         =   ({32{uart_reg_cr_r}}           & uart_reg_cr)           |
                            ({32{uart_reg_isr_r}}          & uart_reg_isr)          |
                            ({32{uart_reg_ier_r}}          & uart_reg_ier)          |
                            ({32{uart_reg_rxd_r}}          & uart_reg_rxd)          |
                            ({32{uart_reg_prscr_r}}        & uart_reg_prscr)        |
                            ({32{uart_reg_txd_r}}          & uart_reg_txd);

/********* Write regs *********/
reg write_ack;

always @(posedge clk or negedge rst_n)
    if(!rst_n)      write_ack <= 1'b0;
    else            write_ack <= |sys_write_req;

assign sys_write_ready = write_ack;

/********* Regs fields *********/
// CR
reg         uart_reg_cr_rx_enable;
reg         uart_reg_cr_tx_enable;

// ISR
reg         uart_reg_isr_tx_busy                ;
reg         uart_reg_isr_rx_busy                ;
reg         uart_reg_isr_rx_overrun_error       ;
reg         uart_reg_isr_rx_frame_error         ;
reg         uart_reg_isr_data_rx_ready          ;
reg         uart_reg_isr_data_tx_ready          ;

// IER
reg         uart_reg_ier_tx_busy                ;
reg         uart_reg_ier_rx_busy                ;
reg         uart_reg_ier_rx_overrun_error       ;
reg         uart_reg_ier_rx_frame_error         ;
reg         uart_reg_ier_data_rx_ready          ;
reg         uart_reg_ier_data_tx_ready          ;

//RXD
reg [7:0]   r_uart_reg_rxd;

//TXD
reg [7:0]   r_uart_reg_txd;

// PRESCALER
reg [15:0]  uart_reg_prscr_value;

/********* Assigns *********/
assign prescale = uart_reg_prscr_value;

/********* Registers block *********/

/********************************************************************
reg:        CR
offset:     0x00

Field                   offset    width     access
-----------------------------------------------------------
tx_enable               0         1         RW
rx_enable               1         1         RW
********************************************************************/

assign uart_reg_cr = {
                    30'd0,
                    uart_reg_cr_rx_enable,
                    uart_reg_cr_tx_enable
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  uart_reg_cr_tx_enable <= 1'b0;
    else if(uart_reg_cr_w)      uart_reg_cr_tx_enable <= sys_write_data[0];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  uart_reg_cr_rx_enable <= 1'b0;
    else if(uart_reg_cr_w)      uart_reg_cr_rx_enable <= sys_write_data[1];

/********************************************************************
reg:        ISR
offset:     0x04

Field                   offset    width     access
-----------------------------------------------------------
tx_busy                    5         1         RW1C
rx_busy                    4         1         RW1C
rx_overrun_error           3         1         RW1C
rx_frame_error             2         1         RW1C
data_rx_ready              1         1         RW1C
data_tx_ready              0         1         RW1C
********************************************************************/

assign uart_reg_isr = {
                    26'd0,
                    uart_reg_isr_tx_busy              ,
                    uart_reg_isr_rx_busy              ,
                    uart_reg_isr_rx_overrun_error     ,
                    uart_reg_isr_rx_frame_error       ,
                    uart_reg_isr_data_rx_ready        ,
                    uart_reg_isr_data_tx_ready
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                      uart_reg_isr_tx_busy                <= 1'b0;
    else if(uart_reg_isr_w & sys_write_data[5])     uart_reg_isr_tx_busy                <= 1'b0;
    else if(tx_busy         )                       uart_reg_isr_tx_busy                <= 1'b1;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                      uart_reg_isr_rx_busy                <= 1'b0;
    else if(uart_reg_isr_w & sys_write_data[4])     uart_reg_isr_rx_busy                <= 1'b0;
    else if(rx_busy         )                       uart_reg_isr_rx_busy                <= 1'b1;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                      uart_reg_isr_rx_overrun_error       <= 1'b0;
    else if(uart_reg_isr_w & sys_write_data[3])     uart_reg_isr_rx_overrun_error       <= 1'b0;
    else if(rx_overrun_error)                       uart_reg_isr_rx_overrun_error       <= 1'b1;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                      uart_reg_isr_rx_frame_error         <= 1'b0;
    else if(uart_reg_isr_w & sys_write_data[2])     uart_reg_isr_rx_frame_error         <= 1'b0;
    else if(rx_frame_error  )                       uart_reg_isr_rx_frame_error         <= 1'b1;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                      uart_reg_isr_data_rx_ready          <= 1'b0;
    else if(uart_reg_isr_w & sys_write_data[1])     uart_reg_isr_data_rx_ready          <= 1'b0;
    else if(data_rx_ready)                          uart_reg_isr_data_rx_ready          <= 1'b1;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                      uart_reg_isr_data_tx_ready          <= 1'b0;
    else if(uart_reg_isr_w & sys_write_data[0])     uart_reg_isr_data_tx_ready          <= 1'b0;
    else if(data_tx_ack)                            uart_reg_isr_data_tx_ready          <= 1'b1;

/********************************************************************
reg:        IER
offset:     0x08

Field                   offset    width     access
-----------------------------------------------------------
tx_busy                    5         1         RW1C
rx_busy                    4         1         RW1C
rx_overrun_error           3         1         RW1C
rx_frame_error             2         1         RW1C
data_rx_ready              1         1         RW1C
data_tx_ready              0         1         RW1C
********************************************************************/

assign uart_reg_ier = {
                    26'd0,
                    uart_reg_ier_tx_busy,
                    uart_reg_ier_rx_busy,
                    uart_reg_ier_rx_overrun_error,
                    uart_reg_ier_rx_frame_error,
                    uart_reg_ier_data_rx_ready,
                    uart_reg_ier_data_tx_ready
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  uart_reg_ier_tx_busy <= 1'b0;
    else if(uart_reg_ier_w)     uart_reg_ier_tx_busy <= sys_write_data[5];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  uart_reg_ier_rx_busy <= 1'b0;
    else if(uart_reg_ier_w)     uart_reg_ier_rx_busy <= sys_write_data[4];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  uart_reg_ier_rx_overrun_error <= 1'b0;
    else if(uart_reg_ier_w)     uart_reg_ier_rx_overrun_error <= sys_write_data[3];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  uart_reg_ier_rx_frame_error <= 1'b0;
    else if(uart_reg_ier_w)     uart_reg_ier_rx_frame_error <= sys_write_data[2];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  uart_reg_ier_data_rx_ready <= 1'b0;
    else if(uart_reg_ier_w)     uart_reg_ier_data_rx_ready <= sys_write_data[1];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  uart_reg_ier_data_tx_ready <= 1'b0;
    else if(uart_reg_ier_w)     uart_reg_ier_data_tx_ready <= sys_write_data[0];

/********************************************************************
reg:        TR1
offset:     0x0C

Field                   offset    width     access
-----------------------------------------------------------
uart_reg_rxd_r            8        8         RW

********************************************************************/

assign uart_reg_rxd = {
                    24'd0,
                    r_uart_reg_rxd
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  r_uart_reg_rxd <= 8'd0;
    else if(data_rx_ready)      r_uart_reg_rxd <= data_rx;

assign data_rx_ack = data_rx_ready;

/********************************************************************
reg:        TR2
offset:     0x10

Field                   offset    width     access
-----------------------------------------------------------
hs_go_timeout             8         8         RW
hs_trail_timeout          0         8         RW

********************************************************************/

assign uart_reg_txd = {
                    24'd0,
                    r_uart_reg_txd
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  r_uart_reg_txd <= 8'd0;
    else if(uart_reg_txd_w)     r_uart_reg_txd <= sys_write_data[7:0];

assign data_tx = uart_reg_txd_r;

reg set_txd_ready;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                set_txd_ready <= 1'b0;
    else if(uart_reg_txd_w)   set_txd_ready <= 1'b1;
    else if(data_tx_ack)      set_txd_ready <= 1'b0;

assign data_tx_wr = set_txd_ready;

/********************************************************************
reg:        TR2
offset:     0x14

Field                   offset    width     access
-----------------------------------------------------------
prscr_value               0         16         RW

********************************************************************/

assign uart_reg_prscr = {
                    16'd0,
                    uart_reg_prscr_value
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)                      uart_reg_prscr_value <= 16'd0;
    else if(uart_reg_prscr_w)       uart_reg_prscr_value <= sys_write_data[15:0];

endmodule

`endif