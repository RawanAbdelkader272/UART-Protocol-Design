`timescale 1ns / 1ps


module uart_core
    #(
        parameter DBIT    = 8,
                  SB_TICK = 16
     )
    (
        input                    clk, rst_n,

        // ---------- Receive interface ----------
        output [DBIT - 1:0]      r_data,     // byte read from RX FIFO
        input                    rd_req,     // read-enable strobe
        output                   rx_empty,   // RX FIFO empty flag
        input                    rx,         // serial receive line

        // ---------- Transmit interface ----------
        input  [DBIT - 1:0]      w_data,     // byte to write into TX FIFO
        input                    wr_req,     // write-enable strobe
        output                   tx_full,    // TX FIFO full flag
        output                   tx,         // serial transmit line

        // ---------- Baud rate ----------
        input  [10:0]            BAUD_LIMIT  // var_timer terminal count
    );

    // ---- Baud-rate generator ----
    wire baud_tick;
    var_timer #(.BITS(11)) BAUD_GEN(
        .clk    (clk),
        .rst_n  (rst_n),
        .enable (1'b1),
        .LIMIT  (BAUD_LIMIT),
        .done   (baud_tick)
    );

    // ---- Receive path ----
    wire rx_frame_done;
    wire [DBIT - 1:0] rx_raw;

    serial_rx #(.DBIT(DBIT), .SB_TICK(SB_TICK)) RX_PATH(
        .clk       (clk),
        .rst_n     (rst_n),
        .rx        (rx),
        .baud_tick (baud_tick),
        .rx_done   (rx_frame_done),
        .rx_data   (rx_raw)
    );

    // RX FIFO: buffer received bytes until the host reads them
    fifo_generator_0 RX_FIFO(
        .clk   (clk),
        .srst  (~rst_n),
        .din   (rx_raw),
        .wr_en (rx_frame_done),
        .rd_en (rd_req),
        .dout  (r_data),
        .full  (),
        .empty (rx_empty)
    );

    // ---- Transmit path ----
    wire tx_frame_done, tx_fifo_empty;
    wire [DBIT - 1:0] tx_raw;

    serial_tx #(.DBIT(DBIT), .SB_TICK(SB_TICK)) TX_PATH(
        .clk       (clk),
        .rst_n     (rst_n),
        .tx_start  (~tx_fifo_empty),  // send whenever FIFO has data
        .baud_tick (baud_tick),
        .tx_data   (tx_raw),
        .tx_done   (tx_frame_done),
        .tx        (tx)
    );

    // TX FIFO: queue bytes written by the host for serialization
    fifo_generator_0 TX_FIFO(
        .clk   (clk),
        .srst  (~rst_n),
        .din   (w_data),
        .wr_en (wr_req),
        .rd_en (tx_frame_done),
        .dout  (tx_raw),
        .full  (tx_full),
        .empty (tx_fifo_empty)
    );

endmodule
