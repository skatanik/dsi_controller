module i2c_master_wrapper(
    input   wire                    clk                 ,
    input   wire                    rst                 ,

    // *I2C interface
    inout                           scl_io              ,
    inout                           sda_io              ,

    //* system interface
    input   wire [7:0]              ctrl_address        ,
    input   wire                    ctrl_read           ,
    output  wire [31:0]             ctrl_readdata       ,
    output  wire [1:0]              ctrl_response       ,
    input   wire                    ctrl_write          ,
    input   wire [31:0]             ctrl_writedata      ,
    input   wire [3:0]              ctrl_byteenable     ,
    output  wire                    ctrl_waitrequest    ,
    output  wire                    irq
);

wire                    scl_i;
wire                    scl_o;
wire                    scl_t;
wire                    sda_i;
wire                    sda_o;
wire                    sda_t;

wire [6:0]  cmd_address;
wire        cmd_start;
wire        cmd_read;
wire        cmd_write;
wire        cmd_write_multiple;
wire        cmd_stop;
wire        cmd_valid;
wire        cmd_ready;

wire [7:0]  data_in;
wire        data_in_valid;
wire        data_in_ready;
wire        data_in_last;
wire [7:0]  data_out;
wire        data_out_valid;
wire        data_out_ready;
wire        data_out_last;

wire        busy;
wire        bus_control;
wire        bus_active;
wire        missed_ack;

wire [15:0] prescale;
wire        stop_on_idle;

i2c_master i2c_master_0(
    .clk                    (clk        ),
    .rst                    (rst        ),

    /*
     * Host interface
     */
    .cmd_address            (cmd_address        ),
    .cmd_start              (cmd_start          ),
    .cmd_read               (cmd_read           ),
    .cmd_write              (cmd_write          ),
    .cmd_write_multiple     (cmd_write_multiple ),
    .cmd_stop               (cmd_stop           ),
    .cmd_valid              (cmd_valid          ),
    .cmd_ready              (cmd_ready          ),

    .data_in                (data_in            ),
    .data_in_valid          (data_in_valid      ),
    .data_in_ready          (data_in_ready      ),
    .data_in_last           (data_in_last       ),

    .data_out               (data_out           ),
    .data_out_valid         (data_out_valid     ),
    .data_out_ready         (data_out_ready     ),
    .data_out_last          (data_out_last      ),

    /*
     * I2C interface
     */
    .scl_i                  (scl_i              ),
    .scl_o                  (scl_o              ),
    .scl_t                  (scl_t              ),
    .sda_i                  (sda_i              ),
    .sda_o                  (sda_o              ),
    .sda_t                  (sda_t              ),

    /*
     * Status
     */
    .busy                   (busy               ),
    .bus_control            (bus_control        ),
    .bus_active             (bus_active         ),
    .missed_ack             (missed_ack         ),

    /*
     * Configuration
     */
    .prescale               (prescale           ),
    .stop_on_idle           (stop_on_idle       )
);


endmodule
