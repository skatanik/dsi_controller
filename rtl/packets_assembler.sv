`ifndef DSI_PACKETS_ASSEMBLER
`define DSI_PACKETS_ASSEMBLER

module packets_assembler #(
    CMD_FIFO_DEPTH      = 10
    )(
    /********* Clock signals *********/
        input   wire                            clk_sys                         ,
        input   wire                            rst_n                           ,

    /********* lanes controller iface *********/
        output wire [31:0]                      iface_write_data                ,
        output wire [4:0]                       iface_write_strb                ,
        output wire                             iface_write_rqst                ,
        output wire                             iface_last_word                 ,
        input  wire                             iface_data_rqst                 ,

    /********* pixel FIFO interface *********/
        input   wire  [31:0]                    pix_fifo_data                   ,
        input   wire                            pix_fifo_empty                  ,
        output  wire                            pix_fifo_read                   ,

    /********* cmd FIFO interface *********/
        input   wire  [31:0]                    cmd_fifo_data                   ,
        input   wire  [CMD_FIFO_DEPTH - 1:0]    cmd_fifo_usedw                  ,
        input   wire                            cmd_fifo_empty                  ,
        output  wire                            cmd_fifo_read                   ,

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

);

`define CLK_RST(clk, rst_n)   posedge clk, negedge rst_n
`define RST(rst_n)   !rst_n

/********************************************************************
                        FSM declaration
********************************************************************/
enum logic [3:0]{
    STATE_IDLE,
    STATE_SEND_CMD,
    STATE_SEND_VSS,
    STATE_SEND_HSS,     // send hss packet in HS mode then go to LP mode or send blank packet in HS mode
    STATE_SEND_HBP,     // send hbp packet in HS mode or stay in LP mode
    STATE_SEND_RGB,     // send rgb packet in HS mode, can be sent with appended cmd
    STATE_SEND_HFP,     // send blank packet in HS mode or stay in LP mode
    STATE_LPM
}

logic [3:0] state_current, state_next;

always_ff @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))   state_current <= STATE_IDLE;
    else                state_current <= state_next;

always_comb
    begin
        case (state_current)
            STATE_IDLE:
                state_next = cmd_pending ? STATE_SEND_CMD : (streaming_enable ? STATE_SEND_VSS : STATE_IDLE);

            STATE_SEND_CMD:
                state_next = cmd_send_done ? STATE_IDLE : STATE_SEND_CMD;

            STATE_SEND_VSS:
                state_next = send_vss_done ? STATE_SEND_HSS : STATE_SEND_VSS;

            STATE_SEND_HSS:
                state_next = send_hss_done & hss_up_counter_finished ? STATE_SEND_HBP : (send_hss_done & hss_down_counter_finished ? STATE_LPM : STATE_SEND_HSS);

            STATE_SEND_HBP:
                state_next = send_hbp_done ? STATE_SEND_RGB : STATE_SEND_HBP;

            STATE_SEND_RGB:
                state_next = send_rgb_done ? STATE_SEND_HFP : STATE_SEND_RGB;

            STATE_SEND_HFP:
                state_next = send_hfp_done ? (active_lines_finished ? STATE_SEND_HSS : STATE_SEND_HBP) : STATE_SEND_HFP;

            STATE_LPM:
                state_next = lpm_done ? (streaming_enable ?  STATE_SEND_VSS : STATE_IDLE) : STATE_LPM;

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
After sending each periodical command we check whether there are any commands
in command fifo. If yes then it is appended after current command. But every time we check
the lenght of this command. If command size is too big to write at the current time,
then this command will be sent next time. CMD fifo depth is less than horizontal line size.
Sending is not possible in STATE_LPM. All command are sent in hs mode.
********************************************************************/

