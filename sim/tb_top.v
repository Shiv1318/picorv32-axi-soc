`timescale 1ns/1ps
module tb_top;
    reg clk = 0;
    reg reset = 1;
    wire uart_tx;
    top_sim dut (.clk(clk), .reset(reset), .uart_tx(uart_tx));
    always #10 clk = ~clk;
    initial begin
        $dumpfile("mini_soc.vcd");
        $dumpvars(0, tb_top);
        repeat (4) @(posedge clk);
        reset = 0;
        repeat (6000) @(posedge clk);
        if (dut.u_sram.mem[0]==8'hEF && dut.u_sram.mem[1]==8'hBE &&
            dut.u_sram.mem[2]==8'hAD && dut.u_sram.mem[3]==8'hDE)
            $display("PASS: SRAM write/read-back correct (0xDEADBEEF)");
        else
            $display("FAIL: SRAM contents = %02x%02x%02x%02x",
                dut.u_sram.mem[3], dut.u_sram.mem[2], dut.u_sram.mem[1], dut.u_sram.mem[0]);
        $display("INFO: ROM word 0 read as 0x%08x (expect 0x0000006f = j 0)",
            {dut.u_rom.mem[3], dut.u_rom.mem[2], dut.u_rom.mem[1], dut.u_rom.mem[0]});
        $display("INFO: uart_tx settled at %b (idle-high expected)", uart_tx);
        $finish;
    end
endmodule
