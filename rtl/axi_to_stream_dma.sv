module axi_to_stream_dma #(
    parameter ADDR_WIDTH = 24,
    parameter BURST_SIZE = 128,
    parameter MAX_PENDING_RQST_LOG = 2;
)(
    input   logic                               clk                         ,
    input   logic                               rst_n                       ,

    /********* AXI read channels *********/
    output  logic [4 - 1:0]                     mst_axi_arid                ,
    output  logic [ADDR_WIDTH - 1:0]            mst_axi_araddr              ,
    output  logic [7:0]                         mst_axi_arlen               ,
    output  logic [2:0]                         mst_axi_arsize              ,
    output  logic [1:0]                         mst_axi_arburst             ,
    output  logic [0:0]                         mst_axi_arlock              ,
    output  logic [3:0]                         mst_axi_arcache             ,
    output  logic [2:0]                         mst_axi_arprot              ,
    output  logic [3:0]                         mst_axi_arqos               ,
    output  logic                               mst_axi_arvalid             ,
    input   logic                               mst_axi_arready             ,

    input   logic [4 - 1:0]                     mst_axi_rid                 ,
    input   logic [32 - 1:0]                    mst_axi_rdata               ,
    input   logic [1:0]                         mst_axi_rresp               ,
    input   logic                               mst_axi_rlast               ,
    input   logic                               mst_axi_rvalid              ,
    output  logic                               mst_axi_rready              ,

    /*********  Stream out *********/
    output  logic [31:0]                        st_data                     ,
    output  logic                               st_valid                    ,
    output  logic                               st_endofpacket              ,
    output  logic                               st_startofpacket            ,
    input   logic                               st_ready                    ,

    /********* MM iface *********/
    input   logic [4:0]                         ctrl_address                ,
    input   logic                               ctrl_read                   ,
    output  logic [31:0]                        ctrl_readdata               ,
    output  logic [1:0]                         ctrl_response               ,
    input   logic                               ctrl_write                  ,
    input   logic [31:0]                        ctrl_writedata              ,
    input   logic [3:0]                         ctrl_byteenable             ,
    output  logic                               ctrl_waitrequest
);

localparam REGISTERS_NUMBER     = 3;
localparam ADDR_WIDTH           = 4;
localparam MEMORY_MAP           = {
                                    4'h08,
                                    4'h04,
                                    4'h00
                                    };

wire [REGISTERS_NUMBER - 1 : 0] sys_read_req;
wire                            sys_read_ready;
wire [31:0]                     sys_read_data;
wire [1:0]                      sys_read_resp;
wire                            sys_write_ready;
wire [REGISTERS_NUMBER - 1 : 0] sys_write_req;
wire [3:0]                      sys_write_strb;
wire [31:0]                     sys_write_data;

avalon_mm_manager  #(
        .REGISTERS_NUMBER (REGISTERS_NUMBER     ),
        .ADDR_WIDTH       (ADDR_WIDTH           ),
        .MEMORY_MAP       (MEMORY_MAP           )
    ) avalon_mm_manager_0 (

    .clk                     (clk                           ),
    .rst_n                   (rst_n                         ),

    /********* Avalon MM Slave iface *********/
    .avl_mm_addr             (avl_mm_addr                   ),

    .avl_mm_read             (avl_mm_read                   ),
    .avl_mm_readdata         (avl_mm_readdata               ),
    .avl_mm_response         (avl_mm_response               ),

    .avl_mm_write            (avl_mm_write                  ),
    .avl_mm_writedata        (avl_mm_writedata              ),
    .avl_mm_byteenable       (avl_mm_byteenable             ),

    .avl_mm_waitrequest      (avl_mm_waitrequest            ),

    /********* sys iface *********/
    .sys_read_req            (sys_read_req                  ),
    .sys_read_ready          (sys_read_ready                ),
    .sys_read_data           (sys_read_data                 ),
    .sys_read_resp           (sys_read_resp                 ),

    .sys_write_ready         (sys_write_ready               ),
    .sys_write_req           (sys_write_req                 ),
    .sys_write_strb          (sys_write_strb                ),
    .sys_write_data          (sys_write_data                )
);

