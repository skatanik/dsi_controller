module core_axi_bridge(

    input   wire                               clk                     ,
    input   wire                               rst_n                   ,

    input   wire   [32 - 1:0]                  slv_bus_addr            ,
    input   wire                               slv_bus_read            ,
    output  wire   [32-1:0]                    slv_bus_readdata        ,
    output  wire   [1:0]                       slv_bus_response        ,
    input   wire                               slv_bus_write           ,
    input   wire   [32-1:0]                    slv_bus_writedata       ,
    input   wire   [3:0]                       slv_bus_byteenable      ,
    output  wire                               slv_bus_waitrequest     ,

    output  wire [4 - 1:0]	                    mst_axi_awid            ,
    output  wire [32 - 1:0]	                mst_axi_awaddr          ,
    output  wire [7:0]	                        mst_axi_awlen           ,
    output  wire [2:0]	                        mst_axi_awsize          ,
    output  wire [1:0]	                        mst_axi_awburst         ,
    output  wire [0:0]	                        mst_axi_awlock          ,
    output  wire [3:0]	                        mst_axi_awcache         ,
    output  wire [2:0]	                        mst_axi_awprot          ,
    output  wire [3:0]	                        mst_axi_awqos           ,
    output  wire   	                        mst_axi_awvalid         ,
    input   wire   	                        mst_axi_awready         ,

    output  wire [32 - 1:0]                    mst_axi_wdata           ,
    output  wire [32/8 - 1:0]                  mst_axi_wstrb           ,
    output  wire                               mst_axi_wlast           ,
    output  wire                               mst_axi_wvalid          ,
    input   wire  	                            mst_axi_wready          ,

    input   wire [4 - 1:0]                     mst_axi_bid             ,
    input   wire [4 - 1:0]                     mst_axi_wid             ,
    input   wire [1:0]                         mst_axi_bresp           ,
    input   wire                               mst_axi_bvalid          ,
    output  wire                               mst_axi_bready          ,

    output  wire [4 - 1:0]                     mst_axi_arid            ,
    output  wire [32 - 1:0]                    mst_axi_araddr          ,
    output  wire [7:0]                         mst_axi_arlen           ,
    output  wire [2:0]                         mst_axi_arsize          ,
    output  wire [1:0]                         mst_axi_arburst         ,
    output  wire [0:0]                         mst_axi_arlock          ,
    output  wire [3:0]                         mst_axi_arcache         ,
    output  wire [2:0]                         mst_axi_arprot          ,
    output  wire [3:0]                         mst_axi_arqos           ,
    output  wire                               mst_axi_arvalid         ,
    input   wire                               mst_axi_arready         ,

    input   wire [4 - 1:0]                     mst_axi_rid             ,
    input   wire [32 - 1:0]                    mst_axi_rdata           ,
    input   wire [1:0]                         mst_axi_rresp           ,
    input   wire                               mst_axi_rlast           ,
    input   wire                               mst_axi_rvalid          ,
    output  wire                               mst_axi_rready
);


reg [32-1:0]  r_mst_axi_awaddr;
reg           r_mst_axi_awvalid;

reg [32-1:0]  r_mst_axi_wdata;
reg [4-1:0]   r_mst_axi_wstrb;
reg           r_mst_axi_wlast;
reg           r_mst_axi_wvalid;

reg [32-1:0]  r_mst_axi_araddr;
reg           r_mst_axi_arvalid;

reg [32-1:0]  r_mst_axi_rdata;
reg           r_mst_axi_rready;

reg           r_slv_bus_waitrequest;

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

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)              r_mst_axi_awaddr <= 32'b0;
    else if(slv_bus_write)  r_mst_axi_awaddr <= slv_bus_addr;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  r_mst_axi_awvalid <= 1'b0;
    else if(mst_axi_awready)    r_mst_axi_awvalid <= 1'b0;
    else if(slv_bus_write)      r_mst_axi_awvalid <= 1'b1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)              r_mst_axi_wdata <= 1'b0;
    else if(slv_bus_write)  r_mst_axi_wdata <= slv_bus_writedata;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)              r_mst_axi_wstrb <= 1'b0;
    else if(slv_bus_write)  r_mst_axi_wstrb <= slv_bus_byteenable;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)              r_mst_axi_wvalid <= 1'b0;
    else if(mst_axi_wready) r_mst_axi_wvalid <= 1'b0;
    else if(slv_bus_write)  r_mst_axi_wvalid <= 1'b1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)              r_mst_axi_araddr <= 32'b0;
    else if(slv_bus_read)   r_mst_axi_araddr <= slv_bus_addr;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  r_mst_axi_arvalid <= 1'b0;
    else if(mst_axi_arready)    r_mst_axi_arvalid <= 1'b0;
    else if(slv_bus_read)       r_mst_axi_arvalid <= 1'b1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  r_mst_axi_rready <= 1'b0;
    else if(mst_axi_rvalid)     r_mst_axi_rready <= 1'b0;
    else if(slv_bus_read)       r_mst_axi_rready <= 1'b1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                  r_mst_axi_rdata <= 32'b0;
    else if(mst_axi_rvalid)     r_mst_axi_rdata <= mst_axi_rdata;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                                  r_slv_bus_waitrequest <= 1'b1;
    else if(mst_axi_rvalid || mst_axi_wready)   r_slv_bus_waitrequest <= 1'b0;
    else                                        r_slv_bus_waitrequest <= 1'b1;
end

endmodule