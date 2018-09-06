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
        input wire [4:0]    iface_write_strb        , // iface_write_strb[4] - mode flag. 0 - hs, 1 - lp
        input wire          iface_write_rqst        ,

        output wire         iface_data_rqst         ,

        /********* Misc signals *********/

        input wire [1:0]    reg_lanes_number        ,
        input wire          lines_enable            ,   // enable output buffers of LP lines
        input wire          clock_enable            ,   // enable clock

        /********* Output signals *********/
        output wire         lines_ready             ,
        output wire         clock_ready             ,
        output wire         writing_active          ,

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
    3. when there is no data set  iface_write_strb to all zeros 
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

assign dsi_start_rqst[0] = !transmission_active && iface_write_rqst;
assign dsi_start_rqst[1] = !transmission_active && iface_write_rqst && (|reg_lanes_number);
assign dsi_start_rqst[2] = !transmission_active && iface_write_rqst && (reg_lanes_number[1]);
assign dsi_start_rqst[3] = !transmission_active && iface_write_rqst && (&reg_lanes_number);

genvar i;

generate
for(i = 0; i < 4; i = i + 1)
    dsi_lane_full dsi_lane(
        .clk_sys            (clk_sys                        ), // serial data clock
        .clk_serdes         (clk_serdes                     ), // logic clock = clk_hs/8
        .clk_latch          (clk_latch                      ), // clk_sys, duty cycle 15%
        .rst_n              (rst_n                          ),

        .start_rqst         (dsi_start_rqst[i]              ),
        .fin_rqst           (dsi_fin_rqst[i]                ),  // change to data_rqst <= (state_next == STATE_TX_ACTIVE);
        .inp_data           (dsi_inp_data[i*8 + 7 : i*8]    ),

        .data_rqst          (dsi_data_rqst[i]               ),
        .active             (dsi_active[i]                  ),
        .lines_enable       (dsi_lines_enable[i]            ),

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
        .inp_data           (8'hF0                          ),
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

assign lines_ready = (state_current == STATE_LANES_ACTIVE);
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

assign dsi_fin_rqst     = !repacker_output_strobe & {4{data_valid_out}};
assign dsi_inp_data     = repacker_output_data;

endmodule
