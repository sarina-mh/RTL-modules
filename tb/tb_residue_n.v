// ============================================================================
// Testbench: tb_residue_n
// Checks modulo-N counting, wraparound, done, and enable.
// ============================================================================
`timescale 1ns/1ps

module tb_residue_n;
    parameter N     = 5;
    parameter WIDTH = 3;

    reg              clk;
    reg              rst;
    reg              en;
    wire [WIDTH-1:0] value;
    wire             done;

    integer errors;
    reg     expected_done;

    residue_n #(.N(N), .WIDTH(WIDTH)) dut (
        .clk(clk), .rst(rst), .en(en),
        .value(value), .done(done)
    );

    always #5 clk = ~clk;

    task tick;
        input [WIDTH-1:0] exp_value;
        begin
            @(posedge clk); #1;
            expected_done = (exp_value == N - 1);
            if (value !== exp_value) begin
                $display("FAIL residue_n value: got=%0d expected=%0d", value, exp_value);
                errors = errors + 1;
            end
            if (done !== expected_done) begin
                $display("FAIL residue_n done: got=%b expected=%b (value=%0d)",
                         done, expected_done, value);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk    = 1'b0;
        rst    = 1'b1;
        en     = 1'b0;
        errors = 0;

        #12;
        if (value !== 0) begin
            $display("FAIL residue_n reset: value=%0d expected=0", value);
            errors = errors + 1;
        end

        rst = 1'b0;
        en  = 1'b1;

        // 0 -> 1 -> 2 -> 3 -> 4 -> 0 -> 1 -> 2
        tick(3'd1);
        tick(3'd2);
        tick(3'd3);
        tick(3'd4);   // done = 1
        tick(3'd0);
        tick(3'd1);
        tick(3'd2);

        // Disabled: hold
        en = 1'b0;
        tick(3'd2);

        // Asynchronous reset
        rst = 1'b1;
        #1;
        if (value !== 0) begin
            $display("FAIL residue_n async reset: value=%0d expected=0", value);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("tb_residue_n: PASS");
        else
            $display("tb_residue_n: FAIL (%0d errors)", errors);

        $finish;
    end
endmodule
