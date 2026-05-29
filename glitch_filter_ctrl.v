`timescale 1ns / 1ps


module glitch_filter_ctrl(
    input  clk, rst_n,
    input  noisy, settle_done,
    output tmr_hold, clean
    );

    reg [1:0] cur_state, nxt_state;

    // Readable state names
    localparam ST_LOW    = 2'd0,
               ST_RISING = 2'd1,
               ST_HIGH   = 2'd2,
               ST_FALL   = 2'd3;

    // ---- Sequential: update state register ----
    always @(posedge clk, negedge rst_n)
    begin
        if (~rst_n)
            cur_state <= ST_LOW;
        else
            cur_state <= nxt_state;
    end

    // ---- Combinational: next-state logic ----
    always @(*)
    begin
        nxt_state = cur_state;
        case (cur_state)
            ST_LOW:
                if (noisy)
                    nxt_state = ST_RISING;
                // else stay in ST_LOW

            ST_RISING:
                if (~noisy)
                    nxt_state = ST_LOW;           // glitch – go back
                else if (noisy & settle_done)
                    nxt_state = ST_HIGH;          // stable – commit
                // else stay in ST_RISING

            ST_HIGH:
                if (~noisy)
                    nxt_state = ST_FALL;
                // else stay in ST_HIGH

            ST_FALL:
                if (noisy)
                    nxt_state = ST_HIGH;          // glitch – go back
                else if (~noisy & settle_done)
                    nxt_state = ST_LOW;           // stable – commit
                // else stay in ST_FALL

            default: nxt_state = ST_LOW;
        endcase
    end

    // ---- Output logic (Moore) ----
    // Timer is held (reset) while in the stable states
    assign tmr_hold = (cur_state == ST_LOW) | (cur_state == ST_HIGH);
    // Output is high whenever the input is confirmed high
    assign clean    = (cur_state == ST_HIGH) | (cur_state == ST_FALL);

endmodule
