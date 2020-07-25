`ifndef DSI_PACKETS_ASSEMBLER
`define DSI_PACKETS_ASSEMBLER

module packets_assembler (
    /********* Clock signals *********/
        input   wire                            clk                                 ,
        input   wire                            rst_n                               ,

    /********* lanes controller iface *********/
        output  wire [31:0]                     lanes_fifo_data                     , // 32:9 - 3x8 data, 8 - lpm sign, 7:0 lane 0 data
        output  wire [3:0]                      lanes_fifo_write                    ,
        output  wire                            lanes_fifo_lpm                      ,
        input   wire [3:0]                      lanes_fifo_full                     ,
        input   wire [3:0]                      lanes_fifo_empty                    ,

    /********* pixel FIFO interface *********/
        input   wire  [31:0]                    pix_fifo_data                       ,
        input   wire                            pix_fifo_empty                      ,
        output  wire                            pix_fifo_read                       ,

    /********* cmd FIFO interface *********/
        input   wire  [31:0]                    usr_fifo_data                       ,
        input   wire                            usr_fifo_empty                      ,
        output  wire                            usr_fifo_read                       ,

    /********* Control inputs *********/
        input   wire                            lpm_enable                          ,   // 1: go to LPM after sending commands. 0: send blank packet after sending command or data
        input   wire                            user_cmd_transmission_mode          ,   // 0: data from user fifo is sent in HS mode; 1: data from user fifo is sent in LP mode.
        input   wire                            enable_EoT_sending                  ,
        input   wire                            streaming_enable                    ,
        input   wire [2:0]                      lines_number                        ,
    /********* timings registers *********/
        input   wire [15:0]                     horizontal_line_length              ,   // length in clk
        input   wire [15:0]                     horizontal_front_porch              ,   // length in pixels
        input   wire [15:0]                     horizontal_back_porch               ,   // length in pixels
        input   wire [15:0]                     pixels_in_line_number               ,   // length in pixels
        input   wire [15:0]                     vertical_active_lines_number        ,   // length in lines
        input   wire [15:0]                     vertical_front_porch_lines_number   ,   // length in lines
        input   wire [15:0]                     vertical_back_porch_lines_number    ,   // length in lines
        input   wire [15:0]                     lpm_length                              // length in clk

);

`define LP_PACKET_SIZE  16'b0
`define LP_BAUD_TIME    16'b0

`define CLK_RST(clk, rst_n)   posedge clk, negedge rst_n
`define RST(rst_n)   !rst_n

