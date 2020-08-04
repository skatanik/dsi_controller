module por_controller#(
    parameter INP_RESYNC_SIZE = 128
)(
    input  wire             clk_input                   ,
    input  wire             rst_n_input                 ,

    output wire             rst_n_output                ,

    input  wire             pll_1_locked                ,
    input  wire             pll_2_locked                ,

    input  wire             clk_1_in                    ,
    output wire             rst_1_out                   ,

    input  wire             clk_2_in                    ,
    output wire             rst_2_out                   ,

    input  wire             clk_3_in                    ,
    output wire             rst_3_out                   ,

    input  wire             clk_4_in                    ,
    output wire             rst_4_out                   ,

    input  wire             clk_5_in                    ,
    output wire             rst_5_out
);


reg [INP_RESYNC_SIZE-1:0] rst_resync;
reg r_rst_outer_n;
reg r_rst_out_fin;

reg [14-1:0] rst_counter;
reg [32-1:0] pll_1_lock_sync;
reg [32-1:0] pll_2_lock_sync;

assign rst_n_output = r_rst_outer_n;

always @(posedge clk_input) begin
    rst_resync[0] <= rst_n_input;
    rst_resync[INP_RESYNC_SIZE-1:1] <= rst_resync[INP_RESYNC_SIZE-2:0];

    if(!rst_resync[INP_RESYNC_SIZE-1])
        rst_counter <= rst_counter + 1;
    else
        rst_counter <= 'b0;

    if(rst_counter == 500000)
        r_rst_outer_n <= 1'b0;
    else if(rst_resync[INP_RESYNC_SIZE-1])
        r_rst_outer_n <= 1'b1;
    else
        r_rst_outer_n <= 1'b0;

    pll_1_lock_sync[0] <= pll_1_locked;
    pll_2_lock_sync[0] <= pll_2_locked;

    pll_1_lock_sync[32-1:1] <= pll_1_lock_sync[32-2:0];
    pll_2_lock_sync[32-1:1] <= pll_2_lock_sync[32-2:0];

    r_rst_out_fin <= r_rst_outer_n && pll_1_lock_sync[32-1] && pll_2_lock_sync[32-1];

end

reg [INP_RESYNC_SIZE-1:0] rst_1_resync;
reg [INP_RESYNC_SIZE-1:0] rst_2_resync;
reg [INP_RESYNC_SIZE-1:0] rst_3_resync;
reg [INP_RESYNC_SIZE-1:0] rst_4_resync;
reg [INP_RESYNC_SIZE-1:0] rst_5_resync;

always @(posedge clk_1_in)
begin
    rst_1_resync[0] <= r_rst_out_fin;
    rst_1_resync[INP_RESYNC_SIZE-1:1] <= rst_1_resync[INP_RESYNC_SIZE-2:0];
end

assign rst_1_out = rst_1_resync[INP_RESYNC_SIZE-1];

always @(posedge clk_2_in)
begin
    rst_2_resync[0] <= r_rst_out_fin;
    rst_2_resync[INP_RESYNC_SIZE-1:1] <= rst_2_resync[INP_RESYNC_SIZE-2:0];
end

assign rst_2_out = rst_2_resync[INP_RESYNC_SIZE-1];

always @(posedge clk_3_in)
begin
    rst_3_resync[0] <= r_rst_out_fin;
    rst_3_resync[INP_RESYNC_SIZE-1:1] <= rst_3_resync[INP_RESYNC_SIZE-2:0];
end

assign rst_3_out = rst_3_resync[INP_RESYNC_SIZE-1];

always @(posedge clk_4_in)
begin
    rst_4_resync[0] <= r_rst_out_fin;
    rst_4_resync[INP_RESYNC_SIZE-1:1] <= rst_4_resync[INP_RESYNC_SIZE-2:0];
end

assign rst_4_out = rst_4_resync[INP_RESYNC_SIZE-1];

always @(posedge clk_5_in)
begin
    rst_5_resync[0] <= r_rst_out_fin;
    rst_5_resync[INP_RESYNC_SIZE-1:1] <= rst_5_resync[INP_RESYNC_SIZE-2:0];
end

assign rst_5_out = rst_5_resync[INP_RESYNC_SIZE-1];

endmodule
