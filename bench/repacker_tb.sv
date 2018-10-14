`timescale 1ns/1ps

`define CLK_RST(clk, rst_n)   posedge clk, negedge rst_n
`define RST(rst_n)   !rst_n

module repacker_tb();

bit clk;
bit reset_n;

logic [31:0] output_data;
logic [31:0] input_data_1;  // main data
logic [31:0] input_data_2;  // aditional data
logic [31:0] temp_buffer;
logic [2:0]  offset_value;
logic [5:0] data_size_left;
logic        ask_for_extra_data;
logic        read_data;

assign ask_for_extra_data = (data_size_left + offset_value) < 4 ;

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))               output_data <= 32'b0;
    else if(read_data)
        if(ask_for_extra_data)      output_data <= (input_data_1 << (offset_value * 8)) | temp_buffer | (input_data_2 << ((data_size_left + offset_value) * 8));
        else                        output_data <= (input_data_1 << (offset_value * 8)) | temp_buffer;

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))               temp_buffer <= 32'b0;
    else if(read_data)
        if(ask_for_extra_data)      temp_buffer <= 32'b0 | (input_data_2 >> ((4 - data_size_left - offset_value) * 8));
        else                        temp_buffer <= (input_data_1 >> ((4 - offset_value) * 8));

always @(`CLK_RST(clk, reset_n))
    if(`RST(reset_n))                            offset_value <= 3'b0;
    else if(read_data && ask_for_extra_data)     offset_value <= (4 - data_size_left - offset_value);

always
#10 clk = !clk;

initial
begin
reset_n = 0;
repeat(10) @(posedge clk);
reset_n = 1;
end

logic [31:0] temp_data;
logic [31:0] mask;

initial
begin
input_data_1 = $urandom_range(0,32'hffff_ffff);
input_data_2 = $urandom_range(0,32'hffff_ffff);
data_size_left = $urandom_range(0,5'h1f) + 4;
forever
    begin
        repeat(1) @(posedge clk);
        if(read_data)
        begin
            if(data_size_left < 4)
                data_size_left = $urandom_range(0,5'h1f);
            else
                data_size_left = (data_size_left - 4 == 0) ? $urandom_range(0,5'h1f) : data_size_left - 4;

            temp_data = $urandom_range(0,32'hffff_ffff);
            mask = 32'hffff_ffff >> (((data_size_left > 4) ? 0 : (4 - data_size_left % 4) * 8) );
            input_data_1 = temp_data & mask;
            $display("Data %h", temp_data);
            $display("mask %h", mask);
            $display("Data left %d", data_size_left);
            $display("------------------");

            if(ask_for_extra_data)
                input_data_2 = $urandom_range(0,32'hffff_ffff);
        end
    end

end

initial
begin
read_data = 0;

wait (reset_n);
repeat(10) @(posedge clk);

forever
begin
    repeat($urandom_range(1,3)) @(posedge clk);
    #0.1 read_data = !read_data;
end

end

endmodule