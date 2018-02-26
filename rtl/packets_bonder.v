
/********************************************************************
    This module deletes spaces between packets in fifo, bonding fifo data to continious stream.
    also it adds ecc and crc to packets. therefore data from this module can be directly written to serdeses
********************************************************************/

module packets_bonder
    (
        input  wire             clk             ,
        input  wire             reset_n         ,

/********* input data *********/
        input  wire [31:0]      input_data      ,
        input  wire             enable          ,
        output wire             data_request    ,

/********* output data *********/
        output wire [31:0]      output_data     ,
        output wire             ready           ,
        input  wire             read_data
    );




endmodule // packets_bonder
