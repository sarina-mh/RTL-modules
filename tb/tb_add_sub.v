// ============================================================================
// Testbench: tb_add_sub
// Checks both add and subtract modes selected by sub_flag.
// ============================================================================
`timescale 1ns/1ps

module tb_add_sub;
    parameter WIDTH = 8;

    reg  [WIDTH-1:0] a;
    reg  [WIDTH-1:0] b;
    reg              sub_flag;
    reg              cin;
    wire [WIDTH-1:0] result;
    wire             cout;
    wire             overflow;

    integer errors;

    add_sub #(.WIDTH(WIDTH)) dut (
        .a(a), .b(b), .sub_flag(sub_flag), .cin(cin),
        .result(result), .cout(cout), .overflow(overflow)
    );

    task check;
        input [WIDTH-1:0] ta;
        input [WIDTH-1:0] tb;
        input             tsub;
        input             tc;
        reg   [WIDTH:0]   expected;
        begin
            a        = ta;
            b        = tb;
            sub_flag = tsub;
            cin      = tc;
            #1;
            if (tsub)
                expected = {1'b0, ta} - {1'b0, tb} - tc;
            else
                expected = {1'b0, ta} + {1'b0, tb} + tc;

            if ({cout, result} !== expected) begin
                $display("FAIL add_sub: a=%0d b=%0d sub=%b cin=%b -> {cout,result}={b}%0d expected={b}%0d",
                         ta, tb, tsub, tc, cout, result, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;

        check(8'd10,  8'd5,   1'b0, 1'b0);
        check(8'd10,  8'd5,   1'b1, 1'b0);
        check(8'd5,   8'd10,  1'b1, 1'b0);
        check(8'd255, 8'd1,   1'b0, 1'b0);
        check(8'd0,   8'd1,   1'b1, 1'b0);
        check(8'd200, 8'd100, 1'b0, 1'b1);
        check(8'd200, 8'd100, 1'b1, 1'b1);
        check(8'd128, 8'd127, 1'b0, 1'b0);
        check(8'd128, 8'd127, 1'b1, 1'b0);

        if (errors == 0)
            $display("tb_add_sub: PASS");
        else
            $display("tb_add_sub: FAIL (%0d errors)", errors);

        $finish;
    end
endmodule
