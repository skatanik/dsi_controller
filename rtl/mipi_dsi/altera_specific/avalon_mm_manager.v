`ifndef AVALON_MM_MANAGER
`define AVALON_MM_MANAGER

/********************************************************************
            Module operates with 32 bits words only.
            Module does not support burst transactions.
            Read transactions are only full 32 bit word.
            Module does not support write responses
********************************************************************/

module avalon_mm_manager
    #(
        parameter                                        REGISTERS_NUMBER    = 4,
        parameter                                        ADDR_WIDTH          = 4,
        parameter [REGISTERS_NUMBER*ADDR_WIDTH -1 : 0]   MEMORY_MAP          = 0
    )(

    input   wire                                clk                     ,
    input   wire                                rst_n                   ,

    /********* Avalon MM Slave iface *********/
    input   wire [ADDR_WIDTH - 1:0]             avl_mm_addr             ,

    input   wire                                avl_mm_read             ,
    output  wire [31:0]                         avl_mm_readdata         ,
    output  wire [1:0]                          avl_mm_response         ,

    input   wire                                avl_mm_write            ,
    input   wire [31:0]                         avl_mm_writedata        ,
    input   wire [3:0]                          avl_mm_byteenable       ,

    output  wire                                avl_mm_waitrequest      ,

    /********* sys iface *********/
    output  wire [REGISTERS_NUMBER - 1 : 0]     sys_read_req            ,
    input   wire                                sys_read_ready          ,
    input   wire [31:0]                         sys_read_data           ,
    input   wire [1:0]                          sys_read_resp           ,

    input   wire                                sys_write_ready         ,
    output  wire [REGISTERS_NUMBER - 1 : 0]     sys_write_req           ,
    output  wire [3:0]                          sys_write_strb          ,
    output  wire [31:0]                         sys_write_data

);

wire [REGISTERS_NUMBER - 1 : 0] address_hit;

genvar i;

generate
    for(i = 0; i < REGISTERS_NUMBER; i = i + 1)
    begin: addr_matching
        assign address_hit[i]      = &(MEMORY_MAP[i*ADDR_WIDTH + ADDR_WIDTH -1 : i*ADDR_WIDTH] ~^ avl_mm_addr);
        assign sys_read_req[i]     = address_hit[i] & avl_mm_read;
        assign sys_write_req[i]    = address_hit[i] & avl_mm_write;
    end
endgenerate

wire          address_miss;

assign avl_mm_readdata          = sys_read_ready ? sys_read_data : 32'b0;
assign sys_write_data           = avl_mm_writedata;

reg [1:0] avl_mm_response_reg;
reg [1:0] sys_read_resp_reg;

assign address_miss = (avl_mm_read || avl_mm_write) && !(|address_hit);
assign avl_mm_waitrequest = (avl_mm_read && !sys_read_ready) || (avl_mm_write && (!sys_write_ready && !address_miss));

always @(posedge clk or negedge rst_n)
    if(~rst_n)                              avl_mm_response_reg <= 2'b00;
    else if(address_miss & avl_mm_read)     avl_mm_response_reg <= 2'b11;
    else if(sys_read_ready)                 avl_mm_response_reg <= sys_read_resp_reg;
    else                                    avl_mm_response_reg <= 2'b00;

assign sys_write_strb   = avl_mm_byteenable;
assign avl_mm_response  = avl_mm_response_reg;

always @(posedge clk or negedge rst_n)
    if(~rst_n)                  sys_read_resp_reg <= 2'b0;
    else if(sys_read_ready)     sys_read_resp_reg <= sys_read_resp;

endmodule

`endif