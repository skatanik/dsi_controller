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
logic addr_rst;
logic [32-1:0] transfers_number;
logic [32-1:0] transfers_counter;

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
assign addr_rst                 = mst_axi_arready

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
    else if(mst_axi_rready)                     r_mst_axi_arvalid <= 1'b0;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)                                                              request_counter <= 'b0;
    else if(dma_enable && mst_axi_rready && rqst_enable)                    request_counter <= request_counter + 1;
    else if(mst_axi_rready && !request_counter_empty && mst_axi_rlast)      request_counter <= request_counter - 1;
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