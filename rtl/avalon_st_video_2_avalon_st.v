module avl_st_video_2_avl_st_top (
    input wire                      clk                             ,
    input wire                      rst_n                           ,

    /********* Avalon-ST input *********/
    input   wire [23:0]             in_avl_st_data                      ,
    input   wire                    in_avl_st_valid                     ,
    input   wire                    in_avl_st_endofpacket               ,
    input   wire                    in_avl_st_startofpacket             ,
    output  wire                    in_avl_st_ready                     ,

    /********* Avalon-ST output *********/
    output  wire [31:0]             out_avl_st_data                     ,
    output  wire                    out_avl_st_valid                    ,
    output  wire                    out_avl_st_endofpacket              ,
    output  wire                    out_avl_st_startofpacket            ,
    input   wire                    out_avl_st_ready

);

reg skip_frame;
reg prev_frame_ctrl;
reg in_avl_st_valid_delayed;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                      in_avl_st_valid_delayed <= 1'b0;
    else if(!set_skip_frame)        in_avl_st_valid_delayed <= in_avl_st_valid;

wire inp_data_valid;
wire set_skip_frame;

assign set_skip_frame   = inp_data_valid && in_avl_st_startofpacket && (in_avl_st_data[3:0] == 4'hF) && !prev_frame_ctrl;
assign inp_data_valid   = in_avl_st_valid_delayed | in_avl_st_valid;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                          skip_frame <= 1'b0;
    else if(set_skip_frame)                             skip_frame <= 1'b1;
    else if(inp_data_valid && in_avl_st_endofpacket)    skip_frame <= 1'b0;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                                              prev_frame_ctrl <= 1'b0;
    else if(inp_data_valid && in_avl_st_endofpacket && skip_frame)          prev_frame_ctrl <= 1'b1;
    else if(inp_data_valid && in_avl_st_endofpacket)                        prev_frame_ctrl <= 1'b0;


reg [63:0]  input_shift_reg;
reg [3:0]   isr_bytes_number;
reg         sof;
reg         eof;

wire [3:0]  read_bytes_number;
wire        isr_read;
wire        pipeline_enable;
wire        global_enable;
wire        fifo_not_full;
wire        fifo_full;
wire        fifo_empty;
wire        fifo_read;
wire [33:0] fifo_data_out;

assign global_enable        = in_avl_st_ready && inp_data_valid && !set_skip_frame && !skip_frame;
assign read_bytes_number    = ({4{isr_read}} & 4'd4);
assign pipeline_enable      = isr_read & fifo_not_full;

wire [23:0] input_pixels_rgb = {in_avl_st_data[7:0], in_avl_st_data[15:8], in_avl_st_data[23:16]};

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  input_shift_reg <= 64'b0;
    else if(global_enable)      input_shift_reg <= (input_shift_reg >> (read_bytes_number * 8)) | {input_pixels_rgb, 40'b0} >> (4'd5 - isr_bytes_number + read_bytes_number)*8;
    else if(pipeline_enable)    input_shift_reg <= (input_shift_reg >> (read_bytes_number * 8));

always @(posedge clk or negedge rst_n)
    if(!rst_n)                  isr_bytes_number <= 4'd0;
    else if(global_enable)      isr_bytes_number <= isr_bytes_number + 4'd3 - read_bytes_number;
    else if(pipeline_enable)    isr_bytes_number <= isr_bytes_number - read_bytes_number;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                              sof <= 1'b0;
    else if(global_enable && in_avl_st_startofpacket)       sof <= 1'b1;
    else if(sof && pipeline_enable)                         sof <= 1'b0;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                              eof <= 1'b0;
    else if(global_enable && in_avl_st_endofpacket)         eof <= 1'b1;
    else if(eof && pipeline_enable)                         eof <= 1'b0;

assign isr_read = isr_bytes_number >= 4'd4;

wire [33:0] input_pixels_array; // array of 4 pixels from input_shift_reg

assign input_pixels_array   = {sof, eof, input_shift_reg[31:0]};

altera_generic_fifo #(
    .WIDTH      (34),
    .DEPTH      (4),
    .DC_FIFO    (0),
    .SHOWAHEAD  (1)
    ) fifo_34x4_0(
    .aclr           ( !rst_n                ),
    .data           ( input_pixels_array    ),
    .rdclk          ( clk                   ),
    .rdreq          ( fifo_read             ),
    .wrreq          ( pipeline_enable       ),
    .q              ( fifo_data_out         ),
    .empty          ( fifo_empty            ),
    .full           ( fifo_full             )
);

assign fifo_read                    = out_avl_st_ready & out_avl_st_valid;
assign out_avl_st_data              = out_avl_st_valid ? fifo_data_out[31:0] : 32'b0;
assign out_avl_st_valid             = !fifo_empty;
assign out_avl_st_endofpacket       = out_avl_st_valid ? fifo_data_out[32] : 1'b0;
assign out_avl_st_startofpacket     = out_avl_st_valid ? fifo_data_out[33] : 1'b0;

assign fifo_not_full                = !fifo_full;
assign in_avl_st_ready              = fifo_not_full;

endmodule