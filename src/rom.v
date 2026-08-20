// -----------------------------------------------------------------------------
// rom.v
// AXI4-Lite read-only ROM, 64KB (16K x 32-bit words), base 0x0000_0000.
// Contents loaded from rom.hex ($readmemh) - holds the boot firmware.
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module rom #(
    parameter DEPTH_WORDS = 16384,             // 64KB / 4
    parameter ADDR_BITS   = 14,                // log2(DEPTH_WORDS)
    parameter MEM_FILE    = "rom.hex"
) (
    input  wire         clk,
    input  wire         resetn,

    // AXI4-Lite read-only slave interface
    input  wire [31:0] s_axi_araddr,
    input  wire         s_axi_arvalid,
    output reg           s_axi_arready,

    output reg [31:0]  s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output reg           s_axi_rvalid,
    input  wire          s_axi_rready
);

    assign s_axi_rresp = 2'b00; // OKAY

    reg [31:0] mem [0:DEPTH_WORDS-1];

    initial begin
        for (integer i = 0; i < DEPTH_WORDS; i = i + 1)
            mem[i] = 32'h0;
        $readmemh(MEM_FILE, mem);
    end

    // Simple single-beat AXI-Lite read: accept address, return data next cycle
    reg [ADDR_BITS-1:0] word_addr;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            s_axi_arready <= 1'b1;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= 32'h0;
        end else begin
            if (s_axi_arready && s_axi_arvalid) begin
                word_addr     <= s_axi_araddr[ADDR_BITS+1:2];
                s_axi_arready <= 1'b0;
                s_axi_rvalid  <= 1'b1;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid  <= 1'b0;
                s_axi_arready <= 1'b1;
            end

            if (s_axi_arready && s_axi_arvalid)
                s_axi_rdata <= mem[s_axi_araddr[ADDR_BITS+1:2]];
        end
    end

endmodule
