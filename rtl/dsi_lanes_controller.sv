module dsi_lanes_controller
    (
        /********* Clock signals *********/
        input wire          clk_sys                 , // serial data clock
        input wire          clk_serdes              , // logic clock = clk_hs/8
        input wire          clk_serdes_clk          , // logic clock = clk_hs/8 + 90dgr phase shift
        input wire          clk_latch               , // clk_sys, duty cycle 15%
        input wire          rst_n                   ,

        /********* Fifo signals *********/
        input wire [31:0]   iface_write_data        ,
        input wire [3:0]    iface_write_strb        , // iface_write_strb[4] - mode flag. 0 - hs, 1 - lp
        input wire          iface_write_rqst        ,
        input wire          iface_last_word         ,
        input wire          iface_lpm_en            , // should be asserted at least one cycle before iface_write_rqst and disasserted one cycle after iface_last_word

        output wire         iface_data_rqst         ,

        /********* Misc signals *********/

        input wire [1:0]    reg_lanes_number        ,
        input wire          lines_enable            ,   // enable output buffers of LP lines
        input wire          clock_enable            ,   // enable clock

        /********* Output signals *********/
        output wire         lines_ready             ,
        output wire         clock_ready             ,
        output wire         lines_active            ,

        /********* Lanes *********/
        output wire [3:0]   hs_lane_output          ,
        output wire [3:0]   LP_p_output             ,
        output wire [3:0]   LP_n_output             ,

        /********* Clock output *********/
        output wire [3:0]   clock_LP_p_output       ,
        output wire [3:0]   clock_LP_n_output       ,
        output wire [3:0]   clock_hs_output

    );

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
logic [3:0]     dsi_fin_rqst;
logic [3:0]     dsi_data_rqst;
logic [3:0]     dsi_active;
logic [3:0]     dsi_serial_hs_output;
logic [3:0]     dsi_LP_p_output;
logic [3:0]     dsi_LP_n_output;
logic [31:0]    dsi_inp_data;
logic [3:0]     dsi_lines_enable;

assign dsi_start_rqst[0] = !iface_lpm_en && !transmission_active && iface_write_rqst;
assign dsi_start_rqst[1] = !iface_lpm_en && !transmission_active && iface_write_rqst && (|reg_lanes_number);
assign dsi_start_rqst[2] = !iface_lpm_en && !transmission_active && iface_write_rqst && (reg_lanes_number[1]);
assign dsi_start_rqst[3] = !iface_lpm_en && !transmission_active && iface_write_rqst && (&reg_lanes_number);

logic           lp_data_request;
logic           lp_start_rqst;
logic           lp_last_byte;
logic [7:0]     lp_data_byte;
logic [4:0]     lp_bytes_counter;
logic [2:0]     lp_bytes_number;
logic [31:0]    lp_word_to_write;
logic [3:0]     lp_word_strb;

