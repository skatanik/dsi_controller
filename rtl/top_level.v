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
    .clk                     (),
    .rst_n                   (),

    .bus_addr                (),

    .bus_read                (),
    .bus_readdata            (),
    .bus_response            (),

    .bus_write               (),
    .bus_writedata           (),
    .bus_byteenable          (),

    .bus_waitrequest         (),

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
    .s0_bus_addr                (),
    .s0_bus_read                (),
    .s0_bus_readdata            (),
    .s0_bus_response            (),
    .s0_bus_write               (),
    .s0_bus_writedata           (),
    .s0_bus_byteenable          (),
    .s0_bus_waitrequest         (),

    //* Master port 0
    .m0_bus_addr                (),
    .m0_bus_read                (),
    .m0_bus_readdata            (),
    .m0_bus_response            (),
    .m0_bus_write               (),
    .m0_bus_writedata           (),
    .m0_bus_byteenable          (),
    .m0_bus_waitrequest         (),

    //* Master port 1
    .m1_bus_addr                (),
    .m1_bus_read                (),
    .m1_bus_readdata            (),
    .m1_bus_response            (),
    .m1_bus_write               (),
    .m1_bus_writedata           (),
    .m1_bus_byteenable          (),
    .m1_bus_waitrequest         (),

    //* Master port 2
    .m2_bus_addr                (),
    .m2_bus_read                (),
    .m2_bus_readdata            (),
    .m2_bus_response            (),
    .m2_bus_write               (),
    .m2_bus_writedata           (),
    .m2_bus_byteenable          (),
    .m2_bus_waitrequest         (),

    //* Master port 3
    .m3_bus_addr                (),
    .m3_bus_read                (),
    .m3_bus_readdata            (),
    .m3_bus_response            (),
    .m3_bus_write               (),
    .m3_bus_writedata           (),
    .m3_bus_byteenable          (),
    .m3_bus_waitrequest         (),

    //* Master port 4
    .m4_bus_addr                (),
    .m4_bus_read                (),
    .m4_bus_readdata            (),
    .m4_bus_response            (),
    .m4_bus_write               (),
    .m4_bus_writedata           (),
    .m4_bus_byteenable          (),
    .m4_bus_waitrequest         (),

    //* Master port 5
    .m5_bus_addr                (),
    .m5_bus_read                (),
    .m5_bus_readdata            (),
    .m5_bus_response            (),
    .m5_bus_write               (),
    .m5_bus_writedata           (),
    .m5_bus_byteenable          (),
    .m5_bus_waitrequest         (),

    //* Master port 6
    .m6_bus_addr                (),
    .m6_bus_read                (),
    .m6_bus_readdata            (),
    .m6_bus_response            (),
    .m6_bus_write               (),
    .m6_bus_writedata           (),
    .m6_bus_byteenable          (),
    .m6_bus_waitrequest         (),

    //* Master port 7
    .m7_bus_addr                (),
    .m7_bus_read                (),
    .m7_bus_readdata            (),
    .m7_bus_response            (),
    .m7_bus_write               (),
    .m7_bus_writedata           (),
    .m7_bus_byteenable          (),
    .m7_bus_waitrequest         (),

    //* Master port 8
    .m8_bus_addr                (),
    .m8_bus_read                (),
    .m8_bus_readdata            (),
    .m8_bus_response            (),
    .m8_bus_write               (),
    .m8_bus_writedata           (),
    .m8_bus_byteenable          (),
    .m8_bus_waitrequest         ()
);

//* DDR3 controller

//* HDMI ADV Recv

//* HDMI native

//* Pixel reader

//* DSI +
dsi_tx_top #(
    parameter LINE_WIDTH            = 640,
    parameter BITS_PER_PIXEL        = 8,
    parameter BLANK_TIME            = 100,
    parameter BLANK_TIME_HBP_ACT    = 100,
    parameter VSA_LINES_NUMBER      = 100,
    parameter VBP_LINES_NUMBER      = 100,
    parameter IMAGE_HEIGHT          = 100,
    parameter VFP_LINES_NUMBER      = 100
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

//* GPIO

//* Timer

//* Clocking

endmodule
