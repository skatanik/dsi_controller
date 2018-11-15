module ecc_calc
    (
        input  wire [23:0]  data,

        output wire [7:0]   ecc_result
    );

    assign ecc_result[0]    = ^{data[2:0], data[5:4], data[7], data[11:10], data[13], data[16], data[23:20]};
    assign ecc_result[1]    = ^{data[1:0], data[4:3], data[6], data[8], data[10], data[12], data[14], data[17], data[23:20]};
    assign ecc_result[2]    = ^{data[0], data[3:2], data[6:5], data[9], data[12:11], data[15], data[18], data[22:20] };
    assign ecc_result[3]    = ^{data[3:1], data[9:7], data[15:13], data[21:19], data[23]};
    assign ecc_result[4]    = ^{data[9:4], data[20:16], data[23:22]};
    assign ecc_result[5]    = ^{data[19:10], data[23:21]};
    assign ecc_result[7:6]  = 2'b0;

endmodule

module byte_crc
    (
        input  wire [7:0]   data_in,

        input  wire [15:0]  crc_in,
        output wire [15:0]  crc_res
    );


//-----------------------------------------------------------------------------
// CRC module for data[7:0] ,   crc[15:0]=1+x^5+x^12+x^16;
//-----------------------------------------------------------------------------

// Next code was generated using http://outputlogic.com/
logic [15:0] crc_res_r;

assign crc_res = crc_res_r;

    always_comb
    begin
        crc_res_r[0] = crc_in[8] ^ crc_in[12] ^ data_in[0] ^ data_in[4];
        crc_res_r[1] = crc_in[9] ^ crc_in[13] ^ data_in[1] ^ data_in[5];
        crc_res_r[2] = crc_in[10] ^ crc_in[14] ^ data_in[2] ^ data_in[6];
        crc_res_r[3] = crc_in[11] ^ crc_in[15] ^ data_in[3] ^ data_in[7];
        crc_res_r[4] = crc_in[12] ^ data_in[4];
        crc_res_r[5] = crc_in[8] ^ crc_in[12] ^ crc_in[13] ^ data_in[0] ^ data_in[4] ^ data_in[5];
        crc_res_r[6] = crc_in[9] ^ crc_in[13] ^ crc_in[14] ^ data_in[1] ^ data_in[5] ^ data_in[6];
        crc_res_r[7] = crc_in[10] ^ crc_in[14] ^ crc_in[15] ^ data_in[2] ^ data_in[6] ^ data_in[7];
        crc_res_r[8] = crc_in[0] ^ crc_in[11] ^ crc_in[15] ^ data_in[3] ^ data_in[7];
        crc_res_r[9] = crc_in[1] ^ crc_in[12] ^ data_in[4];
        crc_res_r[10] = crc_in[2] ^ crc_in[13] ^ data_in[5];
        crc_res_r[11] = crc_in[3] ^ crc_in[14] ^ data_in[6];
        crc_res_r[12] = crc_in[4] ^ crc_in[8] ^ crc_in[12] ^ crc_in[15] ^ data_in[0] ^ data_in[4] ^ data_in[7];
        crc_res_r[13] = crc_in[5] ^ crc_in[9] ^ crc_in[13] ^ data_in[1] ^ data_in[5];
        crc_res_r[14] = crc_in[6] ^ crc_in[10] ^ crc_in[14] ^ data_in[2] ^ data_in[6];
        crc_res_r[15] = crc_in[7] ^ crc_in[11] ^ crc_in[15] ^ data_in[3] ^ data_in[7];
    end

endmodule

module crc_calculator
    (
        input  wire          clk                ,
        input  wire          reset_n            ,

        input  wire          clear              ,   // reset crc
        input  wire          data_write         ,   // latch crc
        input  wire [1:0]    bytes_number       ,   // bytes number. 0 means that only the first byte from data_input will be used. 1 means that first 2 bytes from data_input will be used etc.
        input  wire [31:0]   data_input         ,

        output wire [15:0]   crc_output_async   ,
        output wire [15:0]   crc_output_sync
    );

reg [15:0] crc_result;

wire [15:0] crc_out[0:3];

assign crc_output_async = crc_out[bytes_number];
assign crc_output_sync  = crc_result;

always @(posedge clk, negedge reset_n)
    if(!reset_n)            crc_result <= 16'hffff;
    else if(clear)          crc_result <= 16'hffff;
    else if(data_write)     crc_result <= crc_out[bytes_number];

byte_crc crc_out_1(
    .data_in    (data_input[7:0]    ),
    .crc_in     (crc_result         ),
    .crc_res    (crc_out[0]          )
    );

byte_crc crc_out_2(
    .data_in    (data_input[15:8]    ),
    .crc_in     (crc_out[0]          ),
    .crc_res    (crc_out[1]          )
    );

byte_crc crc_out_3(
    .data_in    (data_input[23:16]   ),
    .crc_in     (crc_out[1]          ),
    .crc_res    (crc_out[2]          )
    );

byte_crc crc_out_4(
    .data_in    (data_input[31:24]  ),
    .crc_in     (crc_out[2]         ),
    .crc_res    (crc_out[3]         )
    );

endmodule
