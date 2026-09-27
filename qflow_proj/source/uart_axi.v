module uart_axi (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        axi_valid,
    output reg          axi_ready,
    input  wire [31:0] axi_addr,
    input  wire [31:0] axi_wdata,
    input  wire [3:0]  axi_wstrb,
    output reg  [31:0] axi_rdata,
    output wire         uart_tx_pin
);
    wire tx_busy;
    reg  tx_start;
    reg  [7:0] tx_data;
    uart_tx #(.CLK_FREQ(50_000_000), .BAUD_RATE(115_200)) u_tx (
        .clk(clk), .rst_n(rst_n), .tx_start(tx_start), .tx_data(tx_data),
        .tx_busy(tx_busy), .tx(uart_tx_pin)
    );
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_ready <= 1'b0;
            axi_rdata <= 32'h0;
            tx_start  <= 1'b0;
            tx_data   <= 8'h0;
        end else begin
            tx_start  <= 1'b0;
            axi_ready <= axi_valid;
            if (axi_valid) begin
                if (|axi_wstrb) begin
                    tx_data  <= axi_wdata[7:0];
                    tx_start <= 1'b1;
                end else begin
                    axi_rdata <= {31'b0, tx_busy};
                end
            end
        end
    end
endmodule
