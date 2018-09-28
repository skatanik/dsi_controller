module dsi_lane_full #(
    parameter MODE = 0  // 0 - lane, 1 - clk
    )(
    input wire          clk_sys             , // serial data clock
    input wire          clk_serdes          , // logic clock = clk_hs/8
    input wire          clk_latch           , // clk_sys, duty cycle 15%
    input wire          rst_n               ,

    input wire          mode_lp             , // which mode to use to send data throught this lane. 0 - hs, 1 - lp
    input wire          start_rqst          ,
    input wire          fin_rqst            ,
    input wire          lines_enable        ,
    input wire [7:0]    inp_data            ,

    output logic        data_rqst           ,
    output logic        active              ,

    output logic        serial_hs_output    ,
    output logic        LP_p_output         ,
    output logic        LP_n_output
);

logic hs_fin_ack;
logic hs_rqst_timeout;
logic hs_prep_timeout;
logic hs_exit_timeout;
logic hs_data_rqst;
logic lp_data_is_sent;
logic send_esc_mode_entry_done;
logic send_entry_cmd_done;
logic send_mark_one_done;
logic inc_lp_data_bits_counter;

/***********************************
        FSM declaration
************************************/

enum logic [3:0]
{
    STATE_LINES_DISABLED,
    STATE_IDLE,
    STATE_HS_RQST,
    STATE_HS_PREP,
    STATE_HS_ACTIVE,
    STATE_HS_EXIT,
    STATE_LP_SEND_ESC_MODE_ENTRY,
    STATE_LP_SEND_ENTRY_CMD,        // entry command is fixed to Low-Power Data Transmission
    STATE_LP_SEND_LP_CMD,
    STATE_LP_SEND_MARK_ONE
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
            state_next = lines_enable ? (start_rqst ? (mode_lp ? STATE_LP_SEND_ESC_MODE_ENTRY : STATE_HS_RQST) : STATE_IDLE) : STATE_LINES_DISABLED;

        STATE_HS_RQST:
            state_next = hs_rqst_timeout ? STATE_HS_PREP : STATE_HS_RQST;

        STATE_HS_PREP:
            state_next = hs_prep_timeout ? STATE_HS_ACTIVE : STATE_HS_PREP;

        STATE_HS_ACTIVE:
            state_next = hs_fin_ack ? STATE_HS_EXIT : STATE_HS_ACTIVE;

        STATE_HS_EXIT:
            state_next = hs_exit_timeout ? STATE_IDLE : STATE_HS_EXIT;

        STATE_LP_SEND_ESC_MODE_ENTRY:
            state_next = send_esc_mode_entry_done ? STATE_LP_SEND_ENTRY_CMD : STATE_LP_SEND_ESC_MODE_ENTRY;

        STATE_LP_SEND_ENTRY_CMD:
            state_next = send_entry_cmd_done ? STATE_LP_SEND_LP_CMD : STATE_LP_SEND_ENTRY_CMD;

        STATE_LP_SEND_LP_CMD:
            state_next = lp_data_is_sent ? STATE_LP_SEND_MARK_ONE : STATE_LP_SEND_LP_CMD;

        STATE_LP_SEND_MARK_ONE:
            state_next = send_mark_one_done ? STATE_IDLE : STATE_LP_SEND_MARK_ONE;

