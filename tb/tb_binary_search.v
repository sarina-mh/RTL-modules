// ============================================================================
// Testbench: tb_binary_search
// Runs several searches (hit and miss) against a sorted array.
// ============================================================================
`timescale 1ns/1ps

module tb_binary_search;
    parameter N     = 8;
    parameter WIDTH = 8;
    parameter IDX_W = 3;

    reg                    clk;
    reg                    rst;
    reg                    start;
    reg  [N*WIDTH-1:0]     data_in;
    reg  [WIDTH-1:0]       key;
    wire                   found;
    wire [IDX_W-1:0]       index;
    wire                   done;
    wire                   busy;

    integer errors;
    integer k;
    integer sorted_vals [0:N-1];

    binary_search #(
        .N(N), .WIDTH(WIDTH), .IDX_W(IDX_W)
    ) dut (
        .clk(clk), .rst(rst), .start(start),
        .data_in(data_in), .key(key),
        .found(found), .index(index),
        .done(done), .busy(busy)
    );

    always #5 clk = ~clk;

    task run_search;
        input [WIDTH-1:0] search_key;
        input             exp_found;
        input [IDX_W-1:0] exp_index;
        begin
            key = search_key;

            @(posedge clk);
            start = 1'b1;
            @(posedge clk);
            start = 1'b0;

            wait (done);
            #1;

            if (found !== exp_found) begin
                $display("FAIL binary_search found: key=%0d got=%b expected=%b",
                         search_key, found, exp_found);
                errors = errors + 1;
            end

            if (exp_found && (index !== exp_index)) begin
                $display("FAIL binary_search index: key=%0d got=%0d expected=%0d",
                         search_key, index, exp_index);
                errors = errors + 1;
            end

            // Return to idle and clear done before the next search.
            @(posedge clk);
        end
    endtask

    initial begin
        clk     = 1'b0;
        rst     = 1'b1;
        start   = 1'b0;
        key     = {WIDTH{1'b0}};
        data_in = {N*WIDTH{1'b0}};
        errors  = 0;

        // Sorted array: 1, 3, 5, 7, 9, 11, 13, 15
        sorted_vals[0] = 1;
        sorted_vals[1] = 3;
        sorted_vals[2] = 5;
        sorted_vals[3] = 7;
        sorted_vals[4] = 9;
        sorted_vals[5] = 11;
        sorted_vals[6] = 13;
        sorted_vals[7] = 15;

        for (k = 0; k < N; k = k + 1)
            data_in[k*WIDTH +: WIDTH] = sorted_vals[k];

        #12;
        rst = 1'b0;

        run_search(8'd7,  1'b1, 3'd3);
        run_search(8'd1,  1'b1, 3'd0);
        run_search(8'd15, 1'b1, 3'd7);
        run_search(8'd9,  1'b1, 3'd4);
        run_search(8'd8,  1'b0, 3'd0);
        run_search(8'd0,  1'b0, 3'd0);
        run_search(8'd16, 1'b0, 3'd0);

        if (errors == 0)
            $display("tb_binary_search: PASS");
        else
            $display("tb_binary_search: FAIL (%0d errors)", errors);

        $finish;
    end

    initial begin
        #100000;
        $display("tb_binary_search: TIMEOUT");
        $finish;
    end
endmodule
