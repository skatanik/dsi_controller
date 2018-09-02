module dsi_hs_lane #(
    parameter MODE = 0  // 0 - lane, 1 - clk
    )(
    input wire          clk_sys             , // serial data clock
    input wire          clk_serdes          , // logic clock = clk_hs/8
    input wire          clk_latch           , // clk_sys, duty cycle 15%
    input wire          rst_n               ,

    input wire          start_rqst          ,
    input wire          fin_rqst            ,
    input wire [7:0]    inp_data            ,

    output logic        data_rqst           ,
    output logic        active              ,
    output logic        fin_ack             ,        // shows that in the next clock block will finish trail sequence

    output logic        serial_hs_output

    );

/***********************************
        FSM declaration
************************************/

enum logic [2:0]
{
    STATE_IDLE,
    STATE_TX_GO,
    STATE_TX_SYNC,
    STATE_TX_ACTIVE,
    STATE_TX_TRAIL
} state_current, state_next;

always_ff @(posedge clk_sys or negedge rst_n) begin
    if(~rst_n) begin
        state_current <= STATE_IDLE;
    end else begin
        state_current <= state_next;
    end
end

logic tx_hs_go_timeout;
logic tx_hs_trail_timeout;

always_comb begin
    case (state_current)
        STATE_IDLE:
            state_next = start_rqst ? STATE_TX_GO : STATE_IDLE;

        STATE_TX_GO:
            state_next = tx_hs_go_timeout ? (!MODE ? STATE_TX_SYNC : STATE_TX_ACTIVE) : STATE_TX_GO;

        STATE_TX_SYNC:
            state_next = STATE_TX_ACTIVE;

        STATE_TX_ACTIVE:
            state_next = fin_rqst ? STATE_TX_TRAIL : STATE_TX_ACTIVE;

        STATE_TX_TRAIL:
            state_next = tx_hs_trail_timeout ? STATE_IDLE : STATE_TX_TRAIL;

        default :
            state_next = STATE_IDLE;
    endcase
end

assign active       = (state_current != STATE_IDLE);
assign fin_ack      = tx_hs_trail_timeout;

// data_rqst line forming
always_ff @(posedge clk_sys or negedge rst_n) begin
    if(~rst_n) begin
        data_rqst<= 1'b0;
    end else begin
        data_rqst <= (state_next == STATE_TX_SYNC) || (state_next == STATE_TX_ACTIVE);
    end
end

localparam [7:0] SYNC_SEQUENCE = 8'b00011101;

logic [7:0] serdes_data;
logic [7:0] last_bit_byte;

// serdes data mux
always_comb begin
    if(state_current == STATE_TX_SYNC)
        serdes_data = SYNC_SEQUENCE;
    else if(state_current == STATE_TX_ACTIVE)
        serdes_data = inp_data;
    else if(state_current == STATE_TX_TRAIL)
        serdes_data = last_bit_byte;
    else
        serdes_data = 8'b0;
end

// remember bit for trail sequence
always_ff @(posedge clk_sys or negedge rst_n) begin
    if(~rst_n) begin
         last_bit_byte <= 8'd0;
    end else if(state_current == STATE_TX_ACTIVE) begin
         last_bit_byte <= {8{!inp_data[7]}};
    end
end

wire serdes_enable;
wire serdes_out;

assign serdes_enable = active;

altlvds altlvds_inst_0 (
    .tx_enable ( clk_latch ),
    .tx_in ( serdes_data ),
    .tx_inclock ( clk_serdes ),
    .tx_out ( serdes_out )
    );

hs_buff hs_buff_inst_d0 (
    .datain ( serdes_out ),
    .oe ( serdes_enable ),
    .dataout ( serial_hs_output )
    );

// Timeouts
localparam [7:0] TX_HS_GO_TIMEOUT_VAL = 20; // 145 ns + 10*UI THS-zero
localparam [7:0] TX_HS_TRAIL_TIMEOUT_VAL = 10; // 145 ns + 10*UI

logic [7:0] tx_hs_go_counter;
logic [7:0] tx_hs_trail_counter;

always_ff @(posedge clk_sys or negedge rst_n)
    if(~rst_n)                              tx_hs_go_counter <= 0;
    else if(state_next == STATE_TX_GO)      tx_hs_go_counter <= TX_HS_GO_TIMEOUT_VAL;
    else if(state_current == STATE_TX_GO)   tx_hs_go_counter <= tx_hs_go_counter - 1;

assign tx_hs_go_timeout = (state_current == STATE_TX_GO) && !(|tx_hs_go_counter);

always_ff @(posedge clk_sys or negedge rst_n)
    if(~rst_n)                                  tx_hs_trail_counter <= 0;
    else if(state_next == STATE_TX_TRAIL)       tx_hs_trail_counter <= TX_HS_TRAIL_TIMEOUT_VAL;
    else if(state_current == STATE_TX_TRAIL)    tx_hs_trail_counter <= tx_hs_trail_counter - 1;

assign tx_hs_trail_timeout = (state_current == STATE_TX_TRAIL) && !(|tx_hs_trail_counter);


endmodule // dsi_hs_lane