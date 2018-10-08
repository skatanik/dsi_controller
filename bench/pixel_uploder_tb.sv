`timescale 1ns/1ps
module pixel_uploader_tb();

localparam DATA_SIZE = 27264;

bit [31:0] memory_data [0:36352 - 1];
bit [31:0] memory_data_remapped [0:DATA_SIZE-1];

bit clk;
bit clk_slow;
bit rst_n;
bit rst_n_slow;

logic [255:0]   alv_dataread;
logic           avl_read;
logic           avl_waitrequest;
logic           avl_datavalid;
logic [31:0]    avl_address;

logic [31:0]    fifo_data;
logic           fifo_read;
logic           fifo_empty;
logic           upl_enable;

initial
begin
rst_n = 0;
clk = 0;
upl_enable = 0;
repeat(30) @(posedge clk);
rst_n = 1;
repeat(30) @(posedge clk);
upl_enable = 1;

end

initial
begin
clk_slow = 0;
rst_n_slow = 0;
repeat(30) @(posedge clk_slow);
rst_n_slow = 1;
end

initial
begin
alv_dataread = 0;
avl_waitrequest = 0;
avl_datavalid = 0;
fifo_read = 0;

end

initial
begin
for(int i = 0; i < 10000; i = i + 1)
#1000000;

$display("Test Done");
$finish;
end

always
 #10 clk = !clk;

always
 #17 clk_slow = !clk_slow;

semaphore mem_read_sem = new(1);
semaphore fifo_read_sem = new(1);

int j;
int k;

initial
begin

for(int i = 0; i < 36352; i = i + 1)
    memory_data[i] = $urandom_range(0,32'hffffffff);
j = 0;
k = 0;
for(int i = 0; i < 36352; i = i + 1)
    for(int h = 0; h < 3; h = h + 1)
    begin
        memory_data_remapped[j][k*8+:8] = memory_data[i][8*h+:8];
        k = k + 1;
        if(k == 4)
        begin
            k = 0;
            j = j + 1;
        end
    end

$display("mm_rem size %d",j);

end

task automatic memory_read;
logic data_ready;

mem_read_sem.get(1);

data_ready = $urandom_range(0,1);

wait(avl_read);

avl_waitrequest = avl_read & !data_ready;
@(posedge clk);
if(!data_ready)
begin
    repeat($urandom_range(4,0)) @(posedge clk);
    #0.1 avl_waitrequest = 0;
    @(posedge clk);
end

#0.1 avl_datavalid = 1;

for(int i = 0 ; i < 8; i = i + 1)
    alv_dataread[i*32+:32] = memory_data[avl_address + i];

@(posedge clk);

#0.1 avl_datavalid = 0;
alv_dataread = 0;

mem_read_sem.put(1);

endtask : memory_read

task fifo_read_task;

logic [31:0] data_pointer;
fifo_read_sem.get(1);
data_pointer = 0;

repeat(100) @(posedge clk_slow);

for(int i = 0; i < 1136; i = i + 1)
begin
    for(int j = 0; j < 24; j = j + 1)
    begin
            fifo_read = 1;
            if(fifo_empty)
            begin
                $display("FIFO empty!");
                $finish;
            end

            @(posedge clk_slow);
            wait(!clk_slow);
            if(memory_data_remapped[data_pointer] != fifo_data)
            begin
                $display("Wrong data at index %d", data_pointer);
                $display("Data read = %h, data should be = %h", fifo_data , memory_data_remapped[data_pointer]);
                $finish;
            end
            data_pointer = data_pointer + 1;
    end

fifo_read = 0;
repeat($urandom_range(20,10)) @(posedge clk_slow);
end
repeat(200) @(posedge clk_slow);
fifo_read_sem.put(1);

endtask : fifo_read_task

initial
begin

wait(rst_n);
forever
begin
    fork
        memory_read;
        fifo_read_task;
    join_any
end
end

logic           pix_fifo_write;
logic [31:0]    pix_fifo_data;
logic           pix_fifo_full;
logic [9:0]     pix_fifo_usedw;

pixel_uploader pixel_uploader_0(

    .clk                         (clk               ),
    .rst_n                       (rst_n             ),

    .avl_mm_addr                 (avl_address       ),
    .avl_mm_read                 (avl_read          ),

    .avl_mm_readdata             (alv_dataread      ),
    .avl_mm_readdatavalid        (avl_datavalid     ),
    .avl_mm_response             (2'b0),
    .avl_mm_waitrequest          (avl_waitrequest   ),

    .pix_fifo_write              (pix_fifo_write    ),
    .pix_fifo_data               (pix_fifo_data     ),

    .pix_fifo_full               (pix_fifo_full     ),
    .pix_fifo_usedw              (pix_fifo_usedw    ),

    .enable                      (upl_enable        ),
    .word_mode                   (1'b1              ),   // 1 - word addressing, 0 - byte addressing
    .base_address                (32'b0             ),
    .total_size                  (36352         ),
    .pix_fifo_threshold          (1000              ),
    .transform_data              (1                 ),   // 0 - write data from memory directly to fifo, 1 - transform 4 bytes to 4, removing empty 3rd byte in memory data

    .read_error_w                (),
    .active                      ()

    );

fifo_1024_32    fifo_1024_32_inst (
    .data ( pix_fifo_data ),
    .rdclk ( clk_slow ),
    .rdreq ( fifo_read ),
    .wrclk ( clk ),
    .wrreq ( pix_fifo_write ),
    .q ( fifo_data ),
    .rdempty ( fifo_empty ),
    .wrfull ( pix_fifo_full ),
    .wrusedw ( pix_fifo_usedw )
    );

endmodule
