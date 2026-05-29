`timescale 1ns / 1ps


module flex_counter
    #(parameter BITS = 4)(
    input              clk,
    input              rst_n,
    input              enable,
    input              dir,     // 1 = up, 0 = down
    input              load,
    input  [BITS-1:0]  D,
    output [BITS-1:0]  Q
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

    // ---- Combinational: next-value logic ----
    always @(cnt_reg, dir, load, D)
    begin
        cnt_nxt = cnt_reg;
        casex ({load, dir})
            2'b00: cnt_nxt = cnt_reg - 1'b1;   // count down
            2'b01: cnt_nxt = cnt_reg + 1'b1;   // count up
            2'b1x: cnt_nxt = D;                // parallel load
            default: cnt_nxt = cnt_reg;
        endcase
    end

    assign Q = cnt_reg;

endmodule
