module interconnect_mod #(
    parameter M0_BASE   = 32'h0000_0100,
    parameter M0_MASK   = 32'hFFFF_FF00,
    parameter M0_ADDR_W = 1,
    parameter M1_BASE   = 1*256,
    parameter M1_MASK   = 1*256,
    parameter M1_ADDR_W = 1,
    parameter M2_BASE   = 2*256,
    parameter M2_MASK   = 2*256,
    parameter M2_ADDR_W = 1,
    parameter M3_BASE   = 3*256,
    parameter M3_MASK   = 3*256,
    parameter M3_ADDR_W = 1,
    parameter M4_BASE   = 4*256,
    parameter M4_MASK   = 4*256,
    parameter M4_ADDR_W = 1,
    parameter M5_BASE   = 5*256,
    parameter M5_MASK   = 5*256,
    parameter M5_ADDR_W = 1,
    parameter M6_BASE   = 6*256,
    parameter M6_MASK   = 6*256,
    parameter M6_ADDR_W = 1,
    parameter M7_BASE   = 7*256,
    parameter M7_MASK   = 7*256,
    parameter M7_ADDR_W = 1,
    parameter M8_BASE   = 8*256,
    parameter M8_MASK   = 8*256,
    parameter M8_ADDR_W = 1,
    parameter M9_BASE   = 9*256,
    parameter M9_MASK   = 9*256,
    parameter M9_ADDR_W = 1
)(
    // Slave port 0
    s0_bus_addr                ,
    s0_bus_read                ,
    s0_bus_readdata            ,
    s0_bus_response            ,
    s0_bus_write               ,
    s0_bus_writedata           ,
    s0_bus_byteenable          ,
    s0_bus_waitrequest         ,

    //* Master port 0
    m0_bus_addr                ,
    m0_bus_read                ,
    m0_bus_readdata            ,
    m0_bus_response            ,
    m0_bus_write               ,
    m0_bus_writedata           ,
    m0_bus_byteenable          ,
    m0_bus_waitrequest         ,

    //* Master port 1
    m1_bus_addr                ,
    m1_bus_read                ,
    m1_bus_readdata            ,
    m1_bus_response            ,
    m1_bus_write               ,
    m1_bus_writedata           ,
    m1_bus_byteenable          ,
    m1_bus_waitrequest         ,

    //* Master port 2
    m2_bus_addr                ,
    m2_bus_read                ,
    m2_bus_readdata            ,
    m2_bus_response            ,
    m2_bus_write               ,
    m2_bus_writedata           ,
    m2_bus_byteenable          ,
    m2_bus_waitrequest         ,

    //* Master port 3
    m3_bus_addr                ,
    m3_bus_read                ,
    m3_bus_readdata            ,
    m3_bus_response            ,
    m3_bus_write               ,
    m3_bus_writedata           ,
    m3_bus_byteenable          ,
    m3_bus_waitrequest         ,

    //* Master port 4
    m4_bus_addr                ,
    m4_bus_read                ,
    m4_bus_readdata            ,
    m4_bus_response            ,
    m4_bus_write               ,
    m4_bus_writedata           ,
    m4_bus_byteenable          ,
    m4_bus_waitrequest         ,

    //* Master port 5
    m5_bus_addr                ,
    m5_bus_read                ,
    m5_bus_readdata            ,
    m5_bus_response            ,
    m5_bus_write               ,
    m5_bus_writedata           ,
    m5_bus_byteenable          ,
    m5_bus_waitrequest         ,

    //* Master port 6
    m6_bus_addr                ,
    m6_bus_read                ,
    m6_bus_readdata            ,
    m6_bus_response            ,
    m6_bus_write               ,
    m6_bus_writedata           ,
    m6_bus_byteenable          ,
    m6_bus_waitrequest         ,

    //* Master port 7
    m7_bus_addr                ,
    m7_bus_read                ,
    m7_bus_readdata            ,
    m7_bus_response            ,
    m7_bus_write               ,
    m7_bus_writedata           ,
    m7_bus_byteenable          ,
    m7_bus_waitrequest         ,

    //* Master port 8
    m8_bus_addr                ,
    m8_bus_read                ,
    m8_bus_readdata            ,
    m8_bus_response            ,
    m8_bus_write               ,
    m8_bus_writedata           ,
    m8_bus_byteenable          ,
    m8_bus_waitrequest         ,

    //* Master port 9
    m9_bus_addr                ,
    m9_bus_read                ,
    m9_bus_readdata            ,
    m9_bus_response            ,
    m9_bus_write               ,
    m9_bus_writedata           ,
    m9_bus_byteenable          ,
    m9_bus_waitrequest
);

