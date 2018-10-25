`ifndef DSI_PACKETS_ASSEMBLER
`define DSI_PACKETS_ASSEMBLER

module packets_assembler #(
    CMD_FIFO_DEPTH      = 10
    )(
    /********* Clock signals *********/
        input   wire                            clk_sys                         ,
        input   wire                            rst_n                           ,

    /********* lanes controller iface *********/
        output  wire [31:0]                     iface_write_data                ,
        output  wire [3:0]                      iface_write_strb                ,
        output  wire                            iface_write_rqst                ,
        output  wire                            iface_last_word                 ,
        output  wire                            iface_lpm_en                    , //0 - hs, 1 - lp should be asserted at least one cycle before iface_write_rqst and disasserted one cycle after iface_last_word

        input   wire                            iface_data_rqst                 ,
        input   wire                            lanes_controller_lines_active   ,

    /********* pixel FIFO interface *********/
        input   wire  [31:0]                    pix_fifo_data                   ,
        input   wire                            pix_fifo_empty                  ,
        output  wire                            pix_fifo_read                   ,

    /********* cmd FIFO interface *********/
        input   wire  [31:0]                    usr_fifo_data                   ,
        input   wire  [CMD_FIFO_DEPTH - 1:0]    usr_fifo_usedw                  ,
        input   wire                            usr_fifo_empty                  ,
        output  wire                            usr_fifo_read                   ,

    /********* Control inputs *********/
        input   wire                            lpm_enable                      ,   // 1: go to LPM after sending commands. 0: send blank packet after sending command or data

    /********* timings registers *********/
        input   wire                            horizontal_full_resolution      ,
        input   wire                            horizontal_active_resolution    ,
        input   wire                            vertical_full_resolution        ,
        input   wire                            vertical_active_resolution      ,
        input   wire                            vsa_lines_number                ,
        input   wire                            vbp_lines_number                ,
        input   wire                            vfp_lines_number                ,
        input   wire                            vbp_pix_number                  ,
        input   wire                            vfp_pix_number                  ,
        input   wire                            user_cmd_transmission_mode      , // 0: data from user fifo is sent in HS mode; 1: data from user fifo is sent in LP mode.

);

`define CLK_RST(clk, rst_n)   posedge clk, negedge rst_n
`define RST(rst_n)   !rst_n

/********************************************************************
                        FSM declaration
********************************************************************/
enum logic [3:0]{
    STATE_IDLE,
    STATE_WRITE_VSS,
    STATE_WRITE_VSS_BL,
    STATE_WRITE_HSS_0,
    STATE_WRITE_HSS_BL_0,
    STATE_WRITE_HSS_1,
    STATE_WRITE_HBP,
    STATE_WRITE_RGB,
    STATE_WRITE_HSS_BL_1,
    STATE_WRITE_HFP,
    STATE_WRITE_HSS_2,
    STATE_WRITE_HSS_BL_2,
    STATE_WRITE_LPM
}

logic [3:0] state_current, state_next;

always_ff @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))   state_current <= STATE_IDLE;
    else                state_current <= state_next;

