module fifo_to_lane_bridge (
    input   wire                clk                 ,    // Clock
    input   wire                rst_n               ,  // Asynchronous reset active low

    /********* input fifo iface *********/
    input   wire [7:0]          fifo_data           ,
    input   wire                fifo_empty          ,
    output  wire                fifo_read           ,

    input   wire                mode_lp_in          ,

    /********* Lane iface *********/
    output  wire                mode_lp             , // which mode to use to send data throught this lane. 0 - hs, 1 - lp
    output  wire                start_rqst          ,
    output  wire                fin_rqst            ,
    output  wire [7:0]          inp_data            ,
    input   wire                data_rqst           ,

    /********* packet to packet timeout *********/
    input   wire [15:0]         p2p_timeout

);

logic [7:0] middle_buffer;
logic       fifo_empty_delayed;
logic       state_active;
logic       mode_lp_reg;
logic [7:0] fifo_data_inv;

genvar i;
generate
    for (i = 0; i < 8; i = i + 1) begin: lines_inversion
        assign fifo_data_inv[i] = fifo_data[7-i];
    end
endgenerate

always_ff @(posedge clk or negedge rst_n)
    if(!rst_n)      fifo_empty_delayed <= 1'b0;
    else            fifo_empty_delayed <= fifo_empty;

assign start_rqst = (fifo_empty_delayed ^ fifo_empty) & !fifo_empty & !state_active & data_rqst;

always_ff @(posedge clk or negedge rst_n)
    if(!rst_n)                  state_active <= 1'b0;
    else if(start_rqst)         state_active <= 1'b1;
    else if(fin_rqst)           state_active <= 1'b0;

always_ff @(posedge clk or negedge rst_n)
    if(!rst_n)                  mode_lp_reg <= 1'b0;
    else if(fifo_read)          mode_lp_reg <= mode_lp_in;
    else if(fin_rqst)           mode_lp_reg <= 1'b0;

always_ff @(posedge clk or negedge rst_n)
    if(!rst_n)                                          middle_buffer <= 1'b0;
    else if(start_rqst)                                 middle_buffer <= fifo_data_inv;
    else if(!fifo_empty && data_rqst && state_active)   middle_buffer <= fifo_data_inv;

assign fin_rqst     = (fifo_empty_delayed ^ fifo_empty) & fifo_empty & state_active;
assign mode_lp      = mode_lp_in;
assign fifo_read    = state_active & data_rqst & !fifo_empty | start_rqst;
assign inp_data     = middle_buffer;

/********* timeout counter *********/
logic [15:0]    counter;

always_ff @(posedge clk or negedge rst_n)
    if(!rst_n)          counter <= 16'b0;
    else if(fin_rqst)   counter <= p2p_timeout;
    else if(|counter)   counter <= counter - 16'd1;

assign fifo_not_empty = !fifo_empty & !(|counter);

endmodule