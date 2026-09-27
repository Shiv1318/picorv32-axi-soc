module uart_tx #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115_200
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output reg        tx_busy,
    output reg        tx
);
    localparam integer BIT_PERIOD = CLK_FREQ / BAUD_RATE;
    reg [15:0] clk_cnt;
    reg [3:0]  bit_idx;
    reg [9:0]  shift_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx        <= 1'b1;
            tx_busy   <= 1'b0;
            clk_cnt   <= 16'd0;
            bit_idx   <= 4'd0;
            shift_reg <= 10'h3FF;
        end else if (tx_start && !tx_busy) begin
            shift_reg <= {1'b1, tx_data, 1'b0};
            tx_busy   <= 1'b1;
            bit_idx   <= 4'd0;
            clk_cnt   <= 16'd0;
        end else if (tx_busy) begin
            if (clk_cnt == BIT_PERIOD-1) begin
                clk_cnt   <= 16'd0;
                tx        <= shift_reg[0];
                shift_reg <= {1'b1, shift_reg[9:1]};
                bit_idx   <= bit_idx + 4'd1;
                if (bit_idx == 4'd9)
                    tx_busy <= 1'b0;
            end else begin
                clk_cnt <= clk_cnt + 16'd1;
            end
        end
    end
endmodule
