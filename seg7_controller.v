`timescale 1ns / 1ps


module seg7_controller(
    input  clk, rst_n,
    input  [5:0] D0, D1, D2, D3, D4, D5, D6, D7,
    output [7:0] AN,
    output [6:0] seg7,
    output DP
    );

    wire scan_tick;
    wire [2:0] digit_sel;
    wire [5:0] active_slot;
    wire [7:0] anode_onehot;

    // Free-running counter selects the active digit slot
    flex_counter #(.BITS(3)) DIGIT_CTR(
        .clk    (clk),
        .rst_n  (rst_n),
        .enable (scan_tick),
        .up     (1'b1),
        .load   (1'b0),
        .D      (),
        .Q      (digit_sel)
    );

    // Tick generator: ~960 Hz scan rate (104,165 cycles @ 100 MHz)
    countdown_timer #(.MAX_COUNT(104_165)) SCAN_TMR(
        .clk    (clk),
        .rst_n  (rst_n),
        .enable (1'b1),
        .done   (scan_tick)
    );

    // Decode digit index to one-hot anode enable
    bin_to_onehot #(.WIDTH(3)) ANODE_DEC(
        .sel    (digit_sel),
        .en     (active_slot[5]),    // enable bit from slot
        .one_hot(anode_onehot)
    );

    // AN is active-low
    assign AN = ~anode_onehot;

    // Route the selected slot to the output
    mux8_wide #(.BUS_W(6)) SLOT_MUX(
        .in0(D0), .in1(D1), .in2(D2), .in3(D3),
        .in4(D4), .in5(D5), .in6(D6), .in7(D7),
        .sel(digit_sel),
        .out(active_slot)
    );

    // Decode the 4-bit hex nibble to seven-segment pattern
    nibble_to_seg7 SEG_DEC(
        .nibble(active_slot[4:1]),
        .seg7  (seg7)
    );

    // Decimal point is active-low
    assign DP = ~active_slot[0];

endmodule
