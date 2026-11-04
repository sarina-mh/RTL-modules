// ============================================================================
// Testbench: tb_add
// Checks the combinational adder against the expected {cout, sum}.
// ============================================================================
`timescale 1ns/1ps

module tb_add;
    parameter WIDTH = 8;

    reg  [WIDTH-1:0] a;
    reg  [WIDTH-1:0] b;
    reg              cin;
    wire [WIDTH-1:0] sum;
    wire             cout;
    wire             overflow;

    integer errors;
    integer i;

    add #(.WIDTH(WIDTH)) dut (
        .a(a), .b(b), .cin(cin),
        .sum(sum), .cout(cout), .overflow(overflow)
    );

    task check;
        input [WIDTH-1:0] ta;
        input [WIDTH-1:0] tb;
        input             tc;
        reg   [WIDTH:0]   expected;
        begin
            a   = ta;
            b   = tb;
            cin = tc;
            #1;
            expected = {1'b0, ta} + {1'b0, tb} + tc;
            if ({cout, sum} !== expected) begin
                $display("FAIL add: a=%0d b=%0d cin=%b -> {cout,sum}={b}%0d expected={b}%0d",
                         ta, tb, tc, cout, sum, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;

        check(8'd0,   8'd0,   1'b0);
        check(8'd1,   8'd1,   1'b0);
        check(8'd255, 8'd1,   1'b0);
        check(8'd128, 8'd127, 1'b0);
        check(8'd100, 8'd50,  1'b1);
        check(8'd255, 8'd255, 1'b1);
        check(8'd42,  8'd17,  1'b0);

        for (i = 0; i < 8; i = i + 1)
            check(i, 8'd255 - i, 1'b0);

        if (errors == 0)
            $display("tb_add: PASS");
        else
            $display("tb_add: FAIL (%0d errors)", errors);

        $finish;
    end
endmodule
