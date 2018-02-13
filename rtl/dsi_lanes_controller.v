module dsi_lanes_controller
    (
        /********* Clock signals *********/
        input wire          clk,
        input wire          reset_n,

        /********* Fifo signals *********/

        input wire [32:0]   fifo_data,      // data + speed flag. fifo_data[32]: 1 - hs, 0 - lp
        input wire          fifo_empty,

        output wire         fifo_read,

        /********* Misc signals *********/

        input wire [1:0]    lanes_number


        /********* Output signals *********/

    );



endmodule
