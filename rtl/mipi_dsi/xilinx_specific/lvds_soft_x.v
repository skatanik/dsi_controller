`timescale 1 ps / 1 ps
module lvds_soft_x #(
   parameter P_DELAY = 0
) (
		input  wire       rst ,   // tx_inclock.rst
		input  wire       tx_clock_logic,   // tx_inclock.tx_inclock
		input  wire       tx_clock_io,      // tx_syncclock.tx_syncclock
		input  wire       tx_clock_strobe,  // tx_syncclock.tx_syncclock
		input  wire       tx_en,  // tx_syncclock.tx_syncclock
		input  wire [7:0] tx_in,            // tx_in.tx_in
		output wire       tx_out_p,            // tx_out.tx_out
		output wire       tx_out_n            // tx_out.tx_out
	);

wire            cascade_di;     // slave -> master
wire            cascade_ti;     // slave -> master
wire            cascade_do;     // master -> slave
wire            cascade_to;     // master -> slave
wire           tx_out_en;
wire           tx_out;
wire dout_predelay;


   OSERDES2 #(
        .DATA_RATE_OQ   ("SDR"),
        .DATA_RATE_OT   ("SDR"),
        .DATA_WIDTH     (8),
        .SERDES_MODE    ("MASTER"),
        .OUTPUT_MODE    ("DIFFERENTIAL"),
        .TRAIN_PATTERN  (0)

   )
   OSERDES2_master (
      .OQ(dout_predelay),               // 1-bit output: Data output to pad or IODELAY2
      .SHIFTOUT1(cascade_di), // 1-bit output: Cascade data output
      .SHIFTOUT2(cascade_ti), // 1-bit output: Cascade 3-state output
      .SHIFTOUT3(), // 1-bit output: Cascade differential data output
      .SHIFTOUT4(), // 1-bit output: Cascade differential 3-state output
      .TQ(tx_out_en),               // 1-bit output: 3-state output to pad or IODELAY2
      .CLK0(tx_clock_io),           // 1-bit input: I/O clock input
      .CLK1(1'b0),           // 1-bit input: Secondary I/O clock input
      .CLKDIV(tx_clock_logic),       // 1-bit input: Logic domain clock input
      // D1 - D4: 1-bit (each) input: Parallel data inputs
      .D1(tx_in[4]),
      .D2(tx_in[5]),
      .D3(tx_in[6]),
      .D4(tx_in[7]),
      .IOCE(tx_clock_strobe),           // 1-bit input: Data strobe input
      .OCE(1'b1),             // 1-bit input: Clock enable input
      .RST(rst),             // 1-bit input: Asynchrnous reset input
      .SHIFTIN1(1'b1),   // 1-bit input: Cascade data input
      .SHIFTIN2(1'b1),   // 1-bit input: Cascade 3-state input
      .SHIFTIN3(cascade_do),   // 1-bit input: Cascade differential data input
      .SHIFTIN4(cascade_to),   // 1-bit input: Cascade differential 3-state input
      // T1 - T4: 1-bit (each) input: 3-state control inputs
      .T1(tx_en),
      .T2(tx_en),
      .T3(tx_en),
      .T4(tx_en),
      .TCE(1'b1),             // 1-bit input: 3-state clock enable input
      .TRAIN(1'b0)          // 1-bit input: Training pattern enable input
   );

   OSERDES2 #(
      .DATA_RATE_OQ     ("SDR"),
      .DATA_RATE_OT     ("SDR"),
      .DATA_WIDTH       (8),
      .SERDES_MODE      ("SLAVE"),
      .OUTPUT_MODE      ("DIFFERENTIAL"),
      .TRAIN_PATTERN    (0)
   )
   OSERDES2_slave (
      .OQ(),               // 1-bit output: Data output to pad or IODELAY2
      .SHIFTOUT1(), // 1-bit output: Cascade data output
      .SHIFTOUT2(), // 1-bit output: Cascade 3-state output
      .SHIFTOUT3(cascade_do), // 1-bit output: Cascade differential data output
      .SHIFTOUT4(cascade_to), // 1-bit output: Cascade differential 3-state output
      .TQ(),               // 1-bit output: 3-state output to pad or IODELAY2
      .CLK0(tx_clock_io),           // 1-bit input: I/O clock input
      .CLK1(1'b0),           // 1-bit input: Secondary I/O clock input
      .CLKDIV(tx_clock_logic),       // 1-bit input: Logic domain clock input
      // D1 - D4: 1-bit (each) input: Parallel data inputs
      .D1(tx_in[0]),
      .D2(tx_in[1]),
      .D3(tx_in[2]),
      .D4(tx_in[3]),
      .IOCE(tx_clock_strobe),           // 1-bit input: Data strobe input
      .OCE(1'b1),             // 1-bit input: Clock enable input
      .RST(rst),             // 1-bit input: Asynchrnous reset input
      .SHIFTIN1(cascade_di),   // 1-bit input: Cascade data input
      .SHIFTIN2(cascade_ti),   // 1-bit input: Cascade 3-state input
      .SHIFTIN3(1'b1),   // 1-bit input: Cascade differential data input
      .SHIFTIN4(1'b1),   // 1-bit input: Cascade differential 3-state input
      // T1 - T4: 1-bit (each) input: 3-state control inputs
      .T1(tx_en),
      .T2(tx_en),
      .T3(tx_en),
      .T4(tx_en),
      .TCE(1'b1),             // 1-bit input: 3-state clock enable input
      .TRAIN(1'b0)          // 1-bit input: Training pattern enable input
   );

IODELAY2
     #(.DATA_RATE                  ("SDR"),
       .ODELAY_VALUE               (P_DELAY),
       .COUNTER_WRAPAROUND         ("STAY_AT_LIMIT"),
       .DELAY_SRC                  ("ODATAIN"),
       .SERDES_MODE                ("NONE"),
       .SIM_TAPDELAY_VALUE         (50))
   U_IODelay
     (
      // required datapath
      .T                      (1'b0),
      .DOUT                   (tx_out),
      .ODATAIN                (dout_predelay),
      // inactive data connections
      .IDATAIN                (1'b0),
      // connect up the clocks
      .IOCLK0                 (1'b0),                 // No calibration needed
      .IOCLK1                 (1'b0),                 // No calibration needed
      // Tie of the variable delay programming
      .CAL                    (1'b0),
      .INC                    (1'b0),
      .CE                     (1'b0),
      .RST                    (rst));

wire tx_out_en_n;
assign tx_out_en_n = tx_out_en;

OBUFTDS #(
      .IOSTANDARD("DIFF_SSTL18_II") // Specify the output I/O standard
   ) OBUFTDS_data (
      .O    (tx_out_p      ),     // Diff_p output (connect directly to top-level port)
      .OB   (tx_out_n      ),   // Diff_n output (connect directly to top-level port)
      .I    (tx_out             ),     // Buffer input
     .T     (tx_out_en_n            )      // 3-state enable input
   );

endmodule