module core_axi_bridge(

    input   logic                               clk                     ,
    input   logic                               rst_n                   ,

    input   logic   [32 - 1:0]                  slv_bus_addr            ,
    input   logic                               slv_bus_read            ,
    output  logic   [32-1:0]                    slv_bus_readdata        ,
    output  logic   [1:0]                       slv_bus_response        ,
    input   logic                               slv_bus_write           ,
    input   logic   [32-1:0]                    slv_bus_writedata       ,
    input   logic   [3:0]                       slv_bus_byteenable      ,
    output  logic                               slv_bus_waitrequest     ,

    output  logic [4 - 1:0]	                    mst_axi_awid            ,
    output  logic [32 - 1:0]	                mst_axi_awaddr          ,
    output  logic [7:0]	                        mst_axi_awlen           ,
    output  logic [2:0]	                        mst_axi_awsize          ,
    output  logic [1:0]	                        mst_axi_awburst         ,
    output  logic [0:0]	                        mst_axi_awlock          ,
    output  logic [3:0]	                        mst_axi_awcache         ,
    output  logic [2:0]	                        mst_axi_awprot          ,
    output  logic [3:0]	                        mst_axi_awqos           ,
    output  logic   	                        mst_axi_awvalid         ,
    input   logic   	                        mst_axi_awready         ,

    output  logic [32 - 1:0]                    mst_axi_wdata           ,
    output  logic [32/8 - 1:0]                  mst_axi_wstrb           ,
    output  logic                               mst_axi_wlast           ,
    output  logic                               mst_axi_wvalid          ,
    input   logic  	                            mst_axi_wready          ,

    input   logic [4 - 1:0]                     mst_axi_bid             ,
    input   logic [4 - 1:0]                     mst_axi_wid             ,
    input   logic [1:0]                         mst_axi_bresp           ,
    input   logic                               mst_axi_bvalid          ,
    output  logic                               mst_axi_bready          ,

    output  logic [4 - 1:0]                     mst_axi_arid            ,
    output  logic [32 - 1:0]                    mst_axi_araddr          ,
    output  logic [7:0]                         mst_axi_arlen           ,
    output  logic [2:0]                         mst_axi_arsize          ,
    output  logic [1:0]                         mst_axi_arburst         ,
    output  logic [0:0]                         mst_axi_arlock          ,
    output  logic [3:0]                         mst_axi_arcache         ,
    output  logic [2:0]                         mst_axi_arprot          ,
    output  logic [3:0]                         mst_axi_arqos           ,
    output  logic                               mst_axi_arvalid         ,
    input   logic                               mst_axi_arready         ,

    input   logic [4 - 1:0]                     mst_axi_rid             ,
    input   logic [32 - 1:0]                    mst_axi_rdata           ,
    input   logic [1:0]                         mst_axi_rresp           ,
    input   logic                               mst_axi_rlast           ,
    input   logic                               mst_axi_rvalid          ,
    output  logic                               mst_axi_rready
);


logic [32-1:0]  r_mst_axi_awaddr;
logic           r_mst_axi_awvalid;

logic [32-1:0]  r_mst_axi_wdata;
logic [4-1:0]   r_mst_axi_wstrb;
logic           r_mst_axi_wlast;
logic           r_mst_axi_wvalid;

logic [32-1:0]  r_mst_axi_araddr;
logic           r_mst_axi_arvalid;

logic [32-1:0]  r_mst_axi_rdata;
logic           r_mst_axi_rready;

logic           r_slv_bus_waitrequest;

assign mst_axi_awid         = 4'h0;
assign mst_axi_awlen        = 8'h00;
assign mst_axi_awsize       = 3'b010;
assign mst_axi_awburst      = 2'b00;
assign mst_axi_awlock       = 2'b00;
assign mst_axi_awcache      = 4'b0000;
assign mst_axi_awprot       = 3'b000;
assign mst_axi_awqos        = 4'b000;

assign mst_axi_awaddr       = r_mst_axi_awaddr;
assign mst_axi_awvalid      = r_mst_axi_awvalid;
assign mst_axi_wlast        = 1'b1;
assign mst_axi_bvalid       = 1'b1;

assign mst_axi_araddr       = r_mst_axi_araddr;
assign mst_axi_arvalid      = r_mst_axi_arvalid;
assign slv_bus_readdata     = r_mst_axi_rdata;
assign slv_bus_waitrequest  = r_slv_bus_waitrequest;

assign mst_axi_arid         = 4'h0;
assign mst_axi_arlen        = 8'h00;
assign mst_axi_arsize       = 3'b010;
assign mst_axi_arburst      = 2'b00;
assign mst_axi_arlock       = 2'b00;
assign mst_axi_arcache      = 4'b0000;
assign mst_axi_arprot       = 3'b000;
assign mst_axi_arqos        = 4'b000;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)              r_mst_axi_awaddr <= 32'b0;
    else if(slv_bus_write)  r_mst_axi_awaddr <= slv_bus_addr;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  r_mst_axi_awvalid <= 1'b0;
    else if(mst_axi_awready)    r_mst_axi_awvalid <= 1'b0;
    else if(slv_bus_write)      r_mst_axi_awvalid <= 1'b1;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)              r_mst_axi_wdata <= 1'b0;
    else if(slv_bus_write)  r_mst_axi_wdata <= slv_bus_writedata;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)              r_mst_axi_wstrb <= 1'b0;
    else if(slv_bus_write)  r_mst_axi_wstrb <= slv_bus_byteenable;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)              r_mst_axi_wvalid <= 1'b0;
    else if(mst_axi_wready) r_mst_axi_wvalid <= 1'b0;
    else if(slv_bus_write)  r_mst_axi_wvalid <= 1'b1;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)              r_mst_axi_araddr <= 32'b0;
    else if(slv_bus_read)   r_mst_axi_araddr <= slv_bus_addr;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  r_mst_axi_arvalid <= 1'b0;
    else if(mst_axi_arready)    r_mst_axi_arvalid <= 1'b0;
    else if(slv_bus_read)       r_mst_axi_arvalid <= 1'b1;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  r_mst_axi_rready <= 1'b0;
    else if(mst_axi_rvalid)     r_mst_axi_rready <= 1'b0;
    else if(slv_bus_read)       r_mst_axi_rready <= 1'b1;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  r_mst_axi_rdata <= 32'b0;
    else if(mst_axi_rvalid)     r_mst_axi_rdata <= mst_axi_rdata;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)                                  r_slv_bus_waitrequest <= 1'b1;
    else if(mst_axi_rvalid || mst_axi_wready)   r_slv_bus_waitrequest <= 1'b0;
    else                                        r_slv_bus_waitrequest <= 1'b1;
end

endmodule