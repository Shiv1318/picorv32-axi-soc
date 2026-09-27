// sram_axi.v
// Mini SRAM block: 256 bytes (was 64 KB).
module sram_axi #(
    parameter ADDR_WIDTH = 8
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        axi_valid,
    output reg          axi_ready,
    input  wire [31:0] axi_addr,
    input  wire [31:0] axi_wdata,
    input  wire [3:0]  axi_wstrb,
    output reg  [31:0] axi_rdata
);
    reg [7:0] mem [0:(1<<ADDR_WIDTH)-1];
    wire [ADDR_WIDTH-3:0] word_addr = axi_addr[ADDR_WIDTH-1:2];
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_ready <= 1'b0;
            axi_rdata <= 32'h0;
        end else begin
            axi_ready <= axi_valid;
            if (axi_valid) begin
                if (|axi_wstrb) begin
                    if (axi_wstrb[0]) mem[{word_addr, 2'b00}] <= axi_wdata[7:0];
                    if (axi_wstrb[1]) mem[{word_addr, 2'b01}] <= axi_wdata[15:8];
                    if (axi_wstrb[2]) mem[{word_addr, 2'b10}] <= axi_wdata[23:16];
                    if (axi_wstrb[3]) mem[{word_addr, 2'b11}] <= axi_wdata[31:24];
                end else begin
                    axi_rdata <= { mem[{word_addr, 2'b11}],
                                   mem[{word_addr, 2'b10}],
                                   mem[{word_addr, 2'b01}],
                                   mem[{word_addr, 2'b00}] };
                end
            end
        end
    end
endmodule