always_comb
    begin
        case (state_current)
            STATE_IDLE:
                state_next = (streaming_enable & usr_fifo_empty ? STATE_WRITE_VSS : STATE_IDLE);

            STATE_WRITE_VSS:
                state_next = !cmd_fifo_full ? STATE_WRITE_VSS_BL : STATE_WRITE_VSS;     // if lpm_enable = 1, then we don't write next cmd. Anyways if there is a cmd in usr_fifo, we should set a corresponding flag

            STATE_WRITE_VSS_BL:         // if lpm_enable = 1 then we wait for timeout and don't write anything, otherwise we write blank packet cmd and switch to the next state
                state_next = lpm_enable ? (blank_timeout ? STATE_WRITE_HSS_0 : STATE_WRITE_VSS_BL) : (cmd_fifo_full ? STATE_WRITE_VSS_BL : STATE_WRITE_HSS_0);

            STATE_WRITE_HSS_0:  // if lpm_enable = 1, then we don't write next cmd. But if there a cmd in usr_fifo, we should set a corresponding flag
                state_next = cmd_fifo_full ? STATE_WRITE_HSS_0 : STATE_WRITE_HSS_BL_0;

            STATE_WRITE_HSS_BL_0:
                state_next = lpm_enable ? (blank_timeout ? (last_hss_bl_0 ? STATE_WRITE_HSS_1 : STATE_WRITE_HSS_0) : STATE_WRITE_HSS_BL_0) : (cmd_fifo_full ? STATE_WRITE_HSS_BL_0 : (last_hss_bl_0 ? STATE_WRITE_HSS_1 : STATE_WRITE_HSS_0));

            STATE_WRITE_HSS_1:
                state_next = cmd_fifo_full ? STATE_WRITE_HSS_1 : STATE_WRITE_HBP;

            STATE_WRITE_HBP:
                state_next = lpm_enable ? (blank_timeout ? STATE_WRITE_RGB : STATE_WRITE_HBP) : (cmd_fifo_full ? STATE_WRITE_HBP : STATE_WRITE_RGB);

            STATE_WRITE_RGB:
                state_next = cmd_fifo_full ? STATE_WRITE_RGB : STATE_WRITE_HFP;

            STATE_WRITE_HSS_BL_1:
                state_next = lpm_enable ? (blank_timeout ? STATE_WRITE_HFP : STATE_WRITE_HSS_BL_1) : (cmd_fifo_full ? STATE_WRITE_HSS_BL_1 : STATE_WRITE_HFP);

            STATE_WRITE_HFP:
                state_next = lpm_enable ? (blank_timeout ? (last_pix_line ? STATE_WRITE_HSS_2 : STATE_WRITE_HSS_1) : STATE_WRITE_HFP) : (cmd_fifo_full ? STATE_WRITE_HFP : (last_pix_line ? STATE_WRITE_HSS_2 : STATE_WRITE_HSS_1));

            STATE_WRITE_HSS_2:
                state_next = cmd_fifo_full ? STATE_WRITE_HSS_2 : STATE_WRITE_HSS_BL_2;

            STATE_WRITE_HSS_BL_2:
                state_next = lpm_enable ? (blank_timeout ? (last_hss_bl_2 ? STATE_WRITE_LPM : STATE_WRITE_HSS_2) : STATE_WRITE_HSS_BL_2) : (cmd_fifo_full ? STATE_WRITE_HSS_BL_2 : (last_hss_bl_0 ? STATE_WRITE_LPM : STATE_WRITE_HSS_2));

            STATE_WRITE_LPM:    // we dont write any cmd here, just wait for timeout
                state_next = blank_timeout ? STATE_WRITE_VSS : STATE_WRITE_LPM;


            default :
                state_next = STATE_IDLE;

        endcase
    end


/********************************************************************
                Timing counters
********************************************************************/
// lines counters
logic []    vsa_lines_counter;
logic []    vbp_lines_counter;
logic []    active_lines_counter;
logic []    vfp_lines_counter;

// pix counters
logic []    line_pix_counter; // line pixels counter

always_ff @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))                                               line_pix_counter <= 'b0;
    else if(state_current == STATE_IDLE && streaming_enable)        line_pix_counter <= horizontal_full_resolution;
    else if(!(|line_pix_counter) && state_current != STATE_IDLE)    line_pix_counter <= horizontal_full_resolution;


/********************************************************************
                Sending sequences
FSM forms sequence of commands to be sent and put in in cmd_fifo. When streaming enabled logic fetch cmd from this fifo and switch mux accordingly. If after a command from
cmd_fifo should be a user command from user_fifo then a corresponding flag should be set (cmd_fifo_out_ctrl[0]). every time fsm fills cmd_fifo it checks data in user_fifo.
If there is a new cmd then fsm calculates right size of blanking packet and sets cmd_fifo_out_ctrl[0]. If there is need to get to LP mode FSM stops to fill cmd_fifo
********************************************************************/

/********************************************************************
                        Packets assembler (PA)
********************************************************************/
/*********
TO DO:
1. read_data signal forming
2. read_data for fifo's signal forming
3. write fsm for cmd fifo
*********/


localparam [31:0]   BLANK_PATTERN           = 32'h5555_5555;

