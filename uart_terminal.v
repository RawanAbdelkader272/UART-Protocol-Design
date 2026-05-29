`timescale 1ns / 1ps


module uart_terminal(
    input        clk, rst_n,

    // UART interface
    input        rd_btn,     // read  button (active-high, noisy)
    output       rx_empty,   // LED0: RX buffer empty
    input        rx,

    input  [7:0] sw,         // SW0-SW7: byte to transmit
    input        wr_btn,     // write button (active-high, noisy)
    output       tx_full,    // LED1: TX buffer full
    output       tx,

    // Display
    output [6:0] seg7,
    output [0:7] AN,
    output       DP
    );

    // ---- Debounce / edge-detect read button ----
    wire rd_pedge;
    btn_input RD_BTN(
        .clk     (clk),
        .rst_n   (rst_n),
        .raw_in  (rd_btn),
        .clean   (),
        .rise    (rd_pedge),
        .fall    (),
        .any_edge()
    );

    // ---- Debounce / edge-detect write button ----
    wire wr_pedge;
    btn_input WR_BTN(
        .clk     (clk),
        .rst_n   (rst_n),
        .raw_in  (wr_btn),
        .clean   (),
        .rise    (wr_pedge),
        .fall    (),
        .any_edge()
    );

    // ---- UART core ----
    wire [7:0] rx_byte;
    uart_core #(.DBIT(8), .SB_TICK(16)) UART(
        .clk        (clk),
        .rst_n      (rst_n),
        // RX
        .r_data     (rx_byte),
        .rd_req     (rd_pedge),
        .rx_empty   (rx_empty),
        .rx         (rx),
        // TX
        .w_data     (sw),
        .wr_req     (wr_pedge),
        .tx_full    (tx_full),
        .tx         (tx),
        // Baud: 9600 bps @ 100 MHz → LIMIT = (100e6/9600/16)-1 ≈ 650
        .BAUD_LIMIT (11'd650)
    );

    // ---- Seven-segment display ----
    // Slot layout:
    //   [0] lower nibble of SW byte   (TX side)
    //   [1] upper nibble of SW byte   (TX side)
    //   [2..5] blank
    //   [6] lower nibble of RX byte   (RX side, shown when not empty)
    //   [7] upper nibble of RX byte   (RX side, shown when not empty)
    seg7_controller DISPLAY(
        .clk   (clk),
        .rst_n (rst_n),
        .D0    ({1'b1,    sw[3:0],      1'b0}),
        .D1    ({1'b1,    sw[7:4],      1'b0}),
        .D2    (6'd0),
        .D3    (6'd0),
        .D4    (6'd0),
        .D5    (6'd0),
        .D6    ({~rx_empty, rx_byte[3:0], 1'b0}),
        .D7    ({~rx_empty, rx_byte[7:4], 1'b0}),
        .AN    (AN),
        .seg7  (seg7),
        .DP    (DP)
    );

endmodule
