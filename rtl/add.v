// ============================================================================
// Module: add  (Adder)
// ----------------------------------------------------------------------------
// Description:
//   Combinational (clockless) adder with configurable width.
//   Computes sum = a + b + cin and also produces carry-out and signed overflow.
//
// Parameters:
//   WIDTH : Bit width of the operands and result (default 8)
//
// Inputs:
//   a   : First operand  (WIDTH bits)
//   b   : Second operand (WIDTH bits)
//   cin : Carry-in
//
// Outputs:
//   sum      : Sum result (WIDTH bits)
//   cout     : Carry-out
//   overflow : Signed overflow; asserted when both operands have the same sign
//              but the result has a different sign.
// ============================================================================
module add #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire             cin,
    output wire [WIDTH-1:0] sum,
    output wire             cout,
    output wire             overflow
);

    // One extra bit is used so the carry-out is not lost.
    wire [WIDTH:0] result;

    assign result = {1'b0, a} + {1'b0, b} + cin;

    assign sum  = result[WIDTH-1:0];
    assign cout = result[WIDTH];

    // Signed overflow: operands have equal signs but the result sign differs.
    assign overflow = (a[WIDTH-1] == b[WIDTH-1]) &&
                      (sum[WIDTH-1] != a[WIDTH-1]);

endmodule
