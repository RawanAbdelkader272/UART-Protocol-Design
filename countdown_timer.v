`timescale 1ns / 1ps

module countdown_timer
    #(parameter MAX_COUNT = 255)(
    input  clk,
    input  rst_n,
    input  enable,
    output done
    );

    localparam CNT_BITS = $clog2(MAX_COUNT);

    reg [CNT_BITS - 1:0] cnt_reg, cnt_nxt;

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
    assign done    = (cnt_reg == MAX_COUNT);
    always @(*)
        cnt_nxt = done ? 'b0 : cnt_reg + 1'b1;

endmodule