localparam M0_ADDR_WIDTH = M0_ADDR_W;//$clog2(!(M0_MASK));
localparam M1_ADDR_WIDTH = M1_ADDR_W;//$clog2(!(M1_MASK));
localparam M2_ADDR_WIDTH = M2_ADDR_W;//$clog2(!(M2_MASK));
localparam M3_ADDR_WIDTH = M3_ADDR_W;//$clog2(!(M3_MASK));
localparam M4_ADDR_WIDTH = M4_ADDR_W;//$clog2(!(M4_MASK));
localparam M5_ADDR_WIDTH = M5_ADDR_W;//$clog2(!(M5_MASK));
localparam M6_ADDR_WIDTH = M6_ADDR_W;//$clog2(!(M6_MASK));
localparam M7_ADDR_WIDTH = M7_ADDR_W;//$clog2(!(M7_MASK));
localparam M8_ADDR_WIDTH = M8_ADDR_W;//$clog2(!(M8_MASK));
localparam M9_ADDR_WIDTH = M9_ADDR_W;//$clog2(!(M9_MASK));

input   wire    [32 - 1:0]             s0_bus_addr;
input   wire                           s0_bus_read;
output  wire    [32-1:0]               s0_bus_readdata;
output  wire    [1:0]                  s0_bus_response;
input   wire                           s0_bus_write;
input   wire    [32-1:0]               s0_bus_writedata;
input   wire    [3:0]                  s0_bus_byteenable;
output  wire                           s0_bus_waitrequest;
//* Master port 0
output   wire   [M0_ADDR_WIDTH - 1:0]  m0_bus_addr;
output wire                            m0_bus_read;
input  wire     [32-1:0]               m0_bus_readdata;
input  wire     [1:0]                  m0_bus_response;
output   wire                          m0_bus_write;
output   wire   [32-1:0]               m0_bus_writedata;
output   wire   [3:0]                  m0_bus_byteenable;
input  wire                            m0_bus_waitrequest;
//* Master port 1
output   wire   [M1_ADDR_WIDTH - 1:0]  m1_bus_addr;
output wire                            m1_bus_read;
input  wire     [32-1:0]               m1_bus_readdata;
input  wire     [1:0]                  m1_bus_response;
output   wire                          m1_bus_write;
output   wire   [32-1:0]               m1_bus_writedata;
output   wire   [3:0]                  m1_bus_byteenable;
input  wire                            m1_bus_waitrequest;
//* Master port 2
output   wire   [M2_ADDR_WIDTH - 1:0]  m2_bus_addr;
output wire                            m2_bus_read;
input  wire     [32-1:0]               m2_bus_readdata;
input  wire     [1:0]                  m2_bus_response;
output   wire                          m2_bus_write;
output   wire   [32-1:0]               m2_bus_writedata;
output   wire   [3:0]                  m2_bus_byteenable;
input  wire                            m2_bus_waitrequest;
//* Master port 3
output   wire   [M3_ADDR_WIDTH - 1:0]  m3_bus_addr;
output wire                            m3_bus_read;
input  wire     [32-1:0]               m3_bus_readdata;
input  wire     [1:0]                  m3_bus_response;
output   wire                          m3_bus_write;
output   wire   [32-1:0]               m3_bus_writedata;
output   wire   [3:0]                  m3_bus_byteenable;
input  wire                            m3_bus_waitrequest;
//* Master port 4
output   wire   [M4_ADDR_WIDTH - 1:0]  m4_bus_addr;
output wire                            m4_bus_read;
input  wire     [32-1:0]               m4_bus_readdata;
input  wire     [1:0]                  m4_bus_response;
output   wire                          m4_bus_write;
output   wire   [32-1:0]               m4_bus_writedata;
output   wire   [3:0]                  m4_bus_byteenable;
input  wire                            m4_bus_waitrequest;
//* Master port 5
output   wire   [M5_ADDR_WIDTH - 1:0]  m5_bus_addr;
output wire                            m5_bus_read;
input  wire     [32-1:0]               m5_bus_readdata;
input  wire     [1:0]                  m5_bus_response;
output   wire                          m5_bus_write;
output   wire   [32-1:0]               m5_bus_writedata;
output   wire   [3:0]                  m5_bus_byteenable;
input  wire                            m5_bus_waitrequest;
//* Master port 6
output   wire   [M6_ADDR_WIDTH - 1:0]  m6_bus_addr;
output wire                            m6_bus_read;
input  wire     [32-1:0]               m6_bus_readdata;
input  wire     [1:0]                  m6_bus_response;
output   wire                          m6_bus_write;
output   wire   [32-1:0]               m6_bus_writedata;
output   wire   [3:0]                  m6_bus_byteenable;
input  wire                            m6_bus_waitrequest;
//* Master port 7
output   wire   [M7_ADDR_WIDTH - 1:0]  m7_bus_addr;
output   wire                          m7_bus_read;
input    wire     [32-1:0]             m7_bus_readdata;
input    wire     [1:0]                m7_bus_response;
output   wire                          m7_bus_write;
output   wire   [32-1:0]               m7_bus_writedata;
output   wire   [3:0]                  m7_bus_byteenable;
input  wire                            m7_bus_waitrequest;
//* Master port 8
output   wire   [M8_ADDR_WIDTH - 1:0]  m8_bus_addr;
output wire                            m8_bus_read;
input  wire     [32-1:0]               m8_bus_readdata;
input  wire     [1:0]                  m8_bus_response;
output   wire                          m8_bus_write;
output   wire   [32-1:0]               m8_bus_writedata;
output   wire   [3:0]                  m8_bus_byteenable;
input  wire                            m8_bus_waitrequest;
//* Master port 8
output   wire   [M9_ADDR_WIDTH - 1:0]  m9_bus_addr;
output wire                            m9_bus_read;
input  wire     [32-1:0]               m9_bus_readdata;
input  wire     [1:0]                  m9_bus_response;
output   wire                          m9_bus_write;
output   wire   [32-1:0]               m9_bus_writedata;
output   wire   [3:0]                  m9_bus_byteenable;
input  wire                            m9_bus_waitrequest;

