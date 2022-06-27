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
    parameter VBP_LINES_NUMBER      = 100,
    parameter ACT_LINES_NUMBER      = 100,
    parameter VFP_LINES_NUMBER      = 100
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

    /********* Params *********/
    input   wire [11:0]             i_lines_vtotal                      ,
    input   wire [11:0]             i_lines_vact                        ,
    input   wire [3:0]              i_lines_vsync                       ,
    input   wire [3:0]              i_lines_vbp                         ,
    input   wire [8:0]              i_lines_vfp                         ,
    input   wire [10:0]             i_lines_htotal                      ,
    input   wire [5:0]              i_lines_hbp                         ,
    input   wire [9:0]              i_lines_hact                        ,

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
wire send_vss_done;
wire send_hss_vbp_done;
wire send_hss_act_done;
wire send_blank_header_done;
wire send_blank_crc_done;
wire send_data_header_done;
wire send_data_done;
wire send_data_crc_done;
wire send_hss_vfp_done;
wire send_hfp_done;
wire send_lp_cmd;
wire line_end;
wire last_act_line;

localparam [4:0]        STATE_IDLE                  = 5'd0;
localparam [4:0]        STATE_SEND_LP_CMD           = 5'd1;
localparam [4:0]        STATE_SEND_VSS              = 5'd2;
localparam [4:0]        STATE_SEND_HSS_VBP          = 5'd4;
localparam [4:0]        STATE_SEND_HSS_ACT          = 5'd5;
localparam [4:0]        STATE_SEND_BLANK_HEADER      = 5'd6;
localparam [4:0]        STATE_SEND_BLANK             = 5'd7;
localparam [4:0]        STATE_SEND_BLANK_CRC         = 5'd8;
localparam [4:0]        STATE_SEND_HFP              = 5'd9;
localparam [4:0]        STATE_SEND_DATA_HEADER      = 5'd10;
localparam [4:0]        STATE_SEND_DATA             = 5'd11;
localparam [4:0]        STATE_SEND_DATA_CRC         = 5'd12;
localparam [4:0]        STATE_SEND_HSS_VFP          = 5'd14;

reg [4:0] state_current;
reg [4:0] state_next;

wire state_is_idle                  = (state_current == STATE_IDLE);
wire state_send_lp_cmd              = (state_current == STATE_SEND_LP_CMD);
wire state_send_vss                 = (state_current == STATE_SEND_VSS);
wire state_send_hss_vbp             = (state_current == STATE_SEND_HSS_VBP);
wire state_send_hss_act             = (state_current == STATE_SEND_HSS_ACT);
wire state_send_data_header         = (state_current == STATE_SEND_DATA_HEADER);
wire state_send_data                = (state_current == STATE_SEND_DATA);
wire state_send_data_crc            = (state_current == STATE_SEND_DATA_CRC);
wire state_send_blank_header        = (state_current == STATE_SEND_BLANK_HEADER);
wire state_send_blank               = (state_current == STATE_SEND_BLANK);
wire state_send_blank_crc           = (state_current == STATE_SEND_BLANK_CRC);
wire state_send_hss_vfp             = (state_current == STATE_SEND_HSS_VFP);
wire state_send_hfp                 = (state_current == STATE_SEND_HFP);

always @(posedge clk)
    if(!rst_n)  state_current <= STATE_IDLE;
    else        state_current <= state_next;