`define             SET_OUTP_MUX_DATA       1'b1
`define             SET_OUTP_MUX_CMD        1'b0
`define             SET_CMD_MUX_CMD         1'b1
`define             SET_CMD_MUX_USR         1'b0
`define             SET_DATA_MUX_USR        3'b010
`define             SET_DATA_MUX_PIX        3'b001
`define             SET_DATA_MUX_BLANK      3'b100
`define             SET_DATA_MUX_NULL       3'b000
`define             OUTPUT_MUX_DATA         mux_ctrl_vec[0]
`define             OUTPUT_MUX_CMD          !mux_ctrl_vec[0]
`define             CMD_MUX_USR_FIFO        !mux_ctrl_vec[1]
`define             CMD_MUX_CMD_FIFO        mux_ctrl_vec[1]
`define             DATA_MUX_USR_FIFO       |(mux_ctrl_vec[4:2] & DATA_SOURCE_USR_CMD)
`define             DATA_MUX_PIX_FIFO       |(mux_ctrl_vec[4:2] & DATA_SOURCE_PIX)
`define             DATA_MUX_BLANK          |(mux_ctrl_vec[4:2] & DATA_SOURCE_BLANK)
`define             DATA_MUX_NULL           !(|mux_ctrl_vec[4:2])

logic send_vss;

logic [31:0]    data_to_write;
logic [31:0]    data_to_write_masked;
logic [15:0]    crc_result_sync;
logic [15:0]    crc_result_async;
logic [1:0]     bytes_in_line;
logic           source_cmd_fifo;
logic [23:0]    packet_header;
logic [31:0]    packet_header_wecc;
logic           read_header;
logic           read_lp_data;
logic           packet_type_long;
logic           packet_type_short;
logic [7:0]     ecc_result_0;
logic [7:0]     ecc_result_1;

logic [31:0]    cmd_fifo_out;
logic [2:0]     cmd_fifo_out_ctrl; // next muxes ctrl signals state. cmd_fifo_out_ctrl[0] = 1, next cmd from usr fifo, 0 - from cmd fifo
logic           cmd_fifo_read;
logic           cmd_fifo_not_empty;

logic           data_is_data;  // 0 - current data is being taken from cmd path, 1 - from data path

logic           cmd_fifo_packet_long;
logic           cmd_fifo_packet_short;
logic           cmd_fifo_packet_error;

logic           usr_fifo_packet_long;
logic           usr_fifo_packet_short;
logic           usr_fifo_packet_error;

logic [31:0]    packet_header_cmd;
logic [31:0]    packet_header_usr_fifo;

/********* packet header ecc appending *********/
always_comb
    if(source_cmd_fifo)         packet_header = packet_header_cmd;
    else                        packet_header = packet_header_usr_fifo;

assign packet_header_usr_fifo = {usr_fifo_data, ecc_result_0};

ecc_calc ecc_0
(
    .data       (usr_fifo_data ),
    .ecc_result (ecc_result_0    )
);

assign packet_header_cmd = {cmd_fifo_data, ecc_result_1};

ecc_calc ecc_1
(
    .data       (cmd_fifo_data ),
    .ecc_result (ecc_result_1    )
);

/********* Packet type decoder *********/
logic [16:0]    data_size_left;
logic           current_packet_type; // 1 - long, 0 - short
logic           start_lp_sending;
logic           start_sp_sending;
logic           last_lp_read;
logic           add_crc;
logic [15:0]    crc_val;
logic [17:0]    data_size_left_wo_crc;

assign start_lp_sending = read_header && packet_type_long;
assign start_sp_sending = read_header && packet_type_short;

/********* header type decoding *********/
function [2:0] packet_header_decoder;

input [7:0] data_id;

logic packet_decoder_error;
logic packet_not_reserved;
logic packet_type_long;
logic packet_type_short;

packet_decoder_error = !packet_not_reserved;
packet_not_reserved  = !(|data_id[3:0]) && !(&data_id[3:0]);
packet_type_long     = (!data_id[3] || data_id[3] && (!(|data_id[5:4]) && !(|data_id[2:0]))) && packet_not_reserved;
packet_type_short    = (data_id[3] || !(data_id[3] && (!(|data_id[5:4]) && !(|data_id[2:0])))) && packet_not_reserved;

packet_header_decoder = {packet_decoder_error, packet_type_long, packet_type_short};

endfunction

assign {cmd_fifo_packet_error, cmd_fifo_packet_long, cmd_fifo_packet_short} = packet_header_decoder(cmd_fifo_data[23:16]);
assign {usr_fifo_packet_error, usr_fifo_packet_long, usr_fifo_packet_short} = packet_header_decoder(usr_fifo_data[23:16]);

