// ============================================================================
// Testbench: tb_parity
// Checks even/odd parity generation and the checker error output.
// ============================================================================
`timescale 1ns/1ps

module tb_parity;
    parameter WIDTH = 8;

    reg  [WIDTH-1:0] data;
    reg              parity_in;
    reg              check_mode;

    wire             parity_even;
    wire             parity_odd;
    wire             error_even;
    wire             error_odd;

    integer errors;

    parity #(.WIDTH(WIDTH), .EVEN(1)) dut_even (
        .data(data), .parity_in(parity_in), .check_mode(check_mode),
        .parity_out(parity_even), .error(error_even)
    );

    parity #(.WIDTH(WIDTH), .EVEN(0)) dut_odd (
        .data(data), .parity_in(parity_in), .check_mode(check_mode),
        .parity_out(parity_odd), .error(error_odd)
    );

    task check;
        input [WIDTH-1:0] tdata;
        input             tparity_in;
        input             tcheck_mode;
        reg               exp_even;
        reg               exp_odd;
        begin
            data       = tdata;
            parity_in  = tparity_in;
            check_mode = tcheck_mode;
            #1;

            exp_even = ^tdata;
            exp_odd  = ~^tdata;

            if (parity_even !== exp_even) begin
                $display("FAIL parity even: data=%b -> %b expected %b",
                         tdata, parity_even, exp_even);
                errors = errors + 1;
            end

            if (parity_odd !== exp_odd) begin
                $display("FAIL parity odd: data=%b -> %b expected %b",
                         tdata, parity_odd, exp_odd);
                errors = errors + 1;
            end

            if (tcheck_mode) begin
                if (error_even !== (tparity_in != exp_even)) begin
                    $display("FAIL parity even checker: data=%b parity_in=%b error=%b",
                             tdata, tparity_in, error_even);
                    errors = errors + 1;
                end
                if (error_odd !== (tparity_in != exp_odd)) begin
                    $display("FAIL parity odd checker: data=%b parity_in=%b error=%b",
                             tdata, tparity_in, error_odd);
                    errors = errors + 1;
                end
            end else begin
                if (error_even !== 1'b0 || error_odd !== 1'b0) begin
                    $display("FAIL parity generate mode: error_even=%b error_odd=%b",
                             error_even, error_odd);
                    errors = errors + 1;
                end
            end
        end
    endtask

    initial begin
        errors = 0;

        // Generation mode
        check(8'h00, 1'b0, 1'b0);
        check(8'h01, 1'b0, 1'b0);
        check(8'h03, 1'b0, 1'b0);
        check(8'h07, 1'b0, 1'b0);
        check(8'hFF, 1'b0, 1'b0);
        check(8'hA5, 1'b0, 1'b0);

        // Checker mode: correct parity then corrupted parity
        check(8'hA5, ^8'hA5, 1'b1);
        check(8'hA5, ~^8'hA5, 1'b1);
        check(8'hFF, ^8'hFF, 1'b1);
        check(8'hFF, ~^8'hFF, 1'b1);

        if (errors == 0)
            $display("tb_parity: PASS");
        else
            $display("tb_parity: FAIL (%0d errors)", errors);

        $finish;
    end
endmodule
