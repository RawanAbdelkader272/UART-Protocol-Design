`timescale 1ns / 1ps

module bin_to_onehot
    #(parameter WIDTH = 3)(
    input  [WIDTH - 1:0]       sel,
    input                      en,
    output reg [0: 2**WIDTH-1] one_hot
    );

    always @(sel, en)
    begin
        one_hot = 'b0;          // default: all outputs off
        if (en)
            one_hot[sel] = 1'b1;
    end

endmodule
