// -----------------------------------------------------------------------------
// axi_lite_bridge.v
// Converts the PicoRV32 native memory interface (mem_valid/mem_ready/...)
// into an AXI4-Lite master interface driving the AXI-Lite bus / decoder.
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module axi_lite_bridge (
    input  wire        clk,
    input  wire        resetn,

    // ---------------- PicoRV32 native memory interface (slave side) --------
    input  wire         mem_valid,
    output reg           mem_ready,
    input  wire [31:0]  mem_addr,
    input  wire [31:0]  mem_wdata,
    input  wire [3:0]   mem_wstrb,
    output reg  [31:0]  mem_rdata,

    // ---------------------- AXI4-Lite master interface ---------------------
    // Write address channel
    output reg  [31:0]  m_axi_awaddr,
    output reg           m_axi_awvalid,
    input  wire          m_axi_awready,

    // Write data channel
    output reg  [31:0]  m_axi_wdata,
    output reg  [3:0]   m_axi_wstrb,
    output reg           m_axi_wvalid,
    input  wire          m_axi_wready,

    // Write response channel
    input  wire [1:0]   m_axi_bresp,
    input  wire          m_axi_bvalid,
    output reg           m_axi_bready,

    // Read address channel
    output reg  [31:0]  m_axi_araddr,
    output reg           m_axi_arvalid,
    input  wire          m_axi_arready,

    // Read data channel
    input  wire [31:0]  m_axi_rdata,
    input  wire [1:0]   m_axi_rresp,
    input  wire          m_axi_rvalid,
    output reg           m_axi_rready
);

    // FSM states
    localparam S_IDLE       = 3'd0,
               S_WRITE_ADDR = 3'd1,   // AW/W in flight (until both accepted)
               S_WRITE_RESP = 3'd2,   // waiting for BVALID
               S_READ_ADDR  = 3'd3,   // AR in flight
               S_READ_DATA  = 3'd4;   // waiting for RVALID

    reg [2:0] state;
    reg       aw_done, w_done;   // track independent AW/W handshakes

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            state          <= S_IDLE;
            mem_ready       <= 1'b0;
            mem_rdata       <= 32'h0;
            m_axi_awaddr   <= 32'h0;
            m_axi_awvalid  <= 1'b0;
            m_axi_wdata    <= 32'h0;
            m_axi_wstrb    <= 4'h0;
            m_axi_wvalid   <= 1'b0;
            m_axi_bready   <= 1'b0;
            m_axi_araddr   <= 32'h0;
            m_axi_arvalid  <= 1'b0;
            m_axi_rready   <= 1'b0;
            aw_done         <= 1'b0;
            w_done          <= 1'b0;
        end else begin
            mem_ready <= 1'b0;

            case (state)
                // ------------------------------------------------------------
                S_IDLE: begin
                    if (mem_valid && mem_wstrb != 4'h0) begin
                        // WRITE transaction
                        m_axi_awaddr  <= mem_addr;
                        m_axi_awvalid <= 1'b1;
                        m_axi_wdata   <= mem_wdata;
                        m_axi_wstrb   <= mem_wstrb;
                        m_axi_wvalid  <= 1'b1;
                        aw_done        <= 1'b0;
                        w_done         <= 1'b0;
                        state          <= S_WRITE_ADDR;
                    end else if (mem_valid && mem_wstrb == 4'h0) begin
                        // READ transaction
                        m_axi_araddr  <= mem_addr;
                        m_axi_arvalid <= 1'b1;
                        state          <= S_READ_ADDR;
                    end
                end

                // ------------------------------------------------------------
                S_WRITE_ADDR: begin
                    if (m_axi_awvalid && m_axi_awready) begin
                        m_axi_awvalid <= 1'b0;
                        aw_done        <= 1'b1;
                    end
                    if (m_axi_wvalid && m_axi_wready) begin
                        m_axi_wvalid <= 1'b0;
                        w_done        <= 1'b1;
                    end
                    if ((aw_done || (m_axi_awvalid && m_axi_awready)) &&
                        (w_done  || (m_axi_wvalid  && m_axi_wready))) begin
                        m_axi_bready <= 1'b1;
                        state         <= S_WRITE_RESP;
                    end
                end

                S_WRITE_RESP: begin
                    if (m_axi_bvalid && m_axi_bready) begin
                        m_axi_bready <= 1'b0;
                        mem_ready     <= 1'b1;   // ignore bresp errors for this simple SoC
                        state          <= S_IDLE;
                    end
                end

                // ------------------------------------------------------------
                S_READ_ADDR: begin
                    if (m_axi_arvalid && m_axi_arready) begin
                        m_axi_arvalid <= 1'b0;
                        m_axi_rready  <= 1'b1;
                        state          <= S_READ_DATA;
                    end
                end

                S_READ_DATA: begin
                    if (m_axi_rvalid && m_axi_rready) begin
                        mem_rdata     <= m_axi_rdata;
                        m_axi_rready  <= 1'b0;
                        mem_ready     <= 1'b1;
                        state          <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule

