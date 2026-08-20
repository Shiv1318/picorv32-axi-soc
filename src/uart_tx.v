// -----------------------------------------------------------------------------
// uart_tx.v
// Simple 8N1 UART transmitter. CLK_FREQ / BAUD_RATE sets the bit period.
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module uart_tx #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115_200
) (
    input  wire       clk,
    input  wire       resetn,

    input  wire        tx_start,   // pulse for 1 cycle to begin transmission
    input  wire [7:0]  tx_data,
    output reg          tx_busy,
    output reg          uart_txd   // serial output line (idles high)
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    localparam S_IDLE  = 2'd0,
               S_START = 2'd1,
               S_DATA  = 2'd2,
               S_STOP  = 2'd3;

    reg [1:0]  state;
    reg [15:0] clk_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  shift_reg;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            state      <= S_IDLE;
            clk_cnt    <= 16'd0;
            bit_idx    <= 3'd0;
            shift_reg  <= 8'd0;
            uart_txd   <= 1'b1;
            tx_busy    <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    uart_txd <= 1'b1;
                    clk_cnt   <= 16'd0;
                    bit_idx   <= 3'd0;
                    if (tx_start) begin
                        shift_reg <= tx_data;
                        tx_busy    <= 1'b1;
                        state      <= S_START;
                    end else begin
                        tx_busy <= 1'b0;
                    end
                end

                S_START: begin
                    uart_txd <= 1'b0;          // start bit
                    if (clk_cnt < CLKS_PER_BIT-1) begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end else begin
                        clk_cnt <= 16'd0;
                        state    <= S_DATA;
                    end
                end

                S_DATA: begin
                    uart_txd <= shift_reg[bit_idx];
                    if (clk_cnt < CLKS_PER_BIT-1) begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end else begin
                        clk_cnt <= 16'd0;
                        if (bit_idx < 3'd7) begin
                            bit_idx <= bit_idx + 1'b1;
                        end else begin
                            bit_idx <= 3'd0;
                            state    <= S_STOP;
                        end
                    end
                end

                S_STOP: begin
                    uart_txd <= 1'b1;          // stop bit
                    if (clk_cnt < CLKS_PER_BIT-1) begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end else begin
                        clk_cnt <= 16'd0;
                        tx_busy  <= 1'b0;
                        state    <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