always @(*)
    begin
        case (state_current)
            STATE_IDLE:
                state_next = fifo_line_ready & enable & line_end ? STATE_SEND_VSS : (send_lp_cmd ? STATE_SEND_LP_CMD : STATE_IDLE);

            STATE_SEND_LP_CMD:
                state_next = send_lp_cmd_done ? STATE_IDLE : STATE_SEND_LP_CMD;

            STATE_SEND_VSS:
                state_next = send_vss_done ? STATE_SEND_HSS_VBP : STATE_SEND_VSS;

            STATE_SEND_HSS_VBP:
                state_next = send_hss_vbp_done ? STATE_SEND_HSS_ACT : STATE_SEND_HSS_VBP;
            // horizontal fsm
            STATE_SEND_HSS_ACT:
                state_next = send_hss_act_done ? STATE_SEND_BLANK_HEADER : STATE_SEND_HSS_ACT;

            STATE_SEND_BLANK_HEADER:
                state_next = send_blank_header_done ? STATE_SEND_BLANK : STATE_SEND_BLANK_HEADER;

            STATE_SEND_BLANK:
                state_next = send_data_done ? STATE_SEND_BLANK_CRC : STATE_SEND_BLANK;

            STATE_SEND_BLANK_CRC:
                state_next = send_blank_crc_done ? STATE_SEND_DATA_HEADER : STATE_SEND_BLANK_CRC;

            STATE_SEND_DATA_HEADER:
                state_next = send_data_header_done ? STATE_SEND_DATA : STATE_SEND_DATA_HEADER;

            STATE_SEND_DATA:
                state_next = send_data_done ? STATE_SEND_DATA_CRC : STATE_SEND_DATA;

            STATE_SEND_DATA_CRC:
                state_next = send_data_crc_done ? STATE_SEND_HFP : STATE_SEND_DATA_CRC;

            STATE_SEND_HFP:
                state_next = send_hfp_done ? (last_act_line ? STATE_SEND_HSS_VFP : STATE_SEND_HSS_ACT) : STATE_SEND_HFP;
            // horizontal fsm end
            STATE_SEND_HSS_VFP:
                state_next = send_hss_vfp_done ? (enable ? STATE_SEND_VSS : STATE_IDLE) : STATE_SEND_HSS_VFP;

            default:
                state_next = STATE_IDLE;

        endcase
    end

/********* Send lp cmd *********/
reg send_cmd_reg;

always @(posedge clk)
    if(!rst_n)      send_cmd_reg <= 1'b0;
    else            send_cmd_reg <= send_cmd;

assign send_lp_cmd     = (send_cmd_reg ^ send_cmd) & send_cmd;

/********* IRQ *********/

assign pix_buffer_underflow_set = state_send_data_header && !fifo_line_ready;

/********* Timeouts *********/

wire line_start;
wire last_line_vbp;
wire last_line_vfp;

reg [31:0] pix_counter;
reg [31:0] lines_counter;

always @(posedge clk) begin
    if(!rst_n)          pix_counter <= 32'b0;
    else if(enable) begin
        if(!(|pix_counter)) pix_counter <= i_lines_htotal-1;
        else                pix_counter <= pix_counter - 32'b1;
    end
end

assign line_start = enable & !(|pix_counter);
assign line_end = enable & !(|pix_counter[31:1]) & pix_counter[0];

always @(posedge clk) begin
    if(!rst_n)                  lines_counter <= 32'b0;
    else if(line_end)
        if(!(|lines_counter))   lines_counter <= i_lines_vtotal - 1;
        else                    lines_counter <= lines_counter - 32'b1;
end

reg [31:0] vbp_cnt;
reg [31:0] act_cnt;

always @(posedge clk) begin
    vbp_cnt <= i_lines_vtotal - (i_lines_vsync + i_lines_vbp );
    act_cnt <= i_lines_vtotal - (i_lines_vsync + i_lines_vbp + i_lines_vact);
end

assign last_line_vbp = lines_counter == vbp_cnt;
assign last_line_vfp = !(|lines_counter);
assign last_act_line = lines_counter == act_cnt;

/********* Short packets assembling *********/
wire [23:0] packet_header;
wire [7:0]  ecc_calculated;
wire [31:0] packet_header_full;

reg [15:0] data_bytes_number;
reg  [7:0]  packet_id;

ecc_calc ecc_calc_0
(
    .data           (packet_header  ),
    .ecc_result     (ecc_calculated )
);

assign packet_header_full   = {ecc_calculated, packet_header};
assign packet_header        = {data_bytes_number, packet_id};

always @(*)
    begin
        case(state_current)
            STATE_SEND_LP_CMD:
                data_bytes_number = cmd_packet[23:8];

            STATE_SEND_BLANK_HEADER:
                data_bytes_number = i_lines_hbp * 3 + 2; // align to 32 bit (with crc)

            STATE_SEND_DATA_HEADER:
                data_bytes_number = i_lines_hact * 3;

            default:
                data_bytes_number = 16'b0;

        endcase
    end

