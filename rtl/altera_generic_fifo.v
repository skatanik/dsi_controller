`ifndef ALTERA_GENERIC_FIFO
`define ALTERA_GENERIC_FIFO

module altera_generic_fifo #(
    parameter WIDTH                 = 8,
    parameter DEPTH                 = 8,
    parameter USEDW_WIDTH           = $clog2(DEPTH),
    parameter DC_FIFO               = 0,
    parameter SHOWAHEAD             = 0,
    parameter ALMOST_FULL_VALUE     = 0,
    parameter RAM_BLOCK_TYPE        = "RAM_BLOCK_TYPE=M20K",
    parameter ALMOST_EMPTY_VALUE    = 0
    )(

    input   wire                            aclr                    ,
    input   wire [WIDTH-1:0]                data                    ,
    input   wire                            rdclk                   ,
    input   wire                            rdreq                   ,
    input   wire                            wrclk                   ,
    input   wire                            wrreq                   ,
    output  wire [WIDTH-1:0]                q                       ,
    output  wire                            rdempty                 ,
    output  wire                            wrfull                  ,
    output  wire                            rdfull                  ,
    output  wire [USEDW_WIDTH-1:0]          rdusedw                 ,
    output  wire                            wrempty                 ,
    output  wire [USEDW_WIDTH-1:0]          wrusedw                 ,

    output  wire                            empty                   ,
    output  wire                            full                    ,
    output  wire [USEDW_WIDTH-1:0]          usedw                   ,
    output  wire                            almost_empty            ,
    output  wire                            almost_full

);

generate
if(DC_FIFO)
begin

    wire [WIDTH-1:0] sub_wire0;
    wire  sub_wire1;
    wire  sub_wire2;
    wire  sub_wire3;
    wire [USEDW_WIDTH-1:0] sub_wire4;
    wire  sub_wire5;
    wire [USEDW_WIDTH-1:0] sub_wire6;

    assign q        = sub_wire0;
    assign rdempty  = sub_wire1;
    assign wrfull   = sub_wire2;
    assign rdfull   = sub_wire3;
    assign rdusedw  = sub_wire4;
    assign wrempty  = sub_wire5;
    assign wrusedw  = sub_wire6;

    dcfifo  dcfifo_component (
                .aclr (aclr),
                .data (data),
                .rdclk (rdclk),
                .rdreq (rdreq),
                .wrclk (wrclk),
                .wrreq (wrreq),
                .q (sub_wire0),
                .rdempty (sub_wire1),
                .wrfull (sub_wire2),
                .eccstatus (),
                .rdfull (sub_wire3),
                .rdusedw (sub_wire4),
                .wrempty (sub_wire5),
                .wrusedw (sub_wire6));
    defparam
        dcfifo_component.intended_device_family = "Cyclone 10 GX",
        dcfifo_component.lpm_numwords = DEPTH,
        dcfifo_component.lpm_showahead = SHOWAHEAD ? "ON" : "OFF",
        dcfifo_component.lpm_type = "dcfifo",
        dcfifo_component.lpm_width = WIDTH,
        dcfifo_component.lpm_widthu = USEDW_WIDTH,
        dcfifo_component.overflow_checking = "ON",
        dcfifo_component.lpm_hint  = RAM_BLOCK_TYPE,
        dcfifo_component.rdsync_delaypipe = 5,
        dcfifo_component.read_aclr_synch = "OFF",
        dcfifo_component.underflow_checking = "ON",
        dcfifo_component.use_eab = "ON",
        dcfifo_component.write_aclr_synch = "ON",
        dcfifo_component.enable_ecc  = "FALSE",
        dcfifo_component.rdsync_delaypipe  = 4,
        dcfifo_component.wrsync_delaypipe = 4;

end
else begin

    wire [WIDTH-1:0] sub_wire0;
    wire  sub_wire1;
    wire  sub_wire2;
    wire [USEDW_WIDTH-1:0] sub_wire3;
    wire sub_wire4;
    wire sub_wire5;

    assign q            = sub_wire0;
    assign empty        = sub_wire1;
    assign full         = sub_wire2;
    assign usedw        = sub_wire3;
    assign almost_empty = sub_wire4;
    assign almost_full  = sub_wire5;

    scfifo  scfifo_component (
                .aclr (aclr),
                .clock (rdclk),
                .data (data),
                .rdreq (rdreq),
                .wrreq (wrreq),
                .q (sub_wire0),
                .empty (sub_wire1),
                .almost_empty (sub_wire4),
                .almost_full (sub_wire5),
                .eccstatus (),
                .full (sub_wire2),
                .usedw (sub_wire3),
                .sclr ());
    defparam
        scfifo_component.add_ram_output_register  = "OFF",
        scfifo_component.almost_full_value = ALMOST_FULL_VALUE,
        scfifo_component.almost_empty_value = ALMOST_EMPTY_VALUE,
        scfifo_component.enable_ecc  = "FALSE",
        scfifo_component.intended_device_family  = "Cyclone V",
        scfifo_component.lpm_numwords  = DEPTH,
        scfifo_component.lpm_showahead  = SHOWAHEAD ? "ON" : "OFF",
        scfifo_component.lpm_type  = "scfifo",
        scfifo_component.lpm_hint  = RAM_BLOCK_TYPE,
        scfifo_component.lpm_width  = WIDTH,
        scfifo_component.lpm_widthu  = USEDW_WIDTH,
        scfifo_component.overflow_checking  = "ON",
        scfifo_component.underflow_checking  = "ON",
        scfifo_component.use_eab  = "ON";


    end
endgenerate


endmodule

`endif