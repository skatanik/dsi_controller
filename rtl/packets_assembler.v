module packets_assembler #(
    CMD_FIFO_DEPTH      = 10
    )(
    /********* Clock signals *********/
        input   wire                            clk_sys                         ,
        input   wire                            rst_n                           ,


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

endmodule
