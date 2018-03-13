
/********************************************************************
    This module removes spaces between packets in fifo, bonding fifo data to continious stream.
    also it adds ecc and crc to packets. therefore data from this module can be directly written to serdeses

main ideas:
first packet is always short.
in last byte, where ecc will be placed we can pass:

data in fifo:
Short packet:
[31:24] Data ID
[23:8]  WC


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
reg [31:0]  temp_buffer_2;
reg [31:0]  output_buffer;
reg [15:0]  data_size;

reg         temp_buffer_1_full;
reg         temp_buffer_2_full;
reg         output_buffer_full;
reg [2:0]   data_offset;
reg [15:0]  total_data_size_reg;

wire        data_is_sp;
wire        data_is_lp;

assign fifo_read = fifo_not_empty;

always @(`DSI_CLK_RST(clk, reset_n))
    if(`DSI_RST(reset_n))   temp_buffer_1_full <= 1'b0;
    else if(fifo_read)      temp_buffer_1_full <= 1'b1;
    else                    temp_buffer_1_full <= 1'b0;

always @(`DSI_CLK_RST(clk, reset_n))
    if(`DSI_RST(reset_n))           temp_buffer_2_full <= 1'b0;
    else if(temp_buffer_1_full)     temp_buffer_2_full <= 1'b1;
    else                            temp_buffer_2_full <= 1'b0;

always @(`DSI_CLK_RST(clk, reset_n))
    if(`DSI_RST(reset_n))           output_buffer_full <= 1'b0;
    else if(temp_buffer_2_full)     output_buffer_full <= 1'b1;
    else                            output_buffer_full <= 1'b0;


/********* FIFO Output data parsing *********/

reg [15:0]      current_data_size;
reg [13:0]      fifo_read_cycles_counter;

wire [13:0]     total_fifo_read_cycles;
wire            data_in_fifo_is_header;
wire            data_is_lp;
wire            read_header;
wire            read_lp;

assign read_lp                  = fifo_output_valid && !data_in_fifo_is_header;
assign read_header              = data_in_fifo_is_header && fifo_output_valid;
assign data_in_fifo_is_header   = !(|fifo_read_cycles_counter);

always @(`DSI_CLK_RST(clk, reset_n))
    if(`DSI_RST(reset_n))                                   current_data_size <= 16'h0;
    else if(data_in_fifo_is_header && fifo_output_valid)    current_data_size <= fifo_data[23:8];      // check data size bytes order

always @(`DSI_CLK_RST(clk, reset_n))
    if(`DSI_RST(reset_n))       fifo_read_cycles_counter <= 14'h0;
    else if(read_header)        fifo_read_cycles_counter <= data_is_lp ? (fifo_data[23:10] + |fifo_data[9:8]) : 14'h0;
    else if(read_lp)            fifo_read_cycles_counter <= fifo_read_cycles_counter - 14'd1;

always @(`DSI_CLK_RST(clk, reset_n))
    if(`DSI_RST(reset_n))   fifo_output_valid <= 1'b0;
    else                    fifo_output_valid <= fifo_read;






always @(`DSI_CLK_RST(clk, reset_n))
    if(`DSI_RST(reset_n))               data_offset <= 3'b0;
    else if(data_in_fifo_is_header)     data_offset <= 3'd4 - current_data_size[1:0];


endmodule // packets_bonder
