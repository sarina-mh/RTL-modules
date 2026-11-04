// ============================================================================
// Testbench: tb_flip_flop
// Checks asynchronous reset, enable/hold behavior, and the complemented output.
// ============================================================================
`timescale 1ns/1ps

module tb_flip_flop;
    parameter WIDTH       = 8;
    parameter RESET_VALUE = 8'h00;

    reg              clk;
    reg              rst_n;
    reg              en;
    reg  [WIDTH-1:0] d;
    wire [WIDTH-1:0] q;
    wire [WIDTH-1:0] q_bar;

    integer errors;

    flip_flop #(
        .WIDTH(WIDTH),
        .RESET_VALUE(RESET_VALUE)
    ) dut (
        .clk(clk), .rst_n(rst_n), .en(en), .d(d),
        .q(q), .q_bar(q_bar)
    );

    always #5 clk = ~clk;

    initial begin
        clk   = 1'b0;
        rst_n = 1'b0;
        en    = 1'b0;
        d     = {WIDTH{1'b0}};
        errors = 0;

        #12;
        // Asynchronous reset value
        if (q !== RESET_VALUE) begin
            $display("FAIL flip_flop reset: q=%h expected=%h", q, RESET_VALUE);
            errors = errors + 1;
        end
        if (q_bar !== ~q) begin
            $display("FAIL flip_flop reset: q_bar=%h expected=%h", q_bar, ~q);
            errors = errors + 1;
        end

        rst_n = 1'b1;

        // Enabled capture
        d  = 8'hA5;
        en = 1'b1;
        @(posedge clk); #1;
        if (q !== 8'hA5) begin
            $display("FAIL flip_flop capture: q=%h expected=A5", q);
            errors = errors + 1;
        end
        if (q_bar !== ~q) begin
            $display("FAIL flip_flop q_bar: q_bar=%h expected=%h", q_bar, ~q);
            errors = errors + 1;
        end

        // Disabled: value must hold
        d  = 8'h3C;
        en = 1'b0;
        @(posedge clk); #1;
        if (q !== 8'hA5) begin
            $display("FAIL flip_flop hold: q=%h expected=A5", q);
            errors = errors + 1;
        end

        // Enable again
        d  = 8'hFF;
        en = 1'b1;
        @(posedge clk); #1;
        if (q !== 8'hFF) begin
            $display("FAIL flip_flop second capture: q=%h expected=FF", q);
            errors = errors + 1;
        end

        // Asynchronous reset while running
        rst_n = 1'b0;
        #1;
        if (q !== RESET_VALUE) begin
            $display("FAIL flip_flop async reset: q=%h expected=%h", q, RESET_VALUE);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("tb_flip_flop: PASS");
        else
            $display("tb_flip_flop: FAIL (%0d errors)", errors);

        $finish;
    end
endmodule
