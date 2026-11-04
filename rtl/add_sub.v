// ============================================================================
// Module: add_sub  (Adder/Subtractor with flag)
// ----------------------------------------------------------------------------
// Description:
//   As you suggested, building separate add and subtract blocks is a bit
//   pointless; this module performs both using a single flag (sub_flag).
//     sub_flag = 0  =>  result = a + b + cin
//     sub_flag = 1  =>  result = a - b - cin
//
// Parameters:
//   WIDTH : Bit width of the operands and result (default 8)
//
// Inputs:
//   a        : First operand (WIDTH bits)
//   b        : Second operand (WIDTH bits)
//   sub_flag : Operation select; 0 = add, 1 = subtract
//   cin      : Carry-in / borrow-in
//
// Outputs:
//   result   : Add or subtract result (WIDTH bits)
//   cout     : Carry-out / borrow-out
//   overflow : Signed overflow (depends on the operation)
// ============================================================================
module add_sub #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire             sub_flag,
    input  wire             cin,
    output reg  [WIDTH-1:0] result,
    output reg              cout,
    output reg              overflow
);

    always @(*) begin
        if (!sub_flag) begin
            // Addition
            {cout, result} = {1'b0, a} + {1'b0, b} + cin;
            overflow = (a[WIDTH-1] == b[WIDTH-1]) &&
                       (result[WIDTH-1] != a[WIDTH-1]);
        end else begin
            // Subtraction
            {cout, result} = {1'b0, a} - {1'b0, b} - cin;
            overflow = (a[WIDTH-1] != b[WIDTH-1]) &&
                       (result[WIDTH-1] != a[WIDTH-1]);
        end
    end

endmodule
