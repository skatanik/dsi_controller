module dsi_lane_full #(
    parameter MODE = 0  // 0 - lane, 1 - clk
    )(
    input wire          clk                     , // serial data clock
    input wire          rst_n                   ,

    input wire          mode_lp                 , // which mode to use to send data throught this lane. 0 - hs, 1 - lp
    input wire          start_rqst              ,
    input wire          fin_rqst                ,
    input wire          lines_enable            ,
    input wire [7:0]    inp_data                ,

    output wire         data_rqst               ,
    output wire         active                  ,
    output wire         lane_ready              ,

    input wire [7:0]    tlpx_timeout_val        ,
    input wire [7:0]    hs_prepare_timeout_val  ,
    input wire [7:0]    hs_exit_timeout_val     ,
    input wire [7:0]    hs_go_timeout_val       ,
    input wire [7:0]    hs_trail_timeout_val    ,

    output wire [7:0]   hs_output               ,
    output wire         hs_enable               ,
    output wire         LP_p_output             ,
    output wire         LP_n_output             ,
    output wire         lp_lines_enable
);

wire hs_fin_ack;
wire hs_rqst_timeout;
wire hs_prep_timeout;
wire hs_exit_timeout;
wire hs_data_rqst;
wire lp_data_is_sent;
wire send_esc_mode_entry_done;
wire send_entry_cmd_done;
wire send_mark_one_done;
wire inc_lp_data_bits_counter;
reg [7:0] hs_rqst_counter;

/***********************************
        FSM declaration
************************************/

localparam [3:0] STATE_LINES_DISABLED = 0;
localparam [3:0] STATE_IDLE = 1;
localparam [3:0] STATE_HS_RQST = 2;
localparam [3:0] STATE_HS_PREP = 3;
localparam [3:0] STATE_HS_ACTIVE = 4;
localparam [3:0] STATE_HS_EXIT = 5;
localparam [3:0] STATE_LP_SEND_ESC_MODE_ENTRY = 6;
localparam [3:0] STATE_LP_SEND_ENTRY_CMD = 7;        // entry command is fixed to Low-Power Data Transmission
localparam [3:0] STATE_LP_SEND_LP_CMD = 8;
localparam [3:0] STATE_LP_SEND_MARK_ONE = 9;
localparam [3:0] STATE_ULPS_01 = 10;

reg [3:0] state_current, state_next;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        state_current <= STATE_LINES_DISABLED;
    end else begin
        state_current <= state_next;
    end
end

always @(*) begin
    case (state_current)

        STATE_LINES_DISABLED:
            state_next = lines_enable ? STATE_ULPS_01 : STATE_LINES_DISABLED;

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

        STATE_ULPS_01:
            state_next = (hs_rqst_counter == 0) ? STATE_IDLE : STATE_ULPS_01;

        default :
            state_next = STATE_LINES_DISABLED;
    endcase
end

assign lane_ready = (state_current != STATE_LINES_DISABLED) && (state_current != STATE_ULPS_01);

assign active = (state_current == STATE_HS_ACTIVE) | (state_current == STATE_LP_SEND_LP_CMD);

localparam [7:0]    ESC_MODE_ENTRY      = 8'b00000010;
localparam [7:0]    ENTRY_CMD           = 8'b11100001;
localparam [7:0]    LP_BAUD_TIME        = 8'd30;

reg LP_p;
reg LP_n;
reg [7:0] lp_data_buffer;
reg [3:0] lp_data_bits_counter;
wire       lp_data_rqst;
reg [7:0] lp_baud_counter;
wire       set_first_half_bit;
wire       set_second_half_bit;
wire       next_state_lpdt;
wire       next_state_send_cmd;
reg       last_lp_byte;
wire       send_lp_data;
wire       reset_baud_counter;
reg       fin_rqst_reg;
reg       lp_fin_rqst_reg;
wire       next_state_entry_cmd;
wire       next_state_mark_one;

assign next_state_lpdt          = (state_next == STATE_LP_SEND_ESC_MODE_ENTRY) && (state_current == STATE_IDLE);
assign next_state_entry_cmd     = (state_next == STATE_LP_SEND_ENTRY_CMD) && (state_current == STATE_LP_SEND_ESC_MODE_ENTRY);
assign next_state_mark_one      = (state_next == STATE_LP_SEND_MARK_ONE) && (state_current == STATE_LP_SEND_LP_CMD);
assign next_state_send_cmd      = (state_current == STATE_LP_SEND_ENTRY_CMD) && (state_next == STATE_LP_SEND_LP_CMD);
assign data_rqst                = (/*(state_current == STATE_HS_RQST) ||*/ (state_current == STATE_HS_PREP) || (state_current == STATE_HS_ACTIVE)) ? hs_data_rqst : lp_data_rqst;