// Data to write mux

always_comb
    if(data_source_vector & DATA_SOURCE_PIX)            data_to_write = pix_fifo_data;
    else if(data_source_vector & DATA_SOURCE_USR_CMD)   data_to_write = cmd_fifo_data;
    else if(data_source_vector & DATA_SOURCE_BLANK)     data_to_write = BLANK_PATTERN;
    else                                                data_to_write = 32'b0;

/********* Fifo reading, crc adding *********/

logic [16:0]    packet_size_left;
logic [15:0]    packet_size_left_wocrc;
logic           no_data_is_being_sent;

assign packet_size_left_wocrc = (packet_size_left > 17'd2) ? (packet_size_left - 17'd2) : 16'b0;
assign no_data_is_being_sent  = !(|packet_size_left);
/********* latch long packet data size *********/

logic [16:0] cmd_lp_size_wcrc;
logic [16:0] usr_lp_size_wcrc;

assign cmd_lp_size_wcrc = packet_header_cmd[23:8] + 17'd2;
assign usr_lp_size_wcrc = packet_header_usr_fifo[23:8] + 17'd2;

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))                                                           packet_size_left <= 17'd0;
    else if(streaming_en)                                                       packet_size_left <= 17'd0;
    else if(!streaming_enable && read_data)
        if(OUTPUT_MUX_CMD)                                                      packet_size_left <= usr_lp_size_wcrc;
        else                                                                    packet_size_left <= (packet_size_left >= 4) ? (packet_size_left - 17'd4) : 17'd0;

    else if(streaming_enable && read_data)
        if(OUTPUT_MUX_CMD && CMD_MUX_CMD_FIFO && DATA_MUX_NULL)                 packet_size_left <= cmd_lp_size_wcrc;
        else if(OUTPUT_MUX_CMD && CMD_MUX_USR_FIFO && DATA_MUX_NULL)            packet_size_left <= usr_lp_size_wcrc;
        else if(DATA_MUX_USR_FIFO && last_data_read_from_fifo)                  packet_size_left <= cmd_lp_size_wcrc;

        else if((DATA_MUX_PIX_FIFO || DATA_MUX_BLANK) && last_data_read_from_fifo)
            if(next_cmd_from_usr_fifo)                                          packet_size_left <= usr_lp_size_wcrc;
            else                                                                packet_size_left <= cmd_lp_size_wcrc;
        else if((DATA_MUX_USR_FIFO || DATA_MUX_PIX_FIFO || DATA_MUX_BLANK))     packet_size_left <= (packet_size_left >= 4) ? (packet_size_left - 17'd4) : 17'd0;

assign bytes_in_line = (packet_size_left_wocrc >= 4) ? 2'd3 : (packet_size_left_wocrc[1:0] - 2'd1);

logic last_fifo_reading;
logic last_fifo_reading_wcrc;

/********* check for the last read words *********/
assign last_fifo_reading        = !(|packet_size_left_wocrc[15:2]) && |packet_size_left_wocrc[1:0] | (packet_size_left_wocrc == 16'd4);
assign last_fifo_reading_wcrc   = !(|packet_size_left[16:2]) && |packet_size_left[1:0] | (packet_size_left == 17'd4);

logic [31:0] lp_data_output;

/********* latch data or data with crc or just crc to long packet output data register  *********/

assign data_to_write_masked = data_to_write & (32'hffff_ffff >> ((packet_size_left_wocrc >= 4) ? 0 : (4 - packet_size_left_wocrc[1:0])));

always_comb
    if(!last_fifo_reading & !last_fifo_reading_wcrc)        lp_data_output = data_to_write_masked;
    else if(last_fifo_reading & last_fifo_reading_wcrc)     lp_data_output = data_to_write_masked & (32'hffff_ffff >> (packet_size_left_wocrc[1:0] * 8)) |
                                                                               ({16'b0, crc_result_async} << ((2'd2 - packet_size_left_wocrc[1:0]) * 8));
    else if(last_fifo_reading & !last_fifo_reading_wcrc)    lp_data_output = data_to_write_masked & (32'hffff_ffff >> ((17'd4 - packet_size_left) * 8)) | ( {16'b0, crc_result_async} << ((packet_size_left) * 8));
    else if(!last_fifo_reading & last_fifo_reading_wcrc)    lp_data_output = {16'b0, crc_result_sync} >> ((2 - packet_size_left_wocrc) * 8) | 32'b0;

assign read_lp_data = read_data && (OUTPUT_MUX_DATA);

crc_calculator
(
    .clk                (clk                    ),
    .reset_n            (reset_n                ),
    .clear              (OUTPUT_MUX_CMD         ),
    .data_write         (read_lp_data           ),
    .bytes_number       (bytes_in_line          ),
    .data_input         (data_to_write_masked   ),
    .crc_output_async   (crc_result_async       ),
    .crc_output_sync    (crc_result_sync        )
);

/********* Muxes control *********/
/********* Actually looks like FSM, but it is easier to understand *********/

//  The worst thing is the situation when we need two data words at one clock (when ask_for_extra_data = 1)
//  In this case we jump over one muxes state.
// This signal can become 1 only after long packets because only these packets can have a variable length


logic [4:0] mux_ctrl_vec;
logic next_cmd_from_usr_fifo;
logic set_source_data_usr_fifo;
logic last_data_read_from_fifo;
logic next_packet_from_usr_fifo;
logic streaming_en;
logic streaming_enable_delayed;

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))       streaming_enable_delayed <= 1'b0;
    else                    streaming_enable_delayed <= streaming_enable;

assign streaming_en = (streaming_enable_delayed ^ streaming_enable) & streaming_enable;

assign next_packet_from_usr_fifo    = cmd_fifo_out_ctrl[0];
assign set_source_data_usr_fifo     = usr_fifo_packet_long && CMD_MUX_USR_FIFO && OUTPUT_MUX_CMD && no_data_is_being_sent;
assign last_data_read_from_fifo     = !no_data_is_being_sent && last_fifo_reading_wcrc;

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))                                                                           mux_ctrl_vec <= {SET_DATA_MUX_NULL, SET_CMD_MUX_USR, SET_OUTP_MUX_CMD};
    else if(streaming_en)                                                                       mux_ctrl_vec <= {SET_DATA_MUX_NULL, SET_CMD_MUX_CMD, SET_OUTP_MUX_CMD};
    else if(!streaming_enable && read_data)
        if(set_source_data_usr_fifo)                                                            mux_ctrl_vec <= {SET_DATA_MUX_USR, SET_CMD_MUX_USR, SET_OUTP_MUX_DATA};
        else if(last_data_read_from_fifo)                                                       mux_ctrl_vec <= {SET_DATA_MUX_NULL, SET_CMD_MUX_USR, SET_OUTP_MUX_CMD};

    else if(streaming_enable && read_data)
        if(OUTPUT_MUX_CMD && CMD_MUX_CMD_FIFO && DATA_MUX_NULL)
            if(cmd_fifo_packet_short && !next_packet_from_usr_fifo || cmd_fifo_empty)           mux_ctrl_vec <= mux_ctrl_vec;
            else if(cmd_fifo_packet_short && next_packet_from_usr_fifo)                         mux_ctrl_vec <= {SET_DATA_MUX_NULL,     SET_CMD_MUX_USR, SET_OUTP_MUX_CMD};
            else if(cmd_fifo_packet_long && lp_pix)                                             mux_ctrl_vec <= {SET_DATA_MUX_PIX,      SET_CMD_MUX_CMD, SET_OUTP_MUX_DATA};
            else if(cmd_fifo_packet_long && lp_blank)                                           mux_ctrl_vec <= {SET_DATA_MUX_BLANK,    SET_CMD_MUX_CMD, SET_OUTP_MUX_DATA};

        else if(OUTPUT_MUX_CMD && CMD_MUX_USR_FIFO && DATA_MUX_NULL)
            if(usr_fifo_packet_long)                                                            mux_ctrl_vec <= {SET_DATA_MUX_USR,  SET_CMD_MUX_CMD, SET_OUTP_MUX_DATA};
            else if(usr_fifo_packet_short)                                                      mux_ctrl_vec <= {SET_DATA_MUX_NULL, SET_CMD_MUX_CMD, SET_OUTP_MUX_CMD};

        else if(DATA_MUX_USR_FIFO && last_data_read_from_fifo)
            if(ask_for_extra_data) // If we ask for extra data, then next muxes state we set accroding to data in cmd fifo and not according to current muxes state
                else if(cmd_fifo_packet_short && !next_packet_from_usr_fifo || cmd_fifo_empty)  mux_ctrl_vec <= {SET_DATA_MUX_NULL,     SET_CMD_MUX_CMD, SET_OUTP_MUX_CMD};
                else if(cmd_fifo_packet_short && next_packet_from_usr_fifo)                     mux_ctrl_vec <= {SET_DATA_MUX_NULL,     SET_CMD_MUX_USR, SET_OUTP_MUX_CMD};
                else if(cmd_fifo_packet_long && lp_pix)                                         mux_ctrl_vec <= {SET_DATA_MUX_PIX,      SET_CMD_MUX_CMD, SET_OUTP_MUX_DATA};
                else if(cmd_fifo_packet_long && lp_blank)                                       mux_ctrl_vec <= {SET_DATA_MUX_BLANK,    SET_CMD_MUX_CMD, SET_OUTP_MUX_DATA};

            else                                                                                mux_ctrl_vec <= {SET_DATA_MUX_NULL, SET_CMD_MUX_CMD, SET_OUTP_MUX_CMD};

        else if((DATA_MUX_PIX_FIFO || DATA_MUX_BLANK) && last_data_read_from_fifo)
            if(next_cmd_from_usr_fifo)
                if(ask_for_extra_data) // If we ask for extra data, then next muxes state we set accroding to data in cmd fifo and not according to current muxes state
                    if(usr_fifo_packet_long)                                                    mux_ctrl_vec <= {SET_DATA_MUX_USR,  SET_CMD_MUX_CMD, SET_OUTP_MUX_DATA};
                    else if(usr_fifo_packet_short)                                              mux_ctrl_vec <= {SET_DATA_MUX_NULL, SET_CMD_MUX_CMD, SET_OUTP_MUX_CMD};
                else                                                                            mux_ctrl_vec <= {SET_DATA_MUX_NULL, SET_CMD_MUX_USR, SET_OUTP_MUX_CMD};

            else if(ask_for_extra_data) // If we ask for extra data, then next muxes state we set accroding to data in cmd fifo and not according to current muxes state
                if(cmd_fifo_packet_short && !next_packet_from_usr_fifo || cmd_fifo_empty)       mux_ctrl_vec <= {SET_DATA_MUX_NULL,     SET_CMD_MUX_CMD, SET_OUTP_MUX_CMD};
                else if(cmd_fifo_packet_short && next_packet_from_usr_fifo)                     mux_ctrl_vec <= {SET_DATA_MUX_NULL,     SET_CMD_MUX_USR, SET_OUTP_MUX_CMD};
                else if(cmd_fifo_packet_long && lp_pix)                                         mux_ctrl_vec <= {SET_DATA_MUX_PIX,      SET_CMD_MUX_CMD, SET_OUTP_MUX_DATA};
                else if(cmd_fifo_packet_long && lp_blank)                                       mux_ctrl_vec <= {SET_DATA_MUX_BLANK,    SET_CMD_MUX_CMD, SET_OUTP_MUX_DATA};

            else                                                                                mux_ctrl_vec <= {SET_DATA_MUX_NULL, SET_CMD_MUX_CMD, SET_OUTP_MUX_CMD};

assign {data_source_vector, source_cmd_fifo, data_is_data} = mux_ctrl_vec;

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))                                                                       next_cmd_from_usr_fifo <= 1'b0;
    else if(read_data && OUTPUT_MUX_CMD && CMD_MUX_CMD_FIFO && next_packet_from_usr_fifo)   next_cmd_from_usr_fifo <= 1'b1;
    else if(read_data && OUTPUT_MUX_CMD && CMD_MUX_USR_FIFO)                                next_cmd_from_usr_fifo <= 1'b0;

