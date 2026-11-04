// ============================================================================
// Testbench: tb_universal_shift
// Checks hold, shift right, shift left, parallel load, and serial outputs.
// ============================================================================
`timescale 1ns/1ps

module tb_universal_shift;
    parameter WIDTH = 8;

    reg              clk;
    reg              rst;
    reg  [1:0]       mode;
    reg              serial_right;
    reg              serial_left;
    reg  [WIDTH-1:0] parallel_in;
    wire [WIDTH-1:0] q;
    wire             serial_out_right;
    wire             serial_out_left;

    integer errors;

    universal_shift #(.WIDTH(WIDTH)) dut (
        .clk(clk), .rst(rst), .mode(mode),
        .serial_right(serial_right), .serial_left(serial_left),
        .parallel_in(parallel_in),
        .q(q),
        .serial_out_right(serial_out_right),
        .serial_out_left(serial_out_left)
    );

    always #5 clk = ~clk;

    initial begin
        clk          = 1'b0;
        rst          = 1'b1;
        mode         = 2'b00;
        serial_right = 1'b0;
        serial_left  = 1'b0;
        parallel_in  = {WIDTH{1'b0}};
        errors       = 0;

        #12;
        if (q !== 8'h00) begin
            $display("FAIL universal_shift reset: q=%h expected=00", q);
            errors = errors + 1;
        end

        rst = 1'b0;

        // Parallel load
        mode        = 2'b11;
        parallel_in = 8'hA5;
        @(posedge clk); #1;
        if (q !== 8'hA5) begin
            $display("FAIL universal_shift load: q=%h expected=A5", q);
            errors = errors + 1;
        end

        // Hold
        mode = 2'b00;
        @(posedge clk); #1;
        if (q !== 8'hA5) begin
            $display("FAIL universal_shift hold: q=%h expected=A5", q);
            errors = errors + 1;
        end

        // Shift right, serial_right = 1
        mode         = 2'b01;
        serial_right = 1'b1;
        if (serial_out_right !== 1'b1) begin
            $display("FAIL universal_shift serial_out_right before shift: %b", serial_out_right);
            errors = errors + 1;
        end
        @(posedge clk); #1;
        if (q !== 8'hD2) begin
            $display("FAIL universal_shift shift right: q=%h expected=D2", q);
            errors = errors + 1;
        end

        // Shift left, serial_left = 0
        mode        = 2'b10;
        serial_left = 1'b0;
        if (serial_out_left !== 1'b1) begin
            $display("FAIL universal_shift serial_out_left before shift: %b", serial_out_left);
            errors = errors + 1;
        end
        @(posedge clk); #1;
        if (q !== 8'hA4) begin
            $display("FAIL universal_shift shift left: q=%h expected=A4", q);
            errors = errors + 1;
        end

        // Shift right, serial_right = 0
        mode         = 2'b01;
        serial_right = 1'b0;
        @(posedge clk); #1;
        if (q !== 8'h52) begin
            $display("FAIL universal_shift shift right 2: q=%h expected=52", q);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("tb_universal_shift: PASS");
        else
            $display("tb_universal_shift: FAIL (%0d errors)", errors);

        $finish;
    end
endmodule
