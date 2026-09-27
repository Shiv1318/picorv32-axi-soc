module mem_bridge (
    input  wire        clk,
    input  wire        resetn,
    input  wire        mem_valid,
    output wire         mem_ready,
    input  wire [31:0] mem_addr,
    input  wire [31:0] mem_wdata,
    input  wire [3:0]  mem_wstrb,
    output wire [31:0] mem_rdata,
    output wire        rom_valid,
    input  wire        rom_ready,
    output wire [31:0] rom_addr,
    input  wire [31:0] rom_rdata,
    output wire        sram_valid,
    input  wire        sram_ready,
    output wire [31:0] sram_addr,
    output wire [31:0] sram_wdata,
    output wire [3:0]  sram_wstrb,
    input  wire [31:0] sram_rdata,
    output wire        uart_valid,
    input  wire        uart_ready,
    output wire [31:0] uart_addr,
    output wire [31:0] uart_wdata,
    output wire [3:0]  uart_wstrb,
    input  wire [31:0] uart_rdata
);
    wire sel_rom  = (mem_addr[31:16] == 16'h0000);
    wire sel_sram = (mem_addr[31:16] == 16'h0001);
    wire sel_uart = (mem_addr[31:16] == 16'h1000);
    assign rom_valid  = mem_valid & sel_rom;
    assign sram_valid = mem_valid & sel_sram;
    assign uart_valid = mem_valid & sel_uart;
    assign rom_addr   = mem_addr;
    assign sram_addr  = mem_addr;
    assign sram_wdata = mem_wdata;
    assign sram_wstrb = mem_wstrb;
    assign uart_addr  = mem_addr;
    assign uart_wdata = mem_wdata;
    assign uart_wstrb = mem_wstrb;
    assign mem_ready = (sel_rom  & rom_ready)  |
                        (sel_sram & sram_ready) |
                        (sel_uart & uart_ready);
    assign mem_rdata = sel_sram ? sram_rdata :
                        sel_uart ? uart_rdata :
                        rom_rdata;
endmodule
