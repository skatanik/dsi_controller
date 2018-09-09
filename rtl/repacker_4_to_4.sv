module repacker_4_to_4(
    input wire          clk                 ,
    input wire          rst_n               ,

    input wire          data_req            ,   // data request signal. Need to get new data on the next clock.
    output wire [31:0]  data_out            ,   // output data
    output wire [3:0]   last_data_strb      ,   // strobes indicate last data bytes on each line

    output wire         data_change_req     ,   // request data changing. new data on the next clock is needed
    input wire  [31:0]  input_data          ,   // input data
    input wire  [3:0]   input_strb          ,   // input strobes

    input wire          enable                  // enable repacker signal
    );

logic [31:0]    input_buffer;
logic           buffer_empty;

always_ff @(posedge clk or negedge rst_n)
    if(~rst_n)                input_buffer <= 0;
    else if(data_change_req)  input_buffer <= input_data;
    else if(!enable)          input_buffer <= 0;

assign data_change_req = enable & (buffer_empty || data_req);

always_ff @(posedge clk or negedge rst_n)
    if(~rst_n)                buffer_empty <= 1;
    else if(data_change_req)  buffer_empty <= 0;
    else if(!enable)          buffer_empty <= 1;

logic [3:0] input_strb_reg;
logic [3:0] output_strb_reg;

always_ff @(posedge clk or negedge rst_n)
    if(~rst_n)                input_strb_reg <= 0;
    else if(data_change_req)  input_strb_reg <= input_strb;
    else if(!enable)          input_strb_reg <= 0;

always_ff @(posedge clk or negedge rst_n)
    if(~rst_n)                      output_strb_reg <= 0;
    else if(data_change_req)        output_strb_reg <= enable ? (input_strb_reg ^ input_strb) & ~input_strb : 4'b0;
    else                            output_strb_reg <= 0;

assign last_data_strb = output_strb_reg;

assign data_out = input_buffer;

endmodule // repacker_4_to_4