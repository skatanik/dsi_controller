`timescale 1ns/1ps
module dsi_core_tb();

localparam DATA_SIZE = 27264;

bit [31:0] memory_data [0:36352 - 1];

bit rst_n;
bit clk_sys;
bit clk_fast;
bit rst_n_fast;

logic [31:0]    iface_write_data;
logic [3:0]     iface_write_strb;
logic           iface_write_rqst;
logic           iface_last_word;
logic           iface_lpm_en;
logic           iface_data_rqst;

logic           lines_enable;
logic           clock_enable;
logic           lines_ready;
logic           clock_ready;
logic           lines_active;

logic [31:0]    hs_lane_output;
logic [3:0]     hs_lane_enable;
logic [3:0]     LP_p_output;
logic [3:0]     LP_n_output;
logic [3:0]     LP_enable;

logic           clock_LP_p_output;
logic           clock_LP_n_output;
logic           clock_LP_enable;
logic           clock_hs_enable;
logic [7:0]     clock_hs_output;

logic           lpm_enable;
logic           user_cmd_transmission_mode;
logic           enable_EoT_sending;
logic           streaming_enable;

logic [255:0]   alv_dataread;
logic           avl_read;
logic           avl_waitrequest;
logic           avl_datavalid;
logic [31:0]    avl_address;

initial begin
rst_n               = 0;
#100
wait(10) @(posedge clk_sys)
rst_n = 1;
end

initial
begin
#1.25;
clk_sys = 1;
forever    #10 clk_sys      = ~clk_sys;
end

initial
begin
clk_fast = 1;
#5;
forever    #5 clk_fast      = ~clk_fast;
end

initial begin
rst_n_fast               = 0;
#100
wait(10) @(posedge clk_fast)
rst_n_fast = 1;
end

logic           pix_fifo_write;
logic [31:0]    pix_fifo_data;
logic           pix_fifo_full;
logic [9:0]     pix_fifo_usedw;
logic [31:0]    pix_fifo_data_r;
logic           pix_fifo_empty;
logic           pix_fifo_read;

logic [31:0]    usr_fifo_data_r;
logic [31:0]    usr_fifo_data;
logic           usr_fifo_usedw;
logic           usr_fifo_empty;
logic           usr_fifo_full;
logic           usr_fifo_read;
logic           usr_fifo_write;

logic           uploader_en;

pixel_uploader pixel_uploader_0 (

        .clk                         (clk_fast          ),
        .rst_n                       (rst_n_fast        ),

    /********* Avalon MM Master read-only iface *********/
        .avl_mm_addr                 (avl_address       ),
        .avl_mm_read                 (avl_read          ),

        .avl_mm_readdata             (alv_dataread      ),
        .avl_mm_readdatavalid        (avl_datavalid     ),
        .avl_mm_response             (2'b0              ),
        .avl_mm_waitrequest          (avl_waitrequest   ),

    /********* Pixel FIFO iface *********/
        .pix_fifo_write              (pix_fifo_write    ),
        .pix_fifo_data               (pix_fifo_data     ),

        .pix_fifo_full               (pix_fifo_full     ),
        .pix_fifo_usedw              (pix_fifo_usedw    ),

    /********* Input control *********/
        .enable                      (uploader_en       ),
        .word_mode                   (1'b1              ),   // 1 - word addressing, 0 - byte addressing
        .base_address                (32'b0             ),
        .total_size                  (36352             ),
        .pix_fifo_threshold          (10'd1000          ),
        .transform_data              (1'b1              ),   // 0 - write data from memory directly to fifo, 1 - transform 4 bytes to 4, removing empty 3rd byte in memory data

        .read_error_w                (),
        .active                      ()

    );


initial
begin

for(int i = 0; i < 36352; i = i + 1)
    memory_data[i] = $urandom_range(0,32'hffffffff);

wait(rst_n_fast);
forever
    memory_read;

end

pix_fifo_32x1024    fifo_1024_32_0 (
    .data           (pix_fifo_data      ),
    .rdclk          (clk_sys            ),
    .rdreq          (pix_fifo_read      ),
    .wrclk          (clk_fast           ),
    .wrreq          (pix_fifo_write     ),
    .q              (pix_fifo_data_r    ),
    .rdempty        (pix_fifo_empty     ),
    .wrfull         (pix_fifo_full      ),
    .wrusedw        (pix_fifo_usedw     )
    );

usr_fifo_32x128    usr_fifo_32x128_0 (
    .data           (usr_fifo_data      ),
    .rdclk          (clk_sys            ),
    .rdreq          (usr_fifo_read      ),
    .wrclk          (clk_fast           ),
    .wrreq          (usr_fifo_write     ),
    .q              (usr_fifo_data_r    ),
    .rdempty        (usr_fifo_empty     ),
    .wrfull         (usr_fifo_full      )
 //   .wrusedw        (usr_fifo_usedw     )
    );

packets_assembler packets_assembler_0
(
    /********* Clock signals *********/
        .clk                                 (clk_sys       ),
        .reset_n                             (rst_n         ),

    /********* lanes controller iface *********/
        .iface_write_data                    (iface_write_data  ),
        .iface_write_strb                    (iface_write_strb  ),
        .iface_write_rqst                    (iface_write_rqst  ),
        .iface_last_word                     (iface_last_word   ),
        .iface_lpm_en                        (iface_lpm_en      ), //0 - hs, 1 - lp should be asserted at least one cycle before iface_write_rqst and disasserted one cycle after iface_last_word

        .iface_data_rqst                     (iface_data_rqst   ),
        .lanes_controller_lines_active       (lines_active      ),

    /********* pixel FIFO interface *********/
        .pix_fifo_data                       (pix_fifo_data_r   ),
        .pix_fifo_empty                      (pix_fifo_empty    ),
        .pix_fifo_read                       (pix_fifo_read     ),

    /********* cmd FIFO interface *********/
        .usr_fifo_data                       (usr_fifo_data_r   ),
        .usr_fifo_empty                      (usr_fifo_empty    ),
        .usr_fifo_read                       (usr_fifo_read     ),

    /********* Control inputs *********/
        .lpm_enable                          (lpm_enable                    ),   // 1: go to LPM after sending commands. 0: send blank packet after sending command or data
        .user_cmd_transmission_mode          (user_cmd_transmission_mode    ), // 0: data from user fifo is sent in HS mode; 1: data from user fifo is sent in LP mode.
        .enable_EoT_sending                  (enable_EoT_sending            ),
        .streaming_enable                    (streaming_enable              ),

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

dsi_lanes_controller dsi_lanes_controller_0
    (
        /********* Clock signals *********/
        .clk_sys                 (clk_sys               ), // serial data clock
        .rst_n                   (rst_n                 ),

        /********* Fifo signals *********/
        .iface_write_data        (iface_write_data      ),
        .iface_write_strb        (iface_write_strb      ), // iface_write_strb[4] - mode flag.
        .iface_write_rqst        (iface_write_rqst      ),
        .iface_last_word         (iface_last_word       ),
        .iface_lpm_en            (iface_lpm_en          ), //0 - hs, 1 - lp should be asserted at least one cycle before iface_write_rqst and disasserted one cycle after iface_last_word

        .iface_data_rqst         (iface_data_rqst       ),

        /********* Misc signals *********/

        .reg_lanes_number        (2'd3                  ),
        .lines_enable            (lines_enable          ),   // enable output buffers of LP lines
        .clock_enable            (clock_enable          ),   // enable clock

        /********* Output signals *********/
        .lines_ready             (lines_ready           ),
        .clock_ready             (clock_ready           ),
        .lines_active            (lines_active          ),

        /********* Lanes *********/
        .hs_lane_output          (hs_lane_output        ),
        .hs_lane_enable          (hs_lane_enable        ),
        .LP_p_output             (LP_p_output           ),
        .LP_n_output             (LP_n_output           ),
        .LP_enable               (LP_enable             ),

        /********* Clock output *********/
        .clock_LP_p_output       (clock_LP_p_output     ),
        .clock_LP_n_output       (clock_LP_n_output     ),
        .clock_LP_enable         (clock_LP_enable       ),
        .clock_hs_output         (clock_hs_output       ),
        .clock_hs_enable         (clock_hs_enable       )

    );

/********* enable lines block *********/

bit dsi_lanes_controller_ready;

initial
begin
lines_enable = 0;
clock_enable = 0;
dsi_lanes_controller_ready = 0;
wait(rst_n);

repeat(10) @(posedge clk_sys);
lines_enable = 1;

wait(lines_ready);
repeat(10) @(posedge clk_sys);
clock_enable = 1;

wait(clock_ready);
repeat(10) @(posedge clk_sys);
dsi_lanes_controller_ready = 1;
end

`include test_tasks.sv


initial
begin
lpm_enable = 1;
avl_waitrequest = 0;
avl_datavalid = 0;
user_cmd_transmission_mode = 0;
enable_EoT_sending = 0;
streaming_enable = 0;
alv_dataread = 0;
uploader_en = 0;
usr_fifo_data   = 0;
usr_fifo_write  = 0;

wait(rst_n_fast);

repeat(20) @(posedge clk_fast);

write_usr_fifo(32'h0100_0000);

end

endmodule

