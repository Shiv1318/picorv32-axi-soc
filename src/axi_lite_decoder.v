// -----------------------------------------------------------------------------
// axi_lite_decoder.v
// Single-master, multi-slave AXI4-Lite interconnect.
// Decodes the address (addr -> one-hot select) and routes the single master
// (AXI bridge) to one of three AXI-Lite slaves: ROM, SRAM, UART.
//
// Memory map:
//   ROM  : 0x0000_0000 - 0x0000_FFFF   (64KB, read-only)
//   SRAM : 0x0001_0000 - 0x0001_FFFF   (64KB, read/write)
//   UART : 0x1000_0000 - 0x1000_00FF   (AXI-Lite UART TX peripheral)
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module axi_lite_decoder (
    input  wire clk,
    input  wire resetn,

    // -------------------- Slave side: from AXI bridge (master) -------------
    input  wire [31:0] s_axi_awaddr,
    input  wire         s_axi_awvalid,
    output wire          s_axi_awready,

    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output wire          s_axi_wready,

    output wire [1:0]  s_axi_bresp,
    output wire          s_axi_bvalid,
    input  wire          s_axi_bready,

    input  wire [31:0] s_axi_araddr,
    input  wire         s_axi_arvalid,
    output wire          s_axi_arready,

    output wire [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output wire          s_axi_rvalid,
    input  wire          s_axi_rready,

    // ------------------------- Master side: ROM ------------------------
    output wire [31:0] rom_axi_araddr,
    output wire          rom_axi_arvalid,
    input  wire          rom_axi_arready,
    input  wire [31:0] rom_axi_rdata,
    input  wire [1:0]  rom_axi_rresp,
    input  wire          rom_axi_rvalid,
    output wire          rom_axi_rready,

    // ------------------------- Master side: SRAM ------------------------
    output wire [31:0] sram_axi_awaddr,
    output wire          sram_axi_awvalid,
    input  wire          sram_axi_awready,
    output wire [31:0] sram_axi_wdata,
    output wire [3:0]  sram_axi_wstrb,
    output wire          sram_axi_wvalid,
    input  wire          sram_axi_wready,
    input  wire [1:0]  sram_axi_bresp,
    input  wire          sram_axi_bvalid,
    output wire          sram_axi_bready,
    output wire [31:0] sram_axi_araddr,
    output wire          sram_axi_arvalid,
    input  wire          sram_axi_arready,
    input  wire [31:0] sram_axi_rdata,
    input  wire [1:0]  sram_axi_rresp,
    input  wire          sram_axi_rvalid,
    output wire          sram_axi_rready,

    // ------------------------- Master side: UART ------------------------
    output wire [31:0] uart_axi_awaddr,
    output wire          uart_axi_awvalid,
    input  wire          uart_axi_awready,
    output wire [31:0] uart_axi_wdata,
    output wire [3:0]  uart_axi_wstrb,
    output wire          uart_axi_wvalid,
    input  wire          uart_axi_wready,
    input  wire [1:0]  uart_axi_bresp,
    input  wire          uart_axi_bvalid,
    output wire          uart_axi_bready,
    output wire [31:0] uart_axi_araddr,
    output wire          uart_axi_arvalid,
    input  wire          uart_axi_arready,
    input  wire [31:0] uart_axi_rdata,
    input  wire [1:0]  uart_axi_rresp,
    input  wire          uart_axi_rvalid,
    output wire          uart_axi_rready
);

    // -------------------------------------------------------------------
    // Address decode helpers
    //   ROM  : addr[31:16] == 16'h0000
    //   SRAM : addr[31:16] == 16'h0001
    //   UART : addr[31:28] == 4'h1
    // -------------------------------------------------------------------
    wire aw_sel_sram = (s_axi_awaddr[31:16] == 16'h0001);
    wire aw_sel_uart = (s_axi_awaddr[31:28] == 4'h1);

    wire ar_sel_rom  = (s_axi_araddr[31:16] == 16'h0000);
    wire ar_sel_sram = (s_axi_araddr[31:16] == 16'h0001);
    wire ar_sel_uart = (s_axi_araddr[31:28] == 4'h1);

    // -------------------------------------------------------------------
    // Latch which slave owns the current write / read transaction
    // (captured at the address-phase handshake, held until response)
    // -------------------------------------------------------------------
    reg wsel_sram, wsel_uart;
    reg rsel_rom, rsel_sram, rsel_uart;
    reg w_busy, r_busy;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            wsel_sram <= 1'b0;
            wsel_uart <= 1'b0;
            w_busy     <= 1'b0;
        end else begin
            if (!w_busy && s_axi_awvalid) begin
                wsel_sram <= aw_sel_sram;
                wsel_uart <= aw_sel_uart;
                w_busy     <= 1'b1;
            end else if (w_busy && s_axi_bvalid && s_axi_bready) begin
                w_busy <= 1'b0;
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            rsel_rom  <= 1'b0;
            rsel_sram <= 1'b0;
            rsel_uart <= 1'b0;
            r_busy     <= 1'b0;
        end else begin
            if (!r_busy && s_axi_arvalid) begin
                rsel_rom  <= ar_sel_rom;
                rsel_sram <= ar_sel_sram;
                rsel_uart <= ar_sel_uart;
                r_busy     <= 1'b1;
            end else if (r_busy && s_axi_rvalid && s_axi_rready) begin
                r_busy <= 1'b0;
            end
        end
    end

    // -------------------------------------------------------------------
    // WRITE ADDRESS / DATA -> route to SRAM or UART (ROM is read-only)
    // -------------------------------------------------------------------
    wire wsel_sram_eff = w_busy ? wsel_sram : aw_sel_sram;
    wire wsel_uart_eff = w_busy ? wsel_uart : aw_sel_uart;

    assign sram_axi_awaddr  = s_axi_awaddr;
    assign sram_axi_awvalid = s_axi_awvalid && aw_sel_sram;
    assign sram_axi_wdata   = s_axi_wdata;
    assign sram_axi_wstrb   = s_axi_wstrb;
    assign sram_axi_wvalid  = s_axi_wvalid && wsel_sram_eff;
    assign sram_axi_bready  = s_axi_bready && wsel_sram_eff;

    assign uart_axi_awaddr  = s_axi_awaddr;
    assign uart_axi_awvalid = s_axi_awvalid && aw_sel_uart;
    assign uart_axi_wdata   = s_axi_wdata;
    assign uart_axi_wstrb   = s_axi_wstrb;
    assign uart_axi_wvalid  = s_axi_wvalid && wsel_uart_eff;
    assign uart_axi_bready  = s_axi_bready && wsel_uart_eff;

    assign s_axi_awready = wsel_sram_eff ? sram_axi_awready :
                            wsel_uart_eff ? uart_axi_awready : 1'b0;
    assign s_axi_wready  = wsel_sram_eff ? sram_axi_wready  :
                            wsel_uart_eff ? uart_axi_wready  : 1'b0;
    assign s_axi_bvalid  = wsel_sram_eff ? sram_axi_bvalid  :
                            wsel_uart_eff ? uart_axi_bvalid  : 1'b0;
    assign s_axi_bresp   = wsel_sram_eff ? sram_axi_bresp   :
                            wsel_uart_eff ? uart_axi_bresp   : 2'b00;

    // -------------------------------------------------------------------
    // READ ADDRESS / DATA -> route to ROM, SRAM or UART
    // -------------------------------------------------------------------
    wire rsel_rom_eff  = r_busy ? rsel_rom  : ar_sel_rom;
    wire rsel_sram_eff = r_busy ? rsel_sram : ar_sel_sram;
    wire rsel_uart_eff = r_busy ? rsel_uart : ar_sel_uart;

    assign rom_axi_araddr   = s_axi_araddr;
    assign rom_axi_arvalid  = s_axi_arvalid && ar_sel_rom;
    assign rom_axi_rready   = s_axi_rready && rsel_rom_eff;

    assign sram_axi_araddr  = s_axi_araddr;
    assign sram_axi_arvalid = s_axi_arvalid && ar_sel_sram;
    assign sram_axi_rready  = s_axi_rready && rsel_sram_eff;

    assign uart_axi_araddr  = s_axi_araddr;
    assign uart_axi_arvalid = s_axi_arvalid && ar_sel_uart;
    assign uart_axi_rready  = s_axi_rready && rsel_uart_eff;

    assign s_axi_arready = rsel_rom_eff  ? rom_axi_arready  :
                            rsel_sram_eff ? sram_axi_arready :
                            rsel_uart_eff ? uart_axi_arready : 1'b0;

    assign s_axi_rvalid  = rsel_rom_eff  ? rom_axi_rvalid   :
                            rsel_sram_eff ? sram_axi_rvalid  :
                            rsel_uart_eff ? uart_axi_rvalid  : 1'b0;

    assign s_axi_rdata   = rsel_rom_eff  ? rom_axi_rdata    :
                            rsel_sram_eff ? sram_axi_rdata   :
                            rsel_uart_eff ? uart_axi_rdata   : 32'h0;

    assign s_axi_rresp   = rsel_rom_eff  ? rom_axi_rresp    :
                            rsel_sram_eff ? sram_axi_rresp   :
                            rsel_uart_eff ? uart_axi_rresp   : 2'b00;

endmodule
