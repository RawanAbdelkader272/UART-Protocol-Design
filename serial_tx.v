`timescale 1ns / 1ps


module serial_tx
    #(parameter DBIT    = 8,
                SB_TICK = 16
    )(
    input                  clk, rst_n,
    input                  tx_start,    // begin a new frame
    input                  baud_tick,   // 16x baud-rate strobe
    input  [DBIT - 1:0]    tx_data,     // parallel word to send
    output reg             tx_done,     // frame-complete pulse
    output                 tx           // serial transmit line
    );

    localparam TX_IDLE  = 2'd0,
               TX_START = 2'd1,
               TX_DATA  = 2'd2,
               TX_STOP  = 2'd3;

    reg [1:0]              st_reg,  st_nxt;
    reg [3:0]              tick_reg, tick_nxt;
    reg [$clog2(DBIT)-1:0] bit_reg,  bit_nxt;
    reg [DBIT - 1:0]       shift_reg, shift_nxt;
    reg                    tx_reg,  tx_nxt;       // output bit register

    // ---- Sequential: register block ----
    always @(posedge clk, negedge rst_n)
    begin
        if (~rst_n)
        begin
            st_reg    <= TX_IDLE;
            tick_reg  <= 4'd0;
            bit_reg   <= 'b0;
            shift_reg <= 'b0;
            tx_reg    <= 1'b1;           // idle line is high
        end
        else
        begin
            st_reg    <= st_nxt;
            tick_reg  <= tick_nxt;
            bit_reg   <= bit_nxt;
            shift_reg <= shift_nxt;
            tx_reg    <= tx_nxt;
        end
    end

    // ---- Combinational: next-state / output logic ----
    always @(*)
    begin
        st_nxt    = st_reg;
        tick_nxt  = tick_reg;
        bit_nxt   = bit_reg;
        shift_nxt = shift_reg;
        tx_done   = 1'b0;

        case (st_reg)
            TX_IDLE:
            begin
                tx_nxt = 1'b1;                  // keep line high
                if (tx_start)
                begin
                    tick_nxt  = 4'd0;
                    shift_nxt = tx_data;         // latch word to send
                    st_nxt    = TX_START;
                end
            end

            TX_START:
            begin
                tx_nxt = 1'b0;                  // start bit
                if (baud_tick)
                begin
                    if (tick_reg == 4'd15)
                    begin
                        tick_nxt = 4'd0;
                        bit_nxt  = 'b0;
                        st_nxt   = TX_DATA;
                    end
                    else
                        tick_nxt = tick_reg + 1'b1;
                end
            end

            TX_DATA:
            begin
                tx_nxt = shift_reg[0];           // LSB first
                if (baud_tick)
                begin
                    if (tick_reg == 4'd15)
                    begin
                        tick_nxt  = 4'd0;
                        // Shift out next bit; fill vacated MSB with 0
                        shift_nxt = {1'b0, shift_reg[DBIT - 1:1]};
                        if (bit_reg == (DBIT - 1))
                            st_nxt = TX_STOP;
                        else
                            bit_nxt = bit_reg + 1'b1;
                    end
                    else
                        tick_nxt = tick_reg + 1'b1;
                end
            end

            TX_STOP:
            begin
                tx_nxt = 1'b1;                  // stop bit(s)
                if (baud_tick)
                begin
                    if (tick_reg == (SB_TICK - 1))
                    begin
                        tx_done = 1'b1;
                        st_nxt  = TX_IDLE;
                    end
                    else
                        tick_nxt = tick_reg + 1'b1;
                end
            end

            default: st_nxt = TX_IDLE;
        endcase
    end

    assign tx = tx_reg;

endmodule
