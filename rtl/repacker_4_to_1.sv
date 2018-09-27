module repacker_4_to_1
(
    input   wire clk                            ,
    input   wire rst_n                          ,

    /********* Data source iface *********/
    output  wire            src_data_rqst       ,

    input   wire [31:0]     src_input_data      ,
    input   wire [3:0]      src_input_strb      ,
    input   wire            src_start_rqst      ,
    input   wire            src_fin_rqst        ,

    /********* Data sink iface *********/
    input   wire            sink_data_rqst      ,
    output  wire [7:0]      sink_input_data     ,
    output  wire            sink_start_rqst     ,
    output  wire            sink_fin_rqst

    );

logic [1:0] src_start_rqst_shift_reg;
logic [1:0] byte_counter;
logic [2:0] bytes_number;
logic [7:0] output_data_byte;

always @(posedge clk or negedge rst_n)
    if(~rst_n)      src_start_rqst_shift_reg <= 2'b0;
    else            src_start_rqst_shift_reg <= {src_start_rqst_shift_reg[0], src_start_rqst};

logic last_byte_in_buff;

assign last_byte_in_buff    = sink_data_rqst && ((byte_counter + 2'd1) == bytes_number);
assign sink_start_rqst      = src_start_rqst_shift_reg[1];
assign src_data_rqst        = src_start_rqst_shift_reg[0] || last_byte_in_buff;

logic [36:0] input_buffer_1;
logic [36:0] input_buffer_2;
logic write_buffer_1;

assign write_buffer_1 = src_start_rqst || src_data_rqst;

always @(posedge clk or negedge rst_n)
    if(~rst_n)                  input_buffer_1 <= 32'b0;
    else if(write_buffer_1)     input_buffer_1 <= {src_fin_rqst, src_input_strb, src_input_data};

logic write_buffer_2;

assign write_buffer_2 = src_data_rqst;

always @(posedge clk or negedge rst_n)
    if(~rst_n)                  input_buffer_2 <= 32'b0;
    else if(write_buffer_2)     input_buffer_2 <= input_buffer_1;

assign bytes_number = input_buffer_2[32] + input_buffer_2[33] + input_buffer_2[34] + input_buffer_2[35];

always @(posedge clk or negedge rst_n)
    if(~rst_n)                  byte_counter <= 2'b0;
    else if(sink_start_rqst)    byte_counter <= 2'b0;
    else if(sink_data_rqst)     byte_counter <= byte_counter + 2'b1;

always_comb
    begin
        case (byte_counter)
            2'd0:
                output_data_byte = input_buffer_2[7:0];

            2'd1:
                output_data_byte = input_buffer_2[15:8];

            2'd2:
                output_data_byte = input_buffer_2[23:16];

            2'd3:
                output_data_byte = input_buffer_2[31:24];

            default :
                output_data_byte = input_buffer_2[7:0];
        endcase
    end

assign sink_input_data      = output_data_byte;
assign sink_fin_rqst        = last_byte_in_buff && input_buffer_2[36];

endmodule
