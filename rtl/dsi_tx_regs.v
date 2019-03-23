`ifndef CSI_TX_REGS
`define CSI_TX_REGS

module csi_tx_regs (

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

    output  wire                                packet_assembler_enable         ,
    output  wire                                lanes_enable                    ,
    output  wire                                clk_out_enable                  ,
    output  wire [2:0]                          lanes_number                    ,

    output  wire [7:0]                          tlpx_timeout                    ,
    output  wire [7:0]                          hs_prepare_timeout              ,
    output  wire [7:0]                          hs_exit_timeout                 ,
    output  wire [7:0]                          hs_go_timeout                   ,
    output  wire [7:0]                          hs_trail_timeout                ,

    input   wire                                pix_buffer_underflow_set        ,
    input   wire                                lanes_ready_set                 ,
    input   wire                                clk_ready_set

);

localparam REGISTERS_NUMBER     = 5;
localparam ADDR_WIDTH           = 5;
localparam MEMORY_MAP           = {
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
wire [31:0]  csi_reg_cr;
wire [31:0]  csi_reg_isr;
wire [31:0]  csi_reg_ier;
wire [31:0]  csi_reg_tr1;
wire [31:0]  csi_reg_tr2;

/********* write signals *********/
wire csi_reg_cr_w;
wire csi_reg_isr_w;
wire csi_reg_ier_w;
wire csi_reg_tr1_w;
wire csi_reg_tr2_w;

assign csi_reg_cr_w             = sys_write_req[0];
assign csi_reg_isr_w            = sys_write_req[1];
assign csi_reg_ier_w            = sys_write_req[2];
assign csi_reg_tr1_w            = sys_write_req[3];
assign csi_reg_tr2_w            = sys_write_req[4];

/********* Read signals *********/
wire csi_reg_cr_r;
wire csi_reg_isr_r;
wire csi_reg_ier_r;
wire csi_reg_tr1_r;
wire csi_reg_tr2_r;

assign csi_reg_cr_r        = sys_read_req[0];
assign csi_reg_isr_r       = sys_read_req[1];
assign csi_reg_ier_r       = sys_read_req[2];
assign csi_reg_tr1_r       = sys_read_req[3];
assign csi_reg_tr2_r       = sys_read_req[4];

/********* IRQ *********/
reg irq_reg;

always @(posedge clk or negedge rst_n)
    if(!rst_n)      irq_reg <= 1'b0;
    else            irq_reg <= |(csi_reg_isr & csi_reg_ier);

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
assign reg_read         =   ({32{csi_reg_cr_r}}         & csi_reg_cr)           |
                            ({32{csi_reg_isr_r}}        & csi_reg_isr)          |
                            ({32{csi_reg_ier_r}}        & csi_reg_ier)          |
                            ({32{csi_reg_tr1_r}}        & csi_reg_tr1)          |
                            ({32{csi_reg_tr2_r}}        & csi_reg_tr2);

/********* Write regs *********/
reg write_ack;

always @(posedge clk or negedge rst_n)
    if(!rst_n)      write_ack <= 1'b0;
    else            write_ack <= |sys_write_req;

assign sys_write_ready = write_ack;

/********* Regs fields *********/
// CR
reg         csi_reg_cr_assembler_enable;
reg         csi_reg_cr_lanes_enable;
reg         csi_reg_cr_clk_enable;
reg [1:0]   csi_reg_cr_lanes_number;

// ISR
reg         csi_reg_isr_pix_buff_underflow;
reg         csi_reg_isr_lanes_ready;
reg         csi_reg_isr_clk_ready;

// IER
reg         csi_reg_ier_pix_buff_underflow;
reg         csi_reg_ier_lanes_ready;
reg         csi_reg_ier_clk_ready;


//TR1
reg [7:0]   csi_reg_tr1_tlpx_timeout;
reg [7:0]   csi_reg_tr1_hs_prepare_timeout;
reg [7:0]   csi_reg_tr1_hs_exit_timeout;

// TR2
reg [7:0]   csi_reg_tr1_hs_go_timeout;
reg [7:0]   csi_reg_tr1_hs_trail_timeout;

/********* Assigns *********/

assign lanes_number                 = csi_reg_cr_lanes_number + 3'd1;
assign packet_assembler_enable      = csi_reg_cr_assembler_enable;
assign lanes_enable                 = csi_reg_cr_lanes_enable;
assign clk_out_enable               = csi_reg_cr_clk_enable;

assign tlpx_timeout         = csi_reg_tr1_tlpx_timeout;
assign hs_prepare_timeout   = csi_reg_tr1_hs_prepare_timeout;
assign hs_exit_timeout      = csi_reg_tr1_hs_exit_timeout;
assign hs_go_timeout        = csi_reg_tr1_hs_go_timeout;
assign hs_trail_timeout     = csi_reg_tr1_hs_trail_timeout;


/********* Registers block *********/

/********************************************************************
reg:        CR
offset:     0x00

Field                   offset    width     access
-----------------------------------------------------------
assembler_enable        0         1         RW
lanes_enable            1         1         RW
clk_enable              3         1         RW
lanes_number            8         2         RW
********************************************************************/

assign csi_reg_cr = {
                    20'd0,
                    csi_reg_cr_lanes_number,
                    5'b0,
                    csi_reg_cr_clk_enable,
                    csi_reg_cr_lanes_enable,
                    csi_reg_cr_assembler_enable
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  csi_reg_cr_assembler_enable <= 1'b0;
    else if(csi_reg_cr_w)       csi_reg_cr_assembler_enable <= sys_write_data[0];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  csi_reg_cr_lanes_enable <= 1'b0;
    else if(csi_reg_cr_w)       csi_reg_cr_lanes_enable <= sys_write_data[1];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  csi_reg_cr_clk_enable <= 1'b0;
    else if(csi_reg_cr_w)       csi_reg_cr_clk_enable <= sys_write_data[2];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  csi_reg_cr_lanes_number <= 2'd3;
    else if(csi_reg_cr_w)       csi_reg_cr_lanes_number <= sys_write_data[9:8];

/********************************************************************
reg:        ISR
offset:     0x04

Field                   offset    width     access
-----------------------------------------------------------
pix_buff_underflow         0         1         RW1C
lanes_ready                1         1         RW1C
clk_ready                  2         1         RW1C
********************************************************************/

assign csi_reg_isr = {
                    29'd0,
                    csi_reg_isr_clk_ready,
                    csi_reg_isr_lanes_ready,
                    csi_reg_isr_pix_buff_underflow
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                  csi_reg_isr_pix_buff_underflow <= 1'b0;
    else if(csi_reg_isr_w & sys_write_data[0])   csi_reg_isr_pix_buff_underflow <= 1'b0;
    else if(pix_buffer_underflow_set)           csi_reg_isr_pix_buff_underflow <= 1'b1;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                  csi_reg_isr_lanes_ready <= 1'b0;
    else if(csi_reg_isr_w & sys_write_data[1])   csi_reg_isr_lanes_ready <= 1'b0;
    else if(lanes_ready_set)                    csi_reg_isr_lanes_ready <= 1'b1;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                  csi_reg_isr_clk_ready <= 1'b0;
    else if(csi_reg_isr_w & sys_write_data[2])   csi_reg_isr_clk_ready <= 1'b0;
    else if(clk_ready_set)                      csi_reg_isr_clk_ready <= 1'b1;

/********************************************************************
reg:        IER
offset:     0x08

Field                   offset    width     access
-----------------------------------------------------------
pix_buff_underflow_ier   0         1         RW1C

********************************************************************/

assign csi_reg_ier = {
                    29'd0,
                    csi_reg_ier_clk_ready,
                    csi_reg_ier_lanes_ready,
                    csi_reg_ier_pix_buff_underflow
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)              csi_reg_ier_pix_buff_underflow <= 1'b0;
    else if(csi_reg_ier_w)   csi_reg_ier_pix_buff_underflow <= sys_write_data[0];

always @(posedge clk or negedge rst_n)
    if(!rst_n)              csi_reg_ier_lanes_ready <= 1'b0;
    else if(csi_reg_ier_w)   csi_reg_ier_lanes_ready <= sys_write_data[1];

always @(posedge clk or negedge rst_n)
    if(!rst_n)              csi_reg_ier_clk_ready <= 1'b0;
    else if(csi_reg_ier_w)   csi_reg_ier_clk_ready <= sys_write_data[2];

/********************************************************************
reg:        TR1
offset:     0x0C

Field                   offset    width     access
-----------------------------------------------------------
tlpx_timeout              16        8         RW
hs_prepare_timeout        8         8         RW
hs_exit_timeout           0         8         RW

********************************************************************/

assign csi_reg_tr1 = {
                    8'd0,
                    csi_reg_tr1_tlpx_timeout,
                    csi_reg_tr1_hs_prepare_timeout,
                    csi_reg_tr1_hs_exit_timeout
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)              csi_reg_tr1_tlpx_timeout <= 8'd8;
    else if(csi_reg_tr1_w)  csi_reg_tr1_tlpx_timeout <= sys_write_data[23:16];

always @(posedge clk or negedge rst_n)
    if(!rst_n)              csi_reg_tr1_hs_prepare_timeout <= 8'd15;
    else if(csi_reg_tr1_w)  csi_reg_tr1_hs_prepare_timeout <= sys_write_data[15:8];

always @(posedge clk or negedge rst_n)
    if(!rst_n)              csi_reg_tr1_hs_exit_timeout <= 8'd3;
    else if(csi_reg_tr1_w)  csi_reg_tr1_hs_exit_timeout <= sys_write_data[7:0];

/********************************************************************
reg:        TR2
offset:     0x10

Field                   offset    width     access
-----------------------------------------------------------
hs_go_timeout             8         8         RW
hs_trail_timeout          0         8         RW

********************************************************************/

assign csi_reg_tr2 = {
                    16'd0,
                    csi_reg_tr1_hs_go_timeout,
                    csi_reg_tr1_hs_trail_timeout
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)              csi_reg_tr1_hs_go_timeout <= 8'd30;
    else if(csi_reg_tr2_w)  csi_reg_tr1_hs_go_timeout <= sys_write_data[15:8];

always @(posedge clk or negedge rst_n)
    if(!rst_n)              csi_reg_tr1_hs_trail_timeout <= 8'd2;
    else if(csi_reg_tr2_w)  csi_reg_tr1_hs_trail_timeout <= sys_write_data[7:0];

endmodule

`endif