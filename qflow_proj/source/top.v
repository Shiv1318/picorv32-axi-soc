module top (
    input  wire clk,
    input  wire reset,
    input  wire uart_rx,
    output wire uart_tx
);
    wire resetn = ~reset;
    wire        mem_valid, mem_ready, mem_instr;
    wire [31:0] mem_addr, mem_wdata, mem_rdata;
    wire [3:0]  mem_wstrb;
    wire [31:0] eoi;
    wire        trap;
    picorv32 #(
        .ENABLE_COUNTERS(0), .ENABLE_MUL(0), .ENABLE_DIV(0),
        .ENABLE_IRQ(0), .COMPRESSED_ISA(0)
    ) u_cpu (
        .clk(clk), .resetn(resetn), .mem_valid(mem_valid), .mem_instr(mem_instr),
        .mem_ready(mem_ready), .mem_addr(mem_addr), .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb), .mem_rdata(mem_rdata), .irq(32'h0),
        .eoi(eoi), .trap(trap)
    );
    wire        rom_valid, rom_ready;
    wire [31:0] rom_addr, rom_rdata;
    wire        sram_valid, sram_ready;
    wire [31:0] sram_addr, sram_wdata, sram_rdata;
    wire [3:0]  sram_wstrb;
    wire        uart_valid, uart_ready;
    wire [31:0] uart_addr, uart_wdata, uart_rdata;
    wire [3:0]  uart_wstrb;
    mem_bridge u_bridge (
        .clk(clk), .resetn(resetn), .mem_valid(mem_valid), .mem_ready(mem_ready),
        .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata), .rom_valid(rom_valid), .rom_ready(rom_ready),
        .rom_addr(rom_addr), .rom_rdata(rom_rdata), .sram_valid(sram_valid),
        .sram_ready(sram_ready), .sram_addr(sram_addr), .sram_wdata(sram_wdata),
        .sram_wstrb(sram_wstrb), .sram_rdata(sram_rdata), .uart_valid(uart_valid),
        .uart_ready(uart_ready), .uart_addr(uart_addr), .uart_wdata(uart_wdata),
        .uart_wstrb(uart_wstrb), .uart_rdata(uart_rdata)
    );
    rom_axi #(.ADDR_WIDTH(8), .MEM_FILE("firmware.hex")) u_rom (
        .clk(clk), .rst_n(resetn), .axi_valid(rom_valid), .axi_ready(rom_ready),
        .axi_addr(rom_addr), .axi_rdata(rom_rdata)
    );
    sram_axi #(.ADDR_WIDTH(8)) u_sram (
        .clk(clk), .rst_n(resetn), .axi_valid(sram_valid), .axi_ready(sram_ready),
        .axi_addr(sram_addr), .axi_wdata(sram_wdata), .axi_wstrb(sram_wstrb),
        .axi_rdata(sram_rdata)
    );
    uart_axi u_uart (
        .clk(clk), .rst_n(resetn), .axi_valid(uart_valid), .axi_ready(uart_ready),
        .axi_addr(uart_addr), .axi_wdata(uart_wdata), .axi_wstrb(uart_wstrb),
        .axi_rdata(uart_rdata), .uart_tx_pin(uart_tx)
    );
endmodule
