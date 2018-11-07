module dsi_core_tb();

bit rst_n;
bit clk_sys;
bit clk_serdes;
bit clk_serdes_clk;
bit clk_latch;
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

logic [3:0]     hs_lane_output;
logic [3:0]     LP_p_output;
logic [3:0]     LP_n_output;

logic           clock_LP_p_output;
logic           clock_LP_n_output;
logic           clock_hs_output;

logic           lpm_enable;
logic           user_cmd_transmission_mode;
logic           enable_EoT_sending;
logic           streaming_enable;


initial begin
rst_n               = 0;
#100
wait(10) @(posedge clk_sys)
rst_n = 1;
end

initial
begin
clk_serdes = 1;
#1.25;
forever    #1.25 clk_serdes      = ~clk_serdes;
end

initial
begin
#0.6125;
clk_serdes_clk = 1;
forever    #1.25 clk_serdes_clk      = ~clk_serdes_clk;
end

initial
begin
#5;
clk_latch = 1;
forever
    begin
     #2.5 clk_latch  = ~clk_latch;
     #17.5 clk_latch = 1;
    end
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

pixel_uploader pixel_uploader_0 (

        .clk                         (clk_fast          ),
        .rst_n                       (rst_n_fast        ),

    /********* Avalon MM Master read-only iface *********/
        .avl_mm_addr                 (),
        .avl_mm_read                 (),

        .avl_mm_readdata             (),
        .avl_mm_readdatavalid        (),
        .avl_mm_response             (),
        .avl_mm_waitrequest          (),

    /********* Pixel FIFO iface *********/
        .pix_fifo_write              (),
        .pix_fifo_data               (),

        .pix_fifo_full               (),
        .pix_fifo_usedw              (),

    /********* Input control *********/
        .enable                      (),
        .word_mode                   (),   // 1 - word addressing, 0 - byte addressing
        .base_address                (),
        .total_size                  (),
        .pix_fifo_threshold          (),
        .transform_data              (),   // 0 - write data from memory directly to fifo, 1 - transform 4 bytes to 4, removing empty 3rd byte in memory data

        .read_error_w                (),
        .active                      ()

    );

fifo_1024_32    fifo_1024_32_inst (
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

packets_assembler #(
    .USR_FIFO_DEPTH(10)
    )
packets_assembler
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
        .usr_fifo_usedw                      (usr_fifo_usedw    ),
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
        .clk_serdes              (clk_serdes            ), // logic clock = clk_hs/8
        .clk_serdes_clk          (clk_serdes_clk        ), // logic clock = clk_hs/8 + 90dgr phase shift
        .clk_latch               (clk_latch             ), // clk_sys, duty cycle 15%
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
        .LP_p_output             (LP_p_output           ),
        .LP_n_output             (LP_n_output           ),

        /********* Clock output *********/
        .clock_LP_p_output       (clock_LP_p_output     ),
        .clock_LP_n_output       (clock_LP_n_output     ),
        .clock_hs_output         (clock_hs_output       )

    );

endmodule