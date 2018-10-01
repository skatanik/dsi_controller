`timescale 1ns/1ps

module avalon_mm_manager_tb();

bit clk;
bit rst_n;

logic [3:0]           avl_mm_addr;
logic                 avl_mm_read;
logic                 avl_mm_readdatavalid;
logic [31:0]          avl_mm_readdata;
logic [1:0]           avl_mm_response;
logic                 avl_mm_write;
logic [31:0]          avl_mm_writedata;
logic [3:0]           avl_mm_byteenable;
logic                 avl_mm_waitrequest;
logic [4 - 1 : 0]     sys_read_req;
logic                 sys_read_ready;
logic [31:0]          sys_read_data;
logic [1:0]           sys_read_resp;
logic                 sys_write_ready;
logic [4 - 1 : 0]     sys_write_req;
logic [31:0]          sys_write_data;
logic [3:0]           sys_write_strb;

avalon_mm_manager
    #(
        .REGISTERS_NUMBER(4),
        .ADDR_WIDTH      (4),
        .MEMORY_MAP      ({4'hc, 4'h8, 4'h4, 4'h0})
    )
    avalon_mm_manager_0 (

   .clk                     (clk                    ),
   .rst_n                   (rst_n                  ),


   .avl_mm_addr             (avl_mm_addr            ),

   .avl_mm_read             (avl_mm_read            ),
   .avl_mm_readdatavalid    (avl_mm_readdatavalid   ),
   .avl_mm_readdata         (avl_mm_readdata        ),
   .avl_mm_response         (avl_mm_response        ),

   .avl_mm_write            (avl_mm_write           ),
   .avl_mm_writedata        (avl_mm_writedata       ),
   .avl_mm_byteenable       (avl_mm_byteenable      ),

   .avl_mm_waitrequest      (avl_mm_waitrequest     ),


   .sys_read_req            (sys_read_req           ),
   .sys_read_ready          (sys_read_ready         ),
   .sys_read_data           (sys_read_data          ),
   .sys_read_resp           (sys_read_resp          ),

   .sys_write_ready         (sys_write_ready        ),
   .sys_write_req           (sys_write_req          ),
   .sys_write_strb          (sys_write_strb         ),
   .sys_write_data          (sys_write_data         )

);


logic [3:0]     task_addr;
logic [31:0]    task_data_write;
logic [31:0]    task_data_read;

initial
begin
clk = 0;
forever
    #5 clk = ! clk;
end

initial
begin
rst_n = 0;
repeat(5) @(posedge clk);
rst_n = 1;
end

initial begin
avl_mm_addr = 0;
avl_mm_read = 0;
avl_mm_write = 0;
avl_mm_writedata = 0;
avl_mm_byteenable = 0;
sys_read_resp   = 0;
sys_write_ready     = 1;
sys_write_strb = 0;
task_addr = 0;
task_data_write = 0;
task_data_read = 0;


repeat(10) @(posedge clk);

task_addr           = $urandom_range(0,4'hffff_ffff) << 2;
task_data_write     = $urandom_range(0,32'hffff_ffff);

avalon_write(task_addr, task_data_write);

repeat(1) @(posedge clk);

task_addr           = $urandom_range(0,5'hffff_ffff);

avalon_read(task_addr, task_data_read);

end // initial

always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
         sys_read_data <= 0;
         sys_read_ready <= 1'b0;
    end
    else if(sys_read_ready)
    begin
        sys_read_ready <= 0;
         sys_read_data <= 0;
    end
    else if(|sys_read_req) begin
        sys_read_ready <= 1'b1;
         sys_read_data = $urandom_range(0,32'hffff_ffff);
    end
        else
            sys_read_ready <= 1'b0;
            sys_read_data <= 0;
end


task avalon_write;
    input [31:0] addr;
    input [31:0] data;

    #0.01 avl_mm_addr   = addr;
    avl_mm_write        = 1'b1;
    avl_mm_writedata    = data;
    avl_mm_byteenable   = 4'hf;

    $display($time()," Current waitrequest %h", avl_mm_waitrequest);
    do
        repeat(1) @(posedge clk);
    while(avl_mm_waitrequest);

    avl_mm_addr         = 'b0;
    avl_mm_write        = 1'b0;
    avl_mm_writedata    = 0;
    avl_mm_byteenable   = 0;

endtask : avalon_write

task avalon_read;
    input   [31:0] addr;
    output  [31:0] data;

    #0.01 avl_mm_addr   = addr;
    avl_mm_read         = 1'b1;

    do
        repeat(1) @(posedge clk);
    while(avl_mm_waitrequest);

    avl_mm_addr         = 'b0;
    avl_mm_read        = 1'b0;

    if(avl_mm_readdatavalid && (avl_mm_response == 2'b00))
        data = avl_mm_readdata;
    else
        data = 0;

endtask : avalon_read

endmodule