module mock_cpu (
    input  wire        clk,
    input  wire        resetn,
    output reg          mem_valid,
    input  wire         mem_ready,
    output reg  [31:0] mem_addr,
    output reg  [31:0] mem_wdata,
    output reg  [3:0]  mem_wstrb,
    input  wire [31:0] mem_rdata
);
    reg [3:0] state;
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            state <= 4'd0; mem_valid <= 1'b0; mem_addr <= 32'h0;
            mem_wdata <= 32'h0; mem_wstrb <= 4'h0;
        end else begin
            case (state)
                4'd0: begin mem_addr<=32'h0000_0000; mem_wstrb<=4'b0000; mem_valid<=1'b1;
                    if (mem_valid && mem_ready) state<=4'd1; end
                4'd1: begin mem_valid<=1'b0; state<=4'd2; end
                4'd2: begin mem_addr<=32'h0001_0000; mem_wdata<=32'hDEAD_BEEF;
                    mem_wstrb<=4'b1111; mem_valid<=1'b1;
                    if (mem_valid && mem_ready) state<=4'd3; end
                4'd3: begin mem_valid<=1'b0; state<=4'd4; end
                4'd4: begin mem_addr<=32'h0001_0000; mem_wstrb<=4'b0000; mem_valid<=1'b1;
                    if (mem_valid && mem_ready) state<=4'd5; end
                4'd5: begin mem_valid<=1'b0; state<=4'd6; end
                4'd6: begin mem_addr<=32'h1000_0000; mem_wdata<=32'h0000_0041;
                    mem_wstrb<=4'b0001; mem_valid<=1'b1;
                    if (mem_valid && mem_ready) state<=4'd7; end
                4'd7: begin mem_valid<=1'b0; state<=4'd8; end
                default: mem_valid<=1'b0;
            endcase
        end
    end
endmodule