/********************************************************************
                        Packets assembler (PA)
Packets assembler at the right time strarts to send commands.
If needed sends additional cmds from cmd fifo
calculates right size of each packet (also blank packets if lpm_enable = 0).
adds ECC and CRC, appropriate offset.
Working when low power mode is enabled.
PA works in interrupt mode when signals from counters signalize when PA must start next cmd or data sending.
After sending obligatory cmd or data PA can append cmd from FIFO if size of this cmd is less than time to the next cmd sending.
After sending data in HS mode PA allow lanes to get into LP mode. And then waits for the next signal from corresponding counter.
Working when low power mode is disabled.
PA starts to send sequences of packets in HS mode. In the end of every packet it calculates size of the next packet according to current state and counters values (time to line end).
As when LP mode is off PA can append additional cmd to periodicaly sent cmd or data. After thet it will send blank packet with an appropriate size/
several short packets can be send after regular data in each line. But after sending long packet transmission stopped until next line

********************************************************************/

localparam [31:0] BLANK_PATTERN = 32'h5555_5555;

logic send_vss;

logic [7:0]     ecc_result;
logic [31:0]    data_to_write;
logic [15:0]    crc_result;
logic [1:0]     bytes_in_line;
logic           clear_crc;
logic           write_crc;
logic           source_cmd_fifo;
logic           source_pix_fifo;
logic           source_blank_gen;
logic [23:0]    packet_header;
logic [31:0]    packet_header_wecc;
logic           read_header;
logic           read_lp_data;
logic           packet_type_long;
logic           packet_type_short;

enum logic [1:0] {
    SD_STATE_IDLE,
    SD_STATE_SEND_HEADER,
    SD_STATE_SEND_DATA
} sd_state_current, sd_state_next;

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))   sd_state_current <= SD_STATE_IDLE;
    else                sd_state_current <= sd_state_next;

always_comb
    begin
        case (sd_state_current)
            SD_STATE_IDLE:
                sd_state_next = send_cmd_data ? SD_STATE_SEND_HEADER : SD_STATE_IDLE;

            SD_STATE_SEND_HEADER:
                sd_state_next = start_sp_sending ? (packet_type_long ? SD_STATE_SEND_DATA : (send_cmd_data ? SD_STATE_SEND_HEADER : SD_STATE_IDLE) : SD_STATE_SEND_HEADER);

            SD_STATE_SEND_DATA:
                sd_state_next = ldp_sending_done ? (send_cmd_data ? SD_STATE_SEND_HEADER : SD_STATE_IDLE) : SD_STATE_SEND_DATA;

            default :
                sd_state_next = SD_STATE_IDLE;
        endcase
    end

assign send_header              = (sd_state_current == SD_STATE_SEND_HEADER) && write_available;
assign send_rgb_data            = (sd_state_current == SD_STATE_SEND_DATA) && write_available;
assign sd_next_state_send_data  = (sd_state_current == SD_STATE_SEND_HEADER) && (sd_state_next == SD_STATE_SEND_DATA);
assign sd_next_state_send_data  = (sd_state_current == SD_STATE_SEND_HEADER) && (sd_state_next == SD_STATE_SEND_DATA);

/********* packet header ecc appending *********/
always_comb
    if(source_pix_fifo)         packet_header = current_periodic_cmd;
    else if(source_cmd_fifo)    packet_header = cmd_fifo_data;
    else if(source_blank_gen)   packet_header = BLANK_CMD;
    else                        packet_header = 24'b0;

assign packet_header_wecc = {packet_header, ecc_result};

ecc_calc ecc_0
(
    .data       (packet_header ),
    .ecc_result (ecc_result    )
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

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))               current_packet_type <= 1'b0;
    else if(start_lp_sending)       current_packet_type <= 1'b0;
    else if(start_sp_sending)       current_packet_type <= 1'b0;

