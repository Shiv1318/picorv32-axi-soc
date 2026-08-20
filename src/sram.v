// -----------------------------------------------------------------------------
// sram.v
// AXI4-Lite read/write SRAM, 64KB (16K x 32-bit words), base 0x0001_0000.
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module sram #(
    parameter DEPTH_WORDS = 16384,             // 64KB / 4
    parameter ADDR_BITS   = 14                 // log2(DEPTH_WORDS)
) (
    input  wire         clk,
    input  wire         resetn,

    // Write address channel
    input  wire [31:0] s_axi_awaddr,
    input  wire         s_axi_awvalid,
    output reg           s_axi_awready,

    // Write data channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output reg           s_axi_wready,

    // Write response channel
    output wire [1:0]  s_axi_bresp,
    output reg           s_axi_bvalid,
    input  wire          s_axi_bready,

    // Read address channel
    input  wire [31:0] s_axi_araddr,
    input  wire         s_axi_arvalid,
    output reg           s_axi_arready,

    // Read data channel
    output reg [31:0]  s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output reg           s_axi_rvalid,
    input  wire          s_axi_rready
);

    assign s_axi_bresp = 2'b00; // OKAY
    assign s_axi_rresp = 2'b00; // OKAY

    reg [31:0] mem [0:DEPTH_WORDS-1];

    // ------------------------------- WRITE --------------------------------
    reg aw_hs, w_hs;
    wire [ADDR_BITS-1:0] waddr_w = s_axi_awaddr[ADDR_BITS+1:2];

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            s_axi_awready <= 1'b1;
            s_axi_wready  <= 1'b1;
            s_axi_bvalid  <= 1'b0;
            aw_hs          <= 1'b0;
            w_hs           <= 1'b0;
        end else begin
            // address handshake
            if (s_axi_awready && s_axi_awvalid) begin
                s_axi_awready <= 1'b0;
                aw_hs          <= 1'b1;
            end
            // data handshake + memory write
            if (s_axi_wready && s_axi_wvalid) begin
                s_axi_wready <= 1'b0;
                w_hs          <= 1'b1;
                if (s_axi_wstrb[0]) mem[waddr_w][ 7: 0] <= s_axi_wdata[ 7: 0];
                if (s_axi_wstrb[1]) mem[waddr_w][15: 8] <= s_axi_wdata[15: 8];
                if (s_axi_wstrb[2]) mem[waddr_w][23:16] <= s_axi_wdata[23:16];
                if (s_axi_wstrb[3]) mem[waddr_w][31:24] <= s_axi_wdata[31:24];
            end
            // once both AW & W done, issue response
            if ((aw_hs || (s_axi_awready && s_axi_awvalid)) &&
                (w_hs  || (s_axi_wready  && s_axi_wvalid )) && !s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
            end
            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid  <= 1'b0;
                s_axi_awready <= 1'b1;
                s_axi_wready  <= 1'b1;
                aw_hs          <= 1'b0;
                w_hs           <= 1'b0;
            end
        end
    end

    // -------------------------------- READ ---------------------------------
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            s_axi_arready <= 1'b1;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= 32'h0;
        end else begin
            if (s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b0;
                s_axi_rvalid  <= 1'b1;
                s_axi_rdata   <= mem[s_axi_araddr[ADDR_BITS+1:2]];
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid  <= 1'b0;
                s_axi_arready <= 1'b1;
            end
        end
    end

endmodule
