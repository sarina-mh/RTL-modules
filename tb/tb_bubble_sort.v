// ============================================================================
// Testbench: tb_bubble_sort
// Sorts a small array, waits for done, and compares against a reference sort.
// ============================================================================
`timescale 1ns/1ps

module tb_bubble_sort;
    parameter N     = 6;
    parameter WIDTH = 8;

    reg                clk;
    reg                rst;
    reg                start;
    reg  [N*WIDTH-1:0] data_in;
    wire [N*WIDTH-1:0] data_out;
    wire               done;
    wire               busy;

    integer errors;
    integer k;
    integer in_vals  [0:N-1];
    integer exp_vals [0:N-1];

    bubble_sort #(.N(N), .WIDTH(WIDTH)) dut (
        .clk(clk), .rst(rst), .start(start),
        .data_in(data_in), .data_out(data_out),
        .done(done), .busy(busy)
    );

    always #5 clk = ~clk;

    task sort_expected;
        integer p, q, m, t;
        begin
            for (p = 0; p < N; p = p + 1)
                exp_vals[p] = in_vals[p];

            for (p = 0; p < N-1; p = p + 1) begin
                m = p;
                for (q = p+1; q < N; q = q + 1)
                    if (exp_vals[q] < exp_vals[m])
                        m = q;
                t = exp_vals[p];
                exp_vals[p] = exp_vals[m];
                exp_vals[m] = t;
            end
        end
    endtask

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

        sort_expected();

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

        for (k = 0; k < N; k = k + 1) begin
            if (data_out[k*WIDTH +: WIDTH] !== exp_vals[k]) begin
                $display("FAIL bubble_sort: index %0d got=%0d expected=%0d",
                         k, data_out[k*WIDTH +: WIDTH], exp_vals[k]);
                errors = errors + 1;
            end
        end

        if (errors == 0)
            $display("tb_bubble_sort: PASS");
        else
            $display("tb_bubble_sort: FAIL (%0d errors)", errors);

        $finish;
    end

    initial begin
        #100000;
        $display("tb_bubble_sort: TIMEOUT");
        $finish;
    end
endmodule