/********* Read signals forming *********/
logic blank_read

assign blank_read       = read_data && OUTPUT_MUX_DATA && DATA_MUX_BLANK;
assign pix_fifo_read    = read_lp_data & DATA_MUX_PIX_FIFO & !pix_fifo_empty;
assign usr_fifo_read    = (read_lp_data & DATA_MUX_USR_FIFO || read_data & CMD_MUX_USR_FIFO) & !usr_fifo_empty;
assign cmd_fifo_read    = read_data & CMD_MUX_CMD_FIFO & OUTPUT_MUX_CMD & !cmd_fifo_empty;

logic filling_pipe_read_data;
logic set_filling_pipe_read_data_streaming;
logic cmd_fifo_empty_delayed;
logic cmd_fifo_new_data_avail;
logic usr_fifo_empty_delayed;
logic usr_fifo_new_data_avail;
logic data_writing_in_progress;
logic stop_read_data;
logic set_stop_read_data_hs;
logic reset_stop_read_data_hs;
logic set_stop_read_data_lp;
logic reset_stop_read_data_lp;
logic lanes_controller_lines_active_delayed;
logic lanes_controller_lines_activated;
logic lanes_controller_lines_deactivated;

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))               lanes_controller_lines_active_delayed <= 1'b0;
    else                            lanes_controller_lines_active_delayed <= lanes_controller_lines_active;

