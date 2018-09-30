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
    output  wire                                avl_mm_readdatavalid    ,
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

logic [REGISTERS_NUMBER - 1 : 0] address_hit;

generate
    for(genvar i = 0; i < REGISTERS_NUMBER; i = i + 1)
    begin
        assign address_hit[i]      = &(MEMORY_MAP[i*ADDR_WIDTH + ADDR_WIDTH -1 : i*ADDR_WIDTH] ~^ avl_mm_addr);
        assign sys_read_req[i]     = address_hit[i] & avl_mm_read;
        assign sys_write_req[i]    = address_hit[i] & avl_mm_write;
    end
endgenerate

assign avl_mm_waitrequest = (avl_mm_read && !sys_read_ready) || (avl_mm_write && !sys_write_ready);

logic           data_ready_reg;
logic [31:0]    dataread_reg;
logic           address_miss;

always_ff @(posedge clk or negedge rst_n)
    if(~rst_n)  data_ready_reg <= 1'b0;
    else        data_ready_reg <= sys_read_ready || address_miss && avl_mm_read;

always_ff @(posedge clk or negedge rst_n)
    if(~rst_n)              dataread_reg <= 32'b0;
    else if(address_miss)   dataread_reg <= 32'b0;
    else if(sys_read_ready) dataread_reg <= sys_read_data;

assign avl_mm_readdata          = dataread_reg;
assign avl_mm_readdatavalid     = data_ready_reg;
assign sys_write_data           = avl_mm_writedata;

logic [1:0] avl_mm_response_reg;
logic [1:0] sys_read_resp_reg;

assign address_miss = (avl_mm_read || avl_mm_write) && !(|address_hit);

always_ff @(posedge clk or negedge rst_n)
    if(~rst_n)                              avl_mm_response_reg <= 2'b00;
    else if(address_miss & avl_mm_read)     avl_mm_response_reg <= 2'b11;
    else if(sys_read_ready)                 avl_mm_response_reg <= sys_read_resp_reg;
    else                                    avl_mm_response_reg <= 2'b00;

assign sys_write_strb   = avl_mm_byteenable;
assign avl_mm_response  = avl_mm_response_reg;

always_ff @(posedge clk or negedge rst_n)
    if(~rst_n)                  sys_read_resp_reg <= 2'b0;
    else if(sys_read_ready)     sys_read_resp_reg <= sys_read_resp;

endmodule

`endif
