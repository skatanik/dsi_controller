module packets_assembler(
    /********* Clock signals *********/
        input wire          clk_sys                 ,
        input wire          rst_n                   ,
);

`define CLK_RST(clk, rst_n)   posedge clk, negedge rst_n
`define RST(rst_n)   !rst_n

/********************************************************************
                        FSM declaration
********************************************************************/
enum logic [3:0]{
    STATE_IDLE,
    STATE_SEND_VSS,
    STATE_SEND_HSS,
    STATE_SEND_HBP,
    STATE_SEND_RGB,
    STATE_SEND_HFP,
    STATE_LPM
}

logic [3:0] state_current, state_next;

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))   state_current <= STATE_IDLE;
    else                state_current <= state_next;

endmodule