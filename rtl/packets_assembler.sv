`ifndef DSI_PACKETS_ASSEMBLER
`define DSI_PACKETS_ASSEMBLER

module packets_assembler (
    /********* Clock signals *********/
        input   wire                            clk                                 ,
        input   wire                            reset_n                             ,

    /********* lanes controller iface *********/
        output  wire [31:0]                     iface_write_data                    ,
        output  wire [3:0]                      iface_write_strb                    ,
        output  wire                            iface_write_rqst                    ,
        output  wire                            iface_last_word                     ,
        output  wire                            iface_lpm_en                        , //0 - hs, 1 - lp should be asserted at least one cycle before iface_write_rqst and disasserted one cycle after iface_last_word

        input   wire                            iface_data_rqst                     ,
        input   wire                            lanes_controller_lines_active       ,

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
        input   wire                            user_cmd_transmission_mode          , // 0: data from user fifo is sent in HS mode; 1: data from user fifo is sent in LP mode.
        input   wire                            enable_EoT_sending                  ,
        input   wire                            streaming_enable                    ,
        input   wire [3:0]                      lines_number                        ,
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
logic           usr_fifo_packet_short;
logic           usr_fifo_packet_error;
logic [4:0]     mux_ctrl_vec;
logic           set_source_data_usr_fifo;
logic           last_data_read_from_fifo;
logic           next_packet_from_usr_fifo;
logic           streaming_enable_delayed;
logic           ask_for_extra_data;
logic           read_data;

assign cmd_fifo_out_ctrl = cmd_fifo_data[32];

assign lp_pix       = cmd_fifo_data[21:16] == `PACKET_PPS24;
assign lp_blank     = cmd_fifo_data[21:16] == `PACKET_BLANKING;


cmd_fifo_33x4   cmd_fifo_33x4_inst (
    .aclr   (reset_n           ),
    .clock  (clk               ),
    .data   (cmd_fifo_data_in  ),
    .rdreq  (cmd_fifo_read     ),
    .wrreq  (cmd_fifo_write    ),
    .empty  (cmd_fifo_empty    ),
    .full   (cmd_fifo_full_w   ),
    .q      (cmd_fifo_data_out ),
    .usedw  (cmd_fifo_usedw    )
    );

assign cmd_fifo_data = cmd_fifo_empty ? 33'b0 : cmd_fifo_data_out;

assign cmd_fifo_full = cmd_fifo_usedw == 2'b1;

/********************************************************************
                        FSM declaration
********************************************************************/
enum logic [4:0]{
    STATE_IDLE              ,
    STATE_WRITE_VSS         ,
    STATE_WRITE_VSS_EOT     ,
    STATE_WRITE_VSS_BL      ,
    STATE_WRITE_HSS_0       ,
    STATE_WRITE_HSS_0_EOT   ,
    STATE_WRITE_HSS_BL_0    ,
    STATE_WRITE_HSS_1       ,
    STATE_WRITE_HSS_1_EOT   ,
    STATE_WRITE_HBP         ,
    STATE_WRITE_RGB         ,
    STATE_WRITE_RGB_EOT     ,
    STATE_WRITE_HSS_BL_1    ,
    STATE_WRITE_HFP         ,
    STATE_WRITE_HSS_2       ,
    STATE_WRITE_HSS_2_EOT   ,
    STATE_WRITE_HSS_BL_2    ,
    STATE_WRITE_LPM
} state_current, state_next;

always_ff @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))   state_current <= STATE_IDLE;
    else                state_current <= state_next;

/*
blank_timeout counter when lpm_enable = 1 should start counting only after cmd_fifo_empty = 1
*/

always_comb
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
logic [15:0]    blank_timer;
logic           blank_counter_start; // write me!
logic           blank_counter_active;
logic [15:0]    blank_counter_init_val;
logic [15:0]    blank_packet_size;
logic           usr_fifo_wait_next_read;

assign blank_counter_start = !(|blank_timer) & lpm_enable & cmd_fifo_empty & (usr_fifo_empty || !usr_fifo_wait_next_read) &
                                ((state_current == STATE_WRITE_VSS_BL)      |
                                (state_current == STATE_WRITE_HSS_BL_0)     |
                                (state_current == STATE_WRITE_HBP)          |
                                (state_current == STATE_WRITE_HSS_BL_1)     |
                                (state_current == STATE_WRITE_HFP)          |
                                (state_current == STATE_WRITE_HSS_BL_2)     |
                                (state_current == STATE_WRITE_LPM))         ;

