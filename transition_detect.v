`timescale 1ns / 1ps


module transition_detect(
    input  clk, rst_n,
    input  level,
    output rise, fall, any_edge
    );

    reg [1:0] cur_state, nxt_state;

    localparam SQ_IDLE   = 2'd0,
               SQ_ROSE   = 2'd1,
               SQ_STABLE = 2'd2,
               SQ_FELL   = 2'd3;

    // ---- Sequential: state register ----
    always @(posedge clk, negedge rst_n)
    begin
        if (~rst_n)
            cur_state <= SQ_IDLE;
        else
            cur_state <= nxt_state;
    end

    // ---- Combinational: next-state logic ----
    always @(*)
    begin
        case (cur_state)
            SQ_IDLE  : nxt_state = level ? SQ_ROSE   : SQ_IDLE;
            SQ_ROSE  : nxt_state = level ? SQ_STABLE : SQ_FELL;
            SQ_STABLE: nxt_state = level ? SQ_STABLE : SQ_FELL;
            SQ_FELL  : nxt_state = level ? SQ_ROSE   : SQ_IDLE;
            default  : nxt_state = SQ_IDLE;
        endcase
    end

    // ---- Output logic ----
    assign rise     = (cur_state == SQ_ROSE);
    assign fall     = (cur_state == SQ_FELL);
    assign any_edge = rise | fall;

endmodule
