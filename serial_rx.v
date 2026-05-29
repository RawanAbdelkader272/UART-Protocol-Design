`timescale 1ns / 1ps


module serial_rx
    #(parameter DBIT    = 8,
                SB_TICK = 16
    )(
    input                  clk, rst_n,
    input                  rx,          // serial receive line
    input                  baud_tick,   // 16x baud-rate strobe
    output reg             rx_done,     // frame-complete pulse
    output [DBIT - 1:0]    rx_data      // recovered parallel word
    );

    // State encoding
    localparam RX_IDLE  = 2'd0,
               RX_START = 2'd1,
               RX_DATA  = 2'd2,
               RX_STOP  = 2'd3;

    reg [1:0]              st_reg,  st_nxt;
    reg [3:0]              tick_reg, tick_nxt;  // baud tick counter (0-15)
    reg [$clog2(DBIT)-1:0] bit_reg,  bit_nxt;   // bit index counter
    reg [DBIT - 1:0]       shift_reg, shift_nxt; // receive shift register

    // ---- Sequential: register block ----
    always @(posedge clk, negedge rst_n)
    begin
        if (~rst_n)
        begin
            st_reg    <= RX_IDLE;
            tick_reg  <= 4'd0;
            bit_reg   <= 'b0;
            shift_reg <= 'b0;
        end
        else
        begin
            st_reg    <= st_nxt;
            tick_reg  <= tick_nxt;
            bit_reg   <= bit_nxt;
            shift_reg <= shift_nxt;
        end
    end

    // ---- Combinational: next-state / output logic ----
    always @(*)
    begin
        // Default: hold all registers, clear done
        st_nxt    = st_reg;
        tick_nxt  = tick_reg;
        bit_nxt   = bit_reg;
        shift_nxt = shift_reg;
        rx_done   = 1'b0;

        case (st_reg)
            RX_IDLE:
                if (~rx)                        // start bit detected
                begin
                    tick_nxt = 4'd0;
                    st_nxt   = RX_START;
                end

            RX_START:
                if (baud_tick)
                begin
                    if (tick_reg == 4'd7)       // sample at mid-bit
                    begin
                        tick_nxt = 4'd0;
                        bit_nxt  = 'b0;
                        st_nxt   = RX_DATA;
                    end
                    else
                        tick_nxt = tick_reg + 1'b1;
                end

            RX_DATA:
                if (baud_tick)
                begin
                    if (tick_reg == 4'd15)      // end of this bit period
                    begin
                        tick_nxt  = 4'd0;
                        // LSB-first: shift new bit into MSB, shift right
                        shift_nxt = {rx, shift_reg[DBIT - 1:1]};
                        if (bit_reg == (DBIT - 1))
                            st_nxt = RX_STOP;
                        else
                            bit_nxt = bit_reg + 1'b1;
                    end
                    else
                        tick_nxt = tick_reg + 1'b1;
                end

            RX_STOP:
                if (baud_tick)
                begin
                    if (tick_reg == (SB_TICK - 1))
                    begin
                        rx_done = 1'b1;         // frame complete
                        st_nxt  = RX_IDLE;
                    end
                    else
                        tick_nxt = tick_reg + 1'b1;
                end

            default: st_nxt = RX_IDLE;
        endcase
    end

    assign rx_data = shift_reg;

endmodule
