// ============================================================================
// Module: flip_flop  (D flip-flop)
// ----------------------------------------------------------------------------
// Description:
//   A parameterized-width D flip-flop. On the rising clock edge, if enable is
//   asserted, d is stored into q. The reset is asynchronous and active low
//   (rst_n). A complemented output is also provided.
//
// Parameters:
//   WIDTH       : Data/output width (default 1)
//   RESET_VALUE : Value loaded into q during reset (default 0)
//
// Inputs:
//   clk   : Clock
//   rst_n : Asynchronous reset, active low
//   en    : Storage enable
//   d     : Input data (WIDTH bits)
//
// Outputs:
//   q     : Output (WIDTH bits)
//   q_bar : Complemented output (WIDTH bits)
// ============================================================================
module flip_flop #(
    parameter WIDTH       = 1,
    parameter RESET_VALUE = 0
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire             en,
    input  wire [WIDTH-1:0] d,
    output reg  [WIDTH-1:0] q,
    output wire [WIDTH-1:0] q_bar
);

    assign q_bar = ~q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= RESET_VALUE;
        else if (en)
            q <= d;
    end

endmodule