assign lanes_controller_lines_activated     = (lanes_controller_lines_active_delayed ^ lanes_controller_lines_active) & lanes_controller_lines_active;
assign lanes_controller_lines_deactivated   = (lanes_controller_lines_active_delayed ^ lanes_controller_lines_active) & !lanes_controller_lines_active;

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))   usr_fifo_empty_delayed <= 1'b0;
    else                usr_fifo_empty_delayed <= usr_fifo_empty;

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))   cmd_fifo_empty_delayed <= 1'b0;
    else                cmd_fifo_empty_delayed <= cmd_fifo_empty;

assign cmd_fifo_new_data_avail                  = (cmd_fifo_empty_delayed ^ cmd_fifo_empty) & !cmd_fifo_empty;
assign usr_fifo_new_data_avail                  = (usr_fifo_empty_delayed ^ usr_fifo_empty) & !usr_fifo_empty;
assign set_filling_pipe_read_data_streaming     = reset_stop_read_data_hs & OUTPUT_MUX_CMD & CMD_MUX_USR_FIFO | cmd_fifo_new_data_avail | streaming_en;

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))                               filling_pipe_read_data <= 1'b0;
    else if(!streaming_enable)
        if(usr_fifo_new_data_avail)                 filling_pipe_read_data <= 1'b1;
        else if(iface_write_rqst)                   filling_pipe_read_data <= 1'b0;

    else if(set_filling_pipe_read_data_streaming)   filling_pipe_read_data <= 1'b1;
    else if(iface_write_rqst)                       filling_pipe_read_data <= 1'b0;

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))           data_writing_in_progress <= 1'b0;
    else if(iface_write_rqst)   data_writing_in_progress <= 1'b1;
    else if(iface_last_word)    data_writing_in_progress <= 1'b0;

