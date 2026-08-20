// -----------------------------------------------------------------------------
// uart_axi.v
// AXI4-Lite slave wrapping the UART transmitter, base address 0x1000_0000.
//
// Register map (offset from base):
//   0x00  TXDATA  (W) : writing the low byte starts a UART transmission
//   0x04  STATUS  (R) : bit0 = TX busy
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module uart_axi #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115_200
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
    input  wire          s_axi_rready,

    // Serial output pin
    output wire uart_tx
);

    assign s_axi_bresp = 2'b00;
    assign s_axi_rresp = 2'b00;

    wire       tx_busy;
    reg         tx_start;
    reg  [7:0]  tx_data;

    uart_tx #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_uart_tx (
        .clk       (clk),
        .resetn    (resetn),
        .tx_start  (tx_start),
        .tx_data   (tx_data),
        .tx_busy   (tx_busy),
        .uart_txd  (uart_tx)
    );

    // ------------------------------- WRITE --------------------------------
    reg aw_hs, w_hs;
    reg [31:0] awaddr_latched;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            s_axi_awready  <= 1'b1;
            s_axi_wready   <= 1'b1;
            s_axi_bvalid   <= 1'b0;
            aw_hs           <= 1'b0;
            w_hs            <= 1'b0;
            tx_start        <= 1'b0;
            tx_data         <= 8'h0;
            awaddr_latched  <= 32'h0;
        end else begin
            tx_start <= 1'b0;

            if (s_axi_awready && s_axi_awvalid) begin
                s_axi_awready  <= 1'b0;
                aw_hs           <= 1'b1;
                awaddr_latched  <= s_axi_awaddr;
            end

            if (s_axi_wready && s_axi_wvalid) begin
                s_axi_wready <= 1'b0;
                w_hs          <= 1'b1;
                if (awaddr_latched[7:0] == 8'h00 && s_axi_wstrb[0]) begin
                    tx_data  <= s_axi_wdata[7:0];
                    tx_start <= 1'b1;
                end
            end

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
                if (s_axi_araddr[7:0] == 8'h04)
                    s_axi_rdata <= {31'b0, tx_busy};   // STATUS
                else
                    s_axi_rdata <= 32'h0;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid  <= 1'b0;
                s_axi_arready <= 1'b1;
            end
        end
    end

endmodule
