module dsi_lane_full #(
    parameter MODE = 0  // 0 - lane, 1 - clk
    )(
    input wire          clk_sys     , // serial data clock
    input wire          clk_serdes  , // logic clock = clk_hs/8
    input wire          clk_latch   , // clk_sys, duty cycle 15%
    input wire          rst_n       ,

    input wire          start_rqst  ,
    input wire          fin_rqst    ,
    input wire          lines_enable,
    input wire [7:0]    inp_data    ,

    output logic        data_rqst,
    output logic        active,

    output logic        serial_hs_output,
    output logic        LP_p_output,
    output logic        LP_n_output
);

logic hs_fin_ack;
logic hs_rqst_timeout;
logic hs_prep_timeout;
logic hs_exit_timeout;

/***********************************
        FSM declaration
************************************/

enum logic [2:0]
{
    STATE_LINES_DISABLED,
    STATE_IDLE,
    STATE_HS_RQST,
    STATE_HS_PREP,
    STATE_HS_ACTIVE,
    STATE_HS_EXIT
} state_current, state_next;

always_ff @(posedge clk_sys or negedge rst_n) begin
    if(~rst_n) begin
        state_current <= STATE_LINES_DISABLED;
    end else begin
        state_current <= state_next;
    end
end

always_comb begin
    case (state_current)

        STATE_LINES_DISABLED:
            state_next = lines_enable ? STATE_IDLE : STATE_LINES_DISABLED;

        STATE_IDLE:
            state_next = lines_enable ? (start_rqst ? STATE_HS_RQST : STATE_IDLE) : STATE_LINES_DISABLED;

        STATE_HS_RQST:
            state_next = hs_rqst_timeout ? STATE_HS_PREP : STATE_HS_RQST;

        STATE_HS_PREP:
            state_next = hs_prep_timeout ? STATE_HS_ACTIVE : STATE_HS_PREP;

        STATE_HS_ACTIVE:
            state_next = hs_fin_ack ? STATE_HS_EXIT : STATE_HS_ACTIVE;

        STATE_HS_EXIT:
            state_next = hs_exit_timeout ? STATE_IDLE : STATE_HS_EXIT;

        default :
            state_next = STATE_LINES_DISABLED;
    endcase
end

assign active = (state_current != STATE_LINES_DISABLED) && (state_current != STATE_IDLE);

logic LP_p;
logic LP_n;
// LP lines control
always_ff @(posedge clk_sys or negedge rst_n) begin
    if(~rst_n)                                                              LP_p <= 1;
    else if(state_next == STATE_IDLE || state_next == STATE_HS_EXIT)        LP_p <= 1;
    else if(state_next == STATE_HS_RQST)                                    LP_p <= 0;
end

always_ff @(posedge clk_sys or negedge rst_n) begin
    if(~rst_n)                                                              LP_n <= 1;
    else if(state_next == STATE_IDLE || state_next == STATE_HS_EXIT)        LP_n <= 1;
    else if(state_next == STATE_HS_PREP)                                    LP_n <= 0;
end

logic lp_lines_enable;

assign lp_lines_enable = (state_current != STATE_HS_ACTIVE) && (state_current != STATE_LINES_DISABLED);
// LP lines buffers
hs_buff lp_buff_inst_p (
    .datain     ( LP_p              ),
    .oe         ( lp_lines_enable   ),
    .dataout    ( LP_p_output       )
    );

hs_buff lp_buff_inst_n (
    .datain     ( LP_n              ),
    .oe         ( lp_lines_enable   ),
    .dataout    ( LP_n_output       )
    );

/******* Timeouts *******/

localparam [7:0] T_LPX          = 3;  // 50 ns
localparam [7:0] T_HS_PREPARE   = 3;   // 40 ns + 4*UI  :  85 ns + 6*UI
localparam [7:0] T_HS_EXIT      = 3;  // 100 ns

logic [7:0] hs_rqst_counter;
logic [7:0] hs_prep_counter;
logic [7:0] hs_exit_counter;

always_ff @(posedge clk_sys or negedge rst_n)
    if(~rst_n)                              hs_rqst_counter <= 0;
    else if(state_current == STATE_HS_RQST) hs_rqst_counter <= hs_rqst_counter - 1;
    else if(state_next == STATE_HS_RQST)    hs_rqst_counter <= T_LPX;

assign hs_rqst_timeout = (state_current == STATE_HS_RQST) && !(|hs_rqst_counter);

always_ff @(posedge clk_sys or negedge rst_n)
    if(~rst_n)                              hs_prep_counter <= 0;
    else if(state_current == STATE_HS_PREP) hs_prep_counter <= hs_prep_counter - 1;
    else if(state_next == STATE_HS_PREP)    hs_prep_counter <= T_LPX;

assign hs_prep_timeout = (state_current == STATE_HS_PREP) && !(|hs_prep_counter);

always_ff @(posedge clk_sys or negedge rst_n)
    if(~rst_n)                              hs_exit_counter <= 0;
    else if(state_current == STATE_HS_EXIT) hs_exit_counter <= hs_exit_counter - 1;
    else if(state_next == STATE_HS_EXIT)    hs_exit_counter <= T_LPX;

assign hs_exit_timeout = (state_current == STATE_HS_EXIT) && !(|hs_exit_counter);

logic hs_start_rqst;

assign hs_start_rqst = (state_next == STATE_HS_ACTIVE);

logic hs_lane_active;

dsi_hs_lane  #(
    .MODE(MODE)
    ) dsi_hs_lane_0(
    .clk_sys                (clk_sys            ), // serial data clock
    .clk_serdes             (clk_serdes         ), // logic clock = clk_hs/8
    .clk_latch              (clk_latch          ), // clk_sys, duty cycle 15%
    .rst_n                  (rst_n              ),

    .start_rqst             (hs_start_rqst      ),
    .fin_rqst               (fin_rqst           ),
    .inp_data               (inp_data           ),

    .data_rqst              (data_rqst          ),
    .active                 (hs_lane_active     ),
    .fin_ack                (hs_fin_ack         ),

    .serial_hs_output       (serial_hs_output   )

    );

endmodule
