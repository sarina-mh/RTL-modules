// ============================================================================
// Testbench: tb_comparator
// Checks all six relational outputs for several operand pairs.
// ============================================================================
`timescale 1ns/1ps

module tb_comparator;
    parameter WIDTH = 8;

    reg  [WIDTH-1:0] a;
    reg  [WIDTH-1:0] b;
    wire             eq;
    wire             ne;
    wire             gt;
    wire             lt;
    wire             ge;
    wire             le;

    integer errors;

    comparator #(.WIDTH(WIDTH)) dut (
        .a(a), .b(b),
        .eq(eq), .ne(ne), .gt(gt), .lt(lt), .ge(ge), .le(le)
    );

    task check;
        input [WIDTH-1:0] ta;
        input [WIDTH-1:0] tb;
        begin
            a = ta;
            b = tb;
            #1;

            if (eq !== (ta == tb)) begin
                $display("FAIL comparator eq: a=%0d b=%0d eq=%b", ta, tb, eq);
                errors = errors + 1;
            end
            if (ne !== (ta != tb)) begin
                $display("FAIL comparator ne: a=%0d b=%0d ne=%b", ta, tb, ne);
                errors = errors + 1;
            end
            if (gt !== (ta > tb)) begin
                $display("FAIL comparator gt: a=%0d b=%0d gt=%b", ta, tb, gt);
                errors = errors + 1;
            end
            if (lt !== (ta < tb)) begin
                $display("FAIL comparator lt: a=%0d b=%0d lt=%b", ta, tb, lt);
                errors = errors + 1;
            end
            if (ge !== (ta >= tb)) begin
                $display("FAIL comparator ge: a=%0d b=%0d ge=%b", ta, tb, ge);
                errors = errors + 1;
            end
            if (le !== (ta <= tb)) begin
                $display("FAIL comparator le: a=%0d b=%0d le=%b", ta, tb, le);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;

        check(8'd0,   8'd0);
        check(8'd1,   8'd0);
        check(8'd0,   8'd1);
        check(8'd100, 8'd100);
        check(8'd100, 8'd99);
        check(8'd99,  8'd100);
        check(8'd255, 8'd0);
        check(8'd0,   8'd255);

        if (errors == 0)
            $display("tb_comparator: PASS");
        else
            $display("tb_comparator: FAIL (%0d errors)", errors);

        $finish;
    end
endmodule
