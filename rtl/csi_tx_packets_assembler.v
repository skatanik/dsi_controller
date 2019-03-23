`ifndef CSI_TX_PACKETS_ASSEMBLER
`define CSI_TX_PACKETS_ASSEMBLER

`include "packet_types.vh"

module csi_tx_packets_assembler #(
    parameter LINE_WIDTH        = 640,
    parameter BITS_PER_PIXEL    = 10,
    parameter IMAGE_HEIGHT      = 480,
    parameter BLANK_HORIZONTAL  = 100,
    parameter BLANK_VERTICAL    = 20,
    parameter [5:0] DATA_TYPE   = `LP_RAW10_CODE


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
    output  wire [31:0]             phy_data                            ,
    output  wire [3:0]              phy_write                           ,
    input   wire [3:0]              phy_full                            ,

    /********* Control signals *********/
    input   wire                    enable                              ,
    input   wire [2:0]              lanes_number                        ,
    output  wire                    pix_buffer_underflow_set
);

localparam BYTES_IN_LINE = LINE_WIDTH * BITS_PER_PIXEL / 8;

/********* FSM declaration *********/
wire sending_fs_done;
wire sending_header_done;
wire sending_data_done;
wire sending_crc_done;
wire last_line;
wire wait_h_timeout;
wire sending_fe_done;
wire wait_v_timeout;

localparam [2:0]        STATE_IDLE              = 3'd0;
localparam [2:0]        STATE_SEND_FS           = 3'd1;
localparam [2:0]        STATE_SEND_DATA_HEADER  = 3'd2;
localparam [2:0]        STATE_SEND_DATA         = 3'd3;
localparam [2:0]        STATE_SEND_DATA_CRC     = 3'd4;
localparam [2:0]        STATE_WAIT_H_BLANK      = 3'd5;
localparam [2:0]        STATE_SEND_FE           = 3'd6;
localparam [2:0]        STATE_WAIT_V_BLANK      = 3'd7;

reg [2:0] state_current;
reg [2:0] state_next;

wire state_is_idle             = state_current == STATE_IDLE;
wire state_is_send_fs          = state_current == STATE_SEND_FS;
wire state_is_send_data_header = state_current == STATE_SEND_DATA_HEADER;
wire state_is_send_data        = state_current == STATE_SEND_DATA;
wire state_is_send_data_crc    = state_current == STATE_SEND_DATA_CRC;
wire state_is_wait_h_blank     = state_current == STATE_WAIT_H_BLANK;
wire state_is_send_fe          = state_current == STATE_SEND_FE;
wire state_is_wait_v_blank     = state_current == STATE_WAIT_V_BLANK;

always @(posedge clk or negedge rst_n)
    if(!rst_n)  state_current <= STATE_IDLE;
    else        state_current <= state_next;

always @(*)
    begin
        case (state_current)
            STATE_IDLE:
                state_next = fifo_line_ready & enable ? STATE_SEND_FS : STATE_IDLE;

            STATE_SEND_FS:
                state_next = enable ? (sending_fs_done ? STATE_SEND_DATA_HEADER : STATE_SEND_FS) : STATE_IDLE;

            STATE_SEND_DATA_HEADER:
                state_next = fifo_line_ready & sending_header_done ? STATE_SEND_DATA : STATE_SEND_DATA_HEADER;

            STATE_SEND_DATA:
                state_next = sending_data_done ? STATE_SEND_DATA_CRC : STATE_SEND_DATA;

            STATE_SEND_DATA_CRC:
                state_next = sending_crc_done ? (last_line ? STATE_SEND_FE : STATE_WAIT_H_BLANK) : STATE_SEND_DATA_CRC;

            STATE_WAIT_H_BLANK:
                state_next = wait_h_timeout ? STATE_SEND_DATA_HEADER : STATE_WAIT_H_BLANK;

            STATE_SEND_FE:
                state_next = sending_fe_done ? STATE_WAIT_V_BLANK : STATE_SEND_FE;

            STATE_WAIT_V_BLANK:
                state_next = wait_v_timeout ? STATE_SEND_FS : STATE_WAIT_V_BLANK;

            default:
                state_next = STATE_IDLE;

        endcase
    end

reg pix_buffer_underflow_set_reg;
wire pix_buffer_underflow_set_w;

assign pix_buffer_underflow_set_w   = state_is_send_data_header & !fifo_line_ready;
assign pix_buffer_underflow_set     = (pix_buffer_underflow_set_w ^ pix_buffer_underflow_set_reg) & pix_buffer_underflow_set_w;

always @(posedge clk or negedge rst_n)
    if(!rst_n)      pix_buffer_underflow_set_reg <= 1'b0;
    else            pix_buffer_underflow_set_reg <= pix_buffer_underflow_set_w;

/********* Timeouts *********/
reg [9:0] h_counter;
reg [23:0] v_counter;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                      h_counter <= 10'd0;
    else if(|h_counter & state_is_wait_h_blank)     h_counter <= h_counter - 10'd1;
    else                                            h_counter <= BLANK_HORIZONTAL;

