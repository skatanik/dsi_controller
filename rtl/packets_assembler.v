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

********************************************************************/
/********* LPM enable mode *********/
logic send_vss;

logic [23:0]    command_data;
logic [7:0]     ecc_result;
logic [31:0]    command_res;
logic [31:0]    data_to_write;
logic [15:0]    crc_result;
logic [1:0]     bytes_in_line;
logic           clear_crc;
logic           write_crc;

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
                sd_state_next = send_header ? (header_long_packet ? SD_STATE_SEND_DATA : (send_cmd_data ? SD_STATE_SEND_HEADER : SD_STATE_IDLE) : SD_STATE_SEND_HEADER);

            SD_STATE_SEND_DATA:
                sd_state_next = ldp_sending_done ? (send_cmd_data ? SD_STATE_SEND_HEADER : SD_STATE_IDLE) : SD_STATE_SEND_DATA;

            default :
                sd_state_next = SD_STATE_IDLE;
        endcase
    end

assign command_res = {command_data, ecc_result};

assign send_header              = (sd_state_current == SD_STATE_SEND_HEADER) && write_available;
assign send_rgb_data            = (sd_state_current == SD_STATE_SEND_DATA) && write_available;
assign sd_next_state_send_data  = (sd_state_current == SD_STATE_SEND_HEADER) && (sd_state_next == SD_STATE_SEND_DATA);
assign sd_next_state_send_data  = (sd_state_current == SD_STATE_SEND_HEADER) && (sd_state_next == SD_STATE_SEND_DATA);

/********* Latch data in output register *********/
always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))                   output_data_reg <= 32'b0;
    else if(send_header)                output_data_reg <= command_res;
    else if(send_rgb_data)              output_data_reg <= data_to_write;

logic [15:0] data_counter;

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))                           data_counter <= 16'b0;
    else if(sd_next_state_send_data)            data_counter <= {command_res[23:16], command_res[15:8]};
    else if(send_rgb_data && (|data_counter))   data_counter <= data_counter - 16'd1;

assign ldp_sending_done = (sd_state_current == SD_STATE_SEND_DATA) && !(|data_counter);

// ECC bloc input mux
always_comb
    begin
        if(send_vss)
            command_data = CMD_VSS;
        else if(send_hss)
            command_data = CMD_HSS;
        else if(send_rgb_cmd)
            command_data = CMD_RGB;
        else if(source_cmd_fifo)
            command_data = cmd_fifo_data;
        else
            command_data = 'b0;
    end

ecc_calc ecc_0
(
    .data       (command_data       ),
    .ecc_result (ecc_result         )
);

// CRC block input mux

crc_calculator
(
    .clk                (clk                    ),
    .reset_n            (reset_n                ),
    .clear              (clear_crc              ),
    .data_write         (write_crc              ),
    .bytes_number       (bytes_in_line          ),
    .data_input         (data_to_write          ),
    .crc_output_async   (),
    .crc_output_sync    (crc_result             )
);

always @(*)
    begin
        if(source_pix_fifo)
            data_to_write = pix_fifo_data;
        else if(source_cmd_fifo)
            data_to_write = cmd_fifo_data;
        else
            data_to_write = 32'b0
    end

endmodule
`endif
