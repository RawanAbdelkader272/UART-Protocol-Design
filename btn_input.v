`timescale 1ns / 1ps

module btn_input(
    input  clk, rst_n,
    input  raw_in,
    output clean,
    output rise, fall, any_edge
    );

    // Stage 1: synchronize the async input to the clock domain
    clk_sync #(.PIPE_STAGES(2)) SYNC_INST(
        .clk    (clk),
        .rst_n  (rst_n),
        .D      (raw_in),
        .Q      (synced_in)
    );

    // Stage 2: debounce the synchronized signal
    glitch_filter FILTER_INST(
        .clk      (clk),
        .rst_n    (rst_n),
        .noisy    (synced_in),
        .clean    (clean)
    );

    // Stage 3: detect rising / falling edges on the clean signal
    transition_detect EDGE_INST(
        .clk     (clk),
        .rst_n   (rst_n),
        .level   (clean),
        .rise    (rise),
        .fall    (fall),
        .any_edge(any_edge)
    );

endmodule
