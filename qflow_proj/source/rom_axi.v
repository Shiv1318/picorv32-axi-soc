// rom_axi.v
// Mini ROM block: 256 bytes (word-addressed to avoid mux explosion in synthesis)
module rom_axi #(
    parameter ADDR_WIDTH = 8,
    parameter MEM_FILE   = "firmware.hex"
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        axi_valid,
    output reg          axi_ready,
    input  wire [31:0] axi_addr,
    output reg  [31:0] axi_rdata
);
    localparam WORDS = 1 << (ADDR_WIDTH-2);
    reg [31:0] mem [0:WORDS-1];   // word-addressed, not byte-addressed
    initial begin
        if (MEM_FILE != "")
            $readmemh(MEM_FILE, mem);
    end
    wire [ADDR_WIDTH-3:0] word_addr = axi_addr[ADDR_WIDTH-1:2];
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_ready <= 1'b0;
            axi_rdata <= 32'h0;
        end else begin
            axi_ready <= axi_valid;
            if (axi_valid)
                axi_rdata <= mem[word_addr];
        end
    end
endmodule
