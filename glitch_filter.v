`timescale 1ns / 1ps


module glitch_filter(
    input  clk, rst_n,
    input  noisy,
    output clean
    );

    wire settle_done, tmr_hold;

    // FSM controls whether the timer runs and drives the output
    glitch_filter_ctrl CTRL_INST(
        .clk        (clk),
        .rst_n      (rst_n),
        .noisy      (noisy),
        .settle_done(settle_done),
        .tmr_hold   (tmr_hold),
        .clean      (clean)
    );

    // 20 ms settling timer (1,999,999 cycles @ 100 MHz)
    countdown_timer #(.MAX_COUNT(1_999_999)) SETTLE_TMR(
        .clk    (clk),
        .rst_n  (~tmr_hold),     // hold resets the timer
        .enable (~tmr_hold),
        .done   (settle_done)
    );

endmodule
