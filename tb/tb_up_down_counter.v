// ============================================================================
// Testbench: tb_up_down_counter
// Checks up counting, down counting, wraparound, serial enable, and done.
// ============================================================================
`timescale 1ns/1ps

module tb_up_down_counter;
    parameter WIDTH     = 4;
    parameter MIN_VALUE = 0;
    parameter MAX_VALUE = 5;

    reg              clk;
    reg              rst;
    reg              count_en;
    reg              count_up;
    reg              serial_in;
    wire [WIDTH-1:0] value;
    wire             done;

    integer errors;
    reg     expected_done;

    up_down_counter #(
        .WIDTH(WIDTH),
        .MIN_VALUE(MIN_VALUE),
        .MAX_VALUE(MAX_VALUE)
    ) dut (
        .clk(clk), .rst(rst),
        .count_en(count_en), .count_up(count_up), .serial_in(serial_in),
        .value(value), .done(done)
    );

    always #5 clk = ~clk;

    task tick;
        input [WIDTH-1:0] exp_value;
        begin
            @(posedge clk); #1;
            expected_done = count_up ? (exp_value == MAX_VALUE)
                                     : (exp_value == MIN_VALUE);
            if (value !== exp_value) begin
                $display("FAIL up_down_counter value: got=%0d expected=%0d (up=%b)",
                         value, exp_value, count_up);
                errors = errors + 1;
            end
            if (done !== expected_done) begin
                $display("FAIL up_down_counter done: got=%b expected=%b (value=%0d up=%b)",
                         done, expected_done, value, count_up);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk      = 1'b0;
        rst      = 1'b1;
        count_en = 1'b0;
        count_up = 1'b1;
        serial_in = 1'b1;
        errors   = 0;

        #12;
        if (value !== MIN_VALUE) begin
            $display("FAIL up_down_counter reset: value=%0d expected=%0d", value, MIN_VALUE);
            errors = errors + 1;
        end

        rst      = 1'b0;
        count_en = 1'b1;

        // Count up: 1,2,3,4,5, wrap to 0
        tick(4'd1);
        tick(4'd2);
        tick(4'd3);
        tick(4'd4);
        tick(4'd5);   // done = 1
        tick(4'd0);   // wrap

        // Count down from 0: wrap to 5, then 4,3,2,1,0
        count_up = 1'b0;
        tick(4'd5);
        tick(4'd4);
        tick(4'd3);
        tick(4'd2);
        tick(4'd1);
        tick(4'd0);   // done = 1

        // serial_in = 0 must hold the value
        count_up  = 1'b1;
        serial_in = 1'b0;
        tick(4'd0);

        // count_en = 0 must hold the value
        serial_in = 1'b1;
        count_en  = 1'b0;
        tick(4'd0);

        if (errors == 0)
            $display("tb_up_down_counter: PASS");
        else
            $display("tb_up_down_counter: FAIL (%0d errors)", errors);

        $finish;
    end
endmodule
