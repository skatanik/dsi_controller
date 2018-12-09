module repacker_4_to_4(
    input wire          clk                 ,
    input wire          rst_n               ,

    input wire          ln_data_rqst        ,   // data request signal. Need to get new data on the next clock.
    output wire [31:0]  ln_write_data       ,   // output data
    output wire [3:0]   ln_last_word        ,
    output wire [3:0]   ln_write_rqst       ,

    input wire [31:0]   rpck_write_data     ,
    input wire [3:0]    rpck_write_strb     ,
    input wire          rpck_write_rqst     ,
    input wire          rpck_last_word      ,
    output wire         rpck_data_rqst

    );

logic [31:0]    buffer_1;
logic [31:0]    buffer_2;
logic           stop_filling;
logic           stage_active;
logic           buff_1_full;
logic           buff_2_full;
logic [1:0]     rpck_last_word_delayed;
logic           rpck_write_rqst_delayed;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                              stage_active <= 1'b0;
    else if(!stage_active & buff_2_full)                    stage_active <= 1'b1;
    else if(rpck_last_word_delayed[1] && ln_data_rqst)      stage_active <= 1'b0;

assign rpck_data_rqst = rpck_write_rqst_delayed & !(|rpck_last_word_delayed) | stage_active & ln_data_rqst & !(|ln_last_word);



always @(posedge clk or negedge rst_n)
    if(!rst_n)                                          buffer_1 <= 32'b0;
    else if(rpck_write_rqst || rpck_data_rqst)          buffer_1 <= rpck_write_data;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                          buff_1_full <= 1'b0;
    else if(rpck_write_rqst || rpck_data_rqst)          buff_1_full <= 1'b1;
    else if(rpck_last_word_delayed[0])                  buff_1_full <= 1'b0;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                                      buffer_2 <= 32'b0;
    else if(buff_1_full && (!buff_2_full || ln_data_rqst))          buffer_2 <= buffer_1;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                                                      buff_2_full <= 1'b0;
    else if(buff_1_full && (!buff_2_full || ln_data_rqst))          buff_2_full <= 1'b1;

always @(posedge clk or negedge rst_n)
    if(!rst_n)                      rpck_last_word_delayed <= 1'b0;
    else if(rpck_data_rqst)         rpck_last_word_delayed <= {rpck_last_word_delayed[0], rpck_last_word};
always @(posedge clk or negedge rst_n)
    if(!rst_n)              rpck_write_rqst_delayed <= 1'b0;
    else                    rpck_write_rqst_delayed <= rpck_write_rqst;

endmodule // repacker_4_to_4