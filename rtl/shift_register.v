// ============================================================================
// Module: shift_register  (Shift register)
// ----------------------------------------------------------------------------
// Description:
//   A shift register with the requested controls:
//     init     : loads INIT_VALUE into the register (initialization)
//     load_reg : parallel load from parallel_in
//     shift_en : enables shifting (one bit per clock)
//   Priority: rst > init > load_reg > shift_en
//   The shift direction is selected by the DIR parameter.
//
// Parameters:
//   WIDTH      : Register width (default 8)
//   DIR        : 0 = shift right, 1 = shift left (default 0)
//   INIT_VALUE : Value loaded by init (default 0)
//
// Inputs:
//   clk         : Clock
//   rst         : Asynchronous reset, active high
//   shift_en    : Shift enable
//   init        : Initialize the register
//   load_reg    : Parallel load enable
//   serial_in   : Bit shifted into the register on each shift
//   parallel_in : Parallel load data (WIDTH bits)
//
// Outputs:
//   q          : Register value (WIDTH bits)
//   serial_out : Bit shifted out from the opposite side
// ============================================================================
module shift_register #(
    parameter WIDTH      = 8,
    parameter DIR        = 0,
    parameter INIT_VALUE = 0
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             shift_en,
    input  wire             init,
    input  wire             load_reg,
    input  wire             serial_in,
    input  wire [WIDTH-1:0] parallel_in,
    output reg  [WIDTH-1:0] q,
    output wire             serial_out
);

    // Serial output comes from the side the register shifts towards.
    assign serial_out = (DIR == 0) ? q[0] : q[WIDTH-1];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            q <= INIT_VALUE;
        end else if (init) begin
            q <= INIT_VALUE;
        end else if (load_reg) begin
            q <= parallel_in;
        end else if (shift_en) begin
            if (DIR == 0)
                q <= {serial_in, q[WIDTH-1:1]};   // Shift right
            else
                q <= {q[WIDTH-2:0], serial_in};   // Shift left
        end
    end

endmodule
