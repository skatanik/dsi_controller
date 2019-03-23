`ifndef DSI_TX_PACKETS_ASSEMBLER
`define DSI_TX_PACKETS_ASSEMBLER

`define PACKET_BLANKING     6'h19
`define PACKET_PPS24        6'h3E
`define PACKET_VSS          6'h01
`define PACKET_HSS          6'h21
`define PACKET_EOT          6'h08

module dsi_tx_packets_assembler #(
    parameter LINE_WIDTH            = 640,
    parameter BITS_PER_PIXEL        = 10,
    parameter BLANK_TIME            = 100,
    parameter BLANK_TIME_HBP_ACT    = 100,
    parameter VSA_LINES_NUMBER      = 100,
    parameter HBP_LINES_NUMBER      = 100,
    parameter ACT_LINES_NUMBER      = 100,
    parameter HFP_LINES_NUMBER      = 100
    )(
    /********* System interface *********/
    input wire                      clk                                 ,  // Clock. The same as in PHY
    input wire                      rst_n                               ,  // Asynchronous reset active low

    /********* Input FIFO interface *********/
    input   wire [31:0]             fifo_data                           , // data should be already packed
    input   wire                    fifo_not_empty                      ,
    input   wire                    fifo_line_ready                     ,
    output  wire                    fifo_read_ack                       ,

    /********* PHY interface *********/
    output  wire [32:0]             phy_data                            ,
    output  wire [3:0]              phy_write                           ,
    input   wire [3:0]              phy_full                            ,

    /********* Control signals *********/
    input   wire                    enable                              ,
    input   wire                    send_cmd                            ,
    input   wire [2:0]              lanes_number                        ,
    input   wire [23:0]             cmd_packet                          ,

    output  wire                    pix_buffer_underflow_set
);

localparam BYTES_IN_LINE = LINE_WIDTH * BITS_PER_PIXEL / 8;

/********* FSM declaration *********/

wire send_lp_cmd_done;
wire send_vss_vsa_done;
wire wait_h_blank_vss_vsa_done;
wire send_hss_vsa_done;
wire wait_h_blank_vsa_done;
wire send_hss_hbp_done;
wire wait_h_blank_hbp_done;
wire send_hss_act_done;
wire wait_h_blank_act_hbp_done;
wire send_data_header_done;
wire send_data_done;
wire send_data_crc_done;
wire wait_h_blank_act_hfp_done;
wire send_hss_hfp_done;
wire wait_h_blank_hfp_done;
wire last_wait_h_blank_vsa;
wire last_wait_h_blank_hbp;
wire last_wait_h_blank_act_hfp;
wire last_wait_h_blank_hfp;
wire send_lp_cmd;

localparam [4:0]        STATE_IDLE                  = 5'd0;
localparam [4:0]        STATE_SEND_LP_CMD           = 5'd1;
localparam [4:0]        STATE_SEND_VSS_VSA          = 5'd2;
localparam [4:0]        STATE_WAIT_H_BLANK_VSS_VSA  = 5'd3;
localparam [4:0]        STATE_SEND_HSS_VSA          = 5'd4;
localparam [4:0]        STATE_WAIT_H_BLANK_VSA      = 5'd5;
localparam [4:0]        STATE_SEND_HSS_HBP          = 5'd6;
localparam [4:0]        STATE_WAIT_H_BLANK_HBP      = 5'd7;
localparam [4:0]        STATE_SEND_HSS_ACT          = 5'd8;
localparam [4:0]        STATE_WAIT_H_BLANK_ACT_HBP  = 5'd9;
localparam [4:0]        STATE_SEND_DATA_HEADER      = 5'd10;
localparam [4:0]        STATE_SEND_DATA             = 5'd11;
localparam [4:0]        STATE_SEND_DATA_CRC         = 5'd12;
localparam [4:0]        STATE_WAIT_H_BLANK_ACT_HFP  = 5'd13;
localparam [4:0]        STATE_SEND_HSS_HFP          = 5'd14;
localparam [4:0]        STATE_WAIT_H_BLANK_HFP      = 5'd15;

reg [4:0] state_current;
reg [4:0] state_next;

wire state_is_idle                  = (state_current == STATE_IDLE);
wire state_send_lp_cmd              = (state_current == STATE_SEND_LP_CMD);
wire state_send_vss_vsa             = (state_current == STATE_SEND_VSS_VSA);
wire state_wait_h_blank_vss_vsa     = (state_current == STATE_WAIT_H_BLANK_VSS_VSA);
wire state_send_hss_vsa             = (state_current == STATE_SEND_HSS_VSA);
wire state_wait_h_blank_vsa         = (state_current == STATE_WAIT_H_BLANK_VSA);
wire state_send_hss_hbp             = (state_current == STATE_SEND_HSS_HBP);
wire state_wait_h_blank_hbp         = (state_current == STATE_WAIT_H_BLANK_HBP);
wire state_send_hss_act             = (state_current == STATE_SEND_HSS_ACT);
wire state_wait_h_blank_act_hbp     = (state_current == STATE_WAIT_H_BLANK_ACT_HBP);
wire state_send_data_header         = (state_current == STATE_SEND_DATA_HEADER);
wire state_send_data                = (state_current == STATE_SEND_DATA);
wire state_send_data_crc            = (state_current == STATE_SEND_DATA_CRC);
wire state_wait_h_blank_act_hfp     = (state_current == STATE_WAIT_H_BLANK_ACT_HFP);
wire state_send_hss_hfp             = (state_current == STATE_SEND_HSS_HFP);
wire state_wait_h_blank_hfp         = (state_current == STATE_WAIT_H_BLANK_HFP);

always @(posedge clk or negedge rst_n)
    if(!rst_n)  state_current <= STATE_IDLE;
    else        state_current <= state_next;

always @(*)
    begin
        case (state_current)
            STATE_IDLE:
                state_next = fifo_line_ready & enable ? STATE_SEND_VSS_VSA : (send_lp_cmd ? STATE_SEND_LP_CMD : STATE_IDLE);

            STATE_SEND_LP_CMD:
                state_next = send_lp_cmd_done ? STATE_IDLE : STATE_SEND_LP_CMD;

            STATE_SEND_VSS_VSA:
                state_next = send_vss_vsa_done ? STATE_WAIT_H_BLANK_VSS_VSA : STATE_SEND_VSS_VSA;

            STATE_WAIT_H_BLANK_VSS_VSA:
                state_next = wait_h_blank_vss_vsa_done ? STATE_SEND_HSS_VSA : STATE_WAIT_H_BLANK_VSS_VSA;

            STATE_SEND_HSS_VSA:
                state_next = send_hss_vsa_done ? STATE_WAIT_H_BLANK_VSA : STATE_SEND_HSS_VSA;

            STATE_WAIT_H_BLANK_VSA:
                state_next = wait_h_blank_vsa_done ? (last_wait_h_blank_vsa ? STATE_SEND_HSS_HBP : STATE_SEND_HSS_VSA) : STATE_WAIT_H_BLANK_VSA;

            STATE_SEND_HSS_HBP:
                state_next = send_hss_hbp_done ? STATE_WAIT_H_BLANK_HBP : STATE_SEND_HSS_HBP;

            STATE_WAIT_H_BLANK_HBP:
                state_next = wait_h_blank_hbp_done ? (last_wait_h_blank_hbp ? STATE_SEND_HSS_ACT : STATE_SEND_HSS_HBP) : STATE_WAIT_H_BLANK_HBP;

            STATE_SEND_HSS_ACT:
                state_next = send_hss_act_done ? STATE_WAIT_H_BLANK_ACT_HBP : STATE_SEND_HSS_ACT;

            STATE_WAIT_H_BLANK_ACT_HBP:
                state_next = wait_h_blank_act_hbp_done ? STATE_SEND_DATA_HEADER : STATE_WAIT_H_BLANK_ACT_HBP;

            STATE_SEND_DATA_HEADER:
                state_next = send_data_header_done ? STATE_SEND_DATA : STATE_SEND_DATA_HEADER;

            STATE_SEND_DATA:
                state_next = send_data_done ? STATE_SEND_DATA_CRC : STATE_SEND_DATA;

            STATE_SEND_DATA_CRC:
                state_next = send_data_crc_done ? STATE_WAIT_H_BLANK_ACT_HFP : STATE_SEND_DATA_CRC;

            STATE_WAIT_H_BLANK_ACT_HFP:
                state_next = wait_h_blank_act_hfp_done ? (last_wait_h_blank_act_hfp ? STATE_SEND_HSS_HFP : STATE_SEND_HSS_ACT) : STATE_WAIT_H_BLANK_ACT_HFP;

            STATE_SEND_HSS_HFP:
                state_next = send_hss_hfp_done ? STATE_WAIT_H_BLANK_HFP : STATE_SEND_HSS_HFP;

            STATE_WAIT_H_BLANK_HFP:
                state_next = wait_h_blank_hfp_done ? (last_wait_h_blank_hfp ? STATE_IDLE : STATE_SEND_HSS_HFP) : STATE_SEND_HSS_HFP;

            default:
                state_next = STATE_IDLE;

        endcase
    end

/********* Send lp cmd *********/
reg send_cmd_reg;

always @(posedge clk or negedge rst_n)
    if(!rst_n)      send_cmd_reg <= 1'b0;
    else            send_cmd_reg <= send_cmd;

assign send_lp_cmd     = (send_cmd_reg ^ send_cmd) & send_cmd;

/********* IRQ *********/

assign pix_buffer_underflow_set = state_send_data_header && !fifo_line_ready;

/********* Timeouts *********/
reg [31:0] blank_counter;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                              blank_counter <= 32'b0;
    else if(state_current != state_next)    blank_counter <= BLANK_TIME;
    else                                    blank_counter <= blank_counter - 32'b1;

assign wait_h_blank_vss_vsa_done    = (blank_counter == 0) & state_wait_h_blank_vss_vsa;
assign wait_h_blank_vsa_done        = (blank_counter == 0) & state_wait_h_blank_vsa;
assign wait_h_blank_hbp_done        = (blank_counter == 0) & state_wait_h_blank_hbp;
assign wait_h_blank_act_hbp_done    = (blank_counter == (BLANK_TIME - BLANK_TIME_0)) & state_wait_h_blank_act_hbp;
assign wait_h_blank_act_hfp_done    = (blank_counter == 0) & state_wait_h_blank_act_hfp;
assign wait_h_blank_hfp_done        = (blank_counter == 0) & state_wait_h_blank_hfp;

reg [15:0] lines_counter;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                                                  lines_counter <= 16'b0;
    else if((state_next == STATE_SEND_HSS_VSA) && (lines_counter == 16'b0))     lines_counter <= VSA_LINES_NUMBER;
    else if((state_next == STATE_SEND_HSS_HBP) && (lines_counter == 16'b0))     lines_counter <= HBP_LINES_NUMBER;
    else if((state_next == STATE_SEND_HSS_ACT) && (lines_counter == 16'b0))     lines_counter <= ACT_LINES_NUMBER;
    else if((state_next == STATE_SEND_HSS_HFP) && (lines_counter == 16'b0))     lines_counter <= HFP_LINES_NUMBER;

assign last_wait_h_blank_vsa        = state_send_hss_vsa && (lines_counter == 16'd1);
assign last_wait_h_blank_hbp        = state_send_hss_hbp && (lines_counter == 16'd1);
assign last_wait_h_blank_act_hfp    = state_send_hss_act && (lines_counter == 16'd1);
assign last_wait_h_blank_hfp        = state_send_hss_hfp && (lines_counter == 16'd1);

/********* Short packets assembling *********/
wire [23:0] packet_header;
wire [7:0]  ecc_calculated;
wire [31:0] packet_header_full;

wire [15:0] data_bytes_number;
reg  [7:0]  packet_id;

ecc_calc ecc_calc_0
(
    .data           (packet_header  ),
    .ecc_result     (ecc_calculated )
);

assign packet_header_full   = {ecc_calculated, packet_header};
assign packet_header        = {data_bytes_number, packet_id};

always
    begin
        case(state_current)
            STATE_SEND_LP_CMD:
                data_bytes_number = cmd_packet[23:8];

            STATE_SEND_DATA_HEADER:
                data_bytes_number = BYTES_IN_LINE;

            default:
                data_bytes_number = 16'b0;

        endcase
    end

always @(*)
    begin
        case(state_current)
            STATE_SEND_LP_CMD:
                packet_id = {2'b0, cmd_packet[7:0]};

            STATE_SEND_VSS_VSA:
                packet_id = {2'b0, `PACKET_VSS};

            STATE_SEND_HSS_VSA:
                packet_id = {2'b0, `PACKET_HSS};

            STATE_SEND_HSS_HBP:
                packet_id = {2'b0, `PACKET_HSS};

            STATE_SEND_HSS_ACT:
                packet_id = {2'b0, `PACKET_HSS};

            STATE_SEND_HSS_HFP:
                packet_id = {2'b0, `PACKET_HSS};

            STATE_SEND_DATA_HEADER:
                packet_id = {2'b0, `PACKET_PPS24};

            default:
                packet_id = 8'b0;

        endcase
    end

/********* CRC calculation *********/

wire        clear_crc;
wire        write_crc;
wire [15:0] crc_result;

assign clear_crc            = state_send_data_header;

crc_calculator crc_calculator_0(
    .clk                (clk                ),
    .reset_n            (rst_n              ),
    .clear              (clear_crc          ),
    .data_write         (write_crc          ),
    .bytes_number       (2'b11              ),
    .data_input         (fifo_data          ),
//    .crc_output_async   (),
    .crc_output_sync    (crc_result         )
);

/********* Data size *********/

reg [15:0] data_size_left;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  data_size_left <= 16'b0;
    else if(clear_crc)          data_size_left <= BYTES_IN_LINE/4;
    else if(fifo_read_ack)      data_size_left <= data_size_left - 16'd1;

assign send_data_done = (data_size_left == 16'd1) & fifo_read_ack;

/********* Pre output fifo *********/
reg [33:0]  data_mux;
wire        fifo_mux_write;
wire        fifo_mux_read;
wire [33:0] fifo_mux_data_out;
wire        fifo_mux_empty;
wire        fifo_mux_full;

altera_generic_fifo #(
        .WIDTH      (34),
        .DEPTH      (4),
        .DC_FIFO    (0),
        .SHOWAHEAD  (1)
        )  fifo_mux(
        .data           (data_mux           ),  //  fifo_input.datain
        .wrreq          (fifo_mux_write     ), //            .wrreq
        .rdreq          (fifo_mux_read      ), //            .rdreq
        .rdclk          (clk                ), //            .clk
        .aclr           (!rst_n             ),  //            .aclr
        .q              (fifo_mux_data_out  ),     // fifo_output.dataout
        .empty          (fifo_mux_empty     ), //            .empty
        .full           (fifo_mux_full      )   //            .full
    );

always @(*)
    begin
        case(state_current)
            STATE_SEND_LP_CMD:
                data_mux = {2'b10, packet_header_full};

            STATE_SEND_DATA:
                data_mux = {2'b00, fifo_data};

            STATE_SEND_DATA_CRC:
                data_mux = {2'b01, 16'b0, crc_result};

            default:
                data_mux = {2'b00, packet_header_full};

        endcase
    end

assign fifo_mux_write           = !fifo_mux_full & (state_send_lp_cmd |
                                                    state_send_vss_vsa |
                                                    state_send_hss_vsa |
                                                    state_send_hss_hbp |
                                                    state_send_hss_act |
                                                    state_send_hss_hfp |
                                                    (state_send_data_header & fifo_line_ready) |
                                                    state_send_data |
                                                    state_send_data_crc);

assign fifo_read_ack            = fifo_mux_write & state_send_data & fifo_not_empty;
assign send_lp_cmd_done         = fifo_mux_write & state_send_lp_cmd;
assign send_vss_vsa_done        = fifo_mux_write & state_send_vss_vsa;
assign send_hss_vsa_done        = fifo_mux_write & state_send_hss_vsa;
assign send_hss_hbp_done        = fifo_mux_write & state_send_hss_hbp;
assign send_hss_act_done        = fifo_mux_write & state_send_hss_act;
assign send_data_header_done    = fifo_mux_write & state_send_data_header;
assign send_data_crc_done       = fifo_mux_write & state_send_data_crc;
assign send_hss_hfp_done        = fifo_mux_write & state_send_hss_hfp;
assign write_crc                = fifo_read_ack;

/********* Repacker part *********/

wire fifo_out_write;
wire [3:0] input_bytes_number;
wire [3:0] output_bytes_number;
wire [3:0] shift_free_bytes;
wire [7:0] write_strobes_wide;
wire [2:0] current_lanes_number;

reg [63:0]  shift_register;
reg [3:0]   shift_register_bn;
reg         lp_mode_flag;

always @(posedge clk or negedge rst_n)
    if(!rst_n)              lp_mode_flag <= 1'b0;
    else if(fifo_mux_read)  lp_mode_flag <= fifo_mux_data_out[33];

always @(posedge clk or negedge rst_n)
    if(!rst_n)              shift_register <= 64'b0;
    else                    shift_register <= (shift_register >> ({3{fifo_out_write}} & output_bytes_number)*8) | {64{fifo_mux_read}} & ({32'b0, fifo_mux_data_out[31:0]} << (8 - shift_free_bytes)*8);

always @(posedge clk or negedge rst_n)
    if(!rst_n)              shift_register_bn <= 4'b0;
    else                    shift_register_bn <= shift_register_bn + ({3{fifo_mux_read}} & input_bytes_number) - ({3{fifo_out_write}} & output_bytes_number);

assign current_lanes_number = lp_mode_flag ? 3'b1 : lanes_number;
assign input_bytes_number   = fifo_mux_data_out[32] ? 4'd2 : 4'd4;
assign fifo_out_write       = !(|phy_full) & ((shift_register_bn >= current_lanes_number) || |shift_register_bn & fifo_mux_empty);
assign output_bytes_number  = (shift_register_bn >= current_lanes_number) ? current_lanes_number : shift_register_bn;
assign fifo_mux_read        = (shift_free_bytes >= 4'd4) & !fifo_mux_empty;
assign shift_free_bytes     = 4'd8 - shift_register_bn + (fifo_out_write ? output_bytes_number : 4'd0);
assign phy_data             = {lp_mode_flag, shift_register[31:0]};
assign write_strobes_wide   = {4'b0, {4{fifo_out_write}}} << output_bytes_number;
assign phy_write            = write_strobes_wide[7:4];

endmodule

`endif