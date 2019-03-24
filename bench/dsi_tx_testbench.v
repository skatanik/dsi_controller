`timescale 1ns/1ps

module top_level_csi_tx_tb;

`define MODELING
`define MAX_10

/********************************************************************
16 ms per frame
40 000 000 bit per frame
1666666 rgb pixels per frame
1136x640 = 727040 pixels
********************************************************************/


localparam STITCH_PACKETS = 0;
localparam LANES_NUMBER = 4;
localparam LINE_SIZE_REAL = 640;
localparam LINE_SIZE = LINE_SIZE_REAL;
localparam ROWS_NUM = 48;
localparam DATA_SIZE = LINE_SIZE*ROWS_NUM;
localparam [7:0] SYNC_PATTERN   = 8'b00011101;
localparam LANE_MAX_DELAY   = 30;
localparam LANE_MIN_DELAY   = 0;
localparam DROP_PACKETS_ON_ERROR = 1'b0;
localparam READY_PAUSE_ENABLE   = 1'b0;
localparam PRINT_FRAME   = 1'b0;
localparam ONE_SHOT_MODE = 1'b0;
localparam FREQ     = 500.0;

//`define RECEIVER_ENABLE

real PHY_SLOW_PERIOD = 1.0 / (FREQ/8.0) * 1000.0;
real PHY_FAST_PERIOD = 1.0 / (FREQ/2.0) * 1000.0;

reg [7:0] test_data_array[0:DATA_SIZE-1];

bit                    clk;
bit                    clk_ghz;
bit                    rst_n;
bit                    clk_phy;
bit                    rst_phy_n;
bit                    clk_hs_latch;
bit                    clk_hs;
bit                    clk_hs_clk;

wire                    irq_rx;
wire                    irq_tx;
wire                   dphy_lane_clk_hs;
tri0                   dphy_lane_clk_lp_p;
tri0                   dphy_lane_clk_lp_n;
wire [3:0]             dphy_lane_data_hs;
tri0 [3:0]             dphy_lane_data_lp_p;
tri0 [3:0]             dphy_lane_data_lp_n;

bit [31:0]             avl_mm_addr[1];
bit                    avl_mm_read[1];
wire [31:0]             avl_mm_readdata[1];
wire [1:0]              avl_mm_response[1];
bit                    avl_mm_write[1];
bit [31:0]             avl_mm_writedata[1];
bit [3:0]              avl_mm_byteenable[1];
wire                    avl_mm_waitrequest[1];

pulldown(dphy_lane_clk_lp_p);
pulldown(dphy_lane_clk_lp_n);

initial
begin
forever
begin
   #0.5 clk_ghz = ~clk_ghz;
end
end

initial
begin
#1.25
forever
begin
   #2.5 clk = ~clk;
end
end

initial
begin
repeat(30) @(posedge clk);
rst_n = 1;
end

initial
begin
#1
forever
begin
   #(PHY_SLOW_PERIOD/2) clk_phy = ~clk_phy;
end
end

initial
begin
repeat(30) @(posedge clk_phy);
rst_phy_n = 1;
end

initial
begin
#1
#(PHY_SLOW_PERIOD/4)
forever
begin
//   #9.71 clk_hs_latch = 1'b1;
//   #1.71 clk_hs_latch = 1'b0;
#(PHY_SLOW_PERIOD/2) clk_hs_latch = ~clk_hs_latch;
end
end

initial
begin
#1
forever
begin
   #(PHY_FAST_PERIOD/2) clk_hs = ~clk_hs;      // 400 MHz
end
end

initial
begin
#1
#(PHY_FAST_PERIOD/4)
forever
begin
   #(PHY_FAST_PERIOD/2) clk_hs_clk = ~clk_hs_clk;  // 400 MHz
end
end

/********************************************************************
        Avalon-MM writers
********************************************************************/
task avalon_mm_write;
    input [31:0] addr;
    input [31:0] data;
    input  [2:0] ind;

    #0.01 avl_mm_addr[ind]   = addr;
    avl_mm_write[ind]   = 1'b1;
    avl_mm_writedata[ind]    = data;
    avl_mm_byteenable[ind]   = 4'hf;

    do
        repeat(1) @(posedge clk);
    while(avl_mm_waitrequest[ind]);

    avl_mm_addr[ind]         = 'b0;
    avl_mm_write[ind]        = 1'b0;
    avl_mm_writedata[ind]    = 0;
    avl_mm_byteenable[ind]   = 0;

endtask : avalon_mm_write

task avalon_mm_read;
    input   [31:0] addr;
    output  [31:0] data;
    input    [2:0]  ind;

    #0.01 avl_mm_addr[ind]   = addr;
    avl_mm_read[ind]         = 1'b1;

    do
        repeat(1) @(posedge clk);
    while(avl_mm_waitrequest[ind]);

    data = avl_mm_readdata[ind];

    avl_mm_addr[ind]         = 'b0;
    avl_mm_read[ind]        = 1'b0;

    repeat(1) @(posedge clk);