assign set_stop_read_data_hs       = (cmd_fifo_read || (pix_fifo_read || blank_read) & last_data_read_from_fifo) & user_cmd_transmission_mode & next_cmd_from_usr_fifo & lanes_controller_lines_active;
assign reset_stop_read_data_hs     = lanes_controller_lines_deactivated;
assign set_stop_read_data_lp       = !lanes_controller_lines_active & read_data & (OUTPUT_MUX_CMD & usr_fifo_packet_short | OUTPUT_MUX_DATA & last_data_read_from_fifo)
assign reset_stop_read_data_lp     = !lanes_controller_lines_active & iface_last_word;

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))                                               stop_read_data <= 1'b0;
    else if(set_stop_read_data_hs || set_stop_read_data_lp)         stop_read_data <= 1'b1;
    else if(reset_stop_read_data_hs || reset_stop_read_data_lp)     stop_read_data <= 1'b0;

always_comb
    if(streaming_enable)
            read_data = filling_pipe_read_data | iface_data_rqst & data_writing_in_progress & !stop_read_data;
    else    read_data = filling_pipe_read_data | data_writing_in_progress & iface_data_rqst;


logic iface_lpm_en_reg;

assign iface_lpm_en = iface_lpm_en_reg;

/*********
when streaming_enable = 1
 if user_cmd_transmission_mode = 1 and next_packet_from_usr_fifo then wait until lanes enter LP mode and then set iface_lpm_en_reg and start sending data
 else if user_cmd_transmission_mode = 0 and next_packet_from_usr_fifo then send data right after last packet in HS mode, thus iface_lpm_en_reg stays 0
*********/
always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))                               iface_lpm_en_reg <= 1'b0;
    else if(!streaming_enable)                      iface_lpm_en_reg <= user_cmd_transmission_mode;
    else if(reset_stop_read_data_hs)                iface_lpm_en_reg <= 1'b1;
    else if(reset_stop_read_data_lp & read_data)    iface_lpm_en_reg <= 1'b0;

