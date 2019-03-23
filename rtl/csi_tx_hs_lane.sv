module dsi_hs_lane #(
    parameter MODE = 0  // 0 - lane, 1 - clk
    )(
    input wire          clk                     , // serial data clock
    input wire          rst_n                   ,

    input wire          start_rqst              ,
    input wire          fin_rqst                ,
    input wire [7:0]    inp_data                ,

    output wire        data_rqst                ,
    output wire        active                   ,
    output wire        fin_ack                  ,        // shows that in the next clock block will finish trail sequence

    input wire [7:0]   hs_go_timeout            ,
    input wire [7:0]   hs_trail_timeout         ,

    output wire [7:0]  hs_output                ,
    output             hs_enable
    );

/***********************************
        FSM declaration
************************************/

/* TO DO
add state when all lines are disabled.
*/

enum logic [2:0]
{
    STATE_IDLE,
    STATE_TX_GO,
    STATE_TX_SYNC,
    STATE_TX_ACTIVE,
    STATE_TX_TRAIL
} state_current, state_next;

always_ff @(posedge clk or negedge rst_n) begin
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

logic active_r;

assign active = active_r;

always_ff @(posedge clk or negedge rst_n)
    if(~rst_n)                                  active_r <= 1'b0;
    else if(state_next == STATE_TX_GO)          active_r <= 1'b1;
    else if(state_next == STATE_IDLE)           active_r <= 1'b0;

logic tx_hs_trail_timeout_delayed;

always_ff @(posedge clk or negedge rst_n)
    if(~rst_n)          tx_hs_trail_timeout_delayed <= 1'b0;
    else                tx_hs_trail_timeout_delayed <= tx_hs_trail_timeout;

assign fin_ack      = tx_hs_trail_timeout_delayed;

logic data_rqst_r;

assign data_rqst = data_rqst_r;

// data_rqst line forming
always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        data_rqst_r <= 1'b0;
    end else begin
        data_rqst_r <= (state_next == STATE_TX_ACTIVE) & !fin_rqst;
    end
end

localparam [7:0] SYNC_SEQUENCE = 8'b00011101;

logic [7:0] serdes_data;
logic [7:0] last_bit_byte;

// serdes data mux
always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n)                                  serdes_data <= 8'b0;
    else if(state_current == STATE_TX_SYNC)     serdes_data <= SYNC_SEQUENCE;
    else if(state_current == STATE_TX_ACTIVE)   serdes_data <= inp_data;
    else if(state_current == STATE_TX_TRAIL)    serdes_data <= last_bit_byte;
    else                                        serdes_data <= 8'b0;
end

// remember bit for trail sequence
always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
         last_bit_byte <= 8'd0;
    end else if(state_current == STATE_TX_ACTIVE) begin
         last_bit_byte <= {8{!inp_data[0]}};
    end
end

logic serdes_enable;

always_ff @(posedge clk or negedge rst_n)
    if(~rst_n)          serdes_enable <= 1'b0;
    else                serdes_enable <= (state_current != STATE_IDLE); // or (state_next != STATE_IDLE)

assign hs_output        = serdes_data;
assign hs_enable        = serdes_enable;

// Timeouts

logic [7:0] tx_hs_go_counter;
logic [7:0] tx_hs_trail_counter;

always_ff @(posedge clk or negedge rst_n)
    if(~rst_n)                          tx_hs_go_counter <= 8'd0;
    else if((|tx_hs_go_counter))        tx_hs_go_counter <= tx_hs_go_counter - 8'd1;
    else if(state_next == STATE_TX_GO)  tx_hs_go_counter <= hs_go_timeout - 8'd1;

assign tx_hs_go_timeout = (state_current == STATE_TX_GO) && !(|tx_hs_go_counter);

always_ff @(posedge clk or negedge rst_n)
    if(~rst_n)                              tx_hs_trail_counter <= 8'd0;
    else if((|tx_hs_trail_counter))         tx_hs_trail_counter <= tx_hs_trail_counter - 8'd1;
    else if(state_next == STATE_TX_TRAIL)   tx_hs_trail_counter <= hs_trail_timeout - 8'd1;

assign tx_hs_trail_timeout = (state_current == STATE_TX_TRAIL) && !(|tx_hs_trail_counter);


endmodule // dsi_hs_lane