always @(*)
    begin
        case(state_current)
            STATE_SEND_LP_CMD:
                packet_id = cmd_packet[7:0];

            STATE_SEND_VSS:
                packet_id = {2'b0, `PACKET_VSS};

            STATE_SEND_HSS_VBP:
                packet_id = {2'b0, `PACKET_HSS};

            STATE_SEND_HSS_ACT:
                packet_id = {2'b0, `PACKET_HSS};

            STATE_SEND_HSS_VFP:
                packet_id = {2'b0, `PACKET_HSS};

            STATE_SEND_BLANK_HEADER:
                packet_id = {2'b0, `PACKET_BLANKING};

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

assign clear_crc            = state_send_data_header | state_send_blank_header;

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

always @(posedge clk)
    if(!rst_n)                  data_size_left <= 16'b0;
    else if(clear_crc)          data_size_left <= state_send_data_header ? {8'b0, (i_lines_hact * 3) >> 2} : {12'b0, (i_lines_hbp * 3) >> 2 };
    else if(fifo_read_ack)      data_size_left <= data_size_left - 16'd1;

assign send_data_done = (data_size_left == 16'd1) & fifo_read_ack;

/********* Pre output fifo *********/
reg [33:0]  data_mux;
wire        fifo_mux_write;
wire        fifo_mux_read;
wire [33:0] fifo_mux_data_out;
wire        fifo_mux_empty;
wire        fifo_mux_full;

`ifdef ALTERA
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

`else

scfifo_34 fifo_mux (
  .clk          (clk                ), // input clk
  `ifdef SPARTAN7
  .srst         (!rst_n             ), // input rst
  `else
  .rst          (!rst_n             ), // input rst
  `endif
  .din          (data_mux           ), // input [33 : 0] din
  .wr_en        (fifo_mux_write     ), // input wr_en
  .rd_en        (fifo_mux_read      ), // input rd_en
  .dout         (fifo_mux_data_out  ), // output [33 : 0] dout
  .full         (fifo_mux_full      ), // output full
  .empty        (fifo_mux_empty     ) // output empty
);

`endif

always @(*)
    begin
        case(state_current)
            STATE_SEND_LP_CMD:
                data_mux = {2'b10, packet_header_full};

            STATE_SEND_BLANK:
                data_mux = {2'b00, 32'b0};

            STATE_SEND_BLANK_CRC:
                data_mux = {2'b00, crc_result, 16'b0};

            STATE_SEND_DATA:
                data_mux = {2'b00, fifo_data};

            STATE_SEND_DATA_CRC:
                data_mux = {2'b01, 16'b0, crc_result};

            default:
                data_mux = {2'b00, packet_header_full};

        endcase
    end

assign fifo_mux_write           = !fifo_mux_full & (state_send_lp_cmd |
                                                    state_send_vss & line_start |
                                                    state_send_hss_vbp & line_start |
                                                    state_send_hss_act & line_start |
                                                    state_send_hss_vfp & line_start |
                                                    state_send_data_header |
                                                    state_send_blank_header |
                                                    state_send_data_crc |
                                                    state_send_blank_crc |
                                                    state_send_data | state_send_blank);

assign fifo_read_ack            = fifo_mux_write & (state_send_data | state_send_blank) & fifo_not_empty;
assign send_lp_cmd_done         = fifo_mux_write & state_send_lp_cmd;
assign send_vss_done            = line_end;
assign send_hfp_done            = line_end;
assign send_hss_vbp_done        = line_end & last_line_vbp;
assign send_hss_act_done        = fifo_mux_write & state_send_hss_act;
assign send_data_header_done    = fifo_mux_write & state_send_data_header;
assign send_blank_header_done   = fifo_mux_write & state_send_blank_header;
assign send_data_crc_done       = fifo_mux_write & state_send_data_crc;
assign send_blank_crc_done      = fifo_mux_write & state_send_blank_crc;
assign send_hss_vfp_done        = line_end & last_line_vfp;
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

always @(posedge clk)
    if(!rst_n)              lp_mode_flag <= 1'b0;
    else if(fifo_mux_read)  lp_mode_flag <= fifo_mux_data_out[33];

always @(posedge clk)
    if(!rst_n)              shift_register <= 64'b0;
    else                    shift_register <= (shift_register >> ({3{fifo_out_write}} & output_bytes_number)*8) | {64{fifo_mux_read}} & ({32'b0, fifo_mux_data_out[31:0]} << (8 - shift_free_bytes)*8);

always @(posedge clk)
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