/********* Packets stitching *********/

logic [31:0] output_data;
logic [31:0] input_data_1;  // main data
logic [31:0] input_data_2;  // extra data
logic [31:0] temp_buffer;
logic [2:0]  offset_value;
logic [15:0] data_size_left;
logic        ask_for_extra_data;
logic [2:0]  outp_data_size;
logic        extra_data_ok;

/********* input data muxes *********/

always_comb
    if(DATA_MUX_USR_FIFO && last_data_read_from_fifo)                           input_data_2 = packet_header_cmd;
    else if((DATA_MUX_PIX_FIFO || DATA_MUX_BLANK) && last_data_read_from_fifo)
        if(next_cmd_from_usr_fifo)                                              input_data_2 = packet_header_usr_fifo;
        else                                                                    input_data_2 = packet_header_cmd;
    else                                                                        input_data_2 = 32'b0;

assign input_data_1     = data_is_data ? lp_data_output : packet_header;
assign data_size_left   = OUTPUT_MUX_DATA ? packet_size_left : 17'd4;

/********* extra_data_ok mux. according to current extra data source we check whether corresponding fifo is empty *********/
always_comb
    if(DATA_MUX_USR_FIFO && last_data_read_from_fifo)                               extra_data_ok = !cmd_fifo_empty;
    else if((DATA_MUX_PIX_FIFO || DATA_MUX_BLANK) && last_data_read_from_fifo)
        if(next_cmd_from_usr_fifo)                                                  extra_data_ok = !usr_fifo_empty;
        else                                                                        extra_data_ok = !cmd_fifo_empty;
    else                                                                            extra_data_ok = 1'b0;

/********* packets stitching core *********/
assign ask_for_extra_data = (data_size_left + offset_value) < 4 ;

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))                           output_data <= 32'b0;
     else if(iface_last_word & read_data)       output_data <= 32'b0;
    else if(read_data)
        if(ask_for_extra_data)                  output_data <= (input_data_1 << (offset_value * 8)) | temp_buffer | (input_data_2 << ((data_size_left + offset_value) * 8));
        else                                    output_data <= (input_data_1 << (offset_value * 8)) | temp_buffer;

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))                       temp_buffer <= 32'b0;
    else if(iface_last_word & read_data)    temp_buffer <= 32'b0;
    else if(read_data)
        if(ask_for_extra_data)              temp_buffer <= 32'b0 | (input_data_2 >> ((4 - data_size_left - offset_value) * 8));
        else                                temp_buffer <= (input_data_1 >> ((4 - offset_value) * 8));

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))                                       offset_value <= 3'b0;
    else if(iface_last_word & read_data)                    offset_value <= 3'b0;
    else if(read_data)
        if(ask_for_extra_data && extra_data_ok)             offset_value <= (data_size_left + offset_value);
        else if(ask_for_extra_data && !extra_data_ok)       offset_value <= 3'b0;
        else if(data_size_left < 4)                         offset_value <= data_size_left + offset_value - 4;

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))                                       outp_data_size <= 3'd0;
    else if(iface_last_word & read_data)                    outp_data_size <= 3'd0;
    else if(read_data)
        if(ask_for_extra_data && !extra_data_ok)            outp_data_size <= (data_size_left + offset_value);
        else                                                outp_data_size <= 3'd4;

assign iface_last_word = read_data && ((outp_data_size < 3'd4) || (data_size_left == 0));

always_comb
    case(outp_data_size):
    3'd0:
        iface_write_strb = 4'b0000;
    3'd1:
        iface_write_strb = 4'b0001;
    3'd2:
        iface_write_strb = 4'b0011;
    3'd3:
        iface_write_strb = 4'b0111;
    3'd4:
        iface_write_strb = 4'b1111;
    default:
        iface_write_strb = 4'b0000;


endmodule
`endif
