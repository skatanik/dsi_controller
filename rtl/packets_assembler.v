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

assign send_vss = state_next == STATE_SEND_VSS;

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))                   output_data_reg <= 32'b0;
    else if(send_vss)                   output_data_reg <= cmd_vss;
    else if(cmd_available_delayed)      output_data_reg <= cmd_fifo_out_with_ecc;
    else if(send_hss)                   output_data_reg <= cmd_hss;
    else if(send_rgb_cmd)               output_data_reg <= cmd_rgb;
    else if(send_rgb_data)              output_data_reg <= rgb_fifo_out;
    else if(send_rgb_crc)               output_data_reg <= rgb_crc_res;




endmodule
`endif