`define PACKET_BLANKING     6'h19
`define PACKET_PPS24        6'h3E
`define PACKET_VSS          6'h01
`define PACKET_HSS          6'h21
`define PACKET_EOT          6'h08

/********* CMD fifo signals *********/
logic           cmd_fifo_full;
logic           cmd_fifo_full_w;
logic           cmd_fifo_empty;
logic           cmd_fifo_read;
logic           cmd_fifo_write;
logic [1:0]     cmd_fifo_usedw;
logic [32:0]    cmd_fifo_data;
logic [32:0]    cmd_fifo_data_out;
logic [32:0]    cmd_fifo_data_in;
logic           cmd_fifo_out_ctrl; // next muxes ctrl signals state. cmd_fifo_out_ctrl = 1, next cmd from usr fifo, 0 - from cmd fifo
logic           cmd_fifo_in_ctrl; // next muxes ctrl signals state. cmd_fifo_out_ctrl = 1, next cmd from usr fifo, 0 - from cmd fifo
logic           lp_pix;
logic           lp_blank;
logic           blank_timeout;
logic           last_hss_bl_0;
logic           last_pix_line;
logic           last_hss_bl_2;
logic           usr_fifo_packet_long;
logic           usr_fifo_packet_error;

assign cmd_fifo_out_ctrl = cmd_fifo_data[32];

assign lp_pix       = cmd_fifo_data[21:16] == `PACKET_PPS24;
assign lp_blank     = cmd_fifo_data[21:16] == `PACKET_BLANKING;

logic [32:0]  cmd_fifo_data_in_reg;
logic         cmd_fifo_write_reg;

cmd_fifo_33x4   cmd_fifo_33x4_inst (
    .aclr   (rst_n                      ),
    .clock  (clk                        ),
    .data   (cmd_fifo_data_in_reg       ),
    .rdreq  (cmd_fifo_read              ),
    .wrreq  (cmd_fifo_write_reg         ),
    .empty  (cmd_fifo_empty             ),
    .full   (cmd_fifo_full_w            ),
    .q      (cmd_fifo_data_out          ),
    .usedw  (cmd_fifo_usedw             )
    );

assign cmd_fifo_data = cmd_fifo_empty ? 33'b0 : cmd_fifo_data_out;

assign cmd_fifo_full = cmd_fifo_usedw == 2'b1;

/********************************************************************
                        FSM declaration
********************************************************************/

localparam [4:0] STATE_IDLE              = 0;
localparam [4:0] STATE_WRITE_VSS         = 1;
localparam [4:0] STATE_WRITE_VSS_EOT     = 2;
localparam [4:0] STATE_WRITE_VSS_BL      = 3;
localparam [4:0] STATE_WRITE_HSS_0       = 4;
localparam [4:0] STATE_WRITE_HSS_0_EOT   = 5;
localparam [4:0] STATE_WRITE_HSS_BL_0    = 6;
localparam [4:0] STATE_WRITE_HSS_1       = 7;
localparam [4:0] STATE_WRITE_HSS_1_EOT   = 8;
localparam [4:0] STATE_WRITE_HBP         = 9;
localparam [4:0] STATE_WRITE_RGB         = 10;
localparam [4:0] STATE_WRITE_RGB_EOT     = 11;
localparam [4:0] STATE_WRITE_HSS_BL_1    = 12;
localparam [4:0] STATE_WRITE_HFP         = 13;
localparam [4:0] STATE_WRITE_HSS_2       = 14;
localparam [4:0] STATE_WRITE_HSS_2_EOT   = 15;
localparam [4:0] STATE_WRITE_HSS_BL_2    = 16;
localparam [4:0] STATE_WRITE_LPM         = 17;

reg [4:0] state_current, state_next, state_current_delayed, state_next_delayed;

always @(`CLK_RST(clk, rst_n))
    if(`RST(rst_n))   state_current <= STATE_IDLE;
    else                state_current <= state_next;

/*
blank_timeout counter when lpm_enable = 1 should start counting only after cmd_fifo_empty = 1
*/

always @(*)
    begin
        case (state_current)
            STATE_IDLE:
                state_next = (streaming_enable & usr_fifo_empty ? STATE_WRITE_VSS : STATE_IDLE);

            STATE_WRITE_VSS:
                state_next = !cmd_fifo_full ? (enable_EoT_sending & lpm_enable ? STATE_WRITE_VSS_EOT : STATE_WRITE_VSS_BL) : STATE_WRITE_VSS;     // if lpm_enable = 1, then we don't write next cmd. Anyways if there is a cmd in usr_fifo, we should set a corresponding flag

            STATE_WRITE_VSS_EOT:
                state_next = !cmd_fifo_full ? STATE_WRITE_VSS_BL : STATE_WRITE_VSS_EOT;

            STATE_WRITE_VSS_BL:         // if lpm_enable = 1 then we wait for timeout and don't write anything, otherwise we write blank packet cmd and switch to the next state
                state_next = lpm_enable ? (blank_timeout ? STATE_WRITE_HSS_0 : STATE_WRITE_VSS_BL) : (cmd_fifo_full ? STATE_WRITE_VSS_BL : STATE_WRITE_HSS_0);

            STATE_WRITE_HSS_0:  // if lpm_enable = 1, then we don't write next cmd. But if there a cmd in usr_fifo, we should set a corresponding flag
                state_next = !cmd_fifo_full ? (enable_EoT_sending & lpm_enable ? STATE_WRITE_HSS_0_EOT : STATE_WRITE_HSS_BL_0) : STATE_WRITE_HSS_0;

            STATE_WRITE_HSS_0_EOT:
                state_next = !cmd_fifo_full ? STATE_WRITE_HSS_BL_0 : STATE_WRITE_HSS_0_EOT;

            STATE_WRITE_HSS_BL_0:
                state_next = lpm_enable ? (blank_timeout ? (last_hss_bl_0 ? STATE_WRITE_HSS_1 : STATE_WRITE_HSS_0) : STATE_WRITE_HSS_BL_0) : (cmd_fifo_full ? STATE_WRITE_HSS_BL_0 : (last_hss_bl_0 ? STATE_WRITE_HSS_1 : STATE_WRITE_HSS_0));

            STATE_WRITE_HSS_1:
                state_next = !cmd_fifo_full ? (enable_EoT_sending & lpm_enable ? STATE_WRITE_HSS_1_EOT : STATE_WRITE_HBP) : STATE_WRITE_HSS_1;

            STATE_WRITE_HSS_1_EOT:
                state_next = !cmd_fifo_full ? STATE_WRITE_HBP : STATE_WRITE_HSS_1_EOT;

            STATE_WRITE_HBP:
                state_next = lpm_enable ? (blank_timeout ? STATE_WRITE_RGB : STATE_WRITE_HBP) : (cmd_fifo_full ? STATE_WRITE_HBP : STATE_WRITE_RGB);

            STATE_WRITE_RGB:
                state_next = !cmd_fifo_full ? (enable_EoT_sending & lpm_enable ? STATE_WRITE_RGB_EOT : STATE_WRITE_HSS_BL_1) : STATE_WRITE_RGB;

            STATE_WRITE_RGB_EOT:
                state_next = !cmd_fifo_full ? STATE_WRITE_HSS_BL_1 : STATE_WRITE_RGB_EOT;

            STATE_WRITE_HSS_BL_1:
                state_next = lpm_enable ? (blank_timeout ? STATE_WRITE_HFP : STATE_WRITE_HSS_BL_1) : (cmd_fifo_full ? STATE_WRITE_HSS_BL_1 : STATE_WRITE_HFP);

            STATE_WRITE_HFP:
                state_next = lpm_enable ? (blank_timeout ? (last_pix_line ? STATE_WRITE_HSS_2 : STATE_WRITE_HSS_1) : STATE_WRITE_HFP) : (cmd_fifo_full ? STATE_WRITE_HFP : (last_pix_line ? STATE_WRITE_HSS_2 : STATE_WRITE_HSS_1));

            STATE_WRITE_HSS_2:
                state_next = !cmd_fifo_full ? (enable_EoT_sending & (lpm_enable | last_hss_bl_2) ? STATE_WRITE_HSS_2_EOT : STATE_WRITE_HSS_BL_2) : STATE_WRITE_HSS_2;

            STATE_WRITE_HSS_2_EOT:
                state_next = !cmd_fifo_full ? STATE_WRITE_HSS_BL_2 : STATE_WRITE_HSS_2_EOT;

            STATE_WRITE_HSS_BL_2:
                state_next = lpm_enable ? (blank_timeout ? (last_hss_bl_2 ? STATE_WRITE_LPM : STATE_WRITE_HSS_2) : STATE_WRITE_HSS_BL_2) : (cmd_fifo_full ? STATE_WRITE_HSS_BL_2 : (last_hss_bl_0 ? STATE_WRITE_LPM : STATE_WRITE_HSS_2));

            STATE_WRITE_LPM:    // we dont write any cmd here, just wait for timeout
                state_next = blank_timeout ? (streaming_enable ? STATE_WRITE_VSS : STATE_IDLE) : STATE_WRITE_LPM;

            default :
                state_next = STATE_IDLE;

        endcase
    end

/********************************************************************
                Timing counters
********************************************************************/
reg [15:0]    blank_timer;
wire           blank_counter_start; // write me!
reg           blank_counter_active;
reg [15:0]    blank_counter_init_val;
reg [15:0]    blank_packet_size;
reg           usr_fifo_wait_next_read;
reg             blank_counter_start_reg;

assign blank_counter_start = !(|blank_timer) & lpm_enable & cmd_fifo_empty & (usr_fifo_empty || !usr_fifo_wait_next_read) &
                                ((state_current == STATE_WRITE_VSS_BL)      |
                                (state_current == STATE_WRITE_HSS_BL_0)     |
                                (state_current == STATE_WRITE_HBP)          |
                                (state_current == STATE_WRITE_HSS_BL_1)     |
                                (state_current == STATE_WRITE_HFP)          |
                                (state_current == STATE_WRITE_HSS_BL_2)     |
                                (state_current == STATE_WRITE_LPM))         ;

always @(posedge clk or negedge rst_n)
    if(!rst_n)      blank_counter_start_reg <= 1'b0;
    else            blank_counter_start_reg <= blank_counter_start;

wire [15:0]    usr_packet_length;
wire [15:0]    usr_packet_length_in_clk;

assign usr_packet_length            = usr_fifo_packet_long & !usr_fifo_packet_error ? (16'd6 + usr_fifo_data[15:0]) : 16'd4;
assign usr_packet_length_in_clk     = user_cmd_transmission_mode ? {2'b0, usr_packet_length[15:2]} : 16'd0;

always @(posedge clk or negedge rst_n)
    if(!rst_n)          state_current_delayed <= STATE_IDLE;
    else                state_current_delayed <= state_current;

always @(posedge clk or negedge rst_n)
    if(!rst_n)          state_next_delayed <= STATE_IDLE;
    else                state_next_delayed <= state_next;


always @(`CLK_RST(clk, rst_n))
    if(`RST(rst_n))       blank_counter_init_val <= 16'd0;
    else if(state_current_delayed != state_next_delayed)
        case(state_current)
        STATE_WRITE_VSS:
            blank_counter_init_val <= horizontal_line_length - 16'd1 - {15'b0, enable_EoT_sending} - usr_packet_length_in_clk;

        STATE_WRITE_HSS_0:
            blank_counter_init_val <= horizontal_line_length - 16'd1 - {15'b0, enable_EoT_sending} - usr_packet_length_in_clk;

        STATE_WRITE_HSS_1:
            blank_counter_init_val <= {2'b0, horizontal_back_porch[15:2]} - {15'b0, enable_EoT_sending};

        STATE_WRITE_RGB:
            blank_counter_init_val <= horizontal_line_length - 16'd1 - {14'b0, enable_EoT_sending, 1'b0} - ((pixels_in_line_number * 3) >> 2) - 16'd2 - usr_packet_length_in_clk - {2'b0, horizontal_front_porch[15:2]};

        STATE_WRITE_HSS_BL_1:
            blank_counter_init_val <= {2'b0, horizontal_front_porch[15:2]};

        STATE_WRITE_HSS_2:
            blank_counter_init_val <= horizontal_line_length - 16'd1 - {15'b0, enable_EoT_sending} - usr_packet_length_in_clk;

        STATE_WRITE_HSS_BL_2:
            blank_counter_init_val <= lpm_length;

        default:
            blank_counter_init_val <= 16'd0;

    endcase

always @(`CLK_RST(clk, rst_n))
    if(`RST(rst_n))                     blank_timer <= 16'b0;
    else if(blank_counter_start_reg)    blank_timer <= blank_counter_init_val;
    else if(|blank_timer)               blank_timer <= blank_timer - 16'd1;

always @(`CLK_RST(clk, rst_n))
    if(`RST(rst_n))                     blank_counter_active <= 1'b0;
    else if(blank_counter_start_reg)    blank_counter_active <= 1'b1;
    else if(!(|blank_timer))            blank_counter_active <= 1'b0;

assign blank_timeout = blank_counter_active & (!(|blank_timer));

wire state_write_hs_packet;
wire state_write_lp_hs_packet;
wire state_usr_cmd_allowed;
wire usr_fifo_packet_pending; // flag shows that a packet in usr_fifo should be written after current cmd.

assign state_write_hs_packet =  (state_current == STATE_WRITE_VSS)          |
                                (state_current == STATE_WRITE_HSS_0)        |
                                (state_current == STATE_WRITE_HSS_1)        |
                                (state_current == STATE_WRITE_RGB)          |
                                (state_current == STATE_WRITE_HSS_2)        |
                                (state_current == STATE_WRITE_VSS_EOT)      |
                                (state_current == STATE_WRITE_HSS_0_EOT)    |
                                (state_current == STATE_WRITE_HSS_1_EOT)    |
                                (state_current == STATE_WRITE_RGB_EOT)      |
                                (state_current == STATE_WRITE_HSS_2_EOT)    ;

assign state_write_lp_hs_packet =   (state_current == STATE_WRITE_VSS_BL)   |
                                    (state_current == STATE_WRITE_HSS_BL_0) |
                                    (state_current == STATE_WRITE_HBP)      |
                                    (state_current == STATE_WRITE_HSS_BL_1) |
                                    (state_current == STATE_WRITE_HFP)      |
                                    (state_current == STATE_WRITE_HSS_BL_2);

assign state_usr_cmd_allowed =  (state_current == STATE_WRITE_VSS)        & (!enable_EoT_sending | enable_EoT_sending & !user_cmd_transmission_mode)  |
                                (state_current == STATE_WRITE_HSS_0)      & (!enable_EoT_sending | enable_EoT_sending & !user_cmd_transmission_mode)  |
                                (state_current == STATE_WRITE_RGB)        & (!enable_EoT_sending | enable_EoT_sending & !user_cmd_transmission_mode)  |
                                (state_current == STATE_WRITE_HSS_2)      & (!enable_EoT_sending | enable_EoT_sending & !user_cmd_transmission_mode)  |
                                (state_current == STATE_WRITE_VSS_EOT)    & user_cmd_transmission_mode  |
                                (state_current == STATE_WRITE_HSS_0_EOT)  & user_cmd_transmission_mode  |
                                (state_current == STATE_WRITE_HSS_1_EOT)  & user_cmd_transmission_mode  |
                                (state_current == STATE_WRITE_RGB_EOT)    & user_cmd_transmission_mode  |
                                (state_current == STATE_WRITE_HSS_2_EOT)  & user_cmd_transmission_mode  ;

/********* CMD fifo data mux *********/

reg [23:0]    cmd_packet_header_prefifo;

assign cmd_fifo_in_ctrl     = state_usr_cmd_allowed & usr_fifo_packet_pending;

always @(*)
    begin
        case (state_current)
            STATE_IDLE:
                cmd_packet_header_prefifo = 24'b0;

            STATE_WRITE_VSS:
                cmd_packet_header_prefifo = {16'b0, {2'b0, `PACKET_VSS}};

            STATE_WRITE_VSS_EOT:
                cmd_packet_header_prefifo = {16'b0, {2'b0, `PACKET_EOT}};

            STATE_WRITE_VSS_BL:
                cmd_packet_header_prefifo = lpm_enable ? 24'b0 : {blank_packet_size, {2'b0, `PACKET_BLANKING}};

            STATE_WRITE_HSS_0:
                cmd_packet_header_prefifo = {16'b0, {2'b0, `PACKET_HSS}};

            STATE_WRITE_HSS_0_EOT:
                cmd_packet_header_prefifo = {16'b0, {2'b0, `PACKET_EOT}};

            STATE_WRITE_HSS_BL_0:
                cmd_packet_header_prefifo = lpm_enable ? 24'b0 : {blank_packet_size, {2'b0, `PACKET_BLANKING}};

            STATE_WRITE_HSS_1:
                cmd_packet_header_prefifo = {16'b0, {2'b0, `PACKET_HSS}};

            STATE_WRITE_HSS_1_EOT:
                cmd_packet_header_prefifo = {16'b0, {2'b0, `PACKET_EOT}};

            STATE_WRITE_HBP:
                cmd_packet_header_prefifo = lpm_enable ? 24'b0 : {horizontal_back_porch, {2'b0, `PACKET_BLANKING}};

            STATE_WRITE_RGB:
                cmd_packet_header_prefifo = {(pixels_in_line_number * 3), {2'b0, `PACKET_PPS24}};

            STATE_WRITE_RGB_EOT:
                cmd_packet_header_prefifo = {16'b0, {2'b0, `PACKET_EOT}};

            STATE_WRITE_HSS_BL_1:
                cmd_packet_header_prefifo = lpm_enable ? 24'b0 : {blank_packet_size, {2'b0, `PACKET_BLANKING}};

            STATE_WRITE_HFP:
                cmd_packet_header_prefifo = lpm_enable ? 24'b0 : {horizontal_front_porch, {2'b0, `PACKET_BLANKING}};

            STATE_WRITE_HSS_2:
                cmd_packet_header_prefifo = {16'b0, {2'b0, `PACKET_HSS}};

            STATE_WRITE_HSS_2_EOT:
                cmd_packet_header_prefifo = {16'b0, {2'b0, `PACKET_EOT}};

            STATE_WRITE_HSS_BL_2:
                cmd_packet_header_prefifo = lpm_enable ? 24'b0 : {blank_packet_size, {2'b0, `PACKET_BLANKING}};

            STATE_WRITE_LPM:    // we dont write any cmd here, just wait for timeout
                cmd_packet_header_prefifo = 24'b0;

            default :
                cmd_packet_header_prefifo = 24'b0;

        endcase
    end