always @(posedge clk or negedge rst_n)
    if(~rst_n)                                      lp_data_buffer <= 8'b0;
    else if(next_state_lpdt)                        lp_data_buffer <= ESC_MODE_ENTRY;
    else if(next_state_entry_cmd)                   lp_data_buffer <= ENTRY_CMD;
    else if(send_lp_data)                           lp_data_buffer <= inp_data;
    else if(next_state_mark_one)                    lp_data_buffer <= 8'hff;
    else if(state_next == STATE_IDLE)               lp_data_buffer <= 8'b0;

always @(posedge clk or negedge rst_n)
    if(~rst_n)                          last_lp_byte <= 1'b0;
    else if(send_lp_data)               last_lp_byte <= lp_fin_rqst_reg;
    else if(state_next == STATE_IDLE)   last_lp_byte <= 1'b0;

assign lp_data_is_sent = lp_data_rqst & last_lp_byte;

assign inc_lp_data_bits_counter = !(|lp_baud_counter) && ((state_current == STATE_LP_SEND_ESC_MODE_ENTRY) || (state_current == STATE_LP_SEND_ENTRY_CMD) || (state_current == STATE_LP_SEND_LP_CMD) || (state_current == STATE_LP_SEND_MARK_ONE));

wire bits_counter_is_zero;

assign bits_counter_is_zero     = !(|lp_data_bits_counter) && reset_baud_counter;
assign send_lp_data             = next_state_send_cmd || lp_data_rqst && !last_lp_byte && (state_current != STATE_IDLE);

always @(posedge clk or negedge rst_n)
    if(~rst_n)                                                      lp_data_bits_counter <= 4'b0;
    else if(next_state_lpdt)                                        lp_data_bits_counter <= 4'b1;
    else if(next_state_entry_cmd)                                   lp_data_bits_counter <= 4'd7;
    else if(next_state_mark_one)                                    lp_data_bits_counter <= 4'd0;
    else if(send_lp_data)                                           lp_data_bits_counter <= 4'd7;
    else if(inc_lp_data_bits_counter && (|lp_data_bits_counter))    lp_data_bits_counter <= lp_data_bits_counter - 4'd1;

reg lp_data_rqst_delayed;

always @(posedge clk or negedge rst_n)
    if(!rst_n)  lp_data_rqst_delayed <= 1'b0;
    else        lp_data_rqst_delayed <= lp_data_rqst;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                          lp_fin_rqst_reg <= 1'b0;
    else if(lp_data_rqst_delayed)       lp_fin_rqst_reg <= fin_rqst;

assign lp_data_rqst                 = (state_current == STATE_LP_SEND_LP_CMD) && bits_counter_is_zero  || (state_current == STATE_IDLE) || next_state_send_cmd;
assign send_esc_mode_entry_done     = (state_current == STATE_LP_SEND_ESC_MODE_ENTRY) && bits_counter_is_zero;
assign send_entry_cmd_done          = (state_current == STATE_LP_SEND_ENTRY_CMD) && bits_counter_is_zero;
assign send_mark_one_done           = (state_current == STATE_LP_SEND_MARK_ONE) && set_second_half_bit;

assign reset_baud_counter = next_state_lpdt || inc_lp_data_bits_counter;

always @(posedge clk or negedge rst_n)
    if(~rst_n)                          lp_baud_counter <= 8'b0;
    else if(reset_baud_counter)         lp_baud_counter <= LP_BAUD_TIME;
    else if(state_next == STATE_IDLE)   lp_baud_counter <= 8'b0;
    else if(|lp_baud_counter)           lp_baud_counter <= lp_baud_counter - 8'b1;

