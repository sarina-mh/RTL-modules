// ============================================================================
// Module: mul  (Multiplier)
// ----------------------------------------------------------------------------
// Description:
//   Multiplies two numbers. The result width equals the sum of the two operand
//   widths so no product bits are lost. Both unsigned and signed (two's
//   complement) operation are supported through the SIGNED parameter.
//
// Parameters:
//   A_WIDTH : Width of operand a (default 8)
//   B_WIDTH : Width of operand b (default 8)
//   P_WIDTH : Width of the product (default A_WIDTH + B_WIDTH)
//   SIGNED  : 0 = unsigned, 1 = signed (default 0)
//
// Inputs:
//   a : First operand  (A_WIDTH bits)
//   b : Second operand (B_WIDTH bits)
//
// Outputs:
//   p : Product (P_WIDTH bits)
// ============================================================================
module mul #(
    parameter A_WIDTH = 8,
    parameter B_WIDTH = 8,
    parameter P_WIDTH = A_WIDTH + B_WIDTH,
    parameter SIGNED  = 0
)(
    input  wire [A_WIDTH-1:0] a,
    input  wire [B_WIDTH-1:0] b,
    output wire [P_WIDTH-1:0] p
);

    generate
        if (SIGNED) begin : g_signed
            // Signed (two's complement) multiplication
            assign p = $signed(a) * $signed(b);
        end else begin : g_unsigned
            // Unsigned multiplication
            assign p = a * b;
        end
    endgenerate

endmodule