endtask : avalon_mm_read

bit [31:0] settings_word;
bit [31:0] irq_status_word;
bit [31:0] read_res;

bit controllers_ready;

mailbox write_frame_mailbox;

`define AVL_MM_TX   3'b0
`define AVL_MM_RX   3'b1
`define AVL_MM_DEM  3'd2
`define AVL_MM_CC   3'd3

// Q3.6
localparam [8:0] DEM_WB_COEF_R  = 10'd144;   //2.25
localparam [8:0] DEM_WB_COEF_G  = 10'd64;    //1.0
localparam [8:0] DEM_WB_COEF_B  = 10'd115;   //1.8
localparam [8:0] DEM_EXP_SCALE  = 10'd94;    //1.47
localparam [8:0] DEM_EXP_GAIN   = 10'd80;    //

initial
begin
controllers_ready = 0;
read_res = 0;

for (int i = 0; i < DATA_SIZE; i++) begin
    test_data_array[i] = $urandom_range(0,255);
end

wait(rst_n);
wait(rst_phy_n);
repeat(40) @(posedge clk);

/********* Init TX controller *********/

settings_word = (31'b1 << 1) | (LANES_NUMBER - 1) << 8;

avalon_mm_write(32'b0, settings_word, `AVL_MM_TX);
repeat(1) @(posedge clk);

while(read_res != (32'b1 << 1))
begin
    avalon_mm_read(32'h4, read_res, `AVL_MM_TX);
    repeat(1) @(posedge clk);
end

$display("Lanes ready");

settings_word = (31'b1 << 2) | (31'b1 << 1) | (LANES_NUMBER - 1) << 8;

/********* Enable dphy clock *********/

avalon_mm_write(32'b0, settings_word, `AVL_MM_TX);
repeat(1) @(posedge clk);

while(read_res != (32'd3 << 1))
begin
    avalon_mm_read(32'h4, read_res, `AVL_MM_TX);
    repeat(1) @(posedge clk);
end

$display("Clk ready");

repeat(10) @(posedge clk);

$display("Write CMD");

avalon_mm_write(32'h14, 32'h005F_7538, `AVL_MM_TX);
repeat(10) @(posedge clk);

settings_word = (32'b1 << 3) | (31'b1 << 2) | (31'b1 << 1) | (LANES_NUMBER - 1) << 8;

$display("Send CMD");

avalon_mm_write(32'b0, settings_word, `AVL_MM_TX);
repeat(1) @(posedge clk);

while(!(read_res & (32'd4 << 1)))
begin
    avalon_mm_read(32'h4, read_res, `AVL_MM_TX);
    repeat(1) @(posedge clk);
end

repeat(200) @(posedge clk_phy);

repeat(1) @(posedge clk);

$display("Enable Controller");

settings_word = 32'b1| (31'b1 << 2) | (31'b1 << 1) | (LANES_NUMBER - 1) << 8;

avalon_mm_write(32'b0, settings_word, `AVL_MM_TX);

controllers_ready = 1;

/********* Start data sending *********/
write_frame_mailbox.put(1'b1);

forever
begin : irq_handling
repeat(1) @(posedge clk);
if(irq_rx)
begin
    avalon_mm_read(32'h4, irq_status_word, `AVL_MM_RX);
    repeat(1) @(posedge clk);
    avalon_mm_write(32'h4, 32'hffffffff, `AVL_MM_RX);
    $display("[IRQ checker] Got an IRQ. Status word: %h",irq_status_word);
end
end
end

semaphore traffic_sem = new(1);
mailbox input_data_mailbox;
mailbox enter_lpm_mailbox;
mailbox fifo_write_mailbox;
mailbox repacker_mailbox;


initial
begin

    write_frame_mailbox = new();
    enter_lpm_mailbox = new();
    fifo_write_mailbox = new();
    repacker_mailbox = new();
end

initial
begin
    process::self().srandom(2);
    input_data_mailbox = new();
end

/********* Data loader *********/
bit [23:0] tx_avl_st_in_data;
bit tx_avl_st_in_valid;
bit tx_avl_st_in_endofpacket;
bit tx_avl_st_in_startofpacket;
wire tx_avl_st_in_ready;

wire [31:0]     tx_avl_st_out_data;
wire            tx_avl_st_out_valid;
wire            tx_avl_st_out_endofpacket;
wire            tx_avl_st_out_startofpacket;
wire            tx_avl_st_out_ready;

semaphore avalon_st_loader_sem = new(1);

task automatic avalon_st_loader;
integer k;
bit flag;

k = 0;

avalon_st_loader_sem.get();

//write_frame_mailbox.get(flag);
wait(controllers_ready);
$display("[DATA sender] Start sending data");

@(posedge clk);

while(k < DATA_SIZE/4) begin
    tx_avl_st_in_valid = 1;
    if(k == 0)
        tx_avl_st_in_startofpacket = 1;
    else
        tx_avl_st_in_startofpacket = 0;

    if(k == DATA_SIZE/4  -1)
        tx_avl_st_in_endofpacket = 1;

    if(tx_avl_st_in_ready)
    begin
        tx_avl_st_in_data = {test_data_array[k*3 + 2], test_data_array[k*3 + 1], test_data_array[k*3]};
    end
    @(posedge clk);

    if(tx_avl_st_in_ready & tx_avl_st_in_valid)
        k = k + 1;

    if(k%(LINE_SIZE/4) == 0 && (k != 0) && tx_avl_st_in_ready)
    begin
        tx_avl_st_in_valid = 0;
        tx_avl_st_in_endofpacket = 0;
        repeat(180) @(posedge clk);
        while(!tx_avl_st_in_ready)
            @(posedge clk);
    end

end

$display("[DATA sender] Current k = %d", k);

k = 0;

tx_avl_st_in_endofpacket = 0;
tx_avl_st_in_valid = 0;

$display("[DATA sender] Sending data done");

avalon_st_loader_sem.put();

endtask

 avalon_st_video_2_avalon_st avl_st_video_2_avl_st_top (
    .clk                                (clk                            ),
    .rst_n                              (rst_n                          ),

    /********* Avalon-ST input *********/
    .in_avl_st_data                      (tx_avl_st_in_data             ),
    .in_avl_st_valid                     (tx_avl_st_in_valid            ),
    .in_avl_st_endofpacket               (tx_avl_st_in_endofpacket      ),
    .in_avl_st_startofpacket             (tx_avl_st_in_startofpacket    ),
    .in_avl_st_ready                     (tx_avl_st_in_ready            ),

    /********* Avalon-ST output *********/
    .out_avl_st_data                     (tx_avl_st_out_data            ),
    .out_avl_st_valid                    (tx_avl_st_out_valid           ),
    .out_avl_st_endofpacket              (tx_avl_st_out_endofpacket     ),
    .out_avl_st_startofpacket            (tx_avl_st_out_startofpacket   ),
    .out_avl_st_ready                    (tx_avl_st_out_ready           )

);

/********* CSI TX *********/
dsi_tx_top #(
    .LINE_WIDTH         (LINE_SIZE_REAL     ),
    .BITS_PER_PIXEL     (8                  ),
    .BLANK_TIME         (LINE_SIZE_REAL + 200),  // horizontal blank time
    .BLANK_TIME_HBP_ACT (70                 ),
    .VSA_LINES_NUMBER   (2                  ),
    .VBP_LINES_NUMBER   (4                  ),
    .IMAGE_HEIGHT       (ROWS_NUM           ),
    .VFP_LINES_NUMBER   (4                  )
    ) dsi_tx_top_0(
    /********* System signals *********/
    .clk_sys                                (clk                            ),
    .rst_sys_n                              (rst_n                          ),

    .clk_phy                                (clk_phy                        ),
    .rst_phy_n                              (rst_phy_n                      ),

    .clk_hs_latch                           (clk_hs_latch                   ),
    .clk_hs                                 (clk_hs                         ),
    .clk_hs_clk                             (clk_hs_clk                     ),

    .irq                                    (irq_tx                         ),

    /********* Avalon-ST input *********/
    .in_avl_st_data                         (tx_avl_st_out_data             ),
    .in_avl_st_valid                        (tx_avl_st_out_valid            ),
    .in_avl_st_endofpacket                  (tx_avl_st_out_endofpacket      ),
    .in_avl_st_startofpacket                (tx_avl_st_out_startofpacket    ),
    .in_avl_st_ready                        (tx_avl_st_out_ready            ),

    /********* Output interface *********/
    .dphy_data_hs_out_p                     (),
    .dphy_data_hs_out_n                     (),
    .dphy_data_lp_out_p                     (dphy_lane_data_lp_p            ),
    .dphy_data_lp_out_n                     (dphy_lane_data_lp_n            ),

    .dphy_clk_hs_out_p                      (),
    .dphy_clk_hs_out_n                      (),
    .dphy_clk_lp_out_p                      (dphy_lane_clk_lp_p             ),
    .dphy_clk_lp_out_n                      (dphy_lane_clk_lp_n             ),

    .dphy_clk_hs_out                        (dphy_lane_clk_hs               ),
    .dphy_data_hs_out                       (dphy_lane_data_hs              ),

    /********* Avalon-MM iface *********/
    .avl_mm_address                         (avl_mm_addr[0]                 ),

    .avl_mm_read                            (avl_mm_read[0]                 ),
    .avl_mm_readdata                        (avl_mm_readdata[0]             ),
    .avl_mm_response                        (avl_mm_response[0]             ),

    .avl_mm_write                           (avl_mm_write[0]                ),
    .avl_mm_writedata                       (avl_mm_writedata[0]            ),
    .avl_mm_byteenable                      (avl_mm_byteenable[0]           ),
    .avl_mm_waitrequest                     (avl_mm_waitrequest[0]          )

);

initial
begin

wait(rst_phy_n);

forever
begin
    fork
        avalon_st_loader;
    join_any
end

end

endmodule