dsi_lane_full dsi_lane_0(
        .clk_sys            (clk_sys                            ), // serial data clock
        .clk_serdes         (clk_serdes                         ), // logic clock = clk_hs/8
        .clk_latch          (clk_latch                          ), // clk_sys, duty cycle 15%
        .rst_n              (rst_n                              ),

        .lane_zero          (1'b1                               ),
        .mode_lp            (iface_lpm_en                       ),

        .start_rqst         (!iface_lpm_en ? dsi_start_rqst[0]   : lp_start_rqst               ),
        .fin_rqst           (!iface_lpm_en ? dsi_fin_rqst[0]     : lp_last_byte               ),  // change to data_rqst <= (state_next == STATE_TX_ACTIVE);
        .inp_data           (!iface_lpm_en ? dsi_inp_data[7 : 0] : lp_data_byte               ),

        .data_rqst          (dsi_data_rqst[0]                   ),

        .active             (dsi_active[0]                      ),
        .lines_enable       (dsi_lines_enable[0]                ),

        .serial_hs_output   (dsi_serial_hs_output[0]            ),
        .LP_p_output        (dsi_LP_p_output[0]                 ),
        .LP_n_output        (dsi_LP_n_output[0]                 )
    );

/********* send data to lane 0 with preloading 1 word *********/

repacker_4_to_1 repacker_4_to_1_0
(
    .clk                 (clk_sys                           ),
    .rst_n               (rst_n                             ),

    /********* Data source iface *********/
    .src_data_rqst       (lp_data_request                   ),

    .src_input_data      (iface_write_data                  ),
    .src_input_strb      (iface_write_strb                  ),
    .src_start_rqst      (iface_lpm_en && iface_write_rqst  ),
    .src_fin_rqst        (iface_lpm_en && iface_last_word   ),

    /********* Data sink iface *********/
    .sink_data_rqst      (iface_lpm_en && dsi_data_rqst[0]  ),
    .sink_input_data     (lp_data_byte                      ),
    .sink_start_rqst     (lp_start_rqst                     ),
    .sink_fin_rqst       (lp_last_byte                      )
    );

genvar i;
generate
for(i = 1; i < 4; i = i + 1)
    dsi_lane_full dsi_lane(
        .clk_sys            (clk_sys                            ), // serial data clock
        .clk_serdes         (clk_serdes                         ), // logic clock = clk_hs/8
        .clk_latch          (clk_latch                          ), // clk_sys, duty cycle 15%
        .rst_n              (rst_n                              ),

        .lane_zero          (1'b0                               ),
        .mode_lp            (1'b0                               ),

        .start_rqst         (dsi_start_rqst[i]                  ),
        .fin_rqst           (dsi_fin_rqst[i]                    ),  // change to data_rqst <= (state_next == STATE_TX_ACTIVE);
        .inp_data           (dsi_inp_data[i*8 + 7 : i*8]        ),

        .data_rqst          (dsi_data_rqst[i]                   ),
        .active             (dsi_active[i]                      ),
        .lines_enable       (dsi_lines_enable[i]                ),

        .serial_hs_output   (dsi_serial_hs_output[i]            ),
        .LP_p_output        (dsi_LP_p_output[i]                 ),
        .LP_n_output        (dsi_LP_n_output[i]                 )
    );
endgenerate

assign lines_active = |dsi_active;

/********************************************************************
        CLK lane
********************************************************************/
logic     dsi_start_rqst_clk;
logic     dsi_fin_rqst_clk;
logic     dsi_active_clk;
logic     dsi_serial_hs_output_clk;
logic     dsi_LP_p_output_clk;
logic     dsi_LP_n_output_clk;

dsi_lane_full #(
    .MODE(1)
    ) dsi_lane_clk(
        .clk_sys            (clk_sys                        ), // serial data clock
        .clk_serdes         (clk_serdes_clk                 ), // logic clock = clk_hs/8
        .clk_latch          (clk_latch                      ), // clk_sys, duty cycle 15%
        .rst_n              (rst_n                          ),

        .start_rqst         (dsi_start_rqst_clk             ),
        .fin_rqst           (dsi_fin_rqst_clk               ),
        .inp_data           (8'b01010101                    ),
        .lines_enable       (dsi_lines_enable[0]            ),

        .active             (dsi_active_clk                 ),

        .serial_hs_output   (dsi_serial_hs_output_clk       ),
        .LP_p_output        (dsi_LP_p_output_clk            ),
        .LP_n_output        (dsi_LP_n_output_clk            )
    );


assign hs_lane_output       = dsi_serial_hs_output;
assign LP_p_output          = dsi_LP_p_output;
assign LP_n_output          = dsi_LP_n_output;
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

/********************************************************************
            Preload data part
********************************************************************/

always_ff @(posedge clk_sys or negedge rst_n)
    if(~rst_n)                                          transmission_active <= 1'b0;
    else if(iface_last_word)                            transmission_active <= 1'b0;
    else if(iface_write_rqst && !iface_lpm_en)          transmission_active <= 1'b1;

logic rpckr_iface_data_rqst;
logic enable_repacker = (iface_write_rqst || (|dsi_active)) && !iface_lpm_en;

repacker_4_to_4 repacker_4_to_4_0(
    .clk                (clk_sys                    ),
    .rst_n              (rst_n                      ),

    .data_req           (|dsi_data_rqst             ),   // data request signal. Need to get new data on the next clock.
    .data_out           (dsi_inp_data               ),   // output data
    .last_data_strb     (dsi_fin_rqst               ),   // strobes indicate last data bytes on each line

    .data_change_req    (rpckr_iface_data_rqst      ),   // request data changing. new data on the next clock is needed
    .input_data         (iface_write_data           ),   // input data
    .input_strb         (iface_write_strb[3:0]      ),   // input strobes

    .enable             (enable_repacker            )   // enable repacker signal
    );

assign iface_data_rqst = !iface_lpm_en ? rpckr_iface_data_rqst & transmission_active : lp_data_request;

endmodule
