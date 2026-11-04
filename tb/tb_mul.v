// ============================================================================
// Testbench: tb_mul
// Checks both unsigned and signed multiplier instances.
// ============================================================================
`timescale 1ns/1ps

module tb_mul;
    parameter A_WIDTH = 8;
    parameter B_WIDTH = 8;
    parameter P_WIDTH = A_WIDTH + B_WIDTH;

    reg  [A_WIDTH-1:0] a;
    reg  [B_WIDTH-1:0] b;
    wire [P_WIDTH-1:0] p_unsigned;
    wire [P_WIDTH-1:0] p_signed;

    integer errors;

    reg [P_WIDTH-1:0] expected_unsigned;
    reg [P_WIDTH-1:0] expected_signed;

    mul #(
        .A_WIDTH(A_WIDTH),
        .B_WIDTH(B_WIDTH),
        .P_WIDTH(P_WIDTH),
        .SIGNED(0)
    ) dut_unsigned (
        .a(a), .b(b), .p(p_unsigned)
    );

    mul #(
        .A_WIDTH(A_WIDTH),
        .B_WIDTH(B_WIDTH),
        .P_WIDTH(P_WIDTH),
        .SIGNED(1)
    ) dut_signed (
        .a(a), .b(b), .p(p_signed)
    );

    task check;
        input [A_WIDTH-1:0] ta;
        input [B_WIDTH-1:0] tb;
        begin
            a = ta;
            b = tb;
            #1;

            expected_unsigned = ta * tb;
            expected_signed   = $signed(ta) * $signed(tb);

            if (p_unsigned !== expected_unsigned) begin
                $display("FAIL mul unsigned: a=%0d b=%0d -> p=%0d expected=%0d",
                         ta, tb, p_unsigned, expected_unsigned);
                errors = errors + 1;
            end

            if (p_signed !== expected_signed) begin
                $display("FAIL mul signed: a=%0d b=%0d -> p=%0d expected=%0d",
                         $signed(ta), $signed(tb), $signed(p_signed), $signed(expected_signed));
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;

        check(8'd0,   8'd0);
        check(8'd1,   8'd1);
        check(8'd10,  8'd20);
        check(8'd100, 8'd3);
        check(8'd255, 8'd2);
        check(8'd128, 8'd2);
        check(8'd200, 8'd200);

        // Signed edge cases: -1, -2, -128
        check(8'hFF, 8'd2);     // -1 * 2 = -2
        check(8'hFE, 8'd3);     // -2 * 3 = -6
        check(8'h80, 8'd2);     // -128 * 2 = -256
        check(8'h80, 8'h80);    // -128 * -128 = 16384

        if (errors == 0)
            $display("tb_mul: PASS");
        else
            $display("tb_mul: FAIL (%0d errors)", errors);

        $finish;
    end
endmodule
