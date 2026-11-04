// ============================================================================
// Testbench: tb_mux
// Checks every select value of the parameterized multiplexer.
// ============================================================================
`timescale 1ns/1ps

module tb_mux;
    parameter WIDTH     = 8;
    parameter N         = 4;
    parameter SEL_WIDTH = (N <= 2) ? 1 : $clog2(N);

    reg  [N*WIDTH-1:0]   in;
    reg  [SEL_WIDTH-1:0] sel;
    wire [WIDTH-1:0]     out;

    integer errors;
    integer i;

    mux #(
        .WIDTH(WIDTH),
        .N(N),
        .SEL_WIDTH(SEL_WIDTH)
    ) dut (
        .in(in), .sel(sel), .out(out)
    );

    initial begin
        errors = 0;

        // in[0]=10, in[1]=20, in[2]=30, in[3]=40
        in = {8'd40, 8'd30, 8'd20, 8'd10};

        for (i = 0; i < N; i = i + 1) begin
            sel = i;
            #1;
            if (out !== in[i*WIDTH +: WIDTH]) begin
                $display("FAIL mux: sel=%0d -> out=%0d expected=%0d",
                         i, out, in[i*WIDTH +: WIDTH]);
                errors = errors + 1;
            end
        end

        // Change the inputs and verify again.
        in = {8'd4, 8'd3, 8'd2, 8'd1};
        for (i = 0; i < N; i = i + 1) begin
            sel = i;
            #1;
            if (out !== in[i*WIDTH +: WIDTH]) begin
                $display("FAIL mux (second pass): sel=%0d -> out=%0d expected=%0d",
                         i, out, in[i*WIDTH +: WIDTH]);
                errors = errors + 1;
            end
        end

        if (errors == 0)
            $display("tb_mux: PASS");
        else
            $display("tb_mux: FAIL (%0d errors)", errors);

        $finish;
    end
endmodule