wire [15:0] usr_data_size; // in bytes

assign usr_data_size = cmd_fifo_in_ctrl ? (!user_cmd_transmission_mode ? usr_packet_length : (usr_packet_length * 8 + `LP_PACKET_SIZE) * `LP_BAUD_TIME) : 16'd0;

always @(`CLK_RST(clk, rst_n))
    if(`RST(rst_n))       blank_packet_size <= 16'd0;
    else if(cmd_fifo_write && !lpm_enable)
         case (state_current)
            STATE_WRITE_VSS:
                blank_packet_size <= (horizontal_line_length - 16'd1 - {15'b0, enable_EoT_sending & user_cmd_transmission_mode})*4 - usr_data_size;

            STATE_WRITE_HSS_0:
                blank_packet_size <= (horizontal_line_length - 16'd1 - {15'b0, enable_EoT_sending & user_cmd_transmission_mode})*4 - usr_data_size;

            STATE_WRITE_HSS_1: // hbp before rgb data
                blank_packet_size <= horizontal_back_porch - 16'd6;

            STATE_WRITE_RGB:
                blank_packet_size <= (horizontal_line_length - 16'd1 - {15'b0, enable_EoT_sending & user_cmd_transmission_mode})*4 - horizontal_front_porch - horizontal_back_porch - 16'd12 - pixels_in_line_number * 3 - 16'd6 - usr_data_size;

            STATE_WRITE_HSS_2:
                blank_packet_size <= (horizontal_line_length - 16'd1 - {15'b0, enable_EoT_sending & user_cmd_transmission_mode})*4 - usr_data_size - (last_hss_bl_2 ? (lpm_length)*4 : 16'b0);

            default :
                blank_packet_size <= 24'b0;
        endcase
    else if(lpm_enable)     blank_packet_size <= 16'd0;

 // if lpm_enable than no blanking packet, else horizontal_line_length - vss packet and minus usr_packet size, that depends on transmittion mode HS or LP


// cmd_fifo_in_ctrl - tells mux fsm that there is a data in the usr fifo to read after current cmd
assign cmd_fifo_data_in = {cmd_fifo_in_ctrl, 8'b0, cmd_packet_header_prefifo};
assign cmd_fifo_write   = !cmd_fifo_full & (state_write_hs_packet | state_write_lp_hs_packet & !lpm_enable);

reg cmd_fifo_reg_full;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                                              cmd_fifo_data_in_reg <= 33'b0;
    else if((!cmd_fifo_reg_full || !cmd_fifo_full_w) && cmd_fifo_write)     cmd_fifo_data_in_reg <= cmd_fifo_data_in;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                                              cmd_fifo_reg_full <= 1'b0;
    else if((!cmd_fifo_reg_full || !cmd_fifo_full_w) && cmd_fifo_write)     cmd_fifo_reg_full <= 1'b1;
    else if(cmd_fifo_reg_full && !cmd_fifo_full)                            cmd_fifo_reg_full <= 1'b0;

assign cmd_fifo_write_reg = !cmd_fifo_full & cmd_fifo_reg_full;

always @(`CLK_RST(clk, rst_n))
    if(`RST(rst_n))                                     usr_fifo_wait_next_read <= 1'b0;
    else if(cmd_fifo_write & usr_fifo_packet_pending)   usr_fifo_wait_next_read <= 1'b1;
    else if(usr_fifo_read & usr_fifo_wait_next_read)    usr_fifo_wait_next_read <= 1'b0;

assign usr_fifo_packet_pending = !usr_fifo_empty & !usr_fifo_wait_next_read;

reg [15:0] pix_lines_counter;
reg [15:0] vbp_lines_counter;
reg [15:0] vfp_lines_counter;

always @(`CLK_RST(clk, rst_n))
    if(`RST(rst_n))                                                                         vbp_lines_counter <= 16'd0;
    else if(state_next == STATE_WRITE_VSS)                                                  vbp_lines_counter <= vertical_back_porch_lines_number - 16'd1;
    else if(state_next == STATE_WRITE_HSS_0  && state_current == STATE_WRITE_HSS_BL_0)      vbp_lines_counter <= vbp_lines_counter - 16'd1;

always @(`CLK_RST(clk, rst_n))
    if(`RST(rst_n))                                                                         pix_lines_counter <= 16'd0;
    else if(state_next == STATE_WRITE_HSS_1  && state_current == STATE_WRITE_HSS_BL_0)      pix_lines_counter <= vertical_active_lines_number - 16'd1;
    else if(state_next == STATE_WRITE_HSS_1  && state_current == STATE_WRITE_HFP)           pix_lines_counter <= pix_lines_counter - 16'd1;

always @(`CLK_RST(clk, rst_n))
    if(`RST(rst_n))                                                                         vfp_lines_counter <= 16'd0;
    else if(state_next == STATE_WRITE_HSS_2  && state_current == STATE_WRITE_HFP)           vfp_lines_counter <= vertical_active_lines_number - 16'd1;
    else if(state_next == STATE_WRITE_HSS_2  && state_current == STATE_WRITE_HSS_BL_2)      vfp_lines_counter <= vfp_lines_counter - 16'd1;

assign last_hss_bl_0 = (state_current == STATE_WRITE_HSS_BL_0)  & !(|pix_lines_counter);
assign last_pix_line = (state_current == STATE_WRITE_RGB)       & !(|vbp_lines_counter);
assign last_hss_bl_2 = (state_current == STATE_WRITE_HSS_BL_2)  & !(|vfp_lines_counter);

/********************************************************************
                Sending sequences
FSM forms sequence of commands to be sent and put in in cmd_fifo. When streaming enabled logic fetch cmd from this fifo and switch mux accordingly. If after a command from
cmd_fifo should be a user command from user_fifo then a corresponding flag should be set (cmd_fifo_out_ctrl). every time fsm fills cmd_fifo it checks data in user_fifo.
If there is a new cmd then fsm calculates right size of blanking packet and sets cmd_fifo_out_ctrl. If there is need to get to LP mode FSM stops to fill cmd_fifo
********************************************************************/

/********************************************************************
                        Packets assembler (PA)
********************************************************************/
/*********
TO DO:

*********/

localparam [31:0]   BLANK_PATTERN           = 32'h5555_5555;

wire pix_packet_long;
wire writing_completed;
wire lanes_fifo_empty_w;
wire next_usr_data;

assign next_usr_data = cmd_fifo_out_ctrl;

localparam [3:0] MUX_STATE_IDLE = 0;
localparam [3:0] MUX_STATE_PIX_CMD = 1;
localparam [3:0] MUX_STATE_USR_CMD = 2;
localparam [3:0] MUX_STATE_PIX_DATA = 3;
localparam [3:0] MUX_STATE_USR_DATA = 4;
localparam [3:0] MUX_STATE_BLANK_DATA = 5;
localparam [3:0] MUX_STATE_PIX_CRC = 6;
localparam [3:0] MUX_STATE_BLANK_CRC = 7;
localparam [3:0] MUX_STATE_USR_CRC = 8;
localparam [3:0] MUX_STATE_WAIT_ENTER_LPM = 9;
localparam [3:0] MUX_STATE_WAIT_EXIT_LPM = 10;

reg [3:0] mux_state_current, mux_state_next;

always @(posedge clk or negedge rst_n)
    if(!rst_n)  mux_state_current <= MUX_STATE_IDLE;
    else        mux_state_current <= mux_state_next;

always @(*)
    begin
        if(!streaming_enable)
            case(mux_state_current)
            MUX_STATE_IDLE:
                mux_state_next = !usr_fifo_empty & !usr_fifo_packet_error ? MUX_STATE_USR_CMD : MUX_STATE_IDLE;

            MUX_STATE_USR_CMD:
                mux_state_next = writing_completed ? (usr_fifo_packet_long ? MUX_STATE_USR_DATA : MUX_STATE_IDLE) : MUX_STATE_USR_CMD;

            MUX_STATE_USR_DATA:
                mux_state_next = writing_completed ? MUX_STATE_USR_CRC : MUX_STATE_USR_DATA;

            MUX_STATE_USR_CRC:
                mux_state_next = writing_completed ? (!usr_fifo_empty ? MUX_STATE_USR_CMD : MUX_STATE_IDLE) : MUX_STATE_USR_CRC;

            default:
                mux_state_next = MUX_STATE_IDLE;

            endcase
        else
            case(mux_state_current)
            MUX_STATE_IDLE:
                mux_state_next = !cmd_fifo_empty ? MUX_STATE_PIX_CMD : MUX_STATE_IDLE;

            MUX_STATE_PIX_CMD:
                mux_state_next = writing_completed ? (next_usr_data ? (user_cmd_transmission_mode ? MUX_STATE_WAIT_ENTER_LPM : MUX_STATE_USR_CMD) : (pix_packet_long ? MUX_STATE_PIX_DATA : MUX_STATE_PIX_CMD)) : MUX_STATE_PIX_CMD;

            MUX_STATE_USR_CMD:
                mux_state_next = writing_completed ? (usr_fifo_packet_long ? MUX_STATE_USR_DATA : (user_cmd_transmission_mode ? MUX_STATE_WAIT_EXIT_LPM : MUX_STATE_IDLE)) : MUX_STATE_USR_CMD;

            MUX_STATE_PIX_DATA:
                mux_state_next = writing_completed ? MUX_STATE_PIX_CRC : MUX_STATE_PIX_DATA;

            MUX_STATE_USR_DATA:
                mux_state_next = writing_completed ? MUX_STATE_USR_CRC : MUX_STATE_USR_DATA;

            MUX_STATE_BLANK_DATA:
                mux_state_next = writing_completed ? MUX_STATE_BLANK_CRC : MUX_STATE_BLANK_DATA;

            MUX_STATE_PIX_CRC:
                mux_state_next = writing_completed ? (next_usr_data ? (user_cmd_transmission_mode ? MUX_STATE_WAIT_ENTER_LPM : MUX_STATE_USR_CMD) : MUX_STATE_IDLE) : MUX_STATE_PIX_CRC;

            MUX_STATE_BLANK_CRC:
                mux_state_next = writing_completed ? (next_usr_data ? (user_cmd_transmission_mode ? MUX_STATE_WAIT_ENTER_LPM : MUX_STATE_USR_CMD) : MUX_STATE_IDLE) : MUX_STATE_BLANK_CRC;

            MUX_STATE_USR_CRC:
                mux_state_next = writing_completed ? (user_cmd_transmission_mode ? MUX_STATE_WAIT_EXIT_LPM : MUX_STATE_IDLE) : MUX_STATE_USR_CRC;

            MUX_STATE_WAIT_ENTER_LPM:
                mux_state_next = lanes_fifo_empty_w ? MUX_STATE_USR_CMD : MUX_STATE_WAIT_ENTER_LPM;

            MUX_STATE_WAIT_EXIT_LPM:
                mux_state_next = lanes_fifo_empty_w ? MUX_STATE_IDLE : MUX_STATE_WAIT_EXIT_LPM;

            default:
                mux_state_next = MUX_STATE_IDLE;

            endcase
    end

assign lanes_fifo_empty_w = (&lanes_fifo_empty);

wire [31:0] usr_cmd_header;
wire [31:0] pix_cmd_header;
wire [7:0]  ecc_result_0;
wire [7:0]  ecc_result_1;

assign usr_cmd_header = {ecc_result_0, usr_fifo_data[23:0]};

ecc_calc ecc_0
(
    .data       (usr_fifo_data[23:0] ),         // add bit inversion
    .ecc_result (ecc_result_0    )
);

assign pix_cmd_header = {ecc_result_1, cmd_fifo_data[23:0]};

ecc_calc ecc_1
(
    .data       (cmd_fifo_data[23:0] ),         // add bit inversion
    .ecc_result (ecc_result_1    )
);

wire pix_packet_decoder_error;
wire pix_packet_not_reserved;
wire pix_packet_short;
wire usr_packet_reserved;
wire usr_packet_short;

assign pix_packet_decoder_error    = !pix_packet_not_reserved;
assign pix_packet_not_reserved     = !(!(|cmd_fifo_data[3:0]) & (&cmd_fifo_data[3:0]));
assign pix_packet_long             = !(!cmd_fifo_data[3] | (cmd_fifo_data[5:0] == 6'b001000)) & pix_packet_not_reserved;
assign pix_packet_short            = (!cmd_fifo_data[3] | (cmd_fifo_data[5:0] == 6'b001000)) & pix_packet_not_reserved;

assign usr_fifo_packet_error       = usr_packet_reserved;
assign usr_packet_reserved         = !(|usr_fifo_data[3:0]) & (&usr_fifo_data[3:0]);
assign usr_fifo_packet_long        = !(!cmd_fifo_data[3] | (cmd_fifo_data[5:0] == 6'b001000)) & !usr_packet_reserved;
assign usr_packet_short            = (!cmd_fifo_data[3] | (cmd_fifo_data[5:0] == 6'b001000)) & !usr_packet_reserved;

reg [32:0]    mux_data_reg_with_lpm;
reg [2:0]     mux_bytes_number;
reg           mux_reg_full;
wire           mux_reg_write;
wire           mux_reg_read;
wire           mux_data_lpm;
reg [15:0]    data_size_left;
wire [15:0]    crc_result_async;
wire [15:0]    crc_result_sync;
wire           mux_state_writing;
reg           mux_state_writing_delayed;

assign mux_reg_write        = (mux_reg_read | !mux_reg_full) & mux_state_writing;
assign mux_state_writing    = (mux_state_current != MUX_STATE_IDLE) & (mux_state_current != MUX_STATE_WAIT_ENTER_LPM) & (mux_state_current != MUX_STATE_WAIT_EXIT_LPM);

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  mux_reg_full <= 1'b0;
    else if(mux_reg_write)      mux_reg_full <= 1'b1;
    else if(mux_reg_read)       mux_reg_full <= 1'b0;

always @(posedge clk or negedge rst_n)
    if(!rst_n)      mux_state_writing_delayed <= 1'b0;
    else            mux_state_writing_delayed <= mux_state_writing;

always @(posedge clk or negedge rst_n)
    if(!rst_n)              mux_data_reg_with_lpm <= 32'b0;
    else if(mux_reg_write)
        case(mux_state_current)
        MUX_STATE_PIX_CMD:
            mux_data_reg_with_lpm <= {1'b0, pix_cmd_header};

        MUX_STATE_USR_CMD:
            mux_data_reg_with_lpm <= {user_cmd_transmission_mode, usr_cmd_header};

        MUX_STATE_PIX_DATA:
            mux_data_reg_with_lpm <= {1'b0, pix_fifo_data};

        MUX_STATE_USR_DATA:
            mux_data_reg_with_lpm <= {user_cmd_transmission_mode, usr_fifo_data};

        MUX_STATE_BLANK_DATA:
            mux_data_reg_with_lpm <= {1'b0, BLANK_PATTERN};

        MUX_STATE_PIX_CRC:
            mux_data_reg_with_lpm <= {1'b0, crc_result_async};

        MUX_STATE_BLANK_CRC:
            mux_data_reg_with_lpm <= {1'b0, crc_result_async};

        MUX_STATE_USR_CRC:
            mux_data_reg_with_lpm <= {user_cmd_transmission_mode, crc_result_async};

        default:
            mux_data_reg_with_lpm <= 33'b0;

        endcase

assign pix_fifo_read = (mux_state_current == MUX_STATE_PIX_DATA) &  mux_reg_write;
assign usr_fifo_read = ((mux_state_current == MUX_STATE_USR_CMD) | (mux_state_current == MUX_STATE_USR_DATA)) & mux_reg_write;
assign cmd_fifo_read = (mux_state_current == MUX_STATE_PIX_CMD) &  mux_reg_write;

wire       decrease_data_counter;
wire       set_data_counter_pix;
wire       set_data_counter_cmd;
wire       set_data_header_size;
wire       set_data_crc_size;

assign set_data_crc_size        = (mux_state_next == MUX_STATE_PIX_CRC) | (mux_state_next == MUX_STATE_BLANK_CRC) | (mux_state_next == MUX_STATE_USR_CRC);
assign set_data_header_size     = (mux_state_next == MUX_STATE_USR_CMD) | (mux_state_next == MUX_STATE_PIX_CMD);
assign decrease_data_counter    = mux_state_writing & mux_reg_write;
assign set_data_counter_pix     = ((mux_state_next == MUX_STATE_PIX_DATA) | (mux_state_next == MUX_STATE_BLANK_DATA)) & (mux_state_current == MUX_STATE_PIX_CMD);
assign set_data_counter_cmd     = (mux_state_next == MUX_STATE_USR_DATA) && (mux_state_current == MUX_STATE_USR_CMD);

always @(posedge clk or negedge rst_n)
    if(!rst_n)                          data_size_left <= 16'b0;
    else if(set_data_header_size)       data_size_left <= 16'd4;
    else if(set_data_crc_size)          data_size_left <= 16'd2;
    else if(set_data_counter_cmd)       data_size_left <= usr_cmd_header[15:0];                                         // check me
    else if(set_data_counter_pix)       data_size_left <= pix_cmd_header[15:0];                                         // check me
    else if(decrease_data_counter)      data_size_left <= data_size_left >= 16'd4 ? (data_size_left - 16'd4) : 16'd0;   // |data_size_left[15:2]

assign writing_completed    = decrease_data_counter & (data_size_left <= 16'd4);

always @(posedge clk or negedge rst_n)
    if(!rst_n)  mux_bytes_number <= 'b0;
    else        mux_bytes_number <= |data_size_left[15:2] ? 4'd4 : data_size_left[2:0];

/********* Packet type decoder *********/
wire           clear_crc_calc;
wire [1:0]     bytes_in_line;

assign clear_crc_calc   = (mux_state_current == MUX_STATE_USR_CMD) | (mux_state_current == MUX_STATE_PIX_CMD);
assign bytes_in_line    = data_size_left[1:0] > 2'd1 ? data_size_left[1:0] - 2'd1 : 2'd0;

crc_calculator crc_calculator_0
(
    .clk                (clk                            ),
    .reset_n            (rst_n                        ),
    .clear              (clear_crc_calc                 ),
    .data_write         (mux_reg_write                  ),
    .bytes_number       (bytes_in_line                  ),
    .data_input         (mux_data_reg_with_lpm[31:0]    ),
    .crc_output_async   (crc_result_async               ),
    .crc_output_sync    (crc_result_sync                )
);

reg [3:0] lines_enable;
wire [3:0] rpck_out_bn;

wire        inp_read;
wire [31:0] inp_data;
wire [31:0] out_data;
wire        out_read_ack;
wire        out_ready;

reg [3:0]     shift_total_num;
reg [63:0]    shift_reg;
wire [3:0]     shift_free_bytes;
wire [3:0]     lines_number_real;
wire [31:0]    mux_data_reg;

assign mux_data_reg                     = mux_data_reg_with_lpm[31:0];
assign shift_free_bytes                 = 4'd8 - shift_total_num + (out_read_ack ? lines_number_real : 4'd0);
assign inp_read                         = |shift_free_bytes[3:2] & mux_state_writing_delayed;
assign out_ready                        = (shift_total_num >= lines_number_real) | ((shift_total_num < lines_number_real) & !mux_reg_full) & (shift_total_num != 4'd0);
assign mux_reg_read                     = inp_read;
assign mux_data_lpm                     = mux_data_reg_with_lpm[32];
assign lines_number_real                = mux_data_lpm ? 4'd1 : {1'b0, lines_number};
assign inp_data                         = mux_data_reg;
assign out_data                         = shift_reg[31:0];


always @(posedge clk or negedge rst_n)
if(!rst_n)      shift_reg <= 64'b0;
else            shift_reg <= (shift_reg >> ({4{out_read_ack}} & lines_number_real*8)) | ({64{inp_read}} & ({inp_data, 32'b0} >> (shift_free_bytes - 4'd4)*8));

always @(posedge clk or negedge rst_n)
if(!rst_n)      shift_total_num <= 4'd0;
else            shift_total_num <= shift_total_num - ({4{out_read_ack}} & lines_number_real) + ({3{inp_read}} & mux_bytes_number);

assign rpck_out_bn = |shift_total_num[3:2] ? 4'd4 : shift_total_num;

always @(posedge clk or negedge rst_n)
    if(!rst_n)      lines_enable <= 4'b0;
    else
        case(lines_number_real)
        4'd1:
            lines_enable <= 4'b0001;
        4'd2:
            lines_enable <= 4'b0011;
        4'd3:
            lines_enable <= 4'b0111;
        4'd4:
            lines_enable <= 4'b1111;
        default:
            lines_enable <= 4'b0001;
        endcase

reg [3:0] lines_byte_ok;

always @(*)
    begin
        case(rpck_out_bn)
        4'd1:
            lines_byte_ok = 4'b0001;
        4'd2:
            lines_byte_ok = 4'b0011;
        4'd3:
            lines_byte_ok = 4'b0111;
        4'd4:
            lines_byte_ok = 4'b1111;
        default:
            lines_byte_ok = 4'b0000;
        endcase
    end

assign lanes_fifo_data      = out_data;
assign lanes_fifo_lpm       = mux_data_lpm;
assign lanes_fifo_write     = {4{out_ready}} & lines_enable & lines_byte_ok & ~lanes_fifo_full;
assign out_fifo_full        = lanes_fifo_full;
assign out_read_ack         = out_ready & !(|lanes_fifo_full);

endmodule
`endif