wire m0_addr_hit;
wire m1_addr_hit;
wire m2_addr_hit;
wire m3_addr_hit;
wire m4_addr_hit;
wire m5_addr_hit;
wire m6_addr_hit;
wire m7_addr_hit;
wire m8_addr_hit;
wire m9_addr_hit;

assign m0_addr_hit = (s0_bus_addr & M0_MASK) == M0_BASE;
assign m1_addr_hit = (s0_bus_addr & M1_MASK) == M1_BASE;
assign m2_addr_hit = (s0_bus_addr & M2_MASK) == M2_BASE;
assign m3_addr_hit = (s0_bus_addr & M3_MASK) == M3_BASE;
assign m4_addr_hit = (s0_bus_addr & M4_MASK) == M4_BASE;
assign m5_addr_hit = (s0_bus_addr & M5_MASK) == M5_BASE;
assign m6_addr_hit = (s0_bus_addr & M6_MASK) == M6_BASE;
assign m7_addr_hit = (s0_bus_addr & M7_MASK) == M7_BASE;
assign m8_addr_hit = (s0_bus_addr & M8_MASK) == M8_BASE;
assign m9_addr_hit = (s0_bus_addr & M9_MASK) == M9_BASE;

assign m0_bus_read = s0_bus_read && m0_addr_hit;
assign m1_bus_read = s0_bus_read && m1_addr_hit;
assign m2_bus_read = s0_bus_read && m2_addr_hit;
assign m3_bus_read = s0_bus_read && m3_addr_hit;
assign m4_bus_read = s0_bus_read && m4_addr_hit;
assign m5_bus_read = s0_bus_read && m5_addr_hit;
assign m6_bus_read = s0_bus_read && m6_addr_hit;
assign m7_bus_read = s0_bus_read && m7_addr_hit;
assign m8_bus_read = s0_bus_read && m8_addr_hit;
assign m9_bus_read = s0_bus_read && m9_addr_hit;

