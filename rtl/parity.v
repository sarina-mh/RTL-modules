// ============================================================================
// Module: parity  (Parity generator / checker)
// ----------------------------------------------------------------------------
// Description:
//   This module can both generate and check a parity bit.
//   - Generate mode (check_mode = 0): produces the parity bit for data.
//   - Check mode (check_mode = 1): compares the received parity bit
//     (parity_in) with the computed one and asserts error on a mismatch.
//
// Parameters:
//   WIDTH : Data width (default 8)
//   EVEN  : 1 = even parity, 0 = odd parity (default 1)
//
// Inputs:
//   data       : Input data (WIDTH bits)
//   parity_in  : Received parity bit (used in check mode)
//   check_mode : 0 = generate, 1 = check
//
// Outputs:
//   parity_out : Generated parity bit
//   error      : Parity error; only meaningful in check mode
// ============================================================================
module parity #(
    parameter WIDTH = 8,
    parameter EVEN  = 1
)(
    input  wire [WIDTH-1:0] data,
    input  wire             parity_in,
    input  wire             check_mode,
    output wire             parity_out,
    output wire             error
);

    // XOR of all bits: for even parity this is 1 when the number of ones is odd.
    wire xor_all;

    assign xor_all    = ^data;
    assign parity_out = EVEN ? xor_all : ~xor_all;
    assign error      = check_mode ? (parity_in != parity_out) : 1'b0;

endmodule
