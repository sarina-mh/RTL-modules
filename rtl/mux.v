// ============================================================================
// Module: mux  (Multiplexer)
// ----------------------------------------------------------------------------
// Description:
//   Parameterized multiplexer. It has N inputs, each WIDTH bits wide, and
//   connects one of them to the output based on sel. The inputs are packed
//   into a single vector (input 0 in the lowest bits, input N-1 in the highest).
//
// Parameters:
//   WIDTH     : Width of each input/output (default 8)
//   N         : Number of inputs (default 4)
//   SEL_WIDTH : Select width; automatically ceil(log2(N))
//
// Inputs:
//   in  : Packed input vector, N*WIDTH bits
//   sel : Index of the selected input, SEL_WIDTH bits
//
// Outputs:
//   out : Selected input, WIDTH bits
// ============================================================================
module mux #(
    parameter WIDTH     = 8,
    parameter N         = 4,
    parameter SEL_WIDTH = (N <= 2) ? 1 : $clog2(N)
)(
    input  wire [N*WIDTH-1:0]   in,
    input  wire [SEL_WIDTH-1:0] sel,
    output reg  [WIDTH-1:0]     out
);

    integer i;

    always @(*) begin
        // Default to zero so the output is never floating for an invalid sel.
        out = {WIDTH{1'b0}};
        for (i = 0; i < N; i = i + 1) begin
            if (sel == i)
                out = in[i*WIDTH +: WIDTH];
        end
    end

endmodule
