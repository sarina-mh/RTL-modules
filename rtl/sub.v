// ============================================================================
// Module: sub  (Subtractor)
// ----------------------------------------------------------------------------
// Description:
//   Combinational subtractor with configurable width.
//   Computes diff = a - b - bin and also produces borrow-out and signed overflow.
//
// Parameters:
//   WIDTH : Bit width of the operands and result (default 8)
//
// Inputs:
//   a   : First operand  (WIDTH bits)
//   b   : Second operand (WIDTH bits)
//   bin : Borrow-in
//
// Outputs:
//   diff     : Difference result (WIDTH bits)
//   bout     : Borrow-out
//   overflow : Signed overflow
// ============================================================================
module sub #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire             bin,
    output wire [WIDTH-1:0] diff,
    output wire             bout,
    output wire             overflow
);

    // One extra bit is used so the borrow-out is not lost.
    wire [WIDTH:0] result;

    assign result = {1'b0, a} - {1'b0, b} - bin;

    assign diff = result[WIDTH-1:0];
    assign bout = result[WIDTH];

    // Signed overflow in subtraction: operands have different signs and the
    // result sign differs from the first operand's sign.
    assign overflow = (a[WIDTH-1] != b[WIDTH-1]) &&
                      (diff[WIDTH-1] != a[WIDTH-1]);

endmodule
