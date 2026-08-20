// -----------------------------------------------------------------------------
// top_tb.v
// Testbench for the RISC-V (PicoRV32) SoC subsystem (top.v).
//
// Applies clock + reset, then lets the CPU run the boot firmware in rom.hex
// (lui/addi/sw/jal that writes the character 'A' to the UART AXI register).
// The UART serial output is decoded on-the-fly and the received byte is
// checked against the expected value.
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module top_tb;

    // 50 MHz clock -> 20 ns period, matches CLOCK_PERIOD in config.json / top.sdc
    localparam CLK_PERIOD = 20;
    localparam BAUD_RATE  = 115_200;
    localparam CLK_FREQ   = 50_000_000;
    localparam BIT_PERIOD_NS = (1_000_000_000 / BAUD_RATE);

    reg clk;
    reg reset;
    wire uart_tx;
    reg  uart_rx;

    // ------------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------------
    top u_top (
        .clk      (clk),
        .reset    (reset),
        .uart_tx  (uart_tx),
        .uart_rx  (uart_rx)
    );

    // ------------------------------------------------------------------
    // Clock generation
    // ------------------------------------------------------------------
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // ------------------------------------------------------------------
    // Reset generation
    // ------------------------------------------------------------------
    initial begin
        uart_rx = 1'b1;    // idle high
        reset   = 1'b1;
        repeat (10) @(posedge clk);
        reset = 1'b0;
        $display("[%0t] Reset released", $time);
    end

    // ------------------------------------------------------------------
    // Dump waves
    // ------------------------------------------------------------------
    initial begin
        $dumpfile("top_tb.vcd");
        $dumpvars(0, top_tb);
    end

    // ------------------------------------------------------------------
    // UART receiver model: samples uart_tx and reconstructs bytes (8N1)
    // ------------------------------------------------------------------
    reg [7:0] rx_byte;
    integer   byte_count;

    task uart_receive_byte;
        integer i;
        begin
            @(negedge uart_tx);                    // start bit begins
            #(BIT_PERIOD_NS/2);                     // sample mid start-bit
            if (uart_tx !== 1'b0)
                $display("[%0t] WARNING: expected start bit low", $time);
            for (i = 0; i < 8; i = i + 1) begin
                #(BIT_PERIOD_NS);
                rx_byte[i] = uart_tx;
            end
            #(BIT_PERIOD_NS);                       // stop bit
            if (uart_tx !== 1'b1)
                $display("[%0t] WARNING: expected stop bit high", $time);
            byte_count = byte_count + 1;
            $display("[%0t] UART RX byte #%0d = 0x%02h ('%c')",
                       $time, byte_count, rx_byte, rx_byte);
        end
    endtask

    initial begin
        byte_count = 0;
        wait (reset == 1'b0);
        uart_receive_byte;
        if (rx_byte == 8'h41)
            $display("[%0t] TEST PASSED: received expected byte 'A' (0x41)", $time);
        else
            $display("[%0t] TEST FAILED: expected 0x41, got 0x%02h", $time, rx_byte);
        $finish;
    end

    // ------------------------------------------------------------------
    // Safety timeout
    // ------------------------------------------------------------------
    initial begin
        #2_000_000;  // 2 ms simulation timeout
        $display("[%0t] TEST FAILED: simulation timeout, no UART byte received", $time);
        $finish;
    end

endmodule
