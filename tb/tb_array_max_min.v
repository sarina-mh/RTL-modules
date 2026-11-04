// ============================================================================
// Testbench: tb_array_max_min
// Checks the maximum and minimum of a small array.
// ============================================================================
`timescale 1ns/1ps

module tb_array_max_min;
    parameter N     = 6;
    parameter WIDTH = 8;

    reg                clk;
    reg                rst;
    reg                start;
    reg  [N*WIDTH-1:0] data_in;
    wire [WIDTH-1:0]   max_val;
    wire [WIDTH-1:0]   min_val;
    wire               done;
    wire               busy;

    integer errors;
    integer k;
    integer in_vals [0:N-1];

    array_max_min #(.N(N), .WIDTH(WIDTH)) dut (
        .clk(clk), .rst(rst), .start(start),
        .data_in(data_in),
        .max_val(max_val), .min_val(min_val),
        .done(done), .busy(busy)
    );

    always #5 clk = ~clk;

    initial begin
        clk     = 1'b0;
        rst     = 1'b1;
        start   = 1'b0;
        data_in = {N*WIDTH{1'b0}};
        errors  = 0;

        in_vals[0] = 5;
        in_vals[1] = 2;
        in_vals[2] = 9;
        in_vals[3] = 1;
        in_vals[4] = 5;
        in_vals[5] = 7;

        for (k = 0; k < N; k = k + 1)
            data_in[k*WIDTH +: WIDTH] = in_vals[k];

        #12;
        rst = 1'b0;

        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        wait (done);
        #1;

        if (max_val !== 8'd9) begin
            $display("FAIL array_max_min max: got=%0d expected=9", max_val);
            errors = errors + 1;
        end
        if (min_val !== 8'd1) begin
            $display("FAIL array_max_min min: got=%0d expected=1", min_val);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("tb_array_max_min: PASS");
        else
            $display("tb_array_max_min: FAIL (%0d errors)", errors);

        $finish;
    end

    initial begin
        #100000;
        $display("tb_array_max_min: TIMEOUT");
        $finish;
    end
endmodule
