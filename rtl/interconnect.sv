module interconnect_mod #(
    parameter M0_BASE = 32'h0000_0100,
    parameter M0_MASK = 32'hFFFF_FF00,
    parameter M1_BASE = 1*256,
    parameter M1_MASK = 1*256,
    parameter M2_BASE = 2*256,
    parameter M2_MASK = 2*256,
    parameter M3_BASE = 3*256,
    parameter M3_MASK = 3*256,
    parameter M4_BASE = 4*256,
    parameter M4_MASK = 4*256,
    parameter M5_BASE = 5*256,
    parameter M5_MASK = 5*256,
    parameter M6_BASE = 6*256,
    parameter M6_MASK = 6*256,
    parameter M7_BASE = 7*256,
    parameter M7_MASK = 7*256,
    parameter M8_BASE = 8*256,
    parameter M8_MASK = 8*256
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
    m8_bus_waitrequest
);

localparam M0_ADDR_WIDTH = $clog2(!(M0_MASK+1));
localparam M1_ADDR_WIDTH = $clog2(!(M1_MASK+1));
localparam M2_ADDR_WIDTH = $clog2(!(M2_MASK+1));
localparam M3_ADDR_WIDTH = $clog2(!(M3_MASK+1));
localparam M4_ADDR_WIDTH = $clog2(!(M4_MASK+1));
localparam M5_ADDR_WIDTH = $clog2(!(M5_MASK+1));
localparam M6_ADDR_WIDTH = $clog2(!(M6_MASK+1));
localparam M7_ADDR_WIDTH = $clog2(!(M7_MASK+1));
localparam M8_ADDR_WIDTH = $clog2(!(M8_MASK+1));

input   logic    [32 - 1:0]             s0_bus_addr;
input logic                             s0_bus_read;
output  logic    [32-1:0]               s0_bus_readdata;
output  logic    [1:0]                  s0_bus_response;
input   logic                           s0_bus_write;
input   logic    [32-1:0]               s0_bus_writedata;
input   logic    [3:0]                  s0_bus_byteenable;
output  logic                           s0_bus_waitrequest;
//* Master port 0
output   logic   [M0_ADDR_WIDTH - 1:0]  m0_bus_addr;
output logic                            m0_bus_read;
input  logic     [32-1:0]               m0_bus_readdata;
input  logic     [1:0]                  m0_bus_response;
output   logic                          m0_bus_write;
output   logic   [32-1:0]               m0_bus_writedata;
output   logic   [3:0]                  m0_bus_byteenable;
input  logic                            m0_bus_waitrequest;
//* Master port 1
output   logic   [M1_ADDR_WIDTH - 1:0]  m1_bus_addr;
output logic                            m1_bus_read;
input  logic     [32-1:0]               m1_bus_readdata;
input  logic     [1:0]                  m1_bus_response;
output   logic                          m1_bus_write;
output   logic   [32-1:0]               m1_bus_writedata;
output   logic   [3:0]                  m1_bus_byteenable;
input  logic                            m1_bus_waitrequest;
//* Master port 2
output   logic   [M2_ADDR_WIDTH - 1:0]  m2_bus_addr;
output logic                            m2_bus_read;
input  logic     [32-1:0]               m2_bus_readdata;
input  logic     [1:0]                  m2_bus_response;
output   logic                          m2_bus_write;
output   logic   [32-1:0]               m2_bus_writedata;
output   logic   [3:0]                  m2_bus_byteenable;
input  logic                            m2_bus_waitrequest;
//* Master port 3
output   logic   [M3_ADDR_WIDTH - 1:0]  m3_bus_addr;
output logic                            m3_bus_read;
input  logic     [32-1:0]               m3_bus_readdata;
input  logic     [1:0]                  m3_bus_response;
output   logic                          m3_bus_write;
output   logic   [32-1:0]               m3_bus_writedata;
output   logic   [3:0]                  m3_bus_byteenable;
input  logic                            m3_bus_waitrequest;
//* Master port 4
output   logic   [M4_ADDR_WIDTH - 1:0]  m4_bus_addr;
output logic                            m4_bus_read;
input  logic     [32-1:0]               m4_bus_readdata;
input  logic     [1:0]                  m4_bus_response;
output   logic                          m4_bus_write;
output   logic   [32-1:0]               m4_bus_writedata;
output   logic   [3:0]                  m4_bus_byteenable;
input  logic                            m4_bus_waitrequest;
//* Master port 5
output   logic   [M5_ADDR_WIDTH - 1:0]  m5_bus_addr;
output logic                            m5_bus_read;
input  logic     [32-1:0]               m5_bus_readdata;
input  logic     [1:0]                  m5_bus_response;
output   logic                          m5_bus_write;
output   logic   [32-1:0]               m5_bus_writedata;
output   logic   [3:0]                  m5_bus_byteenable;
input  logic                            m5_bus_waitrequest;
//* Master port 6
output   logic   [M6_ADDR_WIDTH - 1:0]  m6_bus_addr;
output logic                            m6_bus_read;
input  logic     [32-1:0]               m6_bus_readdata;
input  logic     [1:0]                  m6_bus_response;
output   logic                          m6_bus_write;
output   logic   [32-1:0]               m6_bus_writedata;
output   logic   [3:0]                  m6_bus_byteenable;
input  logic                            m6_bus_waitrequest;
//* Master port 7
output   logic   [M7_ADDR_WIDTH - 1:0]  m7_bus_addr;
output logic                            m7_bus_read;
input  logic     [32-1:0]               m7_bus_readdata;
input  logic     [1:0]                  m7_bus_response;
output   logic                          m7_bus_write;
output   logic   [32-1:0]               m7_bus_writedata;
output   logic   [3:0]                  m7_bus_byteenable;
input  logic                            m7_bus_waitrequest;
//* Master port 8
output   logic   [M8_ADDR_WIDTH - 1:0]  m8_bus_addr;
output logic                            m8_bus_read;
input  logic     [32-1:0]               m8_bus_readdata;
input  logic     [1:0]                  m8_bus_response;
output   logic                          m8_bus_write;
output   logic   [32-1:0]               m8_bus_writedata;
output   logic   [3:0]                  m8_bus_byteenable;
input  logic                            m8_bus_waitrequest;