assign set_first_half_bit   = lp_baud_counter == LP_BAUD_TIME;
assign set_second_half_bit  = (lp_baud_counter == {1'b0, LP_BAUD_TIME[7:1]});

wire current_lp_data_bit;
wire [7:0] shifted_lp_data;
wire set_lp_line_to_one;
wire set_lp_line_to_zero;

assign shifted_lp_data          = lp_data_buffer >> (lp_data_bits_counter);
assign current_lp_data_bit      = shifted_lp_data[0];
assign set_lp_line_to_one       = state_next == STATE_IDLE || state_next == STATE_HS_EXIT;
assign set_lp_line_to_zero      = state_next == STATE_LINES_DISABLED;


// LP lines control
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)                                                              LP_p <= 0;
    else if(set_lp_line_to_zero)                                            LP_p <= 0;
    else if(set_lp_line_to_one)                                             LP_p <= 1;
    else if(state_next == STATE_HS_RQST)                                    LP_p <= 0;
    else if(set_first_half_bit && current_lp_data_bit)                      LP_p <= 1;
    else if(set_second_half_bit && current_lp_data_bit)                     LP_p <= 0;
    else if(!current_lp_data_bit && (state_current != STATE_IDLE))          LP_p <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)                                                              LP_n <= 0;
    else if(set_lp_line_to_zero)                                            LP_n <= 0;
    else if(set_lp_line_to_one)                                             LP_n <= 1;
    else if(state_next == STATE_ULPS_01)                                    LP_n <= 1;
    else if(state_next == STATE_HS_PREP)                                    LP_n <= 0;
    else if(set_first_half_bit && !current_lp_data_bit)                     LP_n <= 1;
    else if(set_second_half_bit && !current_lp_data_bit)                    LP_n <= 0;
    else if(current_lp_data_bit && (state_current != STATE_IDLE))           LP_n <= 0;
end

assign lp_lines_enable  = (state_current != STATE_HS_ACTIVE) && (state_current != STATE_LINES_DISABLED);
assign LP_p_output      = LP_p;
assign LP_n_output      = LP_n;

/******* Timeouts *******/

reg [7:0] hs_prep_counter;
reg [7:0] hs_exit_counter;

always @(posedge clk or negedge rst_n)
    if(~rst_n)                                                                      hs_rqst_counter <= 8'd0;
    else if((state_current == STATE_HS_RQST) | (state_current == STATE_ULPS_01))    hs_rqst_counter <= hs_rqst_counter - 8'd1;
    else                                                                            hs_rqst_counter <= tlpx_timeout_val - 8'd1;

assign hs_rqst_timeout = (state_current == STATE_HS_RQST) && !(|hs_rqst_counter);

always @(posedge clk or negedge rst_n)
    if(~rst_n)                              hs_prep_counter <= 8'd0;
    else if(state_current == STATE_HS_PREP) hs_prep_counter <= hs_prep_counter - 8'd1;
    else if(state_next == STATE_HS_PREP)    hs_prep_counter <= hs_prepare_timeout_val - 8'd1;

assign hs_prep_timeout = (state_current == STATE_HS_PREP) && !(|hs_prep_counter);

always @(posedge clk or negedge rst_n)
    if(~rst_n)                              hs_exit_counter <= 8'd0;
    else if(state_current == STATE_HS_EXIT) hs_exit_counter <= hs_exit_counter - 8'd1;
    else if(state_next == STATE_HS_EXIT)    hs_exit_counter <= hs_exit_timeout_val - 8'd1;

assign hs_exit_timeout = (state_current == STATE_HS_EXIT) && !(|hs_exit_counter);

wire hs_start_rqst;

assign hs_start_rqst = (state_next == STATE_HS_ACTIVE) && (state_current != STATE_HS_ACTIVE);

wire hs_lane_active;

always @(posedge clk or negedge rst_n)
    if(~rst_n)                          fin_rqst_reg <= 1'b0;
    else if(fin_rqst && !mode_lp)       fin_rqst_reg <= 1'b1;
    else if(hs_fin_ack)                 fin_rqst_reg <= 1'b0;


dsi_hs_lane  #(
    .MODE(MODE)
    ) dsi_hs_lane_0(
    .clk                    (clk                        ), // serial data clock
    .rst_n                  (rst_n                      ),

    .start_rqst             (hs_start_rqst              ),
    .fin_rqst               (fin_rqst | fin_rqst_reg    ),
    .inp_data               (inp_data                   ),

    .data_rqst              (hs_data_rqst               ),
    .active                 (hs_lane_active             ),
    .fin_ack                (hs_fin_ack                 ),

    .hs_go_timeout          (hs_go_timeout_val          ),
    .hs_trail_timeout       (hs_trail_timeout_val       ),

    .hs_output              (hs_output                  ),
    .hs_enable              (hs_enable                  )

    );

endmodule
