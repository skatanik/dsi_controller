module dsi_lanes_controller
    (
        /********* Clock signals *********/
        input wire          clk_sys                 , // serial data clock
        input wire          rst_n                   ,

        /********* lanes controller iface *********/
        input  wire [32:0] lanes_fifo_data          , // 32:9 - 3x8 data, 8 - lpm sign, 7:0 lane 0 data
        input  wire [3:0]  lanes_fifo_write         ,
        output wire [3:0]  lanes_fifo_full          ,


        /********* Misc signals *********/

        input wire [1:0]    reg_lanes_number        ,
        input wire          lines_enable            ,   // enable output buffers of LP lines
        input wire          clock_enable            ,   // enable clock

        /********* Output signals *********/
        output wire         lines_ready             ,
        output wire         clock_ready             ,
        output wire         lines_active            ,

        /********* Lanes *********/
        output wire [31:0]  hs_lane_output          ,
        output wire [3:0]   hs_lane_enable          ,
        output wire [3:0]   LP_p_output             ,
        output wire [3:0]   LP_n_output             ,
        output wire [3:0]   LP_enable               ,

        /********* Clock output *********/
        output wire         clock_LP_p_output       ,
        output wire         clock_LP_n_output       ,
        output wire         clock_LP_enable         ,
        output wire [7:0]   clock_hs_output         ,
        output wire         clock_hs_enable

    );

// logic clock = clk_hs/8
// logic clock = clk_hs/8 + 90dgr phase shift
// clk_sys, duty cycle 15%

/********************************************************************
   On the power on module has all lines output buffers off. At first it is needed to set  lines_enable signal, then when lines_ready signal is got
   one can wait for a while and then set clock_enable signal and again wait for clock_ready signal. After that it is possible to start writing data.
    When data writing is needed follow next steps
    1. set iface_write_rqst also set iface_write_data with first data  and iface_write_strb
    2. on each active  iface_data_rqst set new data on iface_write_data iface_write_strb
    3. when there is no data set iface_write_rqst and iface_write_strb to all zeros
    4. wait until writing_active is 0.
    after that module can start a new writing data sequence
********************************************************************/
logic           transmission_active;
/********************************************************************
                DSI lanes instances
********************************************************************/
logic [3:0]     dsi_start_rqst;
logic [3:0]     dsi_lp_mode;
logic [3:0]     dsi_fin_rqst;
logic [3:0]     dsi_data_rqst;
logic [3:0]     dsi_active;
logic [31:0]    dsi_hs_output;
logic [3:0]     dsi_LP_p_output;
logic [3:0]     dsi_LP_n_output;
logic [3:0]     dsi_LP_enable;
logic [31:0]    dsi_inp_data;
logic [3:0]     dsi_lines_enable;

logic [31:0]    wr_fifo_data;
logic [3:0]     wr_fifo_write;
logic [3:0]     wr_fifo_full;

genvar i;
generate
for(i = 0; i < 4; i = i + 1) begin : dsi_lane
    dsi_lane_full dsi_lane(
        .clk_sys            (clk_sys                                ), // serial data clock
        .rst_n              (rst_n                                  ),

        .mode_lp            (dsi_lp_mode[i]                         ),

        .start_rqst         (dsi_start_rqst[i]                      ),
        .fin_rqst           (dsi_fin_rqst[i]                        ),  // change to data_rqst <= (state_next == STATE_TX_ACTIVE);
        .inp_data           (dsi_inp_data[i*8 + 7 : i*8]            ),

        .data_rqst          (dsi_data_rqst[i]                       ),
        .active             (dsi_active[i]                          ),
        .lines_enable       (dsi_lines_enable[i]                    ),

        .hs_output          (dsi_hs_output[i*8 + 7 : i*8]           ),
        .hs_enable          (hs_lane_enable[i]                      ),
        .LP_p_output        (dsi_LP_p_output[i]                     ),
        .LP_n_output        (dsi_LP_n_output[i]                     ),
        .lp_lines_enable    (dsi_LP_enable[i]                       )
    );
