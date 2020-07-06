/********************************************************************
            Simple DMA. Reads data from certain address in memory.
            Transform if necessary 4 byte per pixel format to 3 bytes per pixel
            Pixels amount should be multiple of 4.
********************************************************************/

`ifndef PIXEL_UPLOADER
`define PIXEL_UPLOADER

`define CLK_RST(clk, rst_n)   posedge clk, negedge rst_n
`define RST(rst_n)   !rst_n

module pixel_uploader (

    input   wire            clk                         ,
    input   wire            rst_n                       ,

    /********* Avalon MM Master read-only iface *********/
    output wire [31:0]      avl_mm_addr                 ,
    output wire             avl_mm_read                 ,

    input  wire [255:0]     avl_mm_readdata             ,
    input  wire             avl_mm_readdatavalid        ,
    input  wire [1:0]       avl_mm_response             ,
    input  wire             avl_mm_waitrequest          ,

    /********* Pixel FIFO iface *********/
    output wire             pix_fifo_write              ,
    output wire [31:0]      pix_fifo_data               ,

    input  wire             pix_fifo_full               ,
    input  wire [9:0]       pix_fifo_usedw              ,

    /********* Input control *********/
    input  wire             enable                      ,
    input  wire             word_mode                   ,   // 1 - word addressing, 0 - byte addressing
    input  wire [31:0]      base_address                ,
    input  wire [31:0]      total_size                  ,
    input  wire [9:0]       pix_fifo_threshold          ,
    input  wire             transform_data              ,   // 0 - write data from memory directly to fifo, 1 - transform 4 bytes to 4, removing empty 3rd byte in memory data

    output wire             read_error_w                ,
    output wire             active

    );

/********* Vars *********/

logic read_error;
logic read_error_reg;

/********* FSM *********/

enum logic [1:0]
{
    STATE_IDLE,
    STATE_READ_DATA,
    STATE_REPACK_DATA
} state_current, state_next;

logic next_state_idle;
logic next_state_read;
logic next_state_repack;
logic fifo_write_available;
logic repack_done;
logic read_done;

assign next_state_idle     = (state_current == STATE_REPACK_DATA) && (state_next == STATE_IDLE);
assign next_state_read     = (state_current == STATE_IDLE) && (state_next == STATE_READ_DATA);
assign next_state_repack   = (state_current == STATE_READ_DATA) && (state_next == STATE_REPACK_DATA);

always_ff @(`CLK_RST(clk, rst_n))
    if(`RST(rst_n))     state_current <= STATE_IDLE;
    else                state_current <= state_next;

/********* Read memory, repack data, write it to fifo, repeat *********/

always_comb
    begin
        case (state_current)
            STATE_IDLE:
                state_next = enable && fifo_write_available && !read_error_reg ? STATE_READ_DATA : STATE_IDLE;

            STATE_READ_DATA:
                state_next = read_error ? STATE_IDLE : (read_done ? STATE_REPACK_DATA : STATE_READ_DATA);

            STATE_REPACK_DATA:
                state_next = repack_done ? STATE_IDLE : STATE_REPACK_DATA;

            default :
                state_next = STATE_IDLE;
        endcase
    end

/********* Data reader *********/
logic enable_reg;

always @(`CLK_RST(clk, rst_n))
    if(`RST(rst_n))     enable_reg <= 1'b0;
    else                enable_reg <= enable;

logic           initial_write_address;
logic [31:0]    base_address_reg;

assign initial_write_address = (enable_reg ^ enable) & enable;

always @(`CLK_RST(clk, rst_n))
    if(`RST(rst_n))                     base_address_reg <= 'b0;
    else if(initial_write_address)      base_address_reg <= base_address;

logic [31:0]    current_addess;
logic           reset_current_address;

assign reset_current_address = next_state_idle & (current_addess == (base_address_reg + total_size));

always @(`CLK_RST(clk, rst_n))
    if(`RST(rst_n))                     current_addess <= 'b0;
    else if(reset_current_address)      current_addess <= base_address_reg;
    else if(initial_write_address)      current_addess <= base_address;
    else if(next_state_repack)          current_addess <= current_addess + (word_mode ? 32'd8 : 32'd32);

logic avl_mm_read_reg;
logic data_ready;
logic data_ready_delayed;

assign data_ready = avl_mm_read_reg & !avl_mm_waitrequest;

always @(`CLK_RST(clk, rst_n))
    if(`RST(rst_n))             avl_mm_read_reg <= 1'b0;
    else if(next_state_read)    avl_mm_read_reg <= 1'b1;
    else if(data_ready)         avl_mm_read_reg <= 1'b0;

always @(`CLK_RST(clk, rst_n))
    if(`RST(rst_n))     data_ready_delayed <= 1'b0;
    else                data_ready_delayed <= data_ready;

logic read_data;

assign read_error_w = read_error;
assign read_error   = avl_mm_readdatavalid & (|avl_mm_response) || data_ready_delayed & !avl_mm_readdatavalid;
assign read_data    = data_ready_delayed & avl_mm_readdatavalid & !(|avl_mm_response);
assign read_done    = read_data;

always @(`CLK_RST(clk, rst_n))
    if(`RST(rst_n))         read_error_reg <= 1'b0;
    else if(read_error)     read_error_reg <= 1'b1;
    else if(!enable)        read_error_reg <= 1'b0;

logic [255:0] data_reg;

always @(`CLK_RST(clk, rst_n))
    if(`RST(rst_n))         data_reg <= 'b0;
    else if(read_data)      data_reg <= avl_mm_readdata;

/********* Repacker 32 to 4 *********/
/********* remap 256 bit to 192 bit vector *********/

logic [191:0] data_vector_remapped;

genvar i, j;
generate
    for(i = 0; i < 8; i = i + 1)
    begin: remap
        for(j=i*4 - i; j < i*4 - i + 3; j = j + 1)
            assign data_vector_remapped[8*j+:8] = data_reg[(j+i)*8+:8];
    end
endgenerate

logic [2:0] words_counter;
logic       write_fifo_reg;

always @(`CLK_RST(clk, rst_n))
    if(`RST(rst_n))             words_counter <= 2'b0;
    else if(next_state_idle)    words_counter <= 2'b0;
    else if(write_fifo_reg)     words_counter <= words_counter + 2'd1;

logic [31:0] fifo_register;

always @(`CLK_RST(clk, rst_n))
    if(`RST(rst_n))             fifo_register <= 32'b0;
    else if(write_fifo_reg)     fifo_register <= transform_data ? data_vector_remapped[32*words_counter+:32] : data_reg[32*words_counter+:32];

assign write_fifo_reg = (state_current == STATE_REPACK_DATA) && (words_counter <= (transform_data ? 5'd5 : 5'd7)) && (!pix_fifo_full);

logic fifo_buff_write;

always @(`CLK_RST(clk, rst_n))
    if(`RST(rst_n))             fifo_buff_write <= 1'b0;
    else if(!pix_fifo_full)     fifo_buff_write <= write_fifo_reg;

assign pix_fifo_write           = fifo_buff_write & (!pix_fifo_full);
assign pix_fifo_data            = fifo_register;

assign repack_done              = (state_current == STATE_REPACK_DATA) && (words_counter == (transform_data ? 5'd5 : 5'd7));
assign fifo_write_available     = pix_fifo_usedw < pix_fifo_threshold;
assign active                   = state_current != STATE_IDLE;
assign avl_mm_addr              = current_addess;
assign avl_mm_read              = avl_mm_read_reg;

endmodule

`undef CLK_RST
`undef RST

`endif