logic m0_addr_hit;
logic m1_addr_hit;
logic m2_addr_hit;
logic m3_addr_hit;
logic m4_addr_hit;
logic m5_addr_hit;
logic m6_addr_hit;
logic m7_addr_hit;
logic m8_addr_hit;

assign m0_addr_hit = (s0_bus_addr & M0_MASK) == M0_BASE;
assign m1_addr_hit = (s0_bus_addr & M1_MASK) == M1_BASE;
assign m2_addr_hit = (s0_bus_addr & M2_MASK) == M2_BASE;
assign m3_addr_hit = (s0_bus_addr & M3_MASK) == M3_BASE;
assign m4_addr_hit = (s0_bus_addr & M4_MASK) == M4_BASE;
assign m5_addr_hit = (s0_bus_addr & M5_MASK) == M5_BASE;
assign m6_addr_hit = (s0_bus_addr & M6_MASK) == M6_BASE;
assign m7_addr_hit = (s0_bus_addr & M7_MASK) == M7_BASE;
assign m8_addr_hit = (s0_bus_addr & M8_MASK) == M8_BASE;

assign m0_bus_read = s0_bus_read && m0_addr_hit;
assign m1_bus_read = s0_bus_read && m1_addr_hit;
assign m2_bus_read = s0_bus_read && m2_addr_hit;
assign m3_bus_read = s0_bus_read && m3_addr_hit;
assign m4_bus_read = s0_bus_read && m4_addr_hit;
assign m5_bus_read = s0_bus_read && m5_addr_hit;
assign m6_bus_read = s0_bus_read && m6_addr_hit;
assign m7_bus_read = s0_bus_read && m7_addr_hit;
assign m8_bus_read = s0_bus_read && m8_addr_hit;

assign m0_bus_write = s0_bus_write && m0_addr_hit;
assign m1_bus_write = s0_bus_write && m1_addr_hit;
assign m2_bus_write = s0_bus_write && m2_addr_hit;
assign m3_bus_write = s0_bus_write && m3_addr_hit;
assign m4_bus_write = s0_bus_write && m4_addr_hit;
assign m5_bus_write = s0_bus_write && m5_addr_hit;
assign m6_bus_write = s0_bus_write && m6_addr_hit;
assign m7_bus_write = s0_bus_write && m7_addr_hit;
assign m8_bus_write = s0_bus_write && m8_addr_hit;

assign s0_bus_waitrequest = m0_bus_waitrequest & m0_addr_hit |
                            m1_bus_waitrequest & m1_addr_hit |
                            m2_bus_waitrequest & m2_addr_hit |
                            m3_bus_waitrequest & m3_addr_hit |
                            m4_bus_waitrequest & m4_addr_hit |
                            m5_bus_waitrequest & m5_addr_hit |
                            m6_bus_waitrequest & m6_addr_hit |
                            m7_bus_waitrequest & m7_addr_hit |
                            m8_bus_waitrequest & m8_addr_hit;

assign s0_bus_readdata =    m0_bus_readdata & {32{m0_addr_hit}} |
                            m1_bus_readdata & {32{m1_addr_hit}} |
                            m2_bus_readdata & {32{m2_addr_hit}} |
                            m3_bus_readdata & {32{m3_addr_hit}} |
                            m4_bus_readdata & {32{m4_addr_hit}} |
                            m5_bus_readdata & {32{m5_addr_hit}} |
                            m6_bus_readdata & {32{m6_addr_hit}} |
                            m7_bus_readdata & {32{m7_addr_hit}} |
                            m8_bus_readdata & {32{m8_addr_hit}};

assign m0_bus_addr = s0_bus_addr;
assign m1_bus_addr = s0_bus_addr;
assign m2_bus_addr = s0_bus_addr;
assign m3_bus_addr = s0_bus_addr;
assign m4_bus_addr = s0_bus_addr;
assign m5_bus_addr = s0_bus_addr;
assign m6_bus_addr = s0_bus_addr;
assign m7_bus_addr = s0_bus_addr;
assign m8_bus_addr = s0_bus_addr;

assign m0_bus_writedata = s0_bus_writedata;
assign m1_bus_writedata = s0_bus_writedata;
assign m2_bus_writedata = s0_bus_writedata;
assign m3_bus_writedata = s0_bus_writedata;
assign m4_bus_writedata = s0_bus_writedata;
assign m5_bus_writedata = s0_bus_writedata;
assign m6_bus_writedata = s0_bus_writedata;
assign m7_bus_writedata = s0_bus_writedata;
assign m8_bus_writedata = s0_bus_writedata;

assign m0_bus_byteenable = s0_bus_byteenable;
assign m1_bus_byteenable = s0_bus_byteenable;
assign m2_bus_byteenable = s0_bus_byteenable;
assign m3_bus_byteenable = s0_bus_byteenable;
assign m4_bus_byteenable = s0_bus_byteenable;
assign m5_bus_byteenable = s0_bus_byteenable;
assign m6_bus_byteenable = s0_bus_byteenable;
assign m7_bus_byteenable = s0_bus_byteenable;
assign m8_bus_byteenable = s0_bus_byteenable;



endmodule