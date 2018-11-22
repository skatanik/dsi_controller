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