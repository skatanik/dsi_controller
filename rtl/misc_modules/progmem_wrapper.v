module progmem_wrapper(
    //* system signals
    input  wire                     clk                     ,
    input  wire                     rst_n                   ,

    //* system interface
    input   wire [9:0]             ctrl_address            ,

    input   wire                    ctrl_read               ,
    output  wire [31:0]             ctrl_readdata           ,
    output  wire [1:0]              ctrl_response           ,

    output  wire                    ctrl_waitrequest
);

assign ctrl_response = 0;

reg r_ctrl_waitrequest;

assign ctrl_waitrequest = r_ctrl_waitrequest;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)                                  r_ctrl_waitrequest <= 1'b1;
    else if(ctrl_read)                          r_ctrl_waitrequest <= 1'b0;
    else if(ctrl_read || r_ctrl_waitrequest)    r_ctrl_waitrequest <= 1'b1;
end

prgr_rom prgr_rom_0 (
  .clka(clk), // input clka
//   .ena(1'b1), // input ena
  .addra({22'b0, ctrl_address}), // input [31 : 0] addra
  .douta(ctrl_readdata) // output [31 : 0] douta
);

endmodule