logic [15:0]    usr_packet_length;
logic [15:0]    usr_packet_length_in_clk;

assign usr_packet_length            = usr_fifo_packet_long & !usr_fifo_packet_error ? (16'd6 + usr_fifo_data[15:0]) : 16'd4;
assign usr_packet_length_in_clk     = user_cmd_transmission_mode ? {2'b0, usr_packet_length[15:2]} : 16'd0;

always_ff @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))       blank_counter_init_val <= 16'd0;
    else if(state_current != state_next)
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

always_ff @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))               blank_timer <= 16'b0;
    else if(blank_counter_start)    blank_timer <= blank_counter_init_val;
    else if(|blank_timer)           blank_timer <= blank_timer - 16'd1;

always_ff @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))           blank_counter_active <= 1'b0;
    else if(|blank_timer)       blank_counter_active <= 1'b1;
    else if(!(|blank_timer))    blank_counter_active <= 1'b0;

assign blank_timeout = blank_counter_active & (!(|blank_timer));

logic state_write_hs_packet;
logic state_write_lp_hs_packet;
logic state_usr_cmd_allowed;
logic usr_fifo_packet_pending; // flag shows that a packet in usr_fifo should be written after current cmd.

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

assign cmd_fifo_write = !cmd_fifo_full & (state_write_hs_packet | state_write_lp_hs_packet & !lpm_enable);

/********* CMD fifo data mux *********/

logic [23:0]    cmd_packet_header_prefifo;

assign cmd_fifo_in_ctrl     = state_usr_cmd_allowed & usr_fifo_packet_pending;

