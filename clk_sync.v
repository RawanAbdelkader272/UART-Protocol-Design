`timescale 1ns / 1ps


module clk_sync
    #(parameter PIPE_STAGES = 2)(
    input  clk, rst_n,
    input  D,
    output Q
    );

    reg [PIPE_STAGES - 1:0] pipe;

    always @(posedge clk, negedge rst_n)
    begin
        if (~rst_n)
            pipe <= 'b0;
        else
            // Shift new sample in at MSB, output from LSB
            pipe <= {D, pipe[PIPE_STAGES - 1:1]};
    end

    assign Q = pipe[0];     // oldest sample = most settled

endmodule
