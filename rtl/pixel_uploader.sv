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
    output wire [32:0]      avl_mm_addr                 ,
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
    input  wire             transform_data              ,   // 0 - write data from memory directly to fifo, 1 - transform 4 bytes to 4, removing empty 3rd byte in memory data

    output wire             active

    );

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

assign next_state_idle     = (state_current == STATE_REPACK_DATA) && (state_next == STATE_IDLE);
assign next_state_read     = (state_current == STATE_IDLE) && (state_next == STATE_READ_DATA);
assign next_state_repack   = (state_current == STATE_READ_DATA) && (state_next == STATE_REPACK_DATA);

always_ff @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))   state_current <= STATE_IDLE;
    else                state_current <= state_next;

always_comb
    begin
        case (state_current)
            STATE_IDLE:
                state_next = enable && fifo_write_available ? STATE_READ_DATA : STATE_IDLE;

            STATE_READ_DATA:
                state_next = read_done ? STATE_REPACK_DATA : STATE_READ_DATA;

            STATE_REPACK_DATA:
                state_next = repack_done ? STATE_IDLE : STATE_REPACK_DATA;

            default :
                state_next = STATE_IDLE;
        endcase
    end

/********* Data reader *********/
logic enable_reg;

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))   enable_reg <= 1'b0;
    else                enable_reg <= enable;

logic           initial_write_address;
logic [31:0]    base_address_reg;

assign initial_write_address = (enable_reg ^ enable) & enable;

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))                   base_address_reg <= 'b0;
    else if(initial_write_address)      base_address_reg <= base_address;

logic [31:0]    current_addess;
logic           reset_current_address;

assign reset_current_address = next_state_idle & (current_addess == (base_address_reg + total_size));

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))                   current_addess <= 'b0;
    else if(reset_current_address)      current_addess <= base_address_reg;
    else if(initial_write_address)      current_addess <= base_address;
    else if(next_state_repack)          current_addess <= current_addess + 32'd32 * (word_mode ? 32'd1 : 32'd4);

/********* Repacker 32 to 4 *********/


endmodule

`undef CLK_RST
`undef RST

`endif
