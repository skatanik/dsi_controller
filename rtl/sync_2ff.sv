module sync_2ff #(
    parameter WIDTH     = 1,
    parameter STAGES    = 2,
    )(
    input wire clk_out,    // Clock

    input wire [WIDTH-1:0] data_in,
    input wire [WIDTH-1:0] data_out

);

logic [WIDTH-1:0] sync_reg [STAGES-1:0];

always_ff @(posedge clk_out)
    sync_reg <= {sync_reg[STAGES-2:0], data_in};

assign data_out = sync_reg[STAGES-1];

endmodule