module dsi_lanes_controller
    (
        /********* Clock signals *********/
        input wire          clk_sys                 , // serial data clock
        input wire          clk_serdes              , // logic clock = clk_hs/8
        input wire          clk_serdes_clk          , // logic clock = clk_hs/8 + 90dgr phase shift
        input wire          clk_latch               , // clk_sys, duty cycle 15%
        input wire          rst_n                   ,

        /********* Fifo signals *********/

        // host should set iface_write_rqst, and at the same time set iface_write_data to the first data.
        // Then on every iface_data_rqst Host should change data. When it comes to the last data piece Host should set iface_last_word.
        input wire [31:0]   iface_write_data        ,
        input wire [4:0]    iface_write_strb        , // iface_write_strb[4] - mode flag. 0 - hs, 1 - lp
        input wire [3:0]    iface_write_rqst        ,
        input wire [3:0]    iface_last_word         ,

        output wire         iface_data_rqst         ,

        /********* Misc signals *********/

        input wire [1:0]    reg_lanes_number        ,
        input wire          lines_enable            ,   // enable output buffers of LP lines
        input wire          clock_enable            ,   // enable clock

        /********* Output signals *********/
        output wire         lines_ready             ,
        output wire         clock_ready             ,
        output wire         data_underflow_error

    );

/********************************************************************
    Module makes data preload in order to know when the last data comes.
    size of preload data is 2 fifo wide words.
********************************************************************/

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

assign dsi_start_rqst[0] = iface_write_rqst;
assign dsi_start_rqst[1] = iface_write_rqst && (|reg_lanes_number);
assign dsi_start_rqst[2] = iface_write_rqst && (reg_lanes_number[1] && !reg_lanes_number[0]);
assign dsi_start_rqst[3] = iface_write_rqst && (&reg_lanes_number);

genvar i;

generate
for(i = 0; i < 4; i = i + 1)
    dsi_lane_full dsi_lane_(
        .clk_sys            (clk_sys                        ), // serial data clock
        .clk_serdes         (clk_serdes                     ), // logic clock = clk_hs/8
        .clk_latch          (clk_latch                      ), // clk_sys, duty cycle 15%
        .rst_n              (rst_n                          ),

        .start_rqst         (dsi_start_rqst[i]              ),
        .fin_rqst           (dsi_fin_rqst[i]                ),
        .inp_data           (dsi_inp_data[i*8 + 7 : i*8]    ),

        .data_rqst          (dsi_data_rqst[i]               ),
        .active             (dsi_active[i]                  ),

        .serial_hs_output   (dsi_serial_hs_output[i]        ),
        .LP_p_output        (dsi_LP_p_output[i]             ),
        .LP_n_output        (dsi_LP_n_output[i]             )
    );
endgenerate

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
        .inp_data           (8'hAA                          ),

        .active             (dsi_active_clk                 ),

        .serial_hs_output   (dsi_serial_hs_output_clk       ),
        .LP_p_output        (dsi_LP_p_output_clk            ),
        .LP_n_output        (dsi_LP_n_output_clk            )
    );

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
            state_next = dsi_active_clk ? STATE_LANES_ACTIVE : STATE_WAIT_CLK_ACTIVE;

        STATE_LANES_ACTIVE:
            state_next = !clock_enable ? STATE_WAIT_CLK_UNACTIVE : STATE_LANES_ACTIVE;

        STATE_WAIT_CLK_UNACTIVE:
            state_next = !dsi_active_clk ? STATE_DISABLE_BUFFERS : (clock_enable ? STATE_WAIT_CLK_ACTIVE : STATE_WAIT_CLK_UNACTIVE);

        STATE_DISABLE_BUFFERS:
            state_next = !lines_enable ? STATE_IDLE : STATE_DISABLE_BUFFERS;

        default :
            state_next <= STATE_IDLE;
    endcase
end

assign lines_ready = (state_current == STATE_LANES_ACTIVE);
assign clock_ready = dsi_active_clk;

/********************************************************************
            Preload data part
********************************************************************/
logic           pipe_is_empty;
logic           pipe_data_request
logic [31:0]    data_buff_0;
logic [31:0]    data_buff_1;
logic [3:0]     strb_buff_0;
logic [3:0]     strb_buff_1;
logic [3:0]     res_strb;
logic           transmission_active;
logic           data_buff_0_empty;
logic           data_buff_0_empty;

always_ff @(posedge clk_sys or negedge rst_n) begin
    if(~rst_n)                  transmission_active <= 1'b0;
    else if(iface_write_rqst)   transmission_active <= 1'b1;
    else if(iface_last_word)    transmission_active <= 1'b0;

/********* data buffers *********/
logic write_buff_0;
assign write_buff_0 = iface_write_rqst && (data_buff_1_empty || pckt_trnsf_ack);

always_ff @(posedge clk_sys or negedge rst_n) begin
    if(~rst_n)                 data_buff_0 <= 32'b0;
    else if(write_buff_0)      data_buff_0 <= iface_write_data;

always_ff @(posedge clk_sys or negedge rst_n) begin
    if(~rst_n)                      data_buff_1 <= 32'b0;
    else if(!data_buff_0_empty)     data_buff_1 <= data_buff_0;

/********* strobes buffer *********/

always_ff @(posedge clk_sys or negedge rst_n) begin
    if(~rst_n)                 strb_buff_0 <= 4'b0;
    else if(write_buff_0)      strb_buff_0 <= iface_write_data;

always_ff @(posedge clk_sys or negedge rst_n) begin
    if(~rst_n)                      strb_buff_1 <= 4'b0;
    else if(!data_buff_0_empty)     strb_buff_1 <= strb_buff_0;

/********* empty flags *********/

always_ff @(posedge clk_sys or negedge rst_n) begin
    if(~rst_n)                      data_buff_0_empty <= 1'b1;
    else if(write_buff_0)           data_buff_0_empty <= 1'b0;
    else if(!data_buff_0_empty)     data_buff_0_empty <= 1'b1;

always_ff @(posedge clk_sys or negedge rst_n) begin
    if(~rst_n)                                      data_buff_1_empty <= 1'b1;
    else if(!data_buff_0_empty)                     data_buff_1_empty <= 1'b0;
    else if(pckt_trnsf_ack && !data_buff_1_empty)   data_buff_1_empty <= 1'b1;


assign iface_write_rqst = data_buff_0_empty || data_buff_1_empty || pckt_trnsf_ack;

assign data_underflow_error = transmission_active && (data_buff_0_empty || data_buff_1_empty)

/********************************************************************
            4 bytes stream to n bytes stream
********************************************************************/



endmodule