assign wait_h_timeout = state_is_wait_h_blank & (h_counter == 10'd0);

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                      v_counter <= 10'd0;
    else if(|v_counter & state_is_wait_v_blank)     v_counter <= v_counter - 10'd1;
    else                                            v_counter <= BLANK_VERTICAL*(LINE_WIDTH+BLANK_HORIZONTAL);

assign wait_v_timeout = state_is_wait_v_blank & (v_counter == 10'd0);

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
assign data_bytes_number    = (state_current == STATE_SEND_DATA_HEADER) ? BYTES_IN_LINE : 16'b0;

always @(*)
    begin
        case(state_current)
            STATE_SEND_FS:
                packet_id = {2'b0, `SP_FRAME_START_CODE};

            STATE_SEND_DATA_HEADER:
                packet_id = {2'b0, DATA_TYPE};

            STATE_SEND_FE:
                packet_id = {2'b0, `SP_FRAME_END_CODE};

            default:
                packet_id = 8'b0;

        endcase
    end

/********* CRC calculation *********/

wire        clear_crc;
wire        write_crc;
wire [15:0] crc_result;

assign clear_crc            = state_is_send_data_header;

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
reg [11:0] lines_counter;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  data_size_left <= 16'b0;
    else if(clear_crc)          data_size_left <= BYTES_IN_LINE/4;
    else if(fifo_read_ack)      data_size_left <= data_size_left - 16'd1;

assign sending_data_done = (data_size_left == 16'd1) & fifo_read_ack;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                  lines_counter <= 12'b0;
    else if(lines_counter == IMAGE_HEIGHT)      lines_counter <= 12'b0;
    else if(sending_crc_done)                   lines_counter <= lines_counter + 12'd1;

assign last_line = (lines_counter == (IMAGE_HEIGHT - 12'd1));

/********* Pre output fifo *********/
reg [32:0]  data_mux;
wire        fifo_mux_write;
wire        fifo_mux_read;
wire [32:0] fifo_mux_data_out;
wire        fifo_mux_empty;
wire        fifo_mux_full;

altera_generic_fifo #(
        .WIDTH      (33),
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
            STATE_SEND_FS:
                data_mux = {1'b0, packet_header_full};

            STATE_SEND_DATA_HEADER:
                data_mux = {1'b0, packet_header_full};

            STATE_SEND_DATA:
                data_mux = {1'b0, fifo_data};

            STATE_SEND_DATA_CRC:
                data_mux = {1'b1, 16'b0, crc_result};

            STATE_SEND_FE:
                data_mux = {1'b0, packet_header_full};

            default:
                data_mux = 33'b0;

        endcase
    end

assign fifo_mux_write           = !fifo_mux_full & (state_is_send_fs | (state_is_send_data_header & fifo_line_ready) | state_is_send_data | state_is_send_data_crc | state_is_send_fe);
assign fifo_read_ack            = fifo_mux_write & state_is_send_data & fifo_not_empty;
assign sending_fs_done          = fifo_mux_write & state_is_send_fs;
assign sending_header_done      = fifo_mux_write & state_is_send_data_header;
assign sending_crc_done         = fifo_mux_write & state_is_send_data_crc;
assign sending_fe_done          = fifo_mux_write & state_is_send_fe;
assign write_crc                = fifo_read_ack;

/********* Repacker part *********/

wire fifo_out_write;
wire [3:0] input_bytes_number;
wire [3:0] output_bytes_number;
wire [3:0] shift_free_bytes;
wire [7:0] write_strobes_wide;

reg [63:0]  shift_register;
reg [3:0]   shift_register_bn;


always @(posedge clk or negedge rst_n)
    if(!rst_n)              shift_register <= 64'b0;
    else                    shift_register <= (shift_register >> ({3{fifo_out_write}} & output_bytes_number)*8) | {64{fifo_mux_read}} & ({32'b0, fifo_mux_data_out[31:0]} << (8 - shift_free_bytes)*8);

always @(posedge clk or negedge rst_n)
    if(!rst_n)              shift_register_bn <= 4'b0;
    else                    shift_register_bn <= shift_register_bn + ({3{fifo_mux_read}} & input_bytes_number) - ({3{fifo_out_write}} & output_bytes_number);

assign input_bytes_number   = fifo_mux_data_out[32] ? 4'd2 : 4'd4;
assign fifo_out_write       = !(|phy_full) & ((shift_register_bn >= lanes_number) || |shift_register_bn & fifo_mux_empty);
assign output_bytes_number  = (shift_register_bn >= lanes_number) ? lanes_number : shift_register_bn;
assign fifo_mux_read        = (shift_free_bytes >= 4'd4) & !fifo_mux_empty;
assign shift_free_bytes     = 4'd8 - shift_register_bn + (fifo_out_write ? output_bytes_number : 4'd0);
assign phy_data             = shift_register[31:0];
assign write_strobes_wide   = {4'b0, {4{fifo_out_write}}} << output_bytes_number;
assign phy_write            = write_strobes_wide[7:4];

endmodule

`endif