assign m0_bus_write = s0_bus_write && m0_addr_hit;
assign m1_bus_write = s0_bus_write && m1_addr_hit;
assign m2_bus_write = s0_bus_write && m2_addr_hit;
assign m3_bus_write = s0_bus_write && m3_addr_hit;
assign m4_bus_write = s0_bus_write && m4_addr_hit;
assign m5_bus_write = s0_bus_write && m5_addr_hit;
assign m6_bus_write = s0_bus_write && m6_addr_hit;
assign m7_bus_write = s0_bus_write && m7_addr_hit;
assign m8_bus_write = s0_bus_write && m8_addr_hit;
assign m9_bus_write = s0_bus_write && m9_addr_hit;

assign s0_bus_waitrequest = m0_bus_waitrequest & m0_addr_hit |
                            m1_bus_waitrequest & m1_addr_hit |
                            m2_bus_waitrequest & m2_addr_hit |
                            m3_bus_waitrequest & m3_addr_hit |
                            m4_bus_waitrequest & m4_addr_hit |
                            m5_bus_waitrequest & m5_addr_hit |
                            m6_bus_waitrequest & m6_addr_hit |
                            m7_bus_waitrequest & m7_addr_hit |
                            m8_bus_waitrequest & m8_addr_hit |
                            m9_bus_waitrequest & m9_addr_hit;

assign s0_bus_readdata =    m0_bus_readdata & {32{m0_addr_hit}} |
                            m1_bus_readdata & {32{m1_addr_hit}} |
                            m2_bus_readdata & {32{m2_addr_hit}} |
                            m3_bus_readdata & {32{m3_addr_hit}} |
                            m4_bus_readdata & {32{m4_addr_hit}} |
                            m5_bus_readdata & {32{m5_addr_hit}} |
                            m6_bus_readdata & {32{m6_addr_hit}} |
                            m7_bus_readdata & {32{m7_addr_hit}} |
                            m8_bus_readdata & {32{m8_addr_hit}} |
                            m9_bus_readdata & {32{m9_addr_hit}};

assign m0_bus_addr = s0_bus_addr;
assign m1_bus_addr = s0_bus_addr;
assign m2_bus_addr = s0_bus_addr;
assign m3_bus_addr = s0_bus_addr;
assign m4_bus_addr = s0_bus_addr;
assign m5_bus_addr = s0_bus_addr;
assign m6_bus_addr = s0_bus_addr;
assign m7_bus_addr = s0_bus_addr;
assign m8_bus_addr = s0_bus_addr;
assign m9_bus_addr = s0_bus_addr;

assign m0_bus_writedata = s0_bus_writedata;
assign m1_bus_writedata = s0_bus_writedata;
assign m2_bus_writedata = s0_bus_writedata;
assign m3_bus_writedata = s0_bus_writedata;
assign m4_bus_writedata = s0_bus_writedata;
assign m5_bus_writedata = s0_bus_writedata;
assign m6_bus_writedata = s0_bus_writedata;
assign m7_bus_writedata = s0_bus_writedata;
assign m8_bus_writedata = s0_bus_writedata;
assign m9_bus_writedata = s0_bus_writedata;

assign m0_bus_byteenable = s0_bus_byteenable;
assign m1_bus_byteenable = s0_bus_byteenable;
assign m2_bus_byteenable = s0_bus_byteenable;
assign m3_bus_byteenable = s0_bus_byteenable;
assign m4_bus_byteenable = s0_bus_byteenable;
assign m5_bus_byteenable = s0_bus_byteenable;
assign m6_bus_byteenable = s0_bus_byteenable;
assign m7_bus_byteenable = s0_bus_byteenable;
assign m8_bus_byteenable = s0_bus_byteenable;
assign m9_bus_byteenable = s0_bus_byteenable;

endmodule
