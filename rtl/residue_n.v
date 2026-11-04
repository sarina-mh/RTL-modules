// ============================================================================
// Module: residue_n  (Modulo-N counter / residue)
// ----------------------------------------------------------------------------
// Description:
//   A modulo-N counter that counts from 0 to N-1 and wraps back to zero after
//   N-1; therefore the output is always the residue modulo N. done is asserted
//   while the counter is at N-1.
//
// Parameters:
//   N     : Counter modulus (default 10)
//   WIDTH : Output width; automatically ceil(log2(N))
//
// Inputs:
//   clk : Clock
//   rst : Asynchronous reset, active high
//   en  : Count enable
//
// Outputs:
//   value : Current counter value (0 to N-1)
//   done  : Asserted when value == N-1 (last state reached)
// ============================================================================
module residue_n #(
    parameter N     = 10,
    parameter WIDTH = (N <= 2) ? 1 : $clog2(N)
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             en,
    output reg  [WIDTH-1:0] value,
    output wire             done
);

    assign done = (value == N - 1);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            value <= {WIDTH{1'b0}};
        end else if (en) begin
            if (value == N - 1)
                value <= {WIDTH{1'b0}};   // Wrap back to zero (modulo N)
            else
                value <= value + 1'b1;
        end
    end

endmodule
