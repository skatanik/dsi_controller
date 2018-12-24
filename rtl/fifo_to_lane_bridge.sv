module fifo_to_lane_bridge (
    input   wire                clk             ,    // Clock
    input   wire                rst_n           ,  // Asynchronous reset active low

    /********* input fifo iface *********/
    input   wire [7:0]          fifo_data       ,
    input   wire                fifo_empty      ,
    output  wire                fifo_read       ,

    input   wire                mode_lp         ,

    /********* Lane iface *********/
    output  wire                mode_lp             , // which mode to use to send data throught this lane. 0 - hs, 1 - lp
    output  wire                start_rqst          ,
    output  wire                fin_rqst            ,
    output  wire [7:0]          inp_data            ,
    input   wire                data_rqst           ,

    /********* packet to packet timeout *********/
    input   wire [15:0]         p2p_timeout

);

logic           state_active;
logic [32:0]    out_buffer;
logic           read_fifo;
logic           read_fifo_second;
logic           fifo_not_empty;

assign read_fifo    = !state_active ? fifo_not_empty : fifo_not_empty & (data_rqst | read_fifo_second);

always_ff @(posedge clk or negedge rst_n)
    if(!rst_n)                                      state_active <= 1'b0;
    else if(!state_active & fifo_not_empty)         state_active <= 1'b1;
    else if(state_active & !fifo_not_empty)         state_active <= 1'b0;

always_ff @(posedge clk or negedge rst_n)
    if(!rst_n)      read_fifo_second <= 1'b0;
    else            read_fifo_second <= !state_active & fifo_not_empty;

assign fin_rqst     = state_active & !fifo_not_empty;
assign start_rqst   = read_fifo_second;
assign inp_data     = out_buffer;

always_ff @(posedge clk or negedge rst_n)
    if(!rst_n)              out_buffer <= 7'b0;
    else if(read_fifo)      out_buffer <= fifo_data;

/********* timeout counter *********/
logic [15:0]    counter;

always_ff @(posedge clk or negedge rst_n)
    if(!rst_n)          counter <= 16'b0;
    else if(fin_rqst)   counter <= p2p_timeout;
    else if(|counter)   counter <= counter - 16'd1;

assign fifo_not_empty = !fifo_empty & !(|counter);

endmodule