// -----------------------------------------------------------------------------
// top.v
// RISC-V (PicoRV32) based SoC subsystem with AXI-Lite interconnect,
// ROM, SRAM and UART peripheral.
//
// External ports (match pin_order.cfg): clk, reset, uart_tx, uart_rx
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module top (
    input  wire clk,
    input  wire reset,     // active-high external reset
    output wire uart_tx,
    input  wire uart_rx    // reserved for future RX support
);

    wire resetn = ~reset;

    // ------------------------------------------------------------------
    // PicoRV32 native memory interface
    // ------------------------------------------------------------------
    wire         mem_valid;
    wire         mem_instr;
    wire         mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_wstrb;
    wire [31:0] mem_rdata;

    // ------------------------------------------------------------------
    // PicoRV32 CPU core
    // ------------------------------------------------------------------
    picorv32 #(
        .ENABLE_COUNTERS   (1),
        .ENABLE_COUNTERS64 (1),
        .BARREL_SHIFTER    (1),
        .COMPRESSED_ISA    (0),
        .ENABLE_MUL        (0),
        .ENABLE_DIV        (0),
        .ENABLE_IRQ        (1),
        .ENABLE_IRQ_TIMER  (1),
        .PROGADDR_RESET    (32'h0000_0000),
        .PROGADDR_IRQ      (32'h0000_0010),
        .STACKADDR         (32'h0001_FFF0)
    ) u_picorv32 (
        .clk        (clk),
        .resetn     (resetn),
        .trap       (),

        .mem_valid  (mem_valid),
        .mem_instr  (mem_instr),
        .mem_ready  (mem_ready),
        .mem_addr   (mem_addr),
        .mem_wdata  (mem_wdata),
        .mem_wstrb  (mem_wstrb),
        .mem_rdata  (mem_rdata),

        .mem_la_read  (),
        .mem_la_write (),
        .mem_la_addr  (),
        .mem_la_wdata (),
        .mem_la_wstrb (),

        .pcpi_valid (),
        .pcpi_insn  (),
        .pcpi_rs1   (),
        .pcpi_rs2   (),
        .pcpi_wr    (1'b0),
        .pcpi_rd    (32'b0),
        .pcpi_wait  (1'b0),
        .pcpi_ready (1'b0),

        .irq        (32'b0),
        .eoi        (),

        .trace_valid(),
        .trace_data ()
    );

    // ------------------------------------------------------------------
    // AXI-Lite master signals (bridge -> decoder)
    // ------------------------------------------------------------------
    wire [31:0] axi_awaddr;
    wire         axi_awvalid;
    wire         axi_awready;
    wire [31:0] axi_wdata;
    wire [3:0]  axi_wstrb;
    wire         axi_wvalid;
    wire         axi_wready;
    wire [1:0]  axi_bresp;
    wire         axi_bvalid;
    wire         axi_bready;
    wire [31:0] axi_araddr;
    wire         axi_arvalid;
    wire         axi_arready;
    wire [31:0] axi_rdata;
    wire [1:0]  axi_rresp;
    wire         axi_rvalid;
    wire         axi_rready;

    // ------------------------------------------------------------------
    // AXI Bridge: PicoRV32 mem interface -> AXI4-Lite (FSM)
    // ------------------------------------------------------------------
    axi_lite_bridge u_axi_bridge (
        .clk           (clk),
        .resetn        (resetn),

        .mem_valid     (mem_valid),
        .mem_ready     (mem_ready),
        .mem_addr      (mem_addr),
        .mem_wdata     (mem_wdata),
        .mem_wstrb     (mem_wstrb),
        .mem_rdata     (mem_rdata),

        .m_axi_awaddr  (axi_awaddr),
        .m_axi_awvalid (axi_awvalid),
        .m_axi_awready (axi_awready),
        .m_axi_wdata   (axi_wdata),
        .m_axi_wstrb   (axi_wstrb),
        .m_axi_wvalid  (axi_wvalid),
        .m_axi_wready  (axi_wready),
        .m_axi_bresp   (axi_bresp),
        .m_axi_bvalid  (axi_bvalid),
        .m_axi_bready  (axi_bready),
        .m_axi_araddr  (axi_araddr),
        .m_axi_arvalid (axi_arvalid),
        .m_axi_arready (axi_arready),
        .m_axi_rdata   (axi_rdata),
        .m_axi_rresp   (axi_rresp),
        .m_axi_rvalid  (axi_rvalid),
        .m_axi_rready  (axi_rready)
    );

    // ------------------------------------------------------------------
    // Per-slave AXI-Lite interfaces
    // ------------------------------------------------------------------
    // ROM (read-only)
    wire [31:0] rom_araddr;
    wire         rom_arvalid, rom_arready;
    wire [31:0] rom_rdata;
    wire [1:0]  rom_rresp;
    wire         rom_rvalid, rom_rready;

    // SRAM
    wire [31:0] sram_awaddr;
    wire         sram_awvalid, sram_awready;
    wire [31:0] sram_wdata;
    wire [3:0]  sram_wstrb;
    wire         sram_wvalid, sram_wready;
    wire [1:0]  sram_bresp;
    wire         sram_bvalid, sram_bready;
    wire [31:0] sram_araddr;
    wire         sram_arvalid, sram_arready;
    wire [31:0] sram_rdata;
    wire [1:0]  sram_rresp;
    wire         sram_rvalid, sram_rready;

    // UART
    wire [31:0] uartp_awaddr;
    wire         uartp_awvalid, uartp_awready;
    wire [31:0] uartp_wdata;
    wire [3:0]  uartp_wstrb;
    wire         uartp_wvalid, uartp_wready;
    wire [1:0]  uartp_bresp;
    wire         uartp_bvalid, uartp_bready;
    wire [31:0] uartp_araddr;
    wire         uartp_arvalid, uartp_arready;
    wire [31:0] uartp_rdata;
    wire [1:0]  uartp_rresp;
    wire         uartp_rvalid, uartp_rready;

    // ------------------------------------------------------------------
    // AXI Decoder: addr -> one-hot slave select / interconnect
    // ------------------------------------------------------------------
    axi_lite_decoder u_axi_decoder (
        .clk             (clk),
        .resetn          (resetn),

        .s_axi_awaddr    (axi_awaddr),
        .s_axi_awvalid   (axi_awvalid),
        .s_axi_awready   (axi_awready),
        .s_axi_wdata     (axi_wdata),
        .s_axi_wstrb     (axi_wstrb),
        .s_axi_wvalid    (axi_wvalid),
        .s_axi_wready    (axi_wready),
        .s_axi_bresp     (axi_bresp),
        .s_axi_bvalid    (axi_bvalid),
        .s_axi_bready    (axi_bready),
        .s_axi_araddr    (axi_araddr),
        .s_axi_arvalid   (axi_arvalid),
        .s_axi_arready   (axi_arready),
        .s_axi_rdata     (axi_rdata),
        .s_axi_rresp     (axi_rresp),
        .s_axi_rvalid    (axi_rvalid),
        .s_axi_rready    (axi_rready),

        .rom_axi_araddr  (rom_araddr),
        .rom_axi_arvalid (rom_arvalid),
        .rom_axi_arready (rom_arready),
        .rom_axi_rdata   (rom_rdata),
        .rom_axi_rresp   (rom_rresp),
        .rom_axi_rvalid  (rom_rvalid),
        .rom_axi_rready  (rom_rready),

        .sram_axi_awaddr  (sram_awaddr),
        .sram_axi_awvalid (sram_awvalid),
        .sram_axi_awready (sram_awready),
        .sram_axi_wdata   (sram_wdata),
        .sram_axi_wstrb   (sram_wstrb),
        .sram_axi_wvalid  (sram_wvalid),
        .sram_axi_wready  (sram_wready),
        .sram_axi_bresp   (sram_bresp),
        .sram_axi_bvalid  (sram_bvalid),
        .sram_axi_bready  (sram_bready),
        .sram_axi_araddr  (sram_araddr),
        .sram_axi_arvalid (sram_arvalid),
        .sram_axi_arready (sram_arready),
        .sram_axi_rdata   (sram_rdata),
        .sram_axi_rresp   (sram_rresp),
        .sram_axi_rvalid  (sram_rvalid),
        .sram_axi_rready  (sram_rready),

        .uart_axi_awaddr  (uartp_awaddr),
        .uart_axi_awvalid (uartp_awvalid),
        .uart_axi_awready (uartp_awready),
        .uart_axi_wdata   (uartp_wdata),
        .uart_axi_wstrb   (uartp_wstrb),
        .uart_axi_wvalid  (uartp_wvalid),
        .uart_axi_wready  (uartp_wready),
        .uart_axi_bresp   (uartp_bresp),
        .uart_axi_bvalid  (uartp_bvalid),
        .uart_axi_bready  (uartp_bready),
        .uart_axi_araddr  (uartp_araddr),
        .uart_axi_arvalid (uartp_arvalid),
        .uart_axi_arready (uartp_arready),
        .uart_axi_rdata   (uartp_rdata),
        .uart_axi_rresp   (uartp_rresp),
        .uart_axi_rvalid  (uartp_rvalid),
        .uart_axi_rready  (uartp_rready)
    );

    // ------------------------------------------------------------------
    // ROM  0x0000_0000 (64KB, read-only)
    // ------------------------------------------------------------------
    rom #(
        .DEPTH_WORDS (16384),
        .ADDR_BITS   (14),
        .MEM_FILE    ("rom.hex")
    ) u_rom (
        .clk           (clk),
        .resetn        (resetn),
        .s_axi_araddr  (rom_araddr),
        .s_axi_arvalid (rom_arvalid),
        .s_axi_arready (rom_arready),
        .s_axi_rdata   (rom_rdata),
        .s_axi_rresp   (rom_rresp),
        .s_axi_rvalid  (rom_rvalid),
        .s_axi_rready  (rom_rready)
    );

    // ------------------------------------------------------------------
    // SRAM  0x0001_0000 (64KB, read/write)
    // ------------------------------------------------------------------
    sram #(
        .DEPTH_WORDS (16384),
        .ADDR_BITS   (14)
    ) u_sram (
        .clk           (clk),
        .resetn        (resetn),
        .s_axi_awaddr  (sram_awaddr),
        .s_axi_awvalid (sram_awvalid),
        .s_axi_awready (sram_awready),
        .s_axi_wdata   (sram_wdata),
        .s_axi_wstrb   (sram_wstrb),
        .s_axi_wvalid  (sram_wvalid),
        .s_axi_wready  (sram_wready),
        .s_axi_bresp   (sram_bresp),
        .s_axi_bvalid  (sram_bvalid),
        .s_axi_bready  (sram_bready),
        .s_axi_araddr  (sram_araddr),
        .s_axi_arvalid (sram_arvalid),
        .s_axi_arready (sram_arready),
        .s_axi_rdata   (sram_rdata),
        .s_axi_rresp   (sram_rresp),
        .s_axi_rvalid  (sram_rvalid),
        .s_axi_rready  (sram_rready)
    );

    // ------------------------------------------------------------------
    // UART AXI  0x1000_0000
    // ------------------------------------------------------------------
    uart_axi #(
        .CLK_FREQ  (50_000_000),
        .BAUD_RATE (115_200)
    ) u_uart_axi (
        .clk           (clk),
        .resetn        (resetn),
        .s_axi_awaddr  (uartp_awaddr),
        .s_axi_awvalid (uartp_awvalid),
        .s_axi_awready (uartp_awready),
        .s_axi_wdata   (uartp_wdata),
        .s_axi_wstrb   (uartp_wstrb),
        .s_axi_wvalid  (uartp_wvalid),
        .s_axi_wready  (uartp_wready),
        .s_axi_bresp   (uartp_bresp),
        .s_axi_bvalid  (uartp_bvalid),
        .s_axi_bready  (uartp_bready),
        .s_axi_araddr  (uartp_araddr),
        .s_axi_arvalid (uartp_arvalid),
        .s_axi_arready (uartp_arready),
        .s_axi_rdata   (uartp_rdata),
        .s_axi_rresp   (uartp_rresp),
        .s_axi_rvalid  (uartp_rvalid),
        .s_axi_rready  (uartp_rready),
        .uart_tx       (uart_tx)
    );

    // uart_rx currently unused (reserved for future RX support)
    wire _unused_uart_rx = uart_rx;

endmodule
