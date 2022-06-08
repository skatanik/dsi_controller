`ifndef DSI_TX_REGS
`define DSI_TX_REGS

module dsi_tx_regs (

    /********* Sys iface *********/
    input   wire                                clk                             ,   // Clock
    input   wire                                rst_n                           ,   // Asynchronous reset active low

    output  wire                                irq                             ,

    /********* Avalon-MM iface *********/
    input   wire [5:0]                          avl_mm_addr                     ,

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
    output  wire                                send_cmd                        ,
    output  wire [2:0]                          lanes_number                    ,
    output  wire [23:0]                         cmd_packet                      ,

    output  wire [7:0]                          tlpx_timeout                    ,
    output  wire [7:0]                          hs_prepare_timeout              ,
    output  wire [7:0]                          hs_exit_timeout                 ,
    output  wire [7:0]                          hs_go_timeout                   ,
    output  wire [7:0]                          hs_trail_timeout                ,

    output  wire [11:0]                         o_lines_vtotal                  ,
    output  wire [11:0]                         o_lines_vact                    ,
    output  wire [3:0]                          o_lines_vsync                   ,
    output  wire [3:0]                          o_lines_vbp                     ,
    output  wire [8:0]                          o_lines_vfp                     ,
    output  wire [10:0]                         o_lines_htotal                  ,
    output  wire [5:0]                          o_lines_hbp                     ,
    output  wire [9:0]                          o_lines_hact                    ,

    input   wire                                pix_buffer_underflow_set        ,
    input   wire                                lanes_ready_set                 ,
    input   wire                                lanes_active                    ,
    input   wire                                clk_ready_set

);

localparam REGISTERS_NUMBER     = 10;
localparam ADDR_WIDTH           = 6;
localparam MEMORY_MAP           = {
                                    5'h24,
                                    5'h20,
                                    5'h1C,
                                    5'h18,
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
wire [31:0]  dsi_reg_cr;
wire [31:0]  dsi_reg_isr;
wire [31:0]  dsi_reg_ier;
wire [31:0]  dsi_reg_tr1;
wire [31:0]  dsi_reg_tr2;
wire [31:0]  dsi_reg_cmd;
wire [31:0]  dsi_reg_tim1;
wire [31:0]  dsi_reg_tim2;
wire [31:0]  dsi_reg_tim3;
wire [31:0]  dsi_reg_tim4;

/********* write signals *********/
wire dsi_reg_cr_w;
wire dsi_reg_isr_w;
wire dsi_reg_ier_w;
wire dsi_reg_tr1_w;
wire dsi_reg_tr2_w;
wire dsi_reg_cmd_w;
wire dsi_reg_tim1_w;
wire dsi_reg_tim2_w;
wire dsi_reg_tim3_w;
wire dsi_reg_tim4_w;

assign dsi_reg_cr_w             = sys_write_req[0];
assign dsi_reg_isr_w            = sys_write_req[1];
assign dsi_reg_ier_w            = sys_write_req[2];
assign dsi_reg_tr1_w            = sys_write_req[3];
assign dsi_reg_tr2_w            = sys_write_req[4];
assign dsi_reg_cmd_w            = sys_write_req[5];
assign dsi_reg_tim1_w            = sys_write_req[6];
assign dsi_reg_tim2_w            = sys_write_req[7];
assign dsi_reg_tim3_w            = sys_write_req[8];
assign dsi_reg_tim4_w            = sys_write_req[9];

/********* Read signals *********/
wire dsi_reg_cr_r;
wire dsi_reg_isr_r;
wire dsi_reg_ier_r;
wire dsi_reg_tr1_r;
wire dsi_reg_tr2_r;
wire dsi_reg_cmd_r;
wire dsi_reg_tim1_r;
wire dsi_reg_tim2_r;
wire dsi_reg_tim3_r;
wire dsi_reg_tim4_r;

assign dsi_reg_cr_r        = sys_read_req[0];
assign dsi_reg_isr_r       = sys_read_req[1];
assign dsi_reg_ier_r       = sys_read_req[2];
assign dsi_reg_tr1_r       = sys_read_req[3];
assign dsi_reg_tr2_r       = sys_read_req[4];
assign dsi_reg_cmd_r       = sys_read_req[5];
assign dsi_reg_tim1_r       = sys_read_req[6];
assign dsi_reg_tim2_r       = sys_read_req[7];
assign dsi_reg_tim3_r       = sys_read_req[8];
assign dsi_reg_tim4_r       = sys_read_req[9];

/********* IRQ *********/
reg irq_reg;

always @(posedge clk or negedge rst_n)
    if(!rst_n)      irq_reg <= 1'b0;
    else            irq_reg <= |(dsi_reg_isr & dsi_reg_ier);

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
assign reg_read         =   ({32{dsi_reg_cr_r}}         & dsi_reg_cr)           |
                            ({32{dsi_reg_isr_r}}        & dsi_reg_isr)          |
                            ({32{dsi_reg_ier_r}}        & dsi_reg_ier)          |
                            ({32{dsi_reg_tr1_r}}        & dsi_reg_tr1)          |
                            ({32{dsi_reg_cmd_r}}        & dsi_reg_cmd)          |
                            ({32{dsi_reg_tim1_r}}        & dsi_reg_tim1)          |
                            ({32{dsi_reg_tim2_r}}        & dsi_reg_tim2)          |
                            ({32{dsi_reg_tim3_r}}        & dsi_reg_tim3)          |
                            ({32{dsi_reg_tim4_r}}        & dsi_reg_tim4)          |
                            ({32{dsi_reg_tr2_r}}        & dsi_reg_tr2);

/********* Write regs *********/
reg write_ack;

always @(posedge clk or negedge rst_n)
    if(!rst_n)      write_ack <= 1'b0;
    else            write_ack <= |sys_write_req;

assign sys_write_ready = write_ack;

/********* Regs fields *********/
// CR
reg         dsi_reg_cr_assembler_enable;
reg         dsi_reg_cr_lanes_enable;
reg         dsi_reg_cr_clk_enable;
reg         dsi_reg_cr_send_cmd;
reg [1:0]   dsi_reg_cr_lanes_number;

// ISR
reg         dsi_reg_isr_pix_buff_underflow;
reg         dsi_reg_isr_lanes_ready;
reg         dsi_reg_isr_clk_ready;
reg         dsi_reg_isr_lanes_became_active;
reg         dsi_reg_isr_lanes_became_unactive;

// IER
reg         dsi_reg_ier_pix_buff_underflow;
reg         dsi_reg_ier_lanes_ready;
reg         dsi_reg_ier_clk_ready;
reg         dsi_reg_ier_lanes_became_active;
reg         dsi_reg_ier_lanes_became_unactive;


//TR1
reg [7:0]   dsi_reg_tr1_tlpx_timeout;
reg [7:0]   dsi_reg_tr1_hs_prepare_timeout;
reg [7:0]   dsi_reg_tr1_hs_exit_timeout;

// TR2
reg [7:0]   dsi_reg_tr1_hs_go_timeout;
reg [7:0]   dsi_reg_tr1_hs_trail_timeout;

reg [23:0]  dsi_reg_cmd_field;

// timings regs
reg [11:0]  dsi_reg_tim1_lines_vtotal;
reg [11:0]  dsi_reg_tim1_lines_vact;

reg [3:0]  dsi_reg_tim2_lines_vsync;
reg [3:0]  dsi_reg_tim2_lines_vbp;
reg [8:0]  dsi_reg_tim2_lines_vfp;

reg [10:0]  dsi_reg_tim3_lines_htotal;
reg [5:0]  dsi_reg_tim3_lines_hbp;
reg [9:0]  dsi_reg_tim3_lines_hact;



/********* Assigns *********/

assign lanes_number                 = dsi_reg_cr_lanes_number + 3'd1;
assign packet_assembler_enable      = dsi_reg_cr_assembler_enable;
assign send_cmd                     = dsi_reg_cr_send_cmd;
assign lanes_enable                 = dsi_reg_cr_lanes_enable;
assign clk_out_enable               = dsi_reg_cr_clk_enable;
assign cmd_packet                   = dsi_reg_cmd_field;

assign tlpx_timeout         = dsi_reg_tr1_tlpx_timeout;
assign hs_prepare_timeout   = dsi_reg_tr1_hs_prepare_timeout;
assign hs_exit_timeout      = dsi_reg_tr1_hs_exit_timeout;
assign hs_go_timeout        = dsi_reg_tr1_hs_go_timeout;
assign hs_trail_timeout     = dsi_reg_tr1_hs_trail_timeout;


assign o_lines_vtotal      = dsi_reg_tim1_lines_vtotal;
assign o_lines_vact        = dsi_reg_tim1_lines_vact;
assign o_lines_vsync       = dsi_reg_tim2_lines_vsync;
assign o_lines_vbp         = dsi_reg_tim2_lines_vbp;
assign o_lines_vfp         = dsi_reg_tim2_lines_vfp;
assign o_lines_htotal      = dsi_reg_tim3_lines_htotal;
assign o_lines_hbp         = dsi_reg_tim3_lines_hbp;
assign o_lines_hact        = dsi_reg_tim3_lines_hact;


wire lanes_became_active_set;
wire lanes_became_unactive_set;

reg lanes_active_reg;

/********* Registers block *********/

/********************************************************************
reg:        CR
offset:     0x00

Field                   offset    width     access
-----------------------------------------------------------
assembler_enable        0         1         RW
lanes_enable            1         1         RW
clk_enable              2         1         RW
send_cmd                3         1         RW
lanes_number            8         2         RW
********************************************************************/

assign dsi_reg_cr = {
                    20'd0,
                    dsi_reg_cr_lanes_number,
                    5'b0,
                    dsi_reg_cr_send_cmd,
                    dsi_reg_cr_clk_enable,
                    dsi_reg_cr_lanes_enable,
                    dsi_reg_cr_assembler_enable
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  dsi_reg_cr_send_cmd <= 1'b0;
    else if(dsi_reg_cr_w)       dsi_reg_cr_send_cmd <= sys_write_data[3];
    else if(lanes_active)       dsi_reg_cr_send_cmd <= 1'b0;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  dsi_reg_cr_assembler_enable <= 1'b0;
    else if(dsi_reg_cr_w)       dsi_reg_cr_assembler_enable <= sys_write_data[0];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  dsi_reg_cr_lanes_enable <= 1'b0;
    else if(dsi_reg_cr_w)       dsi_reg_cr_lanes_enable <= sys_write_data[1];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  dsi_reg_cr_clk_enable <= 1'b0;
    else if(dsi_reg_cr_w)       dsi_reg_cr_clk_enable <= sys_write_data[2];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  dsi_reg_cr_lanes_number <= 2'd3;
    else if(dsi_reg_cr_w)       dsi_reg_cr_lanes_number <= sys_write_data[10:9];

/********************************************************************
reg:        ISR
offset:     0x04

Field                   offset    width     access
-----------------------------------------------------------
pix_buff_underflow          0         1         RW1C
lanes_ready                 1         1         RW1C
clk_ready                   2         1         RW1C
lanes_became_active         3         1         RW1C
lanes_became_unactive       4         1         RW1C
********************************************************************/

assign dsi_reg_isr = {
                    27'd0,
                    dsi_reg_isr_lanes_became_active,
                    dsi_reg_isr_lanes_became_unactive,
                    dsi_reg_isr_clk_ready,
                    dsi_reg_isr_lanes_ready,
                    dsi_reg_isr_pix_buff_underflow
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                      dsi_reg_isr_pix_buff_underflow <= 1'b0;
    else if(dsi_reg_isr_w & sys_write_data[0])      dsi_reg_isr_pix_buff_underflow <= 1'b0;
    else if(pix_buffer_underflow_set)               dsi_reg_isr_pix_buff_underflow <= 1'b1;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                      dsi_reg_isr_lanes_ready <= 1'b0;
    else if(dsi_reg_isr_w & sys_write_data[1])      dsi_reg_isr_lanes_ready <= 1'b0;
    else if(lanes_ready_set)                        dsi_reg_isr_lanes_ready <= 1'b1;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                      dsi_reg_isr_clk_ready <= 1'b0;
    else if(dsi_reg_isr_w & sys_write_data[2])      dsi_reg_isr_clk_ready <= 1'b0;
    else if(clk_ready_set)                          dsi_reg_isr_clk_ready <= 1'b1;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                      dsi_reg_isr_lanes_became_active <= 1'b0;
    else if(dsi_reg_isr_w & sys_write_data[3])      dsi_reg_isr_lanes_became_active <= 1'b0;
    else if(lanes_became_active_set)                dsi_reg_isr_lanes_became_active <= 1'b1;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                      dsi_reg_isr_lanes_became_unactive <= 1'b0;
    else if(dsi_reg_isr_w & sys_write_data[4])      dsi_reg_isr_lanes_became_unactive <= 1'b0;
    else if(lanes_became_unactive_set)              dsi_reg_isr_lanes_became_unactive <= 1'b1;

always @(posedge clk or negedge rst_n)
    if(!rst_n)      lanes_active_reg <= 1'b0;
    else            lanes_active_reg <= lanes_active;

assign lanes_became_active_set      = (lanes_active_reg ^ lanes_active) & lanes_active;
assign lanes_became_unactive_set    = (lanes_active_reg ^ lanes_active) & !lanes_active;

/********************************************************************
reg:        IER
offset:     0x08

Field                   offset    width     access
-----------------------------------------------------------
pix_buff_underflow_ier   0         1         RW1C

********************************************************************/

assign dsi_reg_ier = {
                    27'd0,
                    dsi_reg_ier_lanes_became_active,
                    dsi_reg_ier_lanes_became_unactive,
                    dsi_reg_ier_clk_ready,
                    dsi_reg_ier_lanes_ready,
                    dsi_reg_ier_pix_buff_underflow
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  dsi_reg_ier_pix_buff_underflow <= 1'b0;
    else if(dsi_reg_ier_w)      dsi_reg_ier_pix_buff_underflow <= sys_write_data[0];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  dsi_reg_ier_lanes_ready <= 1'b0;
    else if(dsi_reg_ier_w)      dsi_reg_ier_lanes_ready <= sys_write_data[1];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  dsi_reg_ier_clk_ready <= 1'b0;
    else if(dsi_reg_ier_w)      dsi_reg_ier_clk_ready <= sys_write_data[2];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  dsi_reg_ier_lanes_became_unactive <= 1'b0;
    else if(dsi_reg_ier_w)      dsi_reg_ier_lanes_became_unactive <= sys_write_data[3];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  dsi_reg_ier_lanes_became_active <= 1'b0;
    else if(dsi_reg_ier_w)      dsi_reg_ier_lanes_became_active <= sys_write_data[4];

/********************************************************************
reg:        TR1
offset:     0x0C

Field                   offset    width     access
-----------------------------------------------------------
tlpx_timeout              16        8         RW
hs_prepare_timeout        8         8         RW
hs_exit_timeout           0         8         RW

********************************************************************/

assign dsi_reg_tr1 = {
                    8'd0,
                    dsi_reg_tr1_tlpx_timeout,
                    dsi_reg_tr1_hs_prepare_timeout,
                    dsi_reg_tr1_hs_exit_timeout
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)              dsi_reg_tr1_tlpx_timeout <= 8'd8;
    else if(dsi_reg_tr1_w)  dsi_reg_tr1_tlpx_timeout <= sys_write_data[23:16];

always @(posedge clk or negedge rst_n)
    if(!rst_n)              dsi_reg_tr1_hs_prepare_timeout <= 8'd1;
    else if(dsi_reg_tr1_w)  dsi_reg_tr1_hs_prepare_timeout <= sys_write_data[15:8];

always @(posedge clk or negedge rst_n)
    if(!rst_n)              dsi_reg_tr1_hs_exit_timeout <= 8'd3;
    else if(dsi_reg_tr1_w)  dsi_reg_tr1_hs_exit_timeout <= sys_write_data[7:0];

/********************************************************************
reg:        TR2
offset:     0x10

Field                   offset    width     access
-----------------------------------------------------------
hs_go_timeout             8         8         RW
hs_trail_timeout          0         8         RW

********************************************************************/

assign dsi_reg_tr2 = {
                    16'd0,
                    dsi_reg_tr1_hs_go_timeout,
                    dsi_reg_tr1_hs_trail_timeout
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)              dsi_reg_tr1_hs_go_timeout <= 8'd30;
    else if(dsi_reg_tr2_w)  dsi_reg_tr1_hs_go_timeout <= sys_write_data[15:8];

always @(posedge clk or negedge rst_n)
    if(!rst_n)              dsi_reg_tr1_hs_trail_timeout <= 8'd2;
    else if(dsi_reg_tr2_w)  dsi_reg_tr1_hs_trail_timeout <= sys_write_data[7:0];

/********************************************************************
reg:        TR2
offset:     0x14

Field                   offset    width     access
-----------------------------------------------------------
cmd_field             8         8         RW
hs_trail_timeout          0         8         RW

********************************************************************/

assign dsi_reg_cmd = {
                    8'd0,
                    dsi_reg_cmd_field
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)              dsi_reg_cmd_field <= 24'd0;
    else if(dsi_reg_cmd_w)  dsi_reg_cmd_field <= sys_write_data[23:0];

/********************************************************************
reg:        TIM1
offset:     0x18

Field                           offset    width     access
-----------------------------------------------------------
dsi_reg_tim1_lines_vtotal        0         12         RW
dsi_reg_tim1_lines_vact          16         12         RW

********************************************************************/

assign dsi_reg_cmd = {
                    4'b0,
                    dsi_reg_tim1_lines_vact,
                    4'b0,
                    dsi_reg_tim1_lines_vtotal
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  dsi_reg_tim1_lines_vact <= 'd0;
    else if(dsi_reg_tim1_w)     dsi_reg_tim1_lines_vact <= sys_write_data[28:16];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  dsi_reg_tim1_lines_vtotal <= 'd0;
    else if(dsi_reg_tim1_w)     dsi_reg_tim1_lines_vtotal <= sys_write_data[11:0];


/********************************************************************
reg:        TIM2
offset:     0x18

Field                           offset    width     access
-----------------------------------------------------------
dsi_reg_tim2_lines_vsync        20         4         RW
dsi_reg_tim2_lines_vbp          16         4         RW
dsi_reg_tim2_lines_vfp          0         9         RW

********************************************************************/
assign dsi_reg_cmd = {
                    8'b0,
                    dsi_reg_tim2_lines_vsync,
                    dsi_reg_tim2_lines_vbp,
                    7'b0,
                    dsi_reg_tim2_lines_vfp
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  dsi_reg_tim2_lines_vsync <= 'd0;
    else if(dsi_reg_tim1_w)     dsi_reg_tim2_lines_vsync <= sys_write_data[28:24];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  dsi_reg_tim2_lines_vbp <= 'd0;
    else if(dsi_reg_tim1_w)     dsi_reg_tim2_lines_vbp <= sys_write_data[20:16];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  dsi_reg_tim2_lines_vfp <= 'd0;
    else if(dsi_reg_tim1_w)     dsi_reg_tim2_lines_vfp <= sys_write_data[9:0];

/********************************************************************
reg:        TIM3
offset:     0x18

Field                           offset    width     access
-----------------------------------------------------------
dsi_reg_tim3_lines_htotal        16         11         RW
dsi_reg_tim3_lines_hbp          10          6         RW
dsi_reg_tim3_lines_hact          0         10         RW

********************************************************************/
assign dsi_reg_cmd = {
                    16'b0,
                    dsi_reg_tim3_lines_htotal,
                    dsi_reg_tim3_lines_hbp,
                    dsi_reg_tim3_lines_hact
                    };

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  dsi_reg_tim3_lines_htotal <= 24'd0;
    else if(dsi_reg_tim1_w)     dsi_reg_tim3_lines_htotal <= sys_write_data[27:16];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  dsi_reg_tim3_lines_hbp <= 24'd0;
    else if(dsi_reg_tim1_w)     dsi_reg_tim3_lines_hbp <= sys_write_data[15:10];

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  dsi_reg_tim3_lines_hact <= 24'd0;
    else if(dsi_reg_tim1_w)     dsi_reg_tim3_lines_hact <= sys_write_data[9:0];

endmodule

`endif