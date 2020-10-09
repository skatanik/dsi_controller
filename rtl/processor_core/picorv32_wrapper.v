
module picorv32_wrapper #(

    parameter [ 0:0] ENABLE_COUNTERS = 1,
	parameter [ 0:0] BARREL_SHIFTER = 0,
	parameter [ 0:0] COMPRESSED_ISA = 0,
	parameter [ 0:0] ENABLE_MUL = 0,
	parameter [ 0:0] ENABLE_DIV = 0,
	parameter [ 0:0] ENABLE_IRQ_QREGS = 1,
	parameter [31:0] PROGADDR_RESET = 32'h 0000_0000,
	parameter [31:0] PROGADDR_IRQ = 32'h 0000_0010,
	parameter [31:0] STACKADDR = 32'h ffff_ffff
)(
    input   wire                                clk                     ,
    input   wire                                rst_n                   ,

    output  wire [32 - 1:0]                     bus_addr                ,

    output  wire                                bus_read                ,
    input   wire [32-1:0]                       bus_readdata            ,
    input   wire [1:0]                          bus_response            ,

    output  wire                                bus_write               ,
    output  wire [32-1:0]                       bus_writedata           ,
    output  wire [3:0]                          bus_byteenable          ,

    input   wire                                bus_waitrequest         ,

    input  wire  [32-1:0]                       irq
);

wire mem_valid;
wire mem_instr;

assign bus_read = mem_valid && (!(|bus_byteenable));
assign bus_write = mem_valid && (|bus_byteenable);

picorv32 #(
		.STACKADDR(STACKADDR),
		.PROGADDR_RESET(PROGADDR_RESET),
		.PROGADDR_IRQ(PROGADDR_IRQ),
		// .BARREL_SHIFTER(BARREL_SHIFTER),
		// .COMPRESSED_ISA(COMPRESSED_ISA),
		// .ENABLE_COUNTERS(ENABLE_COUNTERS),
		// .ENABLE_MUL(ENABLE_MUL),
		// .ENABLE_DIV(ENABLE_DIV),
		.ENABLE_IRQ(1),
		.ENABLE_IRQ_QREGS(ENABLE_IRQ_QREGS)
	) cpu (
		.clk         (clk        ),
		.resetn      (rst_n      ),
		.mem_valid   (mem_valid  ),
		.mem_instr   (mem_instr  ),
		.mem_ready   (!bus_waitrequest  ),
		.mem_addr    (bus_addr   ),
		.mem_wdata   (bus_writedata  ),
		.mem_wstrb   (bus_byteenable  ),
		.mem_rdata   (bus_readdata  ),
		.irq         (irq        )
	);

endmodule