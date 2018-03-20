
/********************************************************************
    This module removes spaces between packets in fifo, bonding fifo data to continious stream.
    also it adds ecc and crc to packets. therefore data from this module can be directly written to serdeses

main ideas:
first packet is always short.
in last byte, where ecc will be placed we can pass:

data in fifo:
Short packet:
[7:0] Data ID
[23:8]  WC
[31:24] 1 bit packet type long or short, 1 bit speed



********************************************************************/

module packets_bonder
    (
        input  wire             clk             ,
        input  wire             reset_n         ,

/********* input data *********/
        input  wire [31:0]      fifo_data       ,
        input  wire             fifo_not_empty  ,
        output wire             fifo_read       ,

/********* output data *********/
        output wire [31:0]      output_data     ,
        output wire             ready           ,
        input  wire             read_data
    );

reg [31:0]  temp_buffer_1;
reg         temp_buffer_1_full;

/********* Adding crc and ecc to fifo data, according to packet type *********/

reg         data_is_header;
reg [15:0]  reading_cycles_left;
reg         fifo_data_valid;
reg         skip_fifo_reading_reg;
reg [1:0]   bytes_in_last_word;
reg         one_cycle_for_crc;
reg [15:0]  data_bytes_left;

wire        packet_speed;
wire        packet_type_lp;
wire        last_packet_word;
wire        read_lp_header;
wire        skip_fifo_reading;
wire [15:0] crc_result;
wire [15:0] crc_result_reg;
wire [47:0] wide_crc_result;
wire [31:0] crc_res;
wire [2:0]  bytes_in_current_word;
wire        lp_reading;
wire [31:0] header_with_ecc;
wire [7:0]  ecc_res;

ecc_calc ecc_calc_0
(
    .data           (fifo_data[23:0]    ),
    .ecc_result     (ecc_res            )
);

assign header_with_ecc      = {ecc_res, fifo_data[23:0]};

crc_calculator crc_calculator_0
(
    .clk                (clk                                ),
    .reset_n            (reset_n                            ),

    .clear              (read_lp_header                     ),   // reset crc
    .data_write         (fifo_data_valid && !data_is_header ),   // latch crc
    .bytes_number       (bytes_in_current_word              ),   // bytes number. 0 means that only the first byte from data_input will be used. 1 means that first 2 bytes from data_input will be used etc.
    .data_input         (fifo_data                          ),

    .crc_output_curr    (crc_result                         ),
    .crc_output_prev    (crc_result_reg                     )
);

