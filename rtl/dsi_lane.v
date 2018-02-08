module dsi_lane
(
    input  wire         clk_hs          ,      // serial data clock
    input  wire         clk_base        ,      // logic clock = clk_hs/8
    input  wire         clk_base_latch  ,      // clk_base, duty cycle 15%
    input  wire         reset_n         ,      // async reset
    input  wire         data_type       ,      // 0 - lp data, 1- hs data
    input  wire         end_of_frame    ,
    input  wire         data_write      ,
    input  wire         dummy_frame     ,
    input  wire [7:0]   data_input      ,

    output wire         data_ready      ,
    output wire         active          ,

    output wire         serial_data_out ,
    output wire         lp_out_p        ,
    output wire         lp_out_n
);

localparam [7:0] SYNC_PATTERN = 8'b00011101;

/* FSM Declararion */

localparam [3:0] STATE_LP_STOP      = 4'd0;
localparam [3:0] STATE_LP_RQST      = 4'd1;
localparam [3:0] STATE_LP_YELD      = 4'd2;
localparam [3:0] STATE_LP_ESC_RQST  = 4'd3;
localparam [3:0] STATE_LP_ESC_GO    = 4'd4;
localparam [3:0] STATE_LP_ESC_CMD   = 4'd5;
localparam [3:0] STATE_LP_LPDT      = 4'd6;
localparam [3:0] STATE_HS_LPX       = 4'd7;
localparam [3:0] STATE_HS_PRPR      = 4'd8;
localparam [3:0] STATE_HS_ZERO      = 4'd9;
localparam [3:0] STATE_HS_SYNC      = 4'd10;
localparam [3:0] STATE_HS_TRNSM     = 4'd11;
localparam [3:0] STATE_HS_TRAIL     = 4'd12;
localparam [3:0] STATE_HS_EXIT      = 4'd13;

reg [3:0]   current_state;
reg [3:0]   next_state;

/* Input data buffers */

reg [10:0]  pre_buff;
reg [10:0]  buff;
reg         prebuff_full;
reg         buff_full;
reg         data_ready_reg;

wire        write_prebuff;
wire        write_buff;
wire        read_buff;

assign      write_prebuff   = data_write && (!prebuff_full || write_buff);
assign      write_buff      = prebuff_full && (!buff_full || read_buff);

always @(posedge clk_base or negedge reset_n)
    if(!reset_n)              pre_buff <= 11'b0;
    else if(write_prebuff)    pre_buff <= {data_type, end_of_frame, dummy_frame, data_input};

always @(posedge clk_base or negedge reset_n)
    if(!reset_n)            buff <= 11'b0;
    else if(write_buff)     buff <= pre_buff;

always @(posedge clk_base or negedge reset_n)
    if(!reset_n)            prebuff_full <= 1'b0;
    else if(write_prebuff)  prebuff_full <= 1'b1;
    else if(write_buff)     prebuff_full <= 1'b0;

always @(posedge clk_base or negedge reset_n)
    if(!reset_n)            buff_full <= 1'b0;
    else if(write_buff)     buff_full <= 1'b1;
    else if(read_buff)      buff_full <= 1'b0;

always @(posedge clk_base or negedge reset_n)
    if(!reset_n)                                                                        data_ready_reg <= 1'b1;
    else if(((buff_full && prebuff_full || data_write && write_buff) && !read_buff))    data_ready_reg <= 1'b0;
    else                                                                                data_ready_reg <= 1'b1;

assign data_ready = 	(!buff_full && !prebuff_full) ||
			(prebuff_full && !buff_full && !data_write) || 
			(!prebuff_full && buff_full && !data_write);

/* timeouts */
localparam [7:0] HS_STATE_LPX_LENGHT    = 8'd10;
localparam [7:0] HS_STATE_PRPR_LENGHT   = 8'd10; // 38 - 95 ns
localparam [7:0] HS_STATE_ZERO_LENGHT   = 8'd10; // 205 - 262 ns min
localparam [7:0] HS_STATE_TRAIL_LENGHT  = 8'd10;
localparam [7:0] HS_STATE_EXIT_LENGHT   = 8'd10;

wire [7:0] timeout_value;

assign timeout_value =  (current_state == STATE_HS_LPX)     ? HS_STATE_LPX_LENGHT   :
                        (current_state == STATE_HS_PRPR)    ? HS_STATE_PRPR_LENGHT  :
                        (current_state == STATE_HS_ZERO)    ? HS_STATE_ZERO_LENGHT  :
                        (current_state == STATE_HS_TRAIL)   ? HS_STATE_TRAIL_LENGHT : HS_STATE_EXIT_LENGHT;

reg [7:0]   state_counter;
wire        counter_enabled;
wire        timeout_activated;

assign counter_enabled      = (current_state == STATE_HS_LPX) || (current_state == STATE_HS_PRPR) || (current_state == STATE_HS_ZERO) || (current_state == STATE_HS_TRAIL) || (current_state == STATE_HS_EXIT);
assign timeout_activated    = (state_counter == timeout_value);