end // dsi_lane

for(i = 0; i < 4; i = i + 1) begin : fifo_to_lane_bridge
    fifo_to_lane_bridge inst(
    .clk                    (clk_sys                                ),    // Clock
    .rst_n                  (rst_n                                  ),  // Asynchronous reset active low

    /********* input fifo iface *********/
    .fifo_data              (lanes_fifo_data[i*8 + 7 : i*8]         ),
    .fifo_empty             (lanes_fifo_empty[i]                    ),
    .fifo_read              (lanes_fifo_read[i]                     ),
    .mode_lp                (i == 0 ? lanes_fifo_data[32] : 1'b0    )

     /********* Lane iface *********/
    .mode_lp                 (dsi_lp_mode[i]                        ), // which mode to use to send data throught this lane. 0 - hs, 1 - lp
    .start_rqst              (dsi_start_rqst[i]                     ),
    .fin_rqst                (dsi_fin_rqst[i]                       ),
    .inp_data                (dsi_inp_data[i*8 + 7 : i*8]           ),
    .data_rqst               (dsi_data_rqst[i]                      ),
    .p2p_timeout             (16'hf                                 ),

    );
    end // fifo_to_lane_bridge

for(i = 0; i < 4; i = i + 1) begin : lanes_fifo
    lane_fifo_9x32  lane_fifo_inst (
    .aclr           (wr_fifo_clear[i]                   ),
    .data           (wr_fifo_data[i*8 + 7 : i*8]        ),
    .wrclk          (wr_clk                             ),
    .wrreq          (wr_fifo_write[i]                   ),
    .wrfull         (wr_fifo_full[i]                    ),
    .rdreq          (lanes_fifo_read[i]                 ),
    .q              (lanes_fifo_data[i*8 + 7 : i*8]     ),
    .rdempty        (lanes_fifo_empty[i]                ),
    .rdclk          (clk_sys                            )
    );
    end // lanes_fifo

endgenerate

assign lines_active = |dsi_active;

assign wr_fifo_data     = lanes_fifo_data[31:0]
assign wr_fifo_write    = lanes_fifo_write;
assign lanes_fifo_full  = wr_fifo_full;

/********************************************************************
        CLK lane
********************************************************************/
logic       dsi_start_rqst_clk;
logic       dsi_fin_rqst_clk;
logic       dsi_active_clk;
logic[7:0]  dsi_serial_hs_output_clk;
logic       dsi_LP_p_output_clk;
logic       dsi_LP_n_output_clk;
logic       dsi_LP_enable_clk;

dsi_lane_full #(
    .MODE(1)
    ) dsi_lane_clk(
        .clk_sys            (clk_sys                        ), // serial data clock
        .rst_n              (rst_n                          ),

        .start_rqst         (dsi_start_rqst_clk             ),
        .fin_rqst           (dsi_fin_rqst_clk               ),
        .inp_data           (8'b01010101                    ),
        .lines_enable       (dsi_lines_enable[0]            ),
        .mode_lp            (1'b0                           ),

        .active             (dsi_active_clk                 ),
        .data_rqst          (                               ),

        .hs_output          (dsi_serial_hs_output_clk       ),
        .hs_enable          (clock_hs_enable                ),
        .LP_p_output        (dsi_LP_p_output_clk            ),
        .LP_n_output        (dsi_LP_n_output_clk            ),
        .lp_lines_enable    (dsi_LP_enable_clk              )
    );

assign hs_lane_output       = dsi_hs_output;
assign LP_p_output          = dsi_LP_p_output;
assign LP_n_output          = dsi_LP_n_output;
assign LP_enable            = dsi_LP_enable;
assign clock_LP_enable      = dsi_LP_enable_clk;
assign clock_LP_p_output    = dsi_LP_p_output_clk;
assign clock_LP_n_output    = dsi_LP_n_output_clk;
assign clock_hs_output      = dsi_serial_hs_output_clk;

/********************************************************************
                    turning ON block FSM declaration
********************************************************************/

enum logic [2:0]
{
    STATE_IDLE,                     // all output buffers are disabled
    STATE_ENABLE_BUFFERS,           // send a signal to lanes to activate output LP buffers. Hold them in LP-11 mode
    STATE_WAIT_CLK_ACTIVE,          // Wait while init sequence of clock line is finished
    STATE_LANES_ACTIVE,             // Main state, clock active, lanes active
    STATE_WAIT_CLK_UNACTIVE,        // Wait while deinit sequence of clock line is finished
    STATE_DISABLE_BUFFERS           // send a signal to lanes to disactivate output LP buffers.
} state_current, state_next;

always_ff @(posedge clk_sys or negedge rst_n) begin
    if(~rst_n) begin
        state_current <= STATE_IDLE;
    end else begin
        state_current <= state_next;
    end
end

always_comb begin
    case (state_current)
        STATE_IDLE:
            state_next = lines_enable ? STATE_ENABLE_BUFFERS : STATE_IDLE;

        STATE_ENABLE_BUFFERS:
            state_next = clock_enable ? STATE_WAIT_CLK_ACTIVE : STATE_ENABLE_BUFFERS;

        STATE_WAIT_CLK_ACTIVE:
            state_next = clock_ready ? STATE_LANES_ACTIVE : STATE_WAIT_CLK_ACTIVE;

        STATE_LANES_ACTIVE:
            state_next = !clock_enable ? STATE_WAIT_CLK_UNACTIVE : STATE_LANES_ACTIVE;

        STATE_WAIT_CLK_UNACTIVE:
            state_next = !clock_ready ? STATE_DISABLE_BUFFERS : (clock_enable ? STATE_WAIT_CLK_ACTIVE : STATE_WAIT_CLK_UNACTIVE);

        STATE_DISABLE_BUFFERS:
            state_next = !lines_enable ? STATE_IDLE : STATE_DISABLE_BUFFERS;

        default :
            state_next <= STATE_IDLE;
    endcase
end

assign lines_ready = (state_current != STATE_IDLE);
assign clock_ready = dsi_active_clk;

assign dsi_start_rqst_clk   = state_next == STATE_WAIT_CLK_ACTIVE;
assign dsi_fin_rqst_clk     = state_next == STATE_WAIT_CLK_UNACTIVE;

always_ff @(posedge clk_sys or negedge rst_n)
    if(~rst_n)                                          dsi_lines_enable[0] <= 1'b0;
    else if(state_current == STATE_ENABLE_BUFFERS)      dsi_lines_enable[0] <= 1'b1;
    else if(state_current == STATE_DISABLE_BUFFERS)     dsi_lines_enable[0] <= 1'b0;

always_ff @(posedge clk_sys or negedge rst_n)
    if(~rst_n)                                          dsi_lines_enable[1] <= 1'b0;
    else if(state_current == STATE_ENABLE_BUFFERS)      dsi_lines_enable[1] <= (|reg_lanes_number);
    else if(state_current == STATE_DISABLE_BUFFERS)     dsi_lines_enable[1] <= !(|reg_lanes_number);

always_ff @(posedge clk_sys or negedge rst_n)
    if(~rst_n)                                          dsi_lines_enable[2] <= 1'b0;
    else if(state_current == STATE_ENABLE_BUFFERS)      dsi_lines_enable[2] <= (reg_lanes_number[1]);
    else if(state_current == STATE_DISABLE_BUFFERS)     dsi_lines_enable[2] <= !(reg_lanes_number[1]);

always_ff @(posedge clk_sys or negedge rst_n)
    if(~rst_n)                                          dsi_lines_enable[3] <= 1'b0;
    else if(state_current == STATE_ENABLE_BUFFERS)      dsi_lines_enable[3] <= (&reg_lanes_number);
    else if(state_current == STATE_DISABLE_BUFFERS)     dsi_lines_enable[3] <= !(&reg_lanes_number);

endmodule
