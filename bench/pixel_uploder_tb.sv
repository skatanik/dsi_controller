module pixel_uploader_tb();

localparam DATA_SIZE = 727040;

logic [31:0] memory_data [0:DATA_SIZE - 1];
logic [31:0] memory_data_read [0:DATA_SIZE-1];

bit clk;
bit clk_slow;
bit rst_n;
bit rst_n_slow;

logic [255:0] alv_dataread;
logic         avl_read;
logic         avl_waitrequest;
logic         avl_datavalid;
logic [31:0]  avl_address;

logic [31:0] fifo_data;
logic        fifo_read;
logic        fifo_empty;

initial
begin
rst_n = 0;
clk = 0;
repeat(30) @(posedge clk);
rst_n = 1;
end

initial
begin
clk_slow = 0;
rst_n_slow = 0;
repeat(30) @(posedge clk_slow);
rst_n_slow = 1;
end

always
 #10 clk = !clk;

always
 #10 clk_slow = !clk_slow;

semaphore mem_read_sem;
semaphore fifo_read_sem;

for(int i = 0; i < DATA_SIZE; i = i + 1)
    memory_data = $urandom_range(0,32'hffffffff);

task automatic memory_read;

mem_read_sem.get(1);

logic data_ready;

data_ready = $urandom_range(0,1);

wait(avl_read);

avl_waitrequest = avl_read & !data_ready;
@(posedge clk);
if(!data_ready)
    repeat($urandom_range(4,0)) @(posedge clk);

avl_waitrequest = 0;

@(posedge clk);
avl_datavalid = 1;

for(int i = 0 ; i < 8; i = i + 1)
    alv_dataread[i*32 + 31 : i*32] = memory_data[i];

@(posedge clk);

avl_datavalid = 0;
alv_dataread = 0'

mem_read_sem.put(1);

endtask : memory_read


logic fifo_mem_addr;

task fifo_read;

fifo_read_sem.get(1);

logic [31:0] data_pointer;

data_pointer = 0;

repeat(100) @(posedge clk_slow);

for(int i = 0; i < 1135; i = i + 1)
begin
    for(int j = 0; j < 639; j = j + 1)
    begin
            fifo_read = 1;
            if(fifo_empty)
            begin
                $display("FIFO empty!");
                $finish;
            end

            @(posedge clk_slow);
            memory_data_read[data_pointer] = fifo_data;
            data_pointer = data_pointer + 1;
    end

fifo_read = 0;
repeat(20) @(posedge clk_slow);
end

fifo_read_sem.put(1);

endtask : fifo_read

initial
begin

wait(rst_n);
forever
begin
    fork
        memory_read;
        fifo_read;
    join_any
end
end

endmodule
