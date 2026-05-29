`timescale 1ns / 1ps


module var_timer
    #(parameter BITS = 4)(
    input              clk,
    input              rst_n,
    input              enable,
    input  [BITS-1:0]  LIMIT,
    output             done
    );

    reg [BITS - 1:0] cnt_reg, cnt_nxt;

    // ---- Sequential: register update ----
    always @(posedge clk, negedge rst_n)
    begin
        if (~rst_n)
            cnt_reg <= 'b0;
        else if (enable)
            cnt_reg <= cnt_nxt;
        // else hold
    end

    // ---- Combinational: wrap-around next value ----
    assign done    = (cnt_reg == LIMIT);
    always @(*)
        cnt_nxt = done ? 'b0 : cnt_reg + 1'b1;

endmodule
