// ============================================================================
// Module: universal_shift  (Universal shift register)
// ----------------------------------------------------------------------------
// Description:
//   A universal shift register that performs four operations selected by mode:
//     mode = 00 : hold
//     mode = 01 : shift right
//     mode = 10 : shift left
//     mode = 11 : parallel load
//   Note: Verilog's >> and << operators also perform shifts, but this module
//   is the synthesizable hardware version with full control.
//
// Parameters:
//   WIDTH : Register width (default 8)
//
// Inputs:
//   clk          : Clock
//   rst          : Asynchronous reset, active high
//   mode         : Operation select (2 bits)
//   serial_right : Bit shifted in at the MSB side during a right shift
//   serial_left  : Bit shifted in at the LSB side during a left shift
//   parallel_in  : Parallel load value (WIDTH bits)
//
// Outputs:
//   q                : Register value (WIDTH bits)
//   serial_out_right : Bit shifted out at the LSB side during a right shift
//   serial_out_left  : Bit shifted out at the MSB side during a left shift
// ============================================================================
module universal_shift #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire [1:0]       mode,
    input  wire             serial_right,
    input  wire             serial_left,
    input  wire [WIDTH-1:0] parallel_in,
    output reg  [WIDTH-1:0] q,
    output wire             serial_out_right,
    output wire             serial_out_left
);

    assign serial_out_right = q[0];
    assign serial_out_left  = q[WIDTH-1];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            q <= {WIDTH{1'b0}};
        end else begin
            case (mode)
                2'b00: q <= q;                              // Hold
                2'b01: q <= {serial_right, q[WIDTH-1:1]};   // Shift right
                2'b10: q <= {q[WIDTH-2:0], serial_left};    // Shift left
                2'b11: q <= parallel_in;                    // Parallel load
            endcase
        end
    end

endmodule