always_comb
    begin
        case (state_current)
            STATE_IDLE:
                cmd_packet_header_prefifo = 24'b0;

            STATE_WRITE_VSS:
                cmd_packet_header_prefifo = {{2'b0, `PACKET_VSS}, 16'b0};

            STATE_WRITE_VSS_EOT:
                cmd_packet_header_prefifo = {{2'b0, `PACKET_EOT}, 16'b0};

            STATE_WRITE_VSS_BL:
                cmd_packet_header_prefifo = lpm_enable ? 24'b0 : {{2'b0, `PACKET_BLANKING}, blank_packet_size};

            STATE_WRITE_HSS_0:
                cmd_packet_header_prefifo = {{2'b0, `PACKET_HSS}, 16'b0};

            STATE_WRITE_HSS_0_EOT:
                cmd_packet_header_prefifo = {{2'b0, `PACKET_EOT}, 16'b0};

            STATE_WRITE_HSS_BL_0:
                cmd_packet_header_prefifo = lpm_enable ? 24'b0 : {{2'b0, `PACKET_BLANKING}, blank_packet_size};

            STATE_WRITE_HSS_1:
                cmd_packet_header_prefifo = {{2'b0, `PACKET_HSS}, 16'b0};

            STATE_WRITE_HSS_1_EOT:
                cmd_packet_header_prefifo = {{2'b0, `PACKET_EOT}, 16'b0};

            STATE_WRITE_HBP:
                cmd_packet_header_prefifo = lpm_enable ? 24'b0 : {{2'b0, `PACKET_BLANKING}, horizontal_back_porch};

            STATE_WRITE_RGB:
                cmd_packet_header_prefifo = {{2'b0, `PACKET_PPS24}, (pixels_in_line_number * 3)};

            STATE_WRITE_RGB_EOT:
                cmd_packet_header_prefifo = {{2'b0, `PACKET_EOT}, 16'b0};

            STATE_WRITE_HSS_BL_1:
                cmd_packet_header_prefifo = lpm_enable ? 24'b0 : {{2'b0, `PACKET_BLANKING}, blank_packet_size};

            STATE_WRITE_HFP:
                cmd_packet_header_prefifo = lpm_enable ? 24'b0 : {{2'b0, `PACKET_BLANKING}, horizontal_front_porch};

            STATE_WRITE_HSS_2:
                cmd_packet_header_prefifo = {{2'b0, `PACKET_HSS}, 16'b0};

            STATE_WRITE_HSS_2_EOT:
                cmd_packet_header_prefifo = {{2'b0, `PACKET_EOT}, 16'b0};

            STATE_WRITE_HSS_BL_2:
                cmd_packet_header_prefifo = lpm_enable ? 24'b0 : {{2'b0, `PACKET_BLANKING}, blank_packet_size};

            STATE_WRITE_LPM:    // we dont write any cmd here, just wait for timeout
                cmd_packet_header_prefifo = 24'b0;

            default :
                cmd_packet_header_prefifo = 24'b0;

        endcase
    end

logic [15:0] usr_data_size; // in bytes

assign usr_data_size = cmd_fifo_in_ctrl ? (!user_cmd_transmission_mode ? usr_packet_length : (usr_packet_length * 8 + `LP_PACKET_SIZE) * `LP_BAUD_TIME) : 16'd0;

always_ff @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))       blank_packet_size <= 16'd0;
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
                blank_packet_size <= (horizontal_line_length - 16'd1 - {15'b0, enable_EoT_sending & user_cmd_transmission_mode})*4 - usr_data_size - last_hss_bl_2 ? (lpm_length)*4 : 16'b0;

            default :
                blank_packet_size <= 24'b0;
        endcase
    else if(lpm_enable)     blank_packet_size <= 16'd0;

 // if lpm_enable than no blanking packet, else horizontal_line_length - vss packet and minus usr_packet size, that depends on transmittion mode HS or LP


// cmd_fifo_in_ctrl - tells mux fsm that there is a data in the usr fifo to read after current cmd
assign cmd_fifo_data_in = {cmd_fifo_in_ctrl, 8'b0, cmd_packet_header_prefifo};

always_ff @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))                                   usr_fifo_wait_next_read <= 1'b0;
    else if(cmd_fifo_write & usr_fifo_packet_pending)   usr_fifo_wait_next_read <= 1'b1;
    else if(usr_fifo_read & usr_fifo_wait_next_read)    usr_fifo_wait_next_read <= 1'b0;

assign usr_fifo_packet_pending = !usr_fifo_empty & !usr_fifo_wait_next_read;

logic [15:0] pix_lines_counter;
logic [15:0] vbp_lines_counter;
logic [15:0] vfp_lines_counter;

always_ff @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))                                                                       vbp_lines_counter <= 16'd0;
    else if(state_next == STATE_WRITE_VSS)                                                  vbp_lines_counter <= vertical_back_porch_lines_number - 16'd1;
    else if(state_next == STATE_WRITE_HSS_0  && state_current == STATE_WRITE_HSS_BL_0)      vbp_lines_counter <= vbp_lines_counter - 16'd1;

always_ff @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))                                                                       pix_lines_counter <= 16'd0;
    else if(state_next == STATE_WRITE_HSS_1  && state_current == STATE_WRITE_HSS_BL_0)      pix_lines_counter <= vertical_active_lines_number - 16'd1;
    else if(state_next == STATE_WRITE_HSS_1  && state_current == STATE_WRITE_HFP)           pix_lines_counter <= pix_lines_counter - 16'd1;

always_ff @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))                                                                       vfp_lines_counter <= 16'd0;
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

`define SET_OUTP_MUX_DATA       1'b1
`define SET_OUTP_MUX_CMD        1'b0
`define SET_CMD_MUX_CMD         1'b1
`define SET_CMD_MUX_USR         1'b0
`define SET_DATA_MUX_USR        3'b010
`define SET_DATA_MUX_PIX        3'b001
`define SET_DATA_MUX_BLANK      3'b100
`define SET_DATA_MUX_NULL       3'b000
`define OUTPUT_MUX_DATA         mux_ctrl_vec[0]
`define OUTPUT_MUX_CMD          !mux_ctrl_vec[0]
`define CMD_MUX_USR_FIFO        !mux_ctrl_vec[1]
`define CMD_MUX_CMD_FIFO        mux_ctrl_vec[1]
`define DATA_MUX_USR_FIFO       |(mux_ctrl_vec[4:2] & `SET_DATA_MUX_USR)
`define DATA_MUX_PIX_FIFO       |(mux_ctrl_vec[4:2] & `SET_DATA_MUX_PIX)
`define DATA_MUX_BLANK          |(mux_ctrl_vec[4:2] & `SET_DATA_MUX_BLANK)
`define DATA_MUX_NULL           !(|mux_ctrl_vec[4:2])

logic [31:0]    data_to_write;
logic [31:0]    data_to_write_masked;
logic [15:0]    crc_result_sync;
logic [15:0]    crc_result_async;
logic [1:0]     bytes_in_line;
logic [23:0]    packet_header;
logic           read_lp_data;
logic [7:0]     ecc_result_0;
logic [7:0]     ecc_result_1;

logic           cmd_fifo_packet_long;
logic           cmd_fifo_packet_short;
logic           cmd_fifo_packet_error;

logic [31:0]    packet_header_cmd;
logic [31:0]    packet_header_usr_fifo;


assign packet_header_usr_fifo = {usr_fifo_data[23:16], usr_fifo_data[7:0], usr_fifo_data[15:8], ecc_result_0};

ecc_calc ecc_0
(
    .data       ({usr_fifo_data[15:8], usr_fifo_data[7:0], usr_fifo_data[23:16]} ),         // add bit inversion
    .ecc_result (ecc_result_0    )
);

assign packet_header_cmd = {cmd_fifo_data[23:16], cmd_fifo_data[7:0], cmd_fifo_data[15:8], ecc_result_1};

ecc_calc ecc_1
(
    .data       ({cmd_fifo_data[15:8], cmd_fifo_data[7:0], cmd_fifo_data[23:16]} ),         // add bit inversion
    .ecc_result (ecc_result_1    )
);

/********* Packet type decoder *********/
logic [16:0]    data_size_left;


crc_calculator crc_calculator_0
(
    .clk                (clk                    ),
    .reset_n            (reset_n                ),
    .clear              (`OUTPUT_MUX_CMD        ),
    .data_write         (read_lp_data           ),
    .bytes_number       (bytes_in_line          ),
    .data_input         (data_to_write_masked   ),
    .crc_output_async   (crc_result_async       ),
    .crc_output_sync    (crc_result_sync        )
);

logic [31:0]    rpck_shadow_buffer;
logic [3:0]     rpck_bytes_in_sb;
logic [3:0]     rpck_bytes_available;
logic [3:0]     rpck_in_bn;
logic [3:0]     rpck_out_bn;
logic [31:0]    rpck_out;
logic           rpck_read;
logic           rpck_write;
logic           rpck_bytes_enough;
logic           rpck_bn_sb_enough;

assign rpck_bn_sb_enough    = rpck_bytes_in_sb > lines_number;
assign rpck_bytes_enough    = rpck_bytes_available > lines_number;
assign rpck_read            = !rpck_bn_sb_enough & mux_reg_full & !(|out_fifo_full);
assign rpck_write           = (rpck_bytes_enough | !mux_reg_full) & !(|out_fifo_full) & (|rpck_bytes_available);
assign rpck_bytes_available = rpck_bytes_in_sb + mux_bytes_number;
assign rpck_out_bn          = rpck_bytes_enough ? (rpck_bytes_available - lines_number) : rpck_bytes_available;
assign rpck_out             = rpck_shadow_buffer | (mux_data_reg << rpck_bytes_in_sb);

always_ff @(posedge clk or negedge rst_n)
    if(!rst_n)          rpck_shadow_buffer <= 32'b0;
    else if(rpck_read)  rpck_shadow_buffer <= rpck_bytes_enough ? (mux_data_reg >> (lines_number - rpck_bytes_in_sb)) : rpck_shadow_buffer | (mux_data_reg << rpck_bytes_in_sb);
    else if(rpck_write) rpck_shadow_buffer <= rpck_shadow_buffer >> (lines_number);

always_ff @(posedge clk or negedge rst_n)
    if(!rst_n)              rpck_bytes_in_sb <= 4'd0;
    else if(rpck_read)      rpck_bytes_in_sb <= rpck_bytes_enough ? (rpck_bytes_available - lines_number) : rpck_bytes_available;
    else if(rpck_write)     rpck_bytes_in_sb <= rpck_bn_sb_enough ? (rpck_bytes_in_sb - lines_number) : 4'd0;

logic [3:0] lines_enable;

always_ff @(posedge clk or negedge rst_n)
    if(!rst_n)      lines_enable <= 4'b0;
    else
        case(lines_number)
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

logic [3:0] lines_byte_ok;

always_comb
    begin
        case(rpck_out_bn):
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

logic [3:0] out_fifo_write;

assign out_fifo_write = {4{rpck_write}} & lines_enable & lines_byte_ok;
assign out_fifo_full  =

endmodule
`endif
