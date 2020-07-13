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
    /* USART */
    /* BUTTON */
    );


//* RISC V core +

//* Interconnect (MUX) +

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
    .C3_MEM_BANKADDR_WIDTH(3)
)
u_mig_ddr3 (

    .c3_sys_clk                             (c3_sys_clk),
    .c3_sys_rst_i                           (c3_sys_rst_i),

    .mcb3_dram_dq                           (mcb3_dram_dq),
    .mcb3_dram_a                            (mcb3_dram_a),
    .mcb3_dram_ba                           (mcb3_dram_ba),
    .mcb3_dram_ras_n                        (mcb3_dram_ras_n),
    .mcb3_dram_cas_n                        (mcb3_dram_cas_n),
    .mcb3_dram_we_n                         (mcb3_dram_we_n),
    .mcb3_dram_odt                          (mcb3_dram_odt),
    .mcb3_dram_cke                          (mcb3_dram_cke),
    .mcb3_dram_ck                           (mcb3_dram_ck),
    .mcb3_dram_ck_n                         (mcb3_dram_ck_n),
    .mcb3_dram_dqs                          (mcb3_dram_dqs),
    .mcb3_dram_dqs_n                        (mcb3_dram_dqs_n),
    .mcb3_dram_udqs                         (mcb3_dram_udqs),    // for X16 parts
    .mcb3_dram_udqs_n                       (mcb3_dram_udqs_n),  // for X16 parts
    .mcb3_dram_udm                          (mcb3_dram_udm),     // for X16 parts
    .mcb3_dram_dm                           (mcb3_dram_dm),
    .mcb3_dram_reset_n                      (mcb3_dram_reset_n),
    .c3_clk0		                        (c3_clk0),
    .c3_rst0		                        (c3_rst0),

    .c3_calib_done                          (c3_calib_done),
    .mcb3_rzq                               (rzq3),

    .mcb3_zio                               (zio3),

    .c3_p0_cmd_clk                          (c3_p0_cmd_clk),
    .c3_p0_cmd_en                           (c3_p0_cmd_en),
    .c3_p0_cmd_instr                        (c3_p0_cmd_instr),
    .c3_p0_cmd_bl                           (c3_p0_cmd_bl),
    .c3_p0_cmd_byte_addr                    (c3_p0_cmd_byte_addr),
    .c3_p0_cmd_empty                        (c3_p0_cmd_empty),
    .c3_p0_cmd_full                         (c3_p0_cmd_full),
    .c3_p0_wr_clk                           (c3_p0_wr_clk),
    .c3_p0_wr_en                            (c3_p0_wr_en),
    .c3_p0_wr_mask                          (c3_p0_wr_mask),
    .c3_p0_wr_data                          (c3_p0_wr_data),
    .c3_p0_wr_full                          (c3_p0_wr_full),
    .c3_p0_wr_empty                         (c3_p0_wr_empty),
    .c3_p0_wr_count                         (c3_p0_wr_count),
    .c3_p0_wr_underrun                      (c3_p0_wr_underrun),
    .c3_p0_wr_error                         (c3_p0_wr_error),
    .c3_p0_rd_clk                           (c3_p0_rd_clk),
    .c3_p0_rd_en                            (c3_p0_rd_en),
    .c3_p0_rd_data                          (c3_p0_rd_data),
    .c3_p0_rd_full                          (c3_p0_rd_full),
    .c3_p0_rd_empty                         (c3_p0_rd_empty),
    .c3_p0_rd_count                         (c3_p0_rd_count),
    .c3_p0_rd_overflow                      (c3_p0_rd_overflow),
    .c3_p0_rd_error                         (c3_p0_rd_error),
    .c3_p1_cmd_clk                          (c3_p1_cmd_clk),
    .c3_p1_cmd_en                           (c3_p1_cmd_en),
    .c3_p1_cmd_instr                        (c3_p1_cmd_instr),
    .c3_p1_cmd_bl                           (c3_p1_cmd_bl),
    .c3_p1_cmd_byte_addr                    (c3_p1_cmd_byte_addr),
    .c3_p1_cmd_empty                        (c3_p1_cmd_empty),
    .c3_p1_cmd_full                         (c3_p1_cmd_full),
    .c3_p1_wr_clk                           (c3_p1_wr_clk),
    .c3_p1_wr_en                            (c3_p1_wr_en),
    .c3_p1_wr_mask                          (c3_p1_wr_mask),
    .c3_p1_wr_data                          (c3_p1_wr_data),
    .c3_p1_wr_full                          (c3_p1_wr_full),
    .c3_p1_wr_empty                         (c3_p1_wr_empty),
    .c3_p1_wr_count                         (c3_p1_wr_count),
    .c3_p1_wr_underrun                      (c3_p1_wr_underrun),
    .c3_p1_wr_error                         (c3_p1_wr_error),
    .c3_p1_rd_clk                           (c3_p1_rd_clk),
    .c3_p1_rd_en                            (c3_p1_rd_en),
    .c3_p1_rd_data                          (c3_p1_rd_data),
    .c3_p1_rd_full                          (c3_p1_rd_full),
    .c3_p1_rd_empty                         (c3_p1_rd_empty),
    .c3_p1_rd_count                         (c3_p1_rd_count),
    .c3_p1_rd_overflow                      (c3_p1_rd_overflow),
    .c3_p1_rd_error                         (c3_p1_rd_error),
    .c3_p2_cmd_clk                          (c3_p2_cmd_clk),
    .c3_p2_cmd_en                           (c3_p2_cmd_en),
    .c3_p2_cmd_instr                        (c3_p2_cmd_instr),
    .c3_p2_cmd_bl                           (c3_p2_cmd_bl),
    .c3_p2_cmd_byte_addr                    (c3_p2_cmd_byte_addr),
    .c3_p2_cmd_empty                        (c3_p2_cmd_empty),
    .c3_p2_cmd_full                         (c3_p2_cmd_full),
    .c3_p2_wr_clk                           (c3_p2_wr_clk),
    .c3_p2_wr_en                            (c3_p2_wr_en),
    .c3_p2_wr_mask                          (c3_p2_wr_mask),
    .c3_p2_wr_data                          (c3_p2_wr_data),
    .c3_p2_wr_full                          (c3_p2_wr_full),
    .c3_p2_wr_empty                         (c3_p2_wr_empty),
    .c3_p2_wr_count                         (c3_p2_wr_count),
    .c3_p2_wr_underrun                      (c3_p2_wr_underrun),
    .c3_p2_wr_error                         (c3_p2_wr_error),
    .c3_p2_rd_clk                           (c3_p2_rd_clk),
    .c3_p2_rd_en                            (c3_p2_rd_en),
    .c3_p2_rd_data                          (c3_p2_rd_data),
    .c3_p2_rd_full                          (c3_p2_rd_full),
    .c3_p2_rd_empty                         (c3_p2_rd_empty),
    .c3_p2_rd_count                         (c3_p2_rd_count),
    .c3_p2_rd_overflow                      (c3_p2_rd_overflow),
    .c3_p2_rd_error                         (c3_p2_rd_error)
);

//* HDMI ADV Recv

//* HDMI native

//* Pixel reader

//* DSI +

//* I2C master

//* Usart RX/TX

//* Programm Mem

//* GPIO

//* Timer

//* Clocking

endmodule