        default :
            state_next = STATE_LINES_DISABLED;
    endcase
end

assign active = (state_current != STATE_LINES_DISABLED) && (state_current != STATE_IDLE);

localparam [7:0]    ESC_MODE_ENTRY      = 8'b00000010;
localparam [7:0]    ENTRY_CMD           = 8'b11100001;
localparam [7:0]    LP_BAUD_TIME        = 8'd30;

logic LP_p;
logic LP_n;
logic [7:0] lp_data_buffer;
logic [3:0] lp_data_bits_counter;
logic       lp_data_rqst;
logic [7:0] lp_baud_counter;
logic       set_first_half_bit;
logic       set_second_half_bit;
logic       next_state_lpdt;
logic       last_lp_byte;
logic       send_lp_data;
logic       reset_baud_counter;

assign next_state_lpdt          = (state_next == STATE_LP_SEND_ESC_MODE_ENTRY) && (state_current == STATE_IDLE);
assign next_state_entry_cmd     = (state_next == STATE_LP_SEND_ENTRY_CMD) && (state_current == STATE_LP_SEND_ESC_MODE_ENTRY);
assign next_state_mark_one      = (state_next == STATE_LP_SEND_MARK_ONE) && (state_current == STATE_LP_SEND_LP_CMD);
assign data_rqst                = ((state_current == STATE_HS_RQST) || (state_current == STATE_HS_PREP) || (state_current == STATE_HS_ACTIVE)) ? hs_data_rqst : lp_data_rqst;

always_ff @(posedge clk_sys or negedge rst_n)
    if(~rst_n)                                      lp_data_buffer <= 8'b0;
    else if(next_state_lpdt)                        lp_data_buffer <= ESC_MODE_ENTRY;
    else if(next_state_entry_cmd)                   lp_data_buffer <= ENTRY_CMD;
    else if(send_lp_data)                           lp_data_buffer <= inp_data;
    else if(next_state_mark_one)                    lp_data_buffer <= 8'hff;

always_ff @(posedge clk_sys or negedge rst_n)
    if(~rst_n)                          last_lp_byte <= 1'b0;
    else if(send_lp_data)               last_lp_byte <= fin_rqst;
    else if(state_next == STATE_IDLE)   last_lp_byte <= 1'b0;

assign lp_data_is_sent = lp_data_rqst & last_lp_byte;

assign inc_lp_data_bits_counter = !(|lp_baud_counter) && ((state_current == STATE_LP_SEND_ESC_MODE_ENTRY) || (state_current == STATE_LP_SEND_ENTRY_CMD) || (state_current == STATE_LP_SEND_LP_CMD) || (state_current == STATE_LP_SEND_MARK_ONE));

logic bits_counter_is_zero;

assign bits_counter_is_zero     = !(|lp_data_bits_counter) && reset_baud_counter;
assign send_lp_data             = (state_current == STATE_LP_SEND_ENTRY_CMD) && (state_next == STATE_LP_SEND_LP_CMD) || lp_data_rqst && !last_lp_byte;

always_ff @(posedge clk_sys or negedge rst_n)
    if(~rst_n)                                                      lp_data_bits_counter <= 4'b0;
    else if(next_state_lpdt)                                        lp_data_bits_counter <= 4'b1;
    else if(next_state_entry_cmd)                                   lp_data_bits_counter <= 4'd7;
    else if(next_state_mark_one)                                    lp_data_bits_counter <= 4'd0;
    else if(send_lp_data)                                           lp_data_bits_counter <= 4'd7;
    else if(inc_lp_data_bits_counter && (|lp_data_bits_counter))    lp_data_bits_counter <= lp_data_bits_counter - 4'd1;

assign lp_data_rqst                 = (state_current == STATE_LP_SEND_LP_CMD) && bits_counter_is_zero || (state_current == STATE_IDLE);
assign send_esc_mode_entry_done     = (state_current == STATE_LP_SEND_ESC_MODE_ENTRY) && bits_counter_is_zero;
assign send_entry_cmd_done          = (state_current == STATE_LP_SEND_ENTRY_CMD) && bits_counter_is_zero;
assign send_mark_one_done           = (state_current == STATE_LP_SEND_MARK_ONE) && set_second_half_bit;

assign reset_baud_counter = next_state_lpdt || inc_lp_data_bits_counter;

always_ff @(posedge clk_sys or negedge rst_n)
    if(~rst_n)                          lp_baud_counter <= 8'b0;
    else if(reset_baud_counter)         lp_baud_counter <= LP_BAUD_TIME;
    else if(state_next == STATE_IDLE)   lp_baud_counter <= 8'b0;
    else if(|lp_baud_counter)           lp_baud_counter <= lp_baud_counter - 8'b1;

assign set_first_half_bit   = lp_baud_counter == LP_BAUD_TIME;
assign set_second_half_bit  = (lp_baud_counter == {1'b0, LP_BAUD_TIME[7:1]});

logic current_lp_data_bit;
logic [7:0] shifted_lp_data;

assign shifted_lp_data = lp_data_buffer >> (lp_data_bits_counter);
assign current_lp_data_bit = shifted_lp_data[0];

// LP lines control
always_ff @(posedge clk_sys or negedge rst_n) begin
    if(~rst_n)                                                              LP_p <= 1;
    else if(state_next == STATE_IDLE || state_next == STATE_HS_EXIT)        LP_p <= 1;
    else if(state_next == STATE_HS_RQST)                                    LP_p <= 0;
    else if(set_first_half_bit && current_lp_data_bit)                      LP_p <= 1;
    else if(set_second_half_bit && current_lp_data_bit)                     LP_p <= 0;
    else if(!current_lp_data_bit)                                           LP_p <= 0;
end

always_ff @(posedge clk_sys or negedge rst_n) begin
    if(~rst_n)                                                              LP_n <= 1;
    else if(state_next == STATE_IDLE || state_next == STATE_HS_EXIT)        LP_n <= 1;
    else if(state_next == STATE_HS_PREP)                                    LP_n <= 0;
    else if(set_first_half_bit && !current_lp_data_bit)                     LP_n <= 1;
    else if(set_second_half_bit && !current_lp_data_bit)                    LP_n <= 0;
    else if(current_lp_data_bit)                                            LP_n <= 0;
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
    else if(state_next == STATE_HS_RQST)    hs_rqst_counter <= T_LPX - 1;

assign hs_rqst_timeout = (state_current == STATE_HS_RQST) && !(|hs_rqst_counter);

always_ff @(posedge clk_sys or negedge rst_n)
    if(~rst_n)                              hs_prep_counter <= 0;
    else if(state_current == STATE_HS_PREP) hs_prep_counter <= hs_prep_counter - 1;
    else if(state_next == STATE_HS_PREP)    hs_prep_counter <= T_HS_PREPARE - 1;

assign hs_prep_timeout = (state_current == STATE_HS_PREP) && !(|hs_prep_counter);

always_ff @(posedge clk_sys or negedge rst_n)
    if(~rst_n)                              hs_exit_counter <= 0;
    else if(state_current == STATE_HS_EXIT) hs_exit_counter <= hs_exit_counter - 1;
    else if(state_next == STATE_HS_EXIT)    hs_exit_counter <= T_HS_EXIT - 1;

assign hs_exit_timeout = (state_current == STATE_HS_EXIT) && !(|hs_exit_counter);

logic hs_start_rqst;

assign hs_start_rqst = (state_next == STATE_HS_ACTIVE) && (state_current != STATE_HS_ACTIVE);

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

    .data_rqst              (hs_data_rqst          ),
    .active                 (hs_lane_active     ),
    .fin_ack                (hs_fin_ack         ),

    .serial_hs_output       (serial_hs_output   )

    );

endmodule
