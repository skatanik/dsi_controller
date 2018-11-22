`timescale 1ns/1ps
module dsi_core_tb();

localparam DATA_SIZE = 27264;

bit [31:0] memory_data [0:36352 - 1];

bit rst_n;
bit clk_sys;
bit clk_fast;
bit rst_n_fast;

logic [31:0]    iface_write_data;
logic [3:0]     iface_write_strb;
logic           iface_write_rqst;
logic           iface_last_word;
logic           iface_lpm_en;
logic           iface_data_rqst;

logic           lines_enable;
logic           clock_enable;
logic           lines_ready;
logic           clock_ready;
logic           lines_active;

logic [31:0]    hs_lane_output;
logic [3:0]     hs_lane_enable;
logic [3:0]     LP_p_output;
logic [3:0]     LP_n_output;
logic [3:0]     LP_enable;

logic           clock_LP_p_output;
logic           clock_LP_n_output;
logic           clock_LP_enable;
logic           clock_hs_enable;
logic [7:0]     clock_hs_output;

logic           lpm_enable;
logic           user_cmd_transmission_mode;
logic           enable_EoT_sending;
logic           streaming_enable;

logic [255:0]   alv_dataread;
logic           avl_read;
logic           avl_waitrequest;
logic           avl_datavalid;
logic [31:0]    avl_address;

initial begin
rst_n               = 0;
#100
wait(10) @(posedge clk_sys)
rst_n = 1;
end

initial
begin
#1.25;
clk_sys = 1;
forever    #10 clk_sys      = ~clk_sys;
end

initial
begin
clk_fast = 1;
#5;
forever    #5 clk_fast      = ~clk_fast;
end

initial begin
rst_n_fast               = 0;
#100
wait(10) @(posedge clk_fast)
rst_n_fast = 1;
end

logic           pix_fifo_write;
logic [31:0]    pix_fifo_data;
logic           pix_fifo_full;
logic [9:0]     pix_fifo_usedw;
logic [31:0]    pix_fifo_data_r;
logic           pix_fifo_empty;
logic           pix_fifo_read;

logic [31:0]    usr_fifo_data_r;
logic [31:0]    usr_fifo_data;
logic           usr_fifo_usedw;
logic           usr_fifo_empty;
logic           usr_fifo_full;
logic           usr_fifo_read;
logic           usr_fifo_write;

logic           uploader_en;

pixel_uploader pixel_uploader_0 (

        .clk                         (clk_fast          ),
        .rst_n                       (rst_n_fast        ),

    /********* Avalon MM Master read-only iface *********/
        .avl_mm_addr                 (avl_address       ),
        .avl_mm_read                 (avl_read          ),

        .avl_mm_readdata             (alv_dataread      ),
        .avl_mm_readdatavalid        (avl_datavalid     ),
        .avl_mm_response             (2'b0              ),
        .avl_mm_waitrequest          (avl_waitrequest   ),

    /********* Pixel FIFO iface *********/
        .pix_fifo_write              (pix_fifo_write    ),
        .pix_fifo_data               (pix_fifo_data     ),

        .pix_fifo_full               (pix_fifo_full     ),
        .pix_fifo_usedw              (pix_fifo_usedw    ),

    /********* Input control *********/
        .enable                      (uploader_en       ),
        .word_mode                   (1'b1              ),   // 1 - word addressing, 0 - byte addressing
        .base_address                (32'b0             ),
        .total_size                  (36352             ),
        .pix_fifo_threshold          (10'd1000          ),
        .transform_data              (1'b1              ),   // 0 - write data from memory directly to fifo, 1 - transform 4 bytes to 4, removing empty 3rd byte in memory data

        .read_error_w                (),
        .active                      ()

    );


initial
begin

for(int i = 0; i < 36352; i = i + 1)
    memory_data[i] = $urandom_range(0,32'hffffffff);

wait(rst_n_fast);
forever
    memory_read;

end

pix_fifo_32x1024    fifo_1024_32_0 (
    .data           (pix_fifo_data      ),
    .rdclk          (clk_sys            ),
    .rdreq          (pix_fifo_read      ),
    .wrclk          (clk_fast           ),
    .wrreq          (pix_fifo_write     ),
    .q              (pix_fifo_data_r    ),
    .rdempty        (pix_fifo_empty     ),
    .wrfull         (pix_fifo_full      ),
    .wrusedw        (pix_fifo_usedw     )
    );

usr_fifo_32x128    usr_fifo_32x128_0 (
    .data           (usr_fifo_data      ),
    .rdclk          (clk_sys            ),
    .rdreq          (usr_fifo_read      ),
    .wrclk          (clk_fast           ),
    .wrreq          (usr_fifo_write     ),
    .q              (usr_fifo_data_r    ),
    .rdempty        (usr_fifo_empty     ),
    .wrfull         (usr_fifo_full      )
 //   .wrusedw        (usr_fifo_usedw     )
    );

packets_assembler packets_assembler_0
(
    /********* Clock signals *********/
        .clk                                 (clk_sys       ),
        .reset_n                             (rst_n         ),

    /********* lanes controller iface *********/
        .iface_write_data                    (iface_write_data  ),
        .iface_write_strb                    (iface_write_strb  ),
        .iface_write_rqst                    (iface_write_rqst  ),
        .iface_last_word                     (iface_last_word   ),
        .iface_lpm_en                        (iface_lpm_en      ), //0 - hs, 1 - lp should be asserted at least one cycle before iface_write_rqst and disasserted one cycle after iface_last_word

        .iface_data_rqst                     (iface_data_rqst   ),
        .lanes_controller_lines_active       (lines_active      ),

    /********* pixel FIFO interface *********/
        .pix_fifo_data                       (pix_fifo_data_r   ),
        .pix_fifo_empty                      (pix_fifo_empty    ),
        .pix_fifo_read                       (pix_fifo_read     ),

    /********* cmd FIFO interface *********/
        .usr_fifo_data                       (usr_fifo_data_r   ),
        .usr_fifo_empty                      (usr_fifo_empty    ),
        .usr_fifo_read                       (usr_fifo_read     ),

    /********* Control inputs *********/
        .lpm_enable                          (lpm_enable                    ),   // 1: go to LPM after sending commands. 0: send blank packet after sending command or data
        .user_cmd_transmission_mode          (user_cmd_transmission_mode    ), // 0: data from user fifo is sent in HS mode; 1: data from user fifo is sent in LP mode.
        .enable_EoT_sending                  (enable_EoT_sending            ),
        .streaming_enable                    (streaming_enable              ),

    /********* timings registers *********/
        .horizontal_line_length              (100),   // length in clk
        .horizontal_front_porch              (20),   // length in pixels
        .horizontal_back_porch               (20),   // length in pixels
        .pixels_in_line_number               (40),   // length in pixels
        .vertical_active_lines_number        (20),   // length in lines
        .vertical_front_porch_lines_number   (5),   // length in lines
        .vertical_back_porch_lines_number    (5),   // length in lines
        .lpm_length                          (20)    // length in clk
);

dsi_lanes_controller dsi_lanes_controller_0
    (
        /********* Clock signals *********/
        .clk_sys                 (clk_sys               ), // serial data clock
        .rst_n                   (rst_n                 ),

        /********* Fifo signals *********/
        .iface_write_data        (iface_write_data      ),
        .iface_write_strb        (iface_write_strb      ), // iface_write_strb[4] - mode flag.
        .iface_write_rqst        (iface_write_rqst      ),
        .iface_last_word         (iface_last_word       ),
        .iface_lpm_en            (iface_lpm_en          ), //0 - hs, 1 - lp should be asserted at least one cycle before iface_write_rqst and disasserted one cycle after iface_last_word

        .iface_data_rqst         (iface_data_rqst       ),

        /********* Misc signals *********/

        .reg_lanes_number        (2'd3                  ),
        .lines_enable            (lines_enable          ),   // enable output buffers of LP lines
        .clock_enable            (clock_enable          ),   // enable clock

        /********* Output signals *********/
        .lines_ready             (lines_ready           ),
        .clock_ready             (clock_ready           ),
        .lines_active            (lines_active          ),

        /********* Lanes *********/
        .hs_lane_output          (hs_lane_output        ),
        .hs_lane_enable          (hs_lane_enable        ),
        .LP_p_output             (LP_p_output           ),
        .LP_n_output             (LP_n_output           ),
        .LP_enable               (LP_enable             ),

        /********* Clock output *********/
        .clock_LP_p_output       (clock_LP_p_output     ),
        .clock_LP_n_output       (clock_LP_n_output     ),
        .clock_LP_enable         (clock_LP_enable       ),
        .clock_hs_output         (clock_hs_output       ),
        .clock_hs_enable         (clock_hs_enable       )

    );

/********* enable lines block *********/

bit dsi_lanes_controller_ready;

initial
begin
lines_enable = 0;
clock_enable = 0;
dsi_lanes_controller_ready = 0;
wait(rst_n);

repeat(10) @(posedge clk_sys);
lines_enable = 1;

wait(lines_ready);
repeat(10) @(posedge clk_sys);
clock_enable = 1;

wait(clock_ready);
repeat(10) @(posedge clk_sys);
dsi_lanes_controller_ready = 1;
end

task automatic write_usr_fifo;

input logic [31:0] data;

wait(!usr_fifo_full)

repeat(1) @(posedge clk_fast);
#0.1 usr_fifo_data = data;
    usr_fifo_write = 1;

repeat(1) @(posedge clk_fast);
usr_fifo_write = 0;

endtask : write_usr_fifo


semaphore mem_read_sem = new(1);

task automatic memory_read;
logic data_ready;

mem_read_sem.get(1);

data_ready = $urandom_range(0,1);

wait(avl_read);

avl_waitrequest = avl_read & !data_ready;
@(posedge clk_fast);
if(!data_ready)
begin
    repeat($urandom_range(4,0)) @(posedge clk_fast);
    #0.1 avl_waitrequest = 0;
    @(posedge clk_fast);
end

#0.1 avl_datavalid = 1;

for(int i = 0 ; i < 8; i = i + 1)
    alv_dataread[i*32+:32] = memory_data[avl_address + i];

@(posedge clk_fast);

#0.1 avl_datavalid = 0;
alv_dataread = 0;

mem_read_sem.put(1);

endtask : memory_read


/********* data stream queue *********/

typedef logic [8:0] data_byte;

mailbox #(data_byte) data_stream_mailbox;
semaphore data_stream_semaphore;
semaphore lp_recv_sem;


/********* LP receiver task *********/
localparam [7:0]    ENTRY_CMD           = 8'b11100001;
logic lp_clk;

assign #0.1 lp_clk =  LP_p_output[0] ^ LP_n_output[0];
logic [7:0] recv_lp_shift_reg;

enum logic [2:0]
{
    ST_LPR_WAIT_ENTRY,
    ST_LPR_WAIT_CMD,
    ST_LPR_RECEIV_DATA
} state_lp_current;

initial
begin
lp_recv_sem = new(1);
data_stream_semaphore = new(1);
data_stream_mailbox = new(1);
recv_lp_shift_reg = 0;
state_lp_current = ST_LPR_WAIT_ENTRY;
end

task automatic LP_receiver;

int bit_counter = 0;

state_lp_current = ST_LPR_WAIT_ENTRY;

lp_recv_sem.get(1);

recv_lp_shift_reg = 0;

wait(LP_p_output[0] != LP_n_output[0]);

while(1)
begin

    if(LP_p_output[0] != LP_n_output[0])
    begin
        @(posedge lp_clk);
        begin
            recv_lp_shift_reg = {recv_lp_shift_reg[6:0], LP_p_output[0]};
            bit_counter = bit_counter + 1;
        end
    end
    else
        break;

    case(state_lp_current)
    ST_LPR_WAIT_ENTRY:
        if(recv_lp_shift_reg[1:0] == 2'b10)
        begin
            state_lp_current = ST_LPR_WAIT_CMD;
            bit_counter = 0;
        end
        else if(recv_lp_shift_reg[0] == 1'b0)
        begin
            bit_counter = 0;
            break;
        end

    ST_LPR_WAIT_CMD:
        if(recv_lp_shift_reg == ENTRY_CMD)
        begin
            state_lp_current = ST_LPR_WAIT_CMD;
            bit_counter = 0;
        end

    ST_LPR_RECEIV_DATA:
        if(bit_counter == 8)
        begin
            bit_counter = 0;
            data_stream_semaphore.get(1);
            data_stream_mailbox.put({1'b0, recv_lp_shift_reg});
            data_stream_semaphore.put(1);
        end
    endcase // state_lp_current
end

lp_recv_sem.put(1);
endtask: LP_receiver

/********* hs receiver task *********/
localparam [7:0] SYNC_SEQUENCE = 8'b00011101;

typedef enum logic [2:0]
{
    LR_WAIT_LP00,
    LR_WAIT_SYNC,
    LR_RECEIVE_DATA
} lr_state;

semaphore lr_semp[0:3];
semaphore lr_semaphore[0:3];
mailbox lr_byte_mailbox[0:3];

initial
begin

for (int i = 0; i < 4; i = i + 1) begin
    lr_semp[i] = new(1);
    lr_semaphore[i] = new(1);
    lr_byte_mailbox[i] = new(1);
end

end

task automatic lane_receiver;
input logic [7:0] data_lane;
input logic LP_p;
input logic LP_n;
input logic [1:0] number;

lr_state current_state;
logic [7:0] data_byte;

lr_semp[number].get(1);

current_state = LR_WAIT_LP00;
data_byte = 0;

while(1)
begin
    case(current_state)

    LR_WAIT_LP00:
        begin
            @(posedge lp_clk);
             if(!(LP_p | LP_n))
                current_state = LR_WAIT_SYNC;
        end

    LR_WAIT_SYNC:
        begin
            @(posedge clk_sys);
            if(data_lane == SYNC_SEQUENCE)
                current_state = LR_RECEIVE_DATA;
        end

    LR_RECEIVE_DATA:
    begin
        @(posedge clk_sys);
        data_byte = data_lane;
        #0.1;
        if(!(LP_n & LP_p))
        begin
            lr_semaphore[number].get(1);
            lr_byte_mailbox[number].put(recv_lp_shift_reg);
            lr_semaphore[number].put(1);
        end
        else
            break;
    end
    endcase // current_state

end

lr_semp[number].put(1);

endtask : lane_receiver

initial
begin

wait(rst_n);
forever
begin
    fork
        lane_receiver(hs_lane_output[7:0], LP_p_output[0], LP_n_output[0], 2'd0);
        lane_receiver(hs_lane_output[15:8], LP_p_output[1], LP_n_output[1], 2'd1);
        lane_receiver(hs_lane_output[23:16], LP_p_output[2], LP_n_output[2], 2'd2);
        lane_receiver(hs_lane_output[31:24], LP_p_output[3], LP_n_output[3], 2'd3);
    join_any
end
end


task automatic HS_receiver;

logic [7:0] data_byte;
int bytes_number;
logic status;

status = 0;
bytes_number = 0;

wait(lr_byte_mailbox[0].num() > 0);

//while(bytes_number == 0)
//    bytes_number = lr_byte_mailbox[0].num();

while(!status)
begin
for (int i = 0; i < 4; i = i + 1) begin
    bytes_number = lr_byte_mailbox[i].num();
    if(bytes_number != 0)
    begin
        lr_semaphore[i].get(1);
        lr_byte_mailbox[i].get(data_byte);
        lr_semaphore[i].put(1);

        data_stream_semaphore.get(1);
        data_stream_mailbox.put({1'b1, data_byte});
        data_stream_semaphore.put(1);
    end
    else
    begin
        status = 1;
        break;
    end
end

@(posedge clk_sys);
#0.2;

end

endtask : HS_receiver

initial
begin

wait(rst_n);
forever
begin
    fork
        HS_receiver;
    join
end
end

typedef struct
{
    logic           speed_mode;
    logic [5:0]     header_id;
    logic [15:0]    data_size;
    logic           ecc_status;
    logic [7:0]     data_array [];
    logic           crc_status;
    logic           packet_type;
} packet_data_type;

int data_size_in_stream_queue;

task data_stream_parser;

logic [31:0] header;
logic [7:0] next_byte;
logic [2:0] packet_type;
packet_data_type new_packet;
logic [15:0] crc_old;
logic [15:0] crc_got;

crc_old = 16'hFFFF;
data_size_in_stream_queue = 0;

wait(data_stream_mailbox.num() > 4);

//while(data_size_in_stream_queue < 4)
//    data_size_in_stream_queue = data_stream_mailbox.num();

for(int i = 0; i < 4; i = i + 1)
begin
    data_stream_mailbox.get({new_packet.speed_mode, next_byte});
    header[8*i+:8] = inverse_byte(next_byte);
end

new_packet.header_id = header[29:24];
new_packet.data_size = {header[15:8], header[23:16]};

if(calc_ecc(header[31:8]) != header[7:0])
    new_packet.ecc_status = 0;
else
    new_packet.ecc_status = 1;

if(new_packet.ecc_status == 1)
begin
    packet_type = packet_header_decoder({2'b0, new_packet.header_id});

    if(packet_type[2])
    begin
        $display("Header error");
        $stop;
    end
    else if(packet_type[1])
    begin
        new_packet.packet_type = 1;
        new_packet.data_array = new[new_packet.data_size];

        data_size_in_stream_queue = 0;
        while(data_size_in_stream_queue < new_packet.data_size + 2)
            data_size_in_stream_queue = data_stream_mailbox.num();

        for (int i = 0; i < new_packet.data_size; i = i + 1) begin
            data_stream_mailbox.get(next_byte);
            crc_old = calc_crc(next_byte, crc_old);

            new_packet.data_array[i] = inverse_byte(next_byte);
        end

        data_stream_mailbox.get(next_byte);
        crc_got[15:8] = next_byte;
        data_stream_mailbox.get(next_byte);
        crc_got[7:0] = next_byte;

        if(crc_old == crc_got)
            new_packet.crc_status = 1;
        else
            new_packet.crc_status = 0;
    end
    else
        new_packet.packet_type = 0;

    print_packet(new_packet);
end

endtask : data_stream_parser

initial
begin

wait(rst_n);
forever
begin
    fork
        data_stream_parser;
    join
end
end

function logic [7:0] inverse_byte;

input logic [7:0] data_byte;

for(int i = 0; i < 8; i = i + 1)
    inverse_byte[i] = data_byte[7-i];

endfunction : inverse_byte

function logic [7:0] calc_ecc;

input logic [23:0] data;

logic [7:0] ecc_result;

ecc_result[0]    = ^{data[2:0], data[5:4], data[7], data[11:10], data[13], data[16], data[23:20]};
ecc_result[1]    = ^{data[1:0], data[4:3], data[6], data[8], data[10], data[12], data[14], data[17], data[23:20]};
ecc_result[2]    = ^{data[0], data[3:2], data[6:5], data[9], data[12:11], data[15], data[18], data[22:20] };
ecc_result[3]    = ^{data[3:1], data[9:7], data[15:13], data[21:19], data[23]};
ecc_result[4]    = ^{data[9:4], data[20:16], data[23:22]};
ecc_result[5]    = ^{data[19:10], data[23:21]};
ecc_result[7:6]  = 2'b0;

calc_ecc = ecc_result;

endfunction : calc_ecc

function [15:0] calc_crc;

    input logic [7:0] data_in;
    input logic [15:0] crc_in;

    logic [15:0] crc_res;

    crc_res[0] = crc_in[8] ^ crc_in[12] ^ data_in[0] ^ data_in[4];
    crc_res[1] = crc_in[9] ^ crc_in[13] ^ data_in[1] ^ data_in[5];
    crc_res[2] = crc_in[10] ^ crc_in[14] ^ data_in[2] ^ data_in[6];
    crc_res[3] = crc_in[11] ^ crc_in[15] ^ data_in[3] ^ data_in[7];
    crc_res[4] = crc_in[12] ^ data_in[4];
    crc_res[5] = crc_in[8] ^ crc_in[12] ^ crc_in[13] ^ data_in[0] ^ data_in[4] ^ data_in[5];
    crc_res[6] = crc_in[9] ^ crc_in[13] ^ crc_in[14] ^ data_in[1] ^ data_in[5] ^ data_in[6];
    crc_res[7] = crc_in[10] ^ crc_in[14] ^ crc_in[15] ^ data_in[2] ^ data_in[6] ^ data_in[7];
    crc_res[8] = crc_in[0] ^ crc_in[11] ^ crc_in[15] ^ data_in[3] ^ data_in[7];
    crc_res[9] = crc_in[1] ^ crc_in[12] ^ data_in[4];
    crc_res[10] = crc_in[2] ^ crc_in[13] ^ data_in[5];
    crc_res[11] = crc_in[3] ^ crc_in[14] ^ data_in[6];
    crc_res[12] = crc_in[4] ^ crc_in[8] ^ crc_in[12] ^ crc_in[15] ^ data_in[0] ^ data_in[4] ^ data_in[7];
    crc_res[13] = crc_in[5] ^ crc_in[9] ^ crc_in[13] ^ data_in[1] ^ data_in[5];
    crc_res[14] = crc_in[6] ^ crc_in[10] ^ crc_in[14] ^ data_in[2] ^ data_in[6];
    crc_res[15] = crc_in[7] ^ crc_in[11] ^ crc_in[15] ^ data_in[3] ^ data_in[7];

    calc_crc = crc_res;

endfunction : calc_crc

function logic [2:0] packet_header_decoder;
    input logic [7:0] data_id;
    logic packet_decoder_error;
    logic packet_not_reserved;
    logic packet_type_long;
    logic packet_type_short;

    packet_decoder_error = !packet_not_reserved;
    packet_not_reserved  = !(|data_id[3:0]) && !(&data_id[3:0]);
    packet_type_long     = (!data_id[3] || data_id[3] && (!(|data_id[5:4]) && !(|data_id[2:0]))) && packet_not_reserved;
    packet_type_short    = (data_id[3] || !(data_id[3] && (!(|data_id[5:4]) && !(|data_id[2:0])))) && packet_not_reserved;

    packet_header_decoder = {packet_decoder_error, packet_type_long, packet_type_short};
endfunction

task print_packet;
    input packet_data_type data_packet;

    $display("/***************** New Packet *********************/");

    if(data_packet.speed_mode)
        $display("Packet type - HS");
    else $display("Packet type - LP");

    $display("Packet ID %x", data_packet.header_id);
    if(data_packet.ecc_status)
        $display("ECC correct");
    else $display("ECC error");

    if(data_packet.packet_type)
    begin
        $display("Packet Long");
        $display("Data size: ",data_packet.data_size);
        if(data_packet.crc_status)
            $display("CRC correct");
        else $display("CRC error");
    end
    else
    begin
        $display("Packet Short");
         $display("Packet Args: ", data_packet.data_size);
    end

    $display("/*****************************************/");

endtask : print_packet


initial
begin
lpm_enable = 1;
avl_waitrequest = 0;
avl_datavalid = 0;
user_cmd_transmission_mode = 0;
enable_EoT_sending = 0;
streaming_enable = 0;
alv_dataread = 0;
uploader_en = 0;
usr_fifo_data   = 0;
usr_fifo_write  = 0;

wait(rst_n_fast);

repeat(20) @(posedge clk_fast);

wait(dsi_lanes_controller_ready);

repeat(20) @(posedge clk_fast);

write_usr_fifo(32'h0001_0000);

end

endmodule

