module repacker_4_to_4_tb();

bit clk;
bit rst_n;

logic [31:0] data_inp;
logic [31:0] data_out;

logic [3:0] input_strb;
logic [3:0] last_data_strb;

logic dchange_req;
logic data_req;

logic enable;

repacker_4_to_4 inst0(
    .clk                (clk            ),
    .rst_n              (rst_n          ),

    .data_req           (data_req       ),   // data request signal. Need to get new data on the next clock.
    .data_out           (data_out       ),   // output data
    .last_data_strb     (last_data_strb ),   // strobes indicate last data bytes on each line

    .data_change_req    (dchange_req    ),   // request data changing. new data on the next clock is needed
    .input_data         (data_inp       ),   // input data
    .input_strb         (input_strb     ),   // input strobes

    .enable             (enable         )   // enable repacker signal
    );

initial
begin
clk     = 0;
rst_n   = 0;

repeat(10) @(posedge clk);

rst_n = 1;

end

always
#10 clk = ~clk;

initial
begin
data_inp    = 0;
input_strb  = 0;
enable  = 0;
wait(rst_n);

repeat(10) @(posedge clk);

write_data();

end

initial
begin
data_req = 0;

wait(rst_n);
repeat(12) @(posedge clk);

#0.01 data_req = 1;
end

task write_data;

    integer data_size = $urandom_range(0, 64);
    bit [31:0] data_array [15:0];
    integer i = 0;

    for (int i = 0; i < 16; i = i + 1) begin
         data_array[i] = $urandom_range(0, 32'hffff_ffff);
    end

    enable = 1;
    input_strb = 4'hf;
    data_inp = data_array[i];
    i = i + 1;

    while(i <= data_size / 4) begin
        repeat(1) @(posedge clk);
        if(dchange_req)
        begin

            #0.01 data_inp = data_array[i];

            if(data_size/4 == i)
                input_strb = 4'b1100;
            else if(data_size/4 - 1 == i)
                input_strb = 4'b0011;
            else  input_strb = 4'hf;
        end
        i = i + 1;
    end
    repeat(1) @(posedge clk);

    #0.001 enable = 0;
endtask : write_data



endmodule // repacker_4_to_4