	component top_level_system is
		port (
			clk_clk                                              : in  std_logic                    := 'X'; -- clk
			dsi_tx_controller_0_dsi_interface_dphy_data_hs_out_p : out std_logic_vector(3 downto 0);        -- dphy_data_hs_out_p
			dsi_tx_controller_0_dsi_interface_dphy_data_hs_out_n : out std_logic_vector(3 downto 0);        -- dphy_data_hs_out_n
			dsi_tx_controller_0_dsi_interface_dphy_data_lp_out_p : out std_logic_vector(3 downto 0);        -- dphy_data_lp_out_p
			dsi_tx_controller_0_dsi_interface_dphy_data_lp_out_n : out std_logic_vector(3 downto 0);        -- dphy_data_lp_out_n
			dsi_tx_controller_0_dsi_interface_dphy_clk_hs_out_p  : out std_logic;                           -- dphy_clk_hs_out_p
			dsi_tx_controller_0_dsi_interface_dphy_clk_hs_out_n  : out std_logic;                           -- dphy_clk_hs_out_n
			dsi_tx_controller_0_dsi_interface_dphy_clk_lp_out_p  : out std_logic;                           -- dphy_clk_lp_out_p
			dsi_tx_controller_0_dsi_interface_dphy_clk_lp_out_n  : out std_logic;                           -- dphy_clk_lp_out_n
			reset_reset_n                                        : in  std_logic                    := 'X'; -- reset_n
			altpll_0_areset_conduit_export                       : in  std_logic                    := 'X'  -- export
		);
	end component top_level_system;

	u0 : component top_level_system
		port map (
			clk_clk                                              => CONNECTED_TO_clk_clk,                                              --                               clk.clk
			dsi_tx_controller_0_dsi_interface_dphy_data_hs_out_p => CONNECTED_TO_dsi_tx_controller_0_dsi_interface_dphy_data_hs_out_p, -- dsi_tx_controller_0_dsi_interface.dphy_data_hs_out_p
			dsi_tx_controller_0_dsi_interface_dphy_data_hs_out_n => CONNECTED_TO_dsi_tx_controller_0_dsi_interface_dphy_data_hs_out_n, --                                  .dphy_data_hs_out_n
			dsi_tx_controller_0_dsi_interface_dphy_data_lp_out_p => CONNECTED_TO_dsi_tx_controller_0_dsi_interface_dphy_data_lp_out_p, --                                  .dphy_data_lp_out_p
			dsi_tx_controller_0_dsi_interface_dphy_data_lp_out_n => CONNECTED_TO_dsi_tx_controller_0_dsi_interface_dphy_data_lp_out_n, --                                  .dphy_data_lp_out_n
			dsi_tx_controller_0_dsi_interface_dphy_clk_hs_out_p  => CONNECTED_TO_dsi_tx_controller_0_dsi_interface_dphy_clk_hs_out_p,  --                                  .dphy_clk_hs_out_p
			dsi_tx_controller_0_dsi_interface_dphy_clk_hs_out_n  => CONNECTED_TO_dsi_tx_controller_0_dsi_interface_dphy_clk_hs_out_n,  --                                  .dphy_clk_hs_out_n
			dsi_tx_controller_0_dsi_interface_dphy_clk_lp_out_p  => CONNECTED_TO_dsi_tx_controller_0_dsi_interface_dphy_clk_lp_out_p,  --                                  .dphy_clk_lp_out_p
			dsi_tx_controller_0_dsi_interface_dphy_clk_lp_out_n  => CONNECTED_TO_dsi_tx_controller_0_dsi_interface_dphy_clk_lp_out_n,  --                                  .dphy_clk_lp_out_n
			reset_reset_n                                        => CONNECTED_TO_reset_reset_n,                                        --                             reset.reset_n
			altpll_0_areset_conduit_export                       => CONNECTED_TO_altpll_0_areset_conduit_export                        --           altpll_0_areset_conduit.export
		);

