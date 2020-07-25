module i2c_edid(
    port_list
);


i2c_slave i2c_slave_0 #(
    .FILTER_LEN(4)
)
(
    input wire         clk,
    input wire         rst,

    /*
     * Host interface
     */
    input  wire        release_bus,

    input  wire [7:0]  data_in,
    input  wire        data_in_valid,
    output wire        data_in_ready,
    input  wire        data_in_last,

    output wire [7:0]  data_out,
    output wire        data_out_valid,
    input  wire        data_out_ready,
    output wire        data_out_last,

    /*
     * I2C interface
     */
    input  wire        scl_i,
    output wire        scl_o,
    output wire        scl_t,
    input  wire        sda_i,
    output wire        sda_o,
    output wire        sda_t,

    /*
     * Status
     */
    output wire        busy,
    output wire [6:0]  bus_address,
    output wire        bus_addressed,
    output wire        bus_active,

    /*
     * Configuration
     */
    input  wire        enable,
    input  wire [6:0]  device_address,
    input  wire [6:0]  device_address_mask
);

endmodule
