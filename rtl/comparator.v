// ============================================================================
// Module: comparator  (Comparator)
// ----------------------------------------------------------------------------
// Description:
//   Compares a and b and produces every possible comparison output at the same
//   time (combinational).
//
// Parameters:
//   WIDTH : Operand width (default 8)
//
// Inputs:
//   a : First operand  (WIDTH bits)
//   b : Second operand (WIDTH bits)
//
// Outputs:
//   eq : a == b
//   ne : a != b
//   gt : a >  b
//   lt : a <  b
//   ge : a >= b
//   le : a <= b
// ============================================================================
module comparator #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire             eq,
    output wire             ne,
    output wire             gt,
    output wire             lt,
    output wire             ge,
    output wire             le
);

    assign eq = (a == b);
    assign ne = (a != b);
    assign gt = (a >  b);
    assign lt = (a <  b);
    assign ge = (a >= b);
    assign le = (a <= b);

endmodule
