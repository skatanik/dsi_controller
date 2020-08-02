module hdmi_recv(
    input   wire            hdmi_rst_n              ,
    input   wire            hdmi_clk                ,

    input   wire [24-1:0]   hdmi_data               ,
    input   wire            hdmi_hs                 ,
    input   wire            hdmi_vs                 ,
    input   wire            hdmi_de                 ,

    /********* ST output *********/
    input   wire            rst_sys_n               ,
    input   wire            clk_sys                 ,

    output  wire [31:0]     st_data                 ,
    output  wire            st_valid                ,
    output  wire            st_endofpacket          ,
    output  wire            st_startofpacket        ,
    input   wire            st_ready
);

endmodule