assign sys_read_resp = 2'b00;
assign sys_write_ready = 1'b1;
assign sys_read_ready = 1'b1;
assign sys_read_data = 'b0;

logic [ADDR_WIDTH-1:0] start_addr;
logic [ADDR_WIDTH-1:0] curr_addr;
logic [30-1:0] words_number;
logic [30-1:0] words_number_cnt;
logic dma_enable;
logic addr_rst;
logic [MAX_PENDING_RQST_LOG:0] request_counter;
logic r_mst_axi_arvalid;
logic request_counter_empty;
logic rqst_enable;
logic r_st_endofpacket;
logic r_st_startofpacket;
logic [32-1:0] transfers_number;
logic [32-1:0] transfers_counter;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  start_addr <= 'b0;
    else if(sys_write_req[0])   start_addr <= sys_write_data;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  words_number <= 'b0;
    else if(sys_write_req[1])   words_number <= sys_write_data;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  dma_enable <= 'b0;
    else if(sys_write_req[2])   dma_enable <= sys_write_data[0];
end

assign mst_axi_arlen        = BURST_SIZE - 1;
assign mst_axi_arburst      = 2'b01;
assign mst_axi_arid         = 4'h0;
assign mst_axi_arsize       = 3'b010;
assign mst_axi_arlock       = 2'b00;
assign mst_axi_arcache      = 4'b0000;
assign mst_axi_arprot       = 3'b000;
assign mst_axi_arqos        = 4'b000;
assign st_data              = mst_axi_rdata;
assign st_valid             = mst_axi_rvalid;
assign mst_axi_rready       = st_ready;
assign st_endofpacket       = r_st_endofpacket;
assign st_startofpacket     = r_st_startofpacket;
assign transfers_number     = words_number >> $clog2(BURST_SIZE);

assign rqst_enable              = !request_counter[MAX_PENDING_RQST_LOG];
assign request_counter_empty    = (request_counter == 0);
assign addr_rst                 = mst_axi_arready && (transfers_counter == (transfers_number - 1))

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  transfers_counter <= 'b0;
    else if(addr_rst)           transfers_counter <= 'b0';
    else if(mst_axi_arready)    transfers_counter <= transfers_counter + 1;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  curr_addr <= 'b0;
    else if(addr_rst)           curr_addr <= start_addr;
    else if(mst_axi_arready)    curr_addr <= curr_addr + (BURST_SIZE*4);
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)                                  r_mst_axi_arvalid <= 1'b0;
    else if(dma_enable && rqst_enable)          r_mst_axi_arvalid <= 1'b1;
    else if(mst_axi_arready)                    r_mst_axi_arvalid <= 1'b0;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)                                                              request_counter <= 'b0;
    else if(dma_enable && mst_axi_rready && rqst_enable)                    request_counter <= request_counter + 1;
    else if(mst_axi_arready && !request_counter_empty && mst_axi_rlast)     request_counter <= request_counter - 1;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)                                                                              words_number_cnt <= 'b0;
    else if(mst_axi_rvalid && mst_axi_rready && (words_number_cnt == (words_number - 1)))   words_number_cnt <= 'b0;
    else if(mst_axi_rvalid && mst_axi_rready)                                               words_number_cnt <= words_number_cnt + 1;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)                                          r_st_endofpacket <= 1'b0;
    else if(words_number_cnt == (words_number - 1))     r_st_endofpacket <= 1'b1;
    else if(mst_axi_rvalid && mst_axi_rready)           r_st_endofpacket <= 1'b0;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  r_st_startofpacket <= 1'b1;
    else if(st_valid)           r_st_startofpacket <= 1'b0;
    else if(r_st_endofpacket)   r_st_startofpacket <= 1'b1;
end


endmodule