assign last_lp_read = read_lp_data && (data_size_left <= 17'd4);
assign add_crc      = read_lp_data && (data_size_left_wo_crc <= 17'd4);

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))           data_size_left <= 17'b0;
    else if(start_lp_sending)   data_size_left <= {1'b0, packet_header[15:0]} + 16'd2;
    else if(last_lp_read)       data_size_left <= 17'b0;
    else if(read_lp_data)       data_size_left <= data_size_left - 17'd4;

assign data_size_left_wo_crc = data_size_left - 17'd2;
assign bytes_in_line = !(|data_size_left_wo_crc[1:0]) ? 2'd3 : data_size_left_wo_crc[1:0];

logic packet_not_reserved;
logic packet_decoder_error;

assign packet_decoder_error = read_header && !packet_not_reserved;
assign packet_not_reserved  = !(|packet_header[19:16]) && !(&packet_header[19:16]);
assign packet_type_long     = !packet_header[19] || packet_header[19] && (!(|packet_header[21:20]) && !(|packet_header[18:16])) && packet_not_reserved;
assign packet_type_short    = packet_header[19] && !(packet_header[19] && (!(|packet_header[21:20]) && !(|packet_header[18:16]))) && packet_not_reserved;

// CRC block input mux

assign clear_crc = (sd_state_current != SD_STATE_SEND_DATA);

always_comb
    if(source_pix_fifo)         data_to_write = pix_fifo_data;
    else if(source_cmd_fifo)    data_to_write = cmd_fifo_data;
    else if(source_blank_gen)   data_to_write = BLANK_PATTERN;
    else                        data_to_write = 32'b0;

crc_calculator
(
    .clk                (clk            ),
    .reset_n            (reset_n        ),
    .clear              (clear_crc      ),
    .data_write         (read_lp_data   ),
    .bytes_number       (bytes_in_line  ),
    .data_input         (data_to_write  ),
    .crc_output_async   (),
    .crc_output_sync    (crc_result     )
);

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))                   crc_val <= 16'b0;
    else if(add_crc && !last_lp_read)   crc_val <= crc_result;

logic [31:0] current_data;

always_comb
    if(sd_state_current == SD_STATE_SEND_HEADER)        current_data = packet_header;
    else if(sd_state_current == SD_STATE_SEND_DATA)     current_data = data_to_write;
    else                                                current_data = 32'b0;

logic [31:0] output_data;
logic [31:0] input_data_1;  // main data
logic [31:0] input_data_2;  // extra data
logic [31:0] temp_buffer;
logic [2:0]  offset_value;
logic [15:0] data_size_left;
logic        ask_for_extra_data;
logic [2:0]  outp_data_size;
logic        extra_data_ok;

assign ask_for_extra_data = (data_size_left + offset_value) < 4 ;

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))               output_data <= 32'b0;
    else if(read_data)
        if(ask_for_extra_data)      output_data <= (input_data_1 << (offset_value * 8)) | temp_buffer | (input_data_2 << ((data_size_left + offset_value) * 8));
        else                        output_data <= (input_data_1 << (offset_value * 8)) | temp_buffer;

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))               temp_buffer <= 32'b0;
    else if(read_data)
        if(ask_for_extra_data)      temp_buffer <= 32'b0 | (input_data_2 >> ((4 - data_size_left - offset_value) * 8));
        else                        temp_buffer <= (input_data_1 >> ((4 - offset_value) * 8));

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))                                       offset_value <= 3'b0;
    else if(read_data)
        if(ask_for_extra_data && extra_data_ok)             offset_value <= (data_size_left + offset_value);
        else if(ask_for_extra_data && !extra_data_ok)       offset_value <= 3'b0;
        else if(data_size_left < 4)                         offset_value <= data_size_left + offset_value - 4;

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))                                       outp_data_size <= 3'd0;
    else if(read_data)
        if(ask_for_extra_data && !extra_data_ok)            outp_data_size <= (data_size_left + offset_value);
        else                                                outp_data_size <= 3'd4;

assign iface_last_word = outp_data_size < 3'd4;

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
