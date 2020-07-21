`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    14:06:55 06/26/2020
// Design Name:
// Module Name:    top_level
// Project Name:
// Target Devices:
// Tool versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//


//                                         +-----------------+
//                                         |                 |
//                                         |                 |
//                                         |     Picorv5     |
//                                         |                 |
//                                         |                 |
//                                         +--------+--------+
//              +-------------+                     |
//        <-----+    GPIO     +<-----+              |                            +--------------+
//              |             |      |        +-----v-----+      +-------------->+    I2C       +<---------->
//              +-------------+      +--------+           |      |               |  EEPROM      |
//                                +---------->+   MUX     <------+               +--------------+
//              +-------------+   |           |           |---------------+
//              |             +<--+   +------->           +------------+  |      +--------------+
//        <----->    I2C      |       |       +-+--+----+-+            |  |      |    UART      +<--------->
//              |    HDMI     |       |         ^  |    |              |  +----->+              |
//              +-------------+       |         |  |    |              |         +--------------+
//                                    |         |  |    +-----------+  +-------------+
//                         +----------+         |  v                |                |
//                         |             +------+--+-----+       +--v-----+       +--v----------+
//              +----------v---+         |               |       |        |       |             |
//              |              |         |               |       |        |       |             |
//              |              |         |     DDR3 MCB  |       | DSI    +------>+   DSI HOST  +-------->
//  +---------->+   HDMI recv  +-------->+               +------>+ Reader |       |             |
//              |              |         |               |       |        |       |   DSI GPIO  |
//              |              |         |               |       |        |       |             |
//              +--------------+         +---------------+       +--------+       +-------------+


//////////////////////////////////////////////////////////////////////////////////
module top_level(
    /* CLK */
    /* DDR */
    /* DPHY */
    /* HDMI parallel */
    /* HDMI native */
    /* I2C EEPROM */
    /* LED */
    /* UART */
    /* BUTTON */
    );

logic sys_clk;
logic sys_rst_n;

logic dsi_phy_clk;
logic dsi_phy_rst_n;

logic dsi_io_clk;
logic dsi_io_rst_n;

logic dsi_io_serdes_latch;

logic    [32 - 1:0]                 s0_bus_addr;
logic                               s0_bus_read;
logic    [32-1:0]                   s0_bus_readdata;
logic    [1:0]                      s0_bus_response;
logic                               s0_bus_write;
logic    [32-1:0]                   s0_bus_writedata;
logic    [3:0]                      s0_bus_byteenable;
logic                               s0_bus_waitrequest;
logic   [M0_ADDR_WIDTH - 1:0]       m0_bus_addr;
logic                               m0_bus_read;
logic     [32-1:0]                  m0_bus_readdata;
logic     [1:0]                     m0_bus_response;
logic                               m0_bus_write;
logic   [32-1:0]                    m0_bus_writedata;
logic   [3:0]                       m0_bus_byteenable;
logic                               m0_bus_waitrequest;
logic   [M1_ADDR_WIDTH - 1:0]       m1_bus_addr;
logic                               m1_bus_read;
logic     [32-1:0]                  m1_bus_readdata;
logic     [1:0]                     m1_bus_response;
logic                               m1_bus_write;
logic   [32-1:0]                    m1_bus_writedata;
logic   [3:0]                       m1_bus_byteenable;
logic                               m1_bus_waitrequest;
logic   [M2_ADDR_WIDTH - 1:0]       m2_bus_addr;
logic                               m2_bus_read;
logic     [32-1:0]                  m2_bus_readdata;
logic     [1:0]                     m2_bus_response;
logic                               m2_bus_write;
logic   [32-1:0]                    m2_bus_writedata;
logic   [3:0]                       m2_bus_byteenable;
logic                               m2_bus_waitrequest;
logic   [M3_ADDR_WIDTH - 1:0]       m3_bus_addr;
logic                               m3_bus_read;
logic     [32-1:0]                  m3_bus_readdata;
logic     [1:0]                     m3_bus_response;
logic                               m3_bus_write;
logic   [32-1:0]                    m3_bus_writedata;
logic   [3:0]                       m3_bus_byteenable;
logic                               m3_bus_waitrequest;
logic   [M4_ADDR_WIDTH - 1:0]       m4_bus_addr;
logic                               m4_bus_read;
logic     [32-1:0]                  m4_bus_readdata;
logic     [1:0]                     m4_bus_response;
logic                               m4_bus_write;
logic   [32-1:0]                    m4_bus_writedata;
logic   [3:0]                       m4_bus_byteenable;
logic                               m4_bus_waitrequest;
logic   [M5_ADDR_WIDTH - 1:0]       m5_bus_addr;
logic                               m5_bus_read;
logic     [32-1:0]                  m5_bus_readdata;
logic     [1:0]                     m5_bus_response;
logic                               m5_bus_write;
logic   [32-1:0]                    m5_bus_writedata;
logic   [3:0]                       m5_bus_byteenable;
logic                               m5_bus_waitrequest;
logic   [M6_ADDR_WIDTH - 1:0]       m6_bus_addr;
logic                               m6_bus_read;
logic     [32-1:0]                  m6_bus_readdata;
logic     [1:0]                     m6_bus_response;
logic                               m6_bus_write;
logic   [32-1:0]                    m6_bus_writedata;
logic   [3:0]                       m6_bus_byteenable;
logic                               m6_bus_waitrequest;
logic   [M7_ADDR_WIDTH - 1:0]       m7_bus_addr;
logic                               m7_bus_read;
logic     [32-1:0]                  m7_bus_readdata;
logic     [1:0]                     m7_bus_response;
logic                               m7_bus_write;
logic   [32-1:0]                    m7_bus_writedata;
logic   [3:0]                       m7_bus_byteenable;
logic                               m7_bus_waitrequest;
logic   [M8_ADDR_WIDTH - 1:0]       m8_bus_addr;
logic                               m8_bus_read;
logic     [32-1:0]                  m8_bus_readdata;
logic     [1:0]                     m8_bus_response;
logic                               m8_bus_write;
logic   [32-1:0]                    m8_bus_writedata;
logic   [3:0]                       m8_bus_byteenable;
logic                               m8_bus_waitrequest;

logic [4 - 1:0]	                    mst_core_axi_awid;
logic [32 - 1:0]	                mst_core_axi_awaddr;
logic [7:0]	                        mst_core_axi_awlen;
logic [2:0]	                        mst_core_axi_awsize;
logic [1:0]	                        mst_core_axi_awburst;
logic [0:0]	                        mst_core_axi_awlock;
logic [3:0]	                        mst_core_axi_awcache;
logic [2:0]	                        mst_core_axi_awprot;
logic [3:0]	                        mst_core_axi_awqos;
logic   	                        mst_core_axi_awvalid;
logic   	                        mst_core_axi_awready;
logic [32 - 1:0]                    mst_core_axi_wdata;
logic [32/8 - 1:0]                  mst_core_axi_wstrb;
logic                               mst_core_axi_wlast;
logic                               mst_core_axi_wvalid;
logic  	                            mst_core_axi_wready;
logic [4 - 1:0]                     mst_core_axi_bid;
logic [4 - 1:0]                     mst_core_axi_wid;
logic [1:0]                         mst_core_axi_bresp;
logic                               mst_core_axi_bvalid;
logic                               mst_core_axi_bready;
logic [4 - 1:0]                     mst_core_axi_arid;
logic [32 - 1:0]                    mst_core_axi_araddr;
logic [7:0]                         mst_core_axi_arlen;
logic [2:0]                         mst_core_axi_arsize;
logic [1:0]                         mst_core_axi_arburst;
logic [0:0]                         mst_core_axi_arlock;
logic [3:0]                         mst_core_axi_arcache;
logic [2:0]                         mst_core_axi_arprot;
logic [3:0]                         mst_core_axi_arqos;
logic                               mst_core_axi_arvalid;
logic                               mst_core_axi_arready;
logic [4 - 1:0]                     mst_core_axi_rid;
logic [32 - 1:0]                    mst_core_axi_rdata;
logic [1:0]                         mst_core_axi_rresp;
logic                               mst_core_axi_rlast;
logic                               mst_core_axi_rvalid;
logic                               mst_core_axi_rready;

//* RISC V core +
 picorv32_wrapper #(
    .ENABLE_COUNTERS(),
	.BARREL_SHIFTER(),
	.COMPRESSED_ISA(),
	.ENABLE_MUL(),
	.ENABLE_DIV(),
	.ENABLE_IRQ_QREGS(),
	.PROGADDR_RESET(),
	.PROGADDR_IRQ(),
	.STACKADDR()
 ) picorv32_core (
    .clk                     (sys_clk               ),
    .rst_n                   (sys_rst_n             ),

    .bus_addr                (s0_bus_addr           ),
    .bus_read                (s0_bus_read           ),
    .bus_readdata            (s0_bus_readdata       ),
    .bus_response            (s0_bus_response       ),
    .bus_write               (s0_bus_write          ),
    .bus_writedata           (s0_bus_writedata      ),
    .bus_byteenable          (s0_bus_byteenable     ),
    .bus_waitrequest         (s0_bus_waitrequest    ),

    .irq                     ()
);

//* Interconnect (MUX) +

interconnect_mod #(
    .M0_BASE(),
    .M0_MASK(),
    .M1_BASE(),
    .M1_MASK(),
    .M2_BASE(),
    .M2_MASK(),
    .M3_BASE(),
    .M3_MASK(),
    .M4_BASE(),
    .M4_MASK(),
    .M5_BASE(),
    .M5_MASK(),
    .M6_BASE(),
    .M6_MASK(),
    .M7_BASE(),
    .M7_MASK(),
    .M8_BASE(),
    .M8_MASK()
)(
    // Slave port 0
    .s0_bus_addr                (s0_bus_addr            ),
    .s0_bus_read                (s0_bus_read            ),
    .s0_bus_readdata            (s0_bus_readdata        ),
    .s0_bus_response            (s0_bus_response        ),
    .s0_bus_write               (s0_bus_write           ),
    .s0_bus_writedata           (s0_bus_writedata       ),
    .s0_bus_byteenable          (s0_bus_byteenable      ),
    .s0_bus_waitrequest         (s0_bus_waitrequest     ),

    //* Master port 0
    .m0_bus_addr                (m0_bus_addr            ),
    .m0_bus_read                (m0_bus_read            ),
    .m0_bus_readdata            (m0_bus_readdata        ),
    .m0_bus_response            (m0_bus_response        ),
    .m0_bus_write               (m0_bus_write           ),
    .m0_bus_writedata           (m0_bus_writedata       ),
    .m0_bus_byteenable          (m0_bus_byteenable      ),
    .m0_bus_waitrequest         (m0_bus_waitrequest     ),

    //* Master port 1
    .m1_bus_addr                (m1_bus_addr            ),
    .m1_bus_read                (m1_bus_read            ),
    .m1_bus_readdata            (m1_bus_readdata        ),
    .m1_bus_response            (m1_bus_response        ),
    .m1_bus_write               (m1_bus_write           ),
    .m1_bus_writedata           (m1_bus_writedata       ),
    .m1_bus_byteenable          (m1_bus_byteenable      ),
    .m1_bus_waitrequest         (m1_bus_waitrequest     ),

    //* Master port 2
    .m2_bus_addr                (m2_bus_addr            ),
    .m2_bus_read                (m2_bus_read            ),
    .m2_bus_readdata            (m2_bus_readdata        ),
    .m2_bus_response            (m2_bus_response        ),
    .m2_bus_write               (m2_bus_write           ),
    .m2_bus_writedata           (m2_bus_writedata       ),
    .m2_bus_byteenable          (m2_bus_byteenable      ),
    .m2_bus_waitrequest         (m2_bus_waitrequest     ),

    //* Master port 3
    .m3_bus_addr                (m3_bus_addr            ),
    .m3_bus_read                (m3_bus_read            ),
    .m3_bus_readdata            (m3_bus_readdata        ),
    .m3_bus_response            (m3_bus_response        ),
    .m3_bus_write               (m3_bus_write           ),
    .m3_bus_writedata           (m3_bus_writedata       ),
    .m3_bus_byteenable          (m3_bus_byteenable      ),
    .m3_bus_waitrequest         (m3_bus_waitrequest     ),

    //* Master port 4
    .m4_bus_addr                (m4_bus_addr            ),
    .m4_bus_read                (m4_bus_read            ),
    .m4_bus_readdata            (m4_bus_readdata        ),
    .m4_bus_response            (m4_bus_response        ),
    .m4_bus_write               (m4_bus_write           ),
    .m4_bus_writedata           (m4_bus_writedata       ),
    .m4_bus_byteenable          (m4_bus_byteenable      ),
    .m4_bus_waitrequest         (m4_bus_waitrequest     ),

    //* Master port 5
    .m5_bus_addr                (m5_bus_addr            ),
    .m5_bus_read                (m5_bus_read            ),
    .m5_bus_readdata            (m5_bus_readdata        ),
    .m5_bus_response            (m5_bus_response        ),
    .m5_bus_write               (m5_bus_write           ),
    .m5_bus_writedata           (m5_bus_writedata       ),
    .m5_bus_byteenable          (m5_bus_byteenable      ),
    .m5_bus_waitrequest         (m5_bus_waitrequest     ),

    //* Master port 6
    .m6_bus_addr                (m6_bus_addr            ),
    .m6_bus_read                (m6_bus_read            ),
    .m6_bus_readdata            (m6_bus_readdata        ),
    .m6_bus_response            (m6_bus_response        ),
    .m6_bus_write               (m6_bus_write           ),
    .m6_bus_writedata           (m6_bus_writedata       ),
    .m6_bus_byteenable          (m6_bus_byteenable      ),
    .m6_bus_waitrequest         (m6_bus_waitrequest     ),

    //* Master port 7
    .m7_bus_addr                (m7_bus_addr            ),
    .m7_bus_read                (m7_bus_read            ),
    .m7_bus_readdata            (m7_bus_readdata        ),
    .m7_bus_response            (m7_bus_response        ),
    .m7_bus_write               (m7_bus_write           ),
    .m7_bus_writedata           (m7_bus_writedata       ),
    .m7_bus_byteenable          (m7_bus_byteenable      ),
    .m7_bus_waitrequest         (m7_bus_waitrequest     ),

    //* Master port 8
    .m8_bus_addr                (m8_bus_addr            ),
    .m8_bus_read                (m8_bus_read            ),
    .m8_bus_readdata            (m8_bus_readdata        ),
    .m8_bus_response            (m8_bus_response        ),
    .m8_bus_write               (m8_bus_write           ),
    .m8_bus_writedata           (m8_bus_writedata       ),
    .m8_bus_byteenable          (m8_bus_byteenable      ),
    .m8_bus_waitrequest         (m8_bus_waitrequest     )
);

//* Prosessor to AXI bridge
core_axi_bridge core_axi_bridge_0(

    .clk                     (sys_clk              ),
    .rst_n                   (sys_rst_n            ),

    .slv_bus_addr            (m0_bus_addr          ),
    .slv_bus_read            (m0_bus_read          ),
    .slv_bus_readdata        (m0_bus_readdata      ),
    .slv_bus_response        (m0_bus_response      ),
    .slv_bus_write           (m0_bus_write         ),
    .slv_bus_writedata       (m0_bus_writedata     ),
    .slv_bus_byteenable      (m0_bus_byteenable    ),
    .slv_bus_waitrequest     (m0_bus_waitrequest   ),

    .mst_axi_awid            (mst_core_axi_awid      ),
    .mst_axi_awaddr          (mst_core_axi_awaddr    ),
    .mst_axi_awlen           (mst_core_axi_awlen     ),
    .mst_axi_awsize          (mst_core_axi_awsize    ),
    .mst_axi_awburst         (mst_core_axi_awburst   ),
    .mst_axi_awlock          (mst_core_axi_awlock    ),
    .mst_axi_awcache         (mst_core_axi_awcache   ),
    .mst_axi_awprot          (mst_core_axi_awprot    ),
    .mst_axi_awqos           (mst_core_axi_awqos     ),
    .mst_axi_awvalid         (mst_core_axi_awvalid   ),
    .mst_axi_awready         (mst_core_axi_awready   ),

    .mst_axi_wdata           (mst_core_axi_wdata     ),
    .mst_axi_wstrb           (mst_core_axi_wstrb     ),
    .mst_axi_wlast           (mst_core_axi_wlast     ),
    .mst_axi_wvalid          (mst_core_axi_wvalid    ),
    .mst_axi_wready          (mst_core_axi_wready    ),

    .mst_axi_bid             (mst_core_axi_bid       ),
    .mst_axi_wid             (mst_core_axi_wid       ),
    .mst_axi_bresp           (mst_core_axi_bresp     ),
    .mst_axi_bvalid          (mst_core_axi_bvalid    ),
    .mst_axi_bready          (mst_core_axi_bready    ),

    .mst_axi_arid            (mst_core_axi_arid      ),
    .mst_axi_araddr          (mst_core_axi_araddr    ),
    .mst_axi_arlen           (mst_core_axi_arlen     ),
    .mst_axi_arsize          (mst_core_axi_arsize    ),
    .mst_axi_arburst         (mst_core_axi_arburst   ),
    .mst_axi_arlock          (mst_core_axi_arlock    ),
    .mst_axi_arcache         (mst_core_axi_arcache   ),
    .mst_axi_arprot          (mst_core_axi_arprot    ),
    .mst_axi_arqos           (mst_core_axi_arqos     ),
    .mst_axi_arvalid         (mst_core_axi_arvalid   ),
    .mst_axi_arready         (mst_core_axi_arready   ),

    .mst_axi_rid             (mst_core_axi_rid       ),
    .mst_axi_rdata           (mst_core_axi_rdata     ),
    .mst_axi_rresp           (mst_core_axi_rresp     ),
    .mst_axi_rlast           (mst_core_axi_rlast     ),
    .mst_axi_rvalid          (mst_core_axi_rvalid    ),
    .mst_axi_rready          (mst_core_axi_rready    )
);

//* DDR3 controller
mig_ddr3 # (
    .C3_P0_MASK_SIZE(4),
    .C3_P0_DATA_PORT_SIZE(32),
    .C3_P1_MASK_SIZE(4),
    .C3_P1_DATA_PORT_SIZE(32),
    .DEBUG_EN(0),
    .C3_MEMCLK_PERIOD(3000),
    .C3_CALIB_SOFT_IP("TRUE"),
    .C3_SIMULATION("FALSE"),
    .C3_RST_ACT_LOW(0),
    .C3_INPUT_CLK_TYPE("SINGLE_ENDED"),
    .C3_MEM_ADDR_ORDER("BANK_ROW_COLUMN"),
    .C3_NUM_DQ_PINS(16),
    .C3_MEM_ADDR_WIDTH(14),
    .C3_MEM_BANKADDR_WIDTH(3),
    .C3_S0_AXI_STRICT_COHERENCY(0),
    .C3_S0_AXI_ENABLE_AP(0),
    .C3_S0_AXI_DATA_WIDTH(32),
    .C3_S0_AXI_SUPPORTS_NARROW_BURST(1),
    .C3_S0_AXI_ADDR_WIDTH(32),
    .C3_S0_AXI_ID_WIDTH(4),
    .C3_S2_AXI_STRICT_COHERENCY(0),
    .C3_S2_AXI_ENABLE_AP(0),
    .C3_S2_AXI_DATA_WIDTH(32),
    .C3_S2_AXI_SUPPORTS_NARROW_BURST(1),
    .C3_S2_AXI_ADDR_WIDTH(32),
    .C3_S2_AXI_ID_WIDTH(4),
    .C3_S3_AXI_STRICT_COHERENCY(0),
    .C3_S3_AXI_ENABLE_AP(0),
    .C3_S3_AXI_DATA_WIDTH(32),
    .C3_S3_AXI_SUPPORTS_NARROW_BURST(1),
    .C3_S3_AXI_ADDR_WIDTH(32),
    .C3_S3_AXI_ID_WIDTH(4)
)
u_mig_ddr3 (

    .c3_sys_clk           (c3_sys_clk),
  .c3_sys_rst_i           (c3_sys_rst_i),

  .mcb3_dram_dq           (mcb3_dram_dq),
  .mcb3_dram_a            (mcb3_dram_a),
  .mcb3_dram_ba           (mcb3_dram_ba),
  .mcb3_dram_ras_n        (mcb3_dram_ras_n),
  .mcb3_dram_cas_n        (mcb3_dram_cas_n),
  .mcb3_dram_we_n         (mcb3_dram_we_n),
  .mcb3_dram_odt          (mcb3_dram_odt),
  .mcb3_dram_cke          (mcb3_dram_cke),
  .mcb3_dram_ck           (mcb3_dram_ck),
  .mcb3_dram_ck_n         (mcb3_dram_ck_n),
  .mcb3_dram_dqs          (mcb3_dram_dqs),
  .mcb3_dram_dqs_n        (mcb3_dram_dqs_n),
  .mcb3_dram_udqs         (mcb3_dram_udqs),    // for X16 parts
  .mcb3_dram_udqs_n       (mcb3_dram_udqs_n),  // for X16 parts
  .mcb3_dram_udm          (mcb3_dram_udm),     // for X16 parts
  .mcb3_dram_dm           (mcb3_dram_dm),
  .mcb3_dram_reset_n      (mcb3_dram_reset_n),
  .c3_clk0		        (c3_clk0),
  .c3_rst0		        (c3_rst0),



  .c3_calib_done    (c3_calib_done),
     .mcb3_rzq               (rzq3),

     .mcb3_zio               (zio3),

    .c3_s0_axi_aclk                         (sys_clk                ),
    .c3_s0_axi_aresetn                      (sys_rst_n              ),
    .c3_s0_axi_awid                         (mst_core_axi_awid      ),
    .c3_s0_axi_awaddr                       (mst_core_axi_awaddr    ),
    .c3_s0_axi_awlen                        (mst_core_axi_awlen     ),
    .c3_s0_axi_awsize                       (mst_core_axi_awsize    ),
    .c3_s0_axi_awburst                      (mst_core_axi_awburst   ),
    .c3_s0_axi_awlock                       (mst_core_axi_awlock    ),
    .c3_s0_axi_awcache                      (mst_core_axi_awcache   ),
    .c3_s0_axi_awprot                       (mst_core_axi_awprot    ),
    .c3_s0_axi_awqos                        (mst_core_axi_awqos     ),
    .c3_s0_axi_awvalid                      (mst_core_axi_awvalid   ),
    .c3_s0_axi_awready                      (mst_core_axi_awready   ),
    .c3_s0_axi_wdata                        (mst_core_axi_wdata     ),
    .c3_s0_axi_wstrb                        (mst_core_axi_wstrb     ),
    .c3_s0_axi_wlast                        (mst_core_axi_wlast     ),
    .c3_s0_axi_wvalid                       (mst_core_axi_wvalid    ),
    .c3_s0_axi_wready                       (mst_core_axi_wready    ),
    .c3_s0_axi_bid                          (mst_core_axi_bid       ),
    .c3_s0_axi_wid                          (mst_core_axi_wid       ),
    .c3_s0_axi_bresp                        (mst_core_axi_bresp     ),
    .c3_s0_axi_bvalid                       (mst_core_axi_bvalid    ),
    .c3_s0_axi_bready                       (mst_core_axi_bready    ),
    .c3_s0_axi_arid                         (mst_core_axi_arid      ),
    .c3_s0_axi_araddr                       (mst_core_axi_araddr    ),
    .c3_s0_axi_arlen                        (mst_core_axi_arlen     ),
    .c3_s0_axi_arsize                       (mst_core_axi_arsize    ),
    .c3_s0_axi_arburst                      (mst_core_axi_arburst   ),
    .c3_s0_axi_arlock                       (mst_core_axi_arlock    ),
    .c3_s0_axi_arcache                      (mst_core_axi_arcache   ),
    .c3_s0_axi_arprot                       (mst_core_axi_arprot    ),
    .c3_s0_axi_arqos                        (mst_core_axi_arqos     ),
    .c3_s0_axi_arvalid                      (mst_core_axi_arvalid   ),
    .c3_s0_axi_arready                      (mst_core_axi_arready   ),
    .c3_s0_axi_rid                          (mst_core_axi_rid       ),
    .c3_s0_axi_rdata                        (mst_core_axi_rdata     ),
    .c3_s0_axi_rresp                        (mst_core_axi_rresp     ),
    .c3_s0_axi_rlast                        (mst_core_axi_rlast     ),
    .c3_s0_axi_rvalid                       (mst_core_axi_rvalid    ),
    .c3_s0_axi_rready                       (mst_core_axi_rready    ),

    //* Write only Port
    .c3_s2_axi_aclk                         (c3_s2_axi_aclk   ),
    .c3_s2_axi_aresetn                      (c3_s2_axi_aresetn),
    .c3_s2_axi_awid                         (c3_s2_axi_awid   ),
    .c3_s2_axi_awaddr                       (c3_s2_axi_awaddr ),
    .c3_s2_axi_awlen                        (c3_s2_axi_awlen  ),
    .c3_s2_axi_awsize                       (c3_s2_axi_awsize ),
    .c3_s2_axi_awburst                      (c3_s2_axi_awburst),
    .c3_s2_axi_awlock                       (c3_s2_axi_awlock ),
    .c3_s2_axi_awcache                      (c3_s2_axi_awcache),
    .c3_s2_axi_awprot                       (c3_s2_axi_awprot ),
    .c3_s2_axi_awqos                        (c3_s2_axi_awqos  ),
    .c3_s2_axi_awvalid                      (c3_s2_axi_awvalid),
    .c3_s2_axi_awready                      (c3_s2_axi_awready),
    .c3_s2_axi_wdata                        (c3_s2_axi_wdata  ),
    .c3_s2_axi_wstrb                        (c3_s2_axi_wstrb  ),
    .c3_s2_axi_wlast                        (c3_s2_axi_wlast  ),
    .c3_s2_axi_wvalid                       (c3_s2_axi_wvalid ),
    .c3_s2_axi_wready                       (c3_s2_axi_wready ),
    .c3_s2_axi_bid                          (c3_s2_axi_bid    ),
    .c3_s2_axi_wid                          (c3_s2_axi_wid    ),
    .c3_s2_axi_bresp                        (c3_s2_axi_bresp  ),
    .c3_s2_axi_bvalid                       (c3_s2_axi_bvalid ),
    .c3_s2_axi_bready                       (c3_s2_axi_bready ),
    .c3_s2_axi_arid                         (c3_s2_axi_arid   ),
    .c3_s2_axi_araddr                       (c3_s2_axi_araddr ),
    .c3_s2_axi_arlen                        (c3_s2_axi_arlen  ),
    .c3_s2_axi_arsize                       (c3_s2_axi_arsize ),
    .c3_s2_axi_arburst                      (c3_s2_axi_arburst),
    .c3_s2_axi_arlock                       (c3_s2_axi_arlock ),
    .c3_s2_axi_arcache                      (c3_s2_axi_arcache),
    .c3_s2_axi_arprot                       (c3_s2_axi_arprot ),
    .c3_s2_axi_arqos                        (c3_s2_axi_arqos  ),
    .c3_s2_axi_arvalid                      (c3_s2_axi_arvalid),
    .c3_s2_axi_arready                      (c3_s2_axi_arready),
    .c3_s2_axi_rid                          (c3_s2_axi_rid    ),
    .c3_s2_axi_rdata                        (c3_s2_axi_rdata  ),
    .c3_s2_axi_rresp                        (c3_s2_axi_rresp  ),
    .c3_s2_axi_rlast                        (c3_s2_axi_rlast  ),
    .c3_s2_axi_rvalid                       (c3_s2_axi_rvalid ),
    .c3_s2_axi_rready                       (c3_s2_axi_rready ),

    //* Read only Port
    .c3_s3_axi_aclk                         (c3_s3_axi_aclk   ),
    .c3_s3_axi_aresetn                      (c3_s3_axi_aresetn),
    .c3_s3_axi_awid                         (c3_s3_axi_awid   ),
    .c3_s3_axi_awaddr                       (c3_s3_axi_awaddr ),
    .c3_s3_axi_awlen                        (c3_s3_axi_awlen  ),
    .c3_s3_axi_awsize                       (c3_s3_axi_awsize ),
    .c3_s3_axi_awburst                      (c3_s3_axi_awburst),
    .c3_s3_axi_awlock                       (c3_s3_axi_awlock ),
    .c3_s3_axi_awcache                      (c3_s3_axi_awcache),
    .c3_s3_axi_awprot                       (c3_s3_axi_awprot ),
    .c3_s3_axi_awqos                        (c3_s3_axi_awqos  ),
    .c3_s3_axi_awvalid                      (c3_s3_axi_awvalid),
    .c3_s3_axi_awready                      (c3_s3_axi_awready),
    .c3_s3_axi_wdata                        (c3_s3_axi_wdata  ),
    .c3_s3_axi_wstrb                        (c3_s3_axi_wstrb  ),
    .c3_s3_axi_wlast                        (c3_s3_axi_wlast  ),
    .c3_s3_axi_wvalid                       (c3_s3_axi_wvalid ),
    .c3_s3_axi_wready                       (c3_s3_axi_wready ),
    .c3_s3_axi_bid                          (c3_s3_axi_bid    ),
    .c3_s3_axi_wid                          (c3_s3_axi_wid    ),
    .c3_s3_axi_bresp                        (c3_s3_axi_bresp  ),
    .c3_s3_axi_bvalid                       (c3_s3_axi_bvalid ),
    .c3_s3_axi_bready                       (c3_s3_axi_bready ),
    .c3_s3_axi_arid                         (c3_s3_axi_arid   ),
    .c3_s3_axi_araddr                       (c3_s3_axi_araddr ),
    .c3_s3_axi_arlen                        (c3_s3_axi_arlen  ),
    .c3_s3_axi_arsize                       (c3_s3_axi_arsize ),
    .c3_s3_axi_arburst                      (c3_s3_axi_arburst),
    .c3_s3_axi_arlock                       (c3_s3_axi_arlock ),
    .c3_s3_axi_arcache                      (c3_s3_axi_arcache),
    .c3_s3_axi_arprot                       (c3_s3_axi_arprot ),
    .c3_s3_axi_arqos                        (c3_s3_axi_arqos  ),
    .c3_s3_axi_arvalid                      (c3_s3_axi_arvalid),
    .c3_s3_axi_arready                      (c3_s3_axi_arready),
    .c3_s3_axi_rid                          (c3_s3_axi_rid    ),
    .c3_s3_axi_rdata                        (c3_s3_axi_rdata  ),
    .c3_s3_axi_rresp                        (c3_s3_axi_rresp  ),
    .c3_s3_axi_rlast                        (c3_s3_axi_rlast  ),
    .c3_s3_axi_rvalid                       (c3_s3_axi_rvalid ),
    .c3_s3_axi_rready                       (c3_s3_axi_rready )
);
//* HDMI ADV Recv

//* HDMI native

//* Pixel reader

//* DSI +
dsi_tx_top #(
    .LINE_WIDTH            (),
    .BITS_PER_PIXEL        (),
    .BLANK_TIME            (),
    .BLANK_TIME_HBP_ACT    (),
    .VSA_LINES_NUMBER      (),
    .VBP_LINES_NUMBER      (),
    .IMAGE_HEIGHT          (),
    .VFP_LINES_NUMBER      ()
    ) (
    /********* System signals *********/
    .clk_sys                                (),
    .rst_sys_n                              (),

    .clk_phy                                (),
    .rst_phy_n                              (),

    .clk_hs_latch                           (),
    .clk_hs                                 (),
    .clk_hs_clk                             (),

    .irq                                    (),

    /********* Avalon-ST input *********/
    .in_avl_st_data                         (),
    .in_avl_st_valid                        (),
    .in_avl_st_endofpacket                  (),
    .in_avl_st_startofpacket                (),
    .in_avl_st_ready                        (),

    /********* Output interface *********/
    .dphy_data_hs_out_p                     (),  // active
    .dphy_data_hs_out_n                     (),  // unactive. do not connect
    .dphy_data_lp_out_p                     (),
    .dphy_data_lp_out_n                     (),

    .dphy_clk_hs_out_p                      (),  // active
    .dphy_clk_hs_out_n                      (),  // unactive. do not connect
    .dphy_clk_lp_out_p                      (),
    .dphy_clk_lp_out_n                      (),

    /********* Avalon-MM iface *********/
    .avl_mm_address                         (),

    .avl_mm_read                            (),
    .avl_mm_readdata                        (),
    .avl_mm_response                        (),

    .avl_mm_write                           (),
    .avl_mm_writedata                       (),
    .avl_mm_byteenable                      (),
    .avl_mm_waitrequest                     ()

);

//* I2C master

//* Usart RX/TX

uart_wrapper uart_wrapper_0(
    //* system signals
    .clk                  (),
    .rst                  (),

    //* external interface
    .rxd                  (),
    .txd                  (),

    //* system interface
    .ctrl_address        (),

    .ctrl_read           (),
    .ctrl_readdata       (),
    .ctrl_response       (),

    .ctrl_write          (),
    .ctrl_writedata      (),
    .ctrl_byteenable     (),
    .ctrl_waitrequest    (),

    .irq                 ()
);

//* Programm Mem
progmem_wrapper progmem_wrapper_0(
    //* system signals
    .clk                     (),
    .rst_n                   (),

    //* system interface
    .ctrl_address            (),

    .ctrl_read               (),
    .ctrl_readdata           (),
    .ctrl_response           (),

    .ctrl_waitrequest        ()
);

//* GPIO

//* Timer

//* Clocking
//* Main PLL (sys clock + dphy)
logic CLKFBOUT;
logic CLKFBIN;
logic CLKOUT0; //* 100 MHz
logic CLKOUT1; //* CLKOUT2 / 8
logic CLKOUT2; //* 600 MHZ
logic CLKOUT3; //* 50 MHz input
logic clk_pre_pll;
logic sys_pll_locked;

IBUFG #(
      .IOSTANDARD("DEFAULT")
   ) IBUFG_inst (
      .O(clk_pre_pll), // Clock buffer output
      .I(clk_in)  // Clock buffer input (connect directly to top-level port)
   );

PLL_BASE #(
    .BANDWIDTH("OPTIMIZED"),             // "HIGH", "LOW" or "OPTIMIZED"
    .CLKFBOUT_MULT(1),                   // Multiply value for all CLKOUT clock outputs (1-64)
    .CLKFBOUT_PHASE(0.0),                // Phase offset in degrees of the clock feedback output (0.0-360.0).
    .CLKIN_PERIOD(0.0),                  // Input clock period in ns to ps resolution (i.e. 33.333 is 30
                                         // MHz).
    // CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for CLKOUT# clock output (1-128)
    .CLKOUT0_DIVIDE(1),
    .CLKOUT1_DIVIDE(1),
    .CLKOUT2_DIVIDE(1),
    .CLKOUT3_DIVIDE(1),
    .CLKOUT4_DIVIDE(1),
    .CLKOUT5_DIVIDE(1),
    // CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for CLKOUT# clock output (0.01-0.99).
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT1_DUTY_CYCLE(0.5),
    .CLKOUT2_DUTY_CYCLE(0.5),
    .CLKOUT3_DUTY_CYCLE(0.5),
    .CLKOUT4_DUTY_CYCLE(0.5),
    .CLKOUT5_DUTY_CYCLE(0.5),
    // CLKOUT0_PHASE - CLKOUT5_PHASE: Output phase relationship for CLKOUT# clock output (-360.0-360.0).
    .CLKOUT0_PHASE(0.0),
    .CLKOUT1_PHASE(0.0),
    .CLKOUT2_PHASE(0.0),
    .CLKOUT3_PHASE(0.0),
    .CLKOUT4_PHASE(0.0),
    .CLKOUT5_PHASE(0.0),
    .CLK_FEEDBACK("CLKFBOUT"),           // Clock source to drive CLKFBIN ("CLKFBOUT" or "CLKOUT0")
    .COMPENSATION("SYSTEM_SYNCHRONOUS"), // "SYSTEM_SYNCHRONOUS", "SOURCE_SYNCHRONOUS", "EXTERNAL"
    .DIVCLK_DIVIDE(1),                   // Division value for all output clocks (1-52)
    .REF_JITTER(0.1),                    // Reference Clock Jitter in UI (0.000-0.999).
    .RESET_ON_LOSS_OF_LOCK("FALSE")      // Must be set to FALSE
) PLL_main (
     .CLKFBOUT(CLKFBOUT), // 1-bit output: PLL_BASE feedback output
     // CLKOUT0 - CLKOUT5: 1-bit (each) output: Clock outputs
     .CLKOUT0(CLKOUT0),
     .CLKOUT1(CLKOUT1),
     .CLKOUT2(CLKOUT2),
     .CLKOUT3(CLKOUT3),
     //   .CLKOUT4(CLKOUT4),
     //   .CLKOUT5(CLKOUT5),
     .LOCKED(sys_pll_locked),     // 1-bit output: PLL_BASE lock status output
     .CLKFBIN(CLKFBIN),   // 1-bit input: Feedback clock input
     .CLKIN(clk_pre_pll),       // 1-bit input: Clock input
     .RST(RST)            // 1-bit input: Reset input
);

BUFG BUFG_feedback (
      .O(CLKFBIN), // Clock buffer output
      .I(CLKFBOUT)  // Clock buffer input (connect directly to top-level port)
   );

BUFG BUFG_sys_clock (
      .O(sys_clk), // Clock buffer output
      .I(CLKOUT0)  // Clock buffer input (connect directly to top-level port)
   );

BUFG BUFG_dsi_main_clock (
      .O(dsi_phy_clk), // Clock buffer output
      .I(CLKOUT1)  // Clock buffer input (connect directly to top-level port)
   );

BUFPLL #(
      .DIVIDE(1),           // DIVCLK divider (1-8)
      .ENABLE_SYNC("TRUE")  // Enable synchrnonization between PLL and GCLK (TRUE/FALSE)
   )
   BUFPLL_dphy_clk (
      .IOCLK(dsi_io_clk),               // 1-bit output: Output I/O clock
      .LOCK(),                 // 1-bit output: Synchronized LOCK output
      .SERDESSTROBE(dsi_io_serdes_latch), // 1-bit output: Output SERDES strobe (connect to ISERDES2/OSERDES2)
      .GCLK(CLKOUT3),                 // 1-bit input: BUFG clock input
      .LOCKED(sys_pll_locked),             // 1-bit input: LOCKED input from PLL
      .PLLIN(CLKOUT2)                // 1-bit input: Clock input from PLL
   );

endmodule