always @(posedge clk_base or negedge reset_n)
    if(!reset_n)                state_counter <= 8'b0;
    else if(timeout_activated)  state_counter <= 8'b0;
    else if(counter_enabled)    state_counter <= state_counter + 8'b1;

/* FSM */
always @(posedge clk_base or negedge reset_n)
    if(!reset_n)        current_state <= STATE_LP_STOP;
    else                current_state <= next_state;

always @*
begin
    case (current_state)

        STATE_LP_STOP:
            next_state = buff_full ? (buff[10] ? (STATE_HS_LPX) : (STATE_LP_RQST)) : STATE_LP_STOP;

        STATE_LP_RQST:
            next_state = STATE_LP_RQST;

        STATE_LP_YELD:
            next_state = STATE_LP_RQST;

        STATE_LP_ESC_RQST:
            next_state = STATE_LP_RQST;

        STATE_LP_ESC_GO:
            next_state = STATE_LP_RQST;

        STATE_LP_ESC_CMD:
            next_state = STATE_LP_RQST;

        STATE_LP_LPDT:
            next_state = STATE_LP_RQST;

        STATE_HS_LPX:
            next_state = timeout_activated ? STATE_HS_PRPR : STATE_HS_LPX;

        STATE_HS_PRPR:
            next_state = timeout_activated ? STATE_HS_ZERO : STATE_HS_PRPR;

        STATE_HS_ZERO:
            next_state = timeout_activated ? STATE_HS_SYNC : STATE_HS_ZERO;

        STATE_HS_SYNC:
            next_state = buff[8] ? STATE_HS_TRNSM : STATE_HS_TRAIL;

        STATE_HS_TRNSM:
            next_state = buff[9] ? STATE_HS_TRAIL : STATE_HS_TRNSM;

        STATE_HS_TRAIL:
            next_state = timeout_activated ? STATE_HS_EXIT : STATE_HS_TRAIL;

        STATE_HS_EXIT:
            next_state = timeout_activated ? STATE_LP_STOP : STATE_HS_EXIT;

        default :
            current_state <= STATE_LP_STOP;

    endcase
end

assign read_buff    = (current_state == STATE_HS_TRNSM);
assign active       = (current_state != STATE_LP_STOP);

wire [1:0]  lp_lines;
wire        serdes_out;
wire        hs_en;
wire        lp_en;

assign lp_lines =       ((current_state == STATE_LP_STOP) || (current_state == STATE_HS_EXIT))   ? 2'b11   :
                        (current_state == STATE_HS_LPX)     ? 2'b01   :
                        (current_state == STATE_HS_PRPR)    ? 2'b00   :
                        2'b00;

assign hs_en = (current_state == STATE_HS_ZERO) ||
               (current_state == STATE_HS_SYNC) ||
               (current_state == STATE_HS_TRNSM) ||
               (current_state == STATE_HS_TRAIL);

assign lp_en = (current_state == STATE_LP_STOP)     ||
               (current_state == STATE_LP_RQST)     ||
               (current_state == STATE_LP_YELD)     ||
               (current_state == STATE_HS_LPX)      ||
               (current_state == STATE_HS_PRPR)     ||
               (current_state == STATE_LP_ESC_RQST) ||
               (current_state == STATE_LP_ESC_GO)   ||
               (current_state == STATE_LP_ESC_CMD)  ||
               (current_state == STATE_HS_EXIT)     ||
               (current_state == STATE_LP_LPDT);

wire [7:0] data_out;
reg  [7:0] trail_sequence;

always @(posedge clk_base or negedge reset_n)
    if(!reset_n)        trail_sequence <= 8'b0;
    else if(buff[9])    trail_sequence <= !({8{buff[0]}});

assign data_out = (current_state == STATE_HS_SYNC) ? SYNC_PATTERN : ((current_state == STATE_HS_TRAIL) ? trail_sequence : ( (current_state == STATE_HS_ZERO) ? 8'b0 : ( (current_state == STATE_HS_TRNSM) ? buff : 8'b0)));

altlvds	altlvds_inst_0 (
	.tx_enable     ( clk_base_latch    ),
	.tx_in         ( data_out          ),
	.tx_inclock    ( clk_hs            ),
	.tx_out        ( serdes_out        )
	);

hs_buff hs_buff_0 (
    .datain     ( serdes_out        ),
    .oe         ( hs_en             ),
    .dataout    ( serial_data_out   )
    );

hs_buff lp_line_p (
    .datain     (lp_lines[0]    ),
    .oe         (lp_en          ),
    .dataout    (lp_out_p       )
    );

hs_buff lp_line_n (
    .datain     (lp_lines[1]    ),
    .oe         (lp_en          ),
    .dataout    (lp_out_n       )
    );

endmodule
