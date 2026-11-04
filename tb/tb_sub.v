// ============================================================================
// Testbench: tb_sub
// Checks the combinational subtractor against the expected {bout, diff}.
// ============================================================================
`timescale 1ns/1ps

module tb_sub;
    parameter WIDTH = 8;

    reg  [WIDTH-1:0] a;
    reg  [WIDTH-1:0] b;
    reg              bin;
    wire [WIDTH-1:0] diff;
    wire             bout;
    wire             overflow;

    integer errors;
    integer i;

    sub #(.WIDTH(WIDTH)) dut (
        .a(a), .b(b), .bin(bin),
        .diff(diff), .bout(bout), .overflow(overflow)
    );

    task check;
        input [WIDTH-1:0] ta;
        input [WIDTH-1:0] tb;
        input             tbin;
        reg   [WIDTH:0]   expected;
        begin
            a   = ta;
            b   = tb;
            bin = tbin;
            #1;
            expected = {1'b0, ta} - {1'b0, tb} - tbin;
            if ({bout, diff} !== expected) begin
                $display("FAIL sub: a=%0d b=%0d bin=%b -> {bout,diff}={b}%0d expected={b}%0d",
                         ta, tb, tbin, bout, diff, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;

        check(8'd0,   8'd0,   1'b0);
        check(8'd1,   8'd1,   1'b0);
        check(8'd0,   8'd1,   1'b0);
        check(8'd128, 8'd127, 1'b0);
        check(8'd100, 8'd50,  1'b1);
        check(8'd255, 8'd255, 1'b1);
        check(8'd42,  8'd17,  1'b0);

        for (i = 0; i < 8; i = i + 1)
            check(i, 8'd255 - i, 1'b0);

        if (errors == 0)
            $display("tb_sub: PASS");
        else
            $display("tb_sub: FAIL (%0d errors)", errors);

        $finish;
    end
endmodule
