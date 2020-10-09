`timescale 1ns/1ps


module tb_dsi_host;

wire                 clk_in                  ;
wire                 rst_n_in                ;
    /* DDR */
wire [16-1:0]        mcb3_dram_dq            ;
wire [14-1:0]        mcb3_dram_a             ;
wire [3-1:0]         mcb3_dram_ba            ;
wire                 mcb3_dram_ras_n         ;
wire                 mcb3_dram_cas_n         ;
wire                 mcb3_dram_we_n          ;
wire                 mcb3_dram_odt           ;
wire                 mcb3_dram_reset_n       ;
wire                 mcb3_dram_cke           ;
wire                 mcb3_dram_dm            ;
wire                 mcb3_dram_udqs          ;
wire                 mcb3_dram_udqs_n        ;
wire                 mcb3_rzq                ;
wire                 mcb3_zio                ;
wire                 mcb3_dram_udm           ;

wire                 mcb3_dram_dqs           ;
wire                 mcb3_dram_dqs_n         ;
wire                 mcb3_dram_ck            ;
wire                 mcb3_dram_ck_n          ;
    /* DPHY */
wire [3:0]      dphy_data_hs_out_p      ;
wire [3:0]      dphy_data_hs_out_n      ;
wire [3:0]      dphy_data_lp_out_p      ;
wire [3:0]      dphy_data_lp_out_n      ;
wire            dphy_clk_hs_out_p       ;
wire            dphy_clk_hs_out_n       ;
wire            dphy_clk_lp_out_p       ;
wire            dphy_clk_lp_out_n       ;
    /* HDMI parallel */
wire [24-1:0]   hdmi_data               ;
wire            hdmi_hs                 ;
wire            hdmi_vs                 ;
wire            hdmi_de                 ;
wire            hdmi_clk                ;

    /* I2C ADV */
    /* I2C EEPROM */
    /* LED */
    /* UART */
wire             rxd                     ;
wire             txd                     ;

reg r_clk_25;
reg r_rst_n;

assign clk_in       = r_clk_25;
assign rst_n_in     = r_rst_n;

initial
begin
r_clk_25 = 0;
#500
forever
begin
    #20 r_clk_25 = ~r_clk_25;
end
end


initial
begin
r_rst_n = 0;

repeat(1000) @(posedge r_clk_25);

r_rst_n = 1;


end

dsi_host_top dsi_host_top_0(
    /* CLK */
    .clk_in                  (clk_in                ),
    .rst_n_in                (rst_n_in              ),

    .mcb3_dram_dq            (mcb3_dram_dq          ),
    .mcb3_dram_a             (mcb3_dram_a           ),
    .mcb3_dram_ba            (mcb3_dram_ba          ),
    .mcb3_dram_ras_n         (mcb3_dram_ras_n       ),
    .mcb3_dram_cas_n         (mcb3_dram_cas_n       ),
    .mcb3_dram_we_n          (mcb3_dram_we_n        ),
    .mcb3_dram_odt           (mcb3_dram_odt         ),
    .mcb3_dram_reset_n       (mcb3_dram_reset_n     ),
    .mcb3_dram_cke           (mcb3_dram_cke         ),
    .mcb3_dram_dm            (mcb3_dram_dm          ),
    .mcb3_dram_udqs          (mcb3_dram_udqs        ),
    .mcb3_dram_udqs_n        (mcb3_dram_udqs_n      ),
    .mcb3_rzq                (mcb3_rzq              ),
    .mcb3_zio                (mcb3_zio              ),
    .mcb3_dram_udm           (mcb3_dram_udm         ),
    .mcb3_dram_dqs           (mcb3_dram_dqs         ),
    .mcb3_dram_dqs_n         (mcb3_dram_dqs_n       ),
    .mcb3_dram_ck            (mcb3_dram_ck          ),
    .mcb3_dram_ck_n          (mcb3_dram_ck_n        ),
    .rzq3                     (1'b0                 ),
    .zio3                     (1'b0                 ),
    /* DPHY */
    .dphy_data_hs_out_p      (dphy_data_hs_out_p    ),
    .dphy_data_hs_out_n      (dphy_data_hs_out_n    ),
    .dphy_data_lp_out_p      (dphy_data_lp_out_p    ),
    .dphy_data_lp_out_n      (dphy_data_lp_out_n    ),
    .dphy_clk_hs_out_p       (dphy_clk_hs_out_p     ),
    .dphy_clk_hs_out_n       (dphy_clk_hs_out_n     ),
    .dphy_clk_lp_out_p       (dphy_clk_lp_out_p     ),
    .dphy_clk_lp_out_n       (dphy_clk_lp_out_n     ),
    /* HDMI parallel */
    .hdmi_data               (hdmi_data             ),
    .hdmi_hs                 (hdmi_hs               ),
    .hdmi_vs                 (hdmi_vs               ),
    .hdmi_de                 (hdmi_de               ),
    .hdmi_clk                (hdmi_clk              ),

    /* I2C ADV */
    /* I2C EEPROM */
    /* LED */
    /* UART */
    .rxd                     (rxd                   ),
    .txd                     (txd                   )
    /* BUTTON */
    );

reg [31:0] debug_symbol;

always @(posedge dsi_host_top_0.sys_clk) begin
    if(dsi_host_top_0.picorv32_core.bus_write) begin
        if(dsi_host_top_0.picorv32_core.bus_addr == 32'h1000_0000) begin
            debug_symbol <= dsi_host_top_0.picorv32_core.bus_writedata;
            $write("%c", debug_symbol);
        end
    end

end

endmodule