assign bytes_in_current_word    = (|data_bytes_left[15:2] ? 3'd4 : data_bytes_left[1:0]);
assign last_packet_word         = reading_cycles_left == 16'd1;
assign packet_type_lp           = (fifo_data[7:2] == 6'hE) || (fifo_data[7:2] == 6'h9);
assign packet_speed             = fifo_data[31] && data_is_header;
assign read_lp_header           = fifo_data_valid && packet_type_lp && data_is_header;
assign lp_reading               = |reading_cycles_left;

// calculate left data
always @(`DSI_CLK_RST(clk, reset_n))
    if(`DSI_RST(reset_n))       data_bytes_left <= 16'd0;
    else if(read_lp_header)     data_bytes_left <= fifo_data[23:8];
    else if(lp_reading)         data_bytes_left <= data_bytes_left - bytes_in_current_word;

always @(`DSI_CLK_RST(clk, reset_n))
    if(`DSI_RST(reset_n))                                                       data_is_header <= 1'b1;
    else if(read_lp_header && |fifo_data[23:8])                                 data_is_header <= 1'b0;
    else if(last_packet_word && fifo_data_valid && !skip_fifo_reading_reg)      data_is_header <= 1'b1;
    else if(skip_fifo_reading)                                                  data_is_header <= 1'b1;

always @(`DSI_CLK_RST(clk, reset_n))
    if(`DSI_RST(reset_n))   fifo_data_valid <= 1'b0;
    else                    fifo_data_valid <= fifo_read;

wire [16:0] total_data_size;
// calc total data bytes
assign total_data_size = fifo_data[23:8] + 17'd2;

// calc amounts of read from fifo cycles
always @(`DSI_CLK_RST(clk, reset_n))
    if(`DSI_RST(reset_n))       reading_cycles_left <= 16'd0;
    else if(read_lp_header)     reading_cycles_left <= total_data_size[16:2] + |total_data_size[1:0];
    else if(lp_reading)         reading_cycles_left <= reading_cycles_left - 16'd1;

// set this reg when last cycle is writing crc data
always @(`DSI_CLK_RST(clk, reset_n))
    if(`DSI_RST(reset_n))                                                       one_cycle_for_crc <= 1'b0;
    else if( (total_data_size[16:2] != fifo_data[16:2]) && read_lp_header)      one_cycle_for_crc <= 1'b1;
    else if(last_packet_word)                                                   one_cycle_for_crc <= 1'b0;

// signal to stop fifo reading
assign skip_fifo_reading = last_packet_word && one_cycle_for_crc;

// remember bytes in last reading from fifo cycle
always @(`DSI_CLK_RST(clk, reset_n))
    if(`DSI_RST(reset_n))       bytes_in_last_word <= 2'b0;
    else if(read_lp_header)     bytes_in_last_word <= fifo_data[9:8];

wire add_crc_to_data;
wire add_one_byte_crc;
wire add_crc_only;

assign add_crc_to_data      = (bytes_in_last_word == 2'd1) || (bytes_in_last_word == 2'd2);
assign add_one_byte_crc     = bytes_in_last_word == 2'd3;
assign add_crc_only         = bytes_in_last_word == 2'b0;

wire write_tb_2;
wire write_tb_1;

assign write_tb_2   = (reading_cycles_left == 16'd2);
assign write_tb_1   = (reading_cycles_left == 16'd1);

/*
if we write header then we write header with ecc - 4 bytes
if we write second from the end data word and there is only 3 bytes left then we add one crc byte - 4 bytes in total
if we write last data word and there are only 3 bytes left then we add one crc byte - 4 bytes in total
if we write last data word and there are 1 or 2 bytes left, then we add 2 bytes of crc - 3 bytes in total
if we write last data word and there is only crc bytes left, then we write it - 2 bytes in total
if we write last data word and there is only one byte crc left, then we write it - 1 bytes in total
*/
always @(`DSI_CLK_RST(clk, reset_n))
    if(`DSI_RST(reset_n))                       temp_buffer_1 <= 32'h0;
    else if(data_is_header && fifo_data_valid)  temp_buffer_1 <= header_with_ecc;
    else if(write_tb_2 && add_one_byte_crc)     temp_buffer_1 <= fifo_data | crc_result[7:0];
    else if(write_tb_1 && add_crc_to_data)      temp_buffer_1 <= fifo_data | (crc_result << bytes_in_last_word * 8);
    else if(write_tb_1 && add_crc_only)         temp_buffer_1 <= {16'd0, crc_result_reg}
    else if(write_tb_1 && add_one_byte_crc)     temp_buffer_1 <= {24'd0, crc_result_reg[15:8]}
    else if(lp_reading )                        temp_buffer_1 <= fifo_data;

wire write_temp_buffer;

assign write_temp_buffer    = data_is_header || lp_reading;

always @(`DSI_CLK_RST(clk, reset_n))
    if(`DSI_RST(reset_n))   temp_buffer_1_full <= 1'b0;
    else if(fifo_read)      temp_buffer_1_full <= write_temp_buffer;

reg [2:0] bytes_in_temp_buffer;

always @(`DSI_CLK_RST(clk, reset_n))
    if(`DSI_RST(reset_n))                       bytes_in_temp_buffer <= 3'b0;
    else if(data_is_header && fifo_data_valid)  bytes_in_temp_buffer <= 3'd4;
    else if(write_tb_2 && add_one_byte_crc)     bytes_in_temp_buffer <= 3'd4;
    else if(write_tb_1 && add_crc_to_data)      bytes_in_temp_buffer <= bytes_in_last_word + 3'd2;
    else if(write_tb_1 && add_crc_only)         bytes_in_temp_buffer <= 3'd2;
    else if(write_tb_1 && add_one_byte_crc)     bytes_in_temp_buffer <= 3'd1;
    else if(lp_reading )                        bytes_in_temp_buffer <= 3'd4;

endmodule // packets_bonder
