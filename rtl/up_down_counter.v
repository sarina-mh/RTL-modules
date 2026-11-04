// ============================================================================
// Module: up_down_counter  (Up/down counter)
// ----------------------------------------------------------------------------
// Description:
//   An up/down counter with a configurable range.
//   - count_up = 1 : counts up
//   - count_up = 0 : counts down
//   - count_en = 1 : counting is enabled
//   - serial_in    : Carry-in / serial enable used to chain counters
//                    (tie it to 1 for standalone operation)
//   - done         : Last state reached (MAX_VALUE when counting up,
//                    MIN_VALUE when counting down)
//   The counter wraps around at the boundaries.
//
// Parameters:
//   WIDTH     : Counter width (default 8)
//   MIN_VALUE : Minimum value (default 0)
//   MAX_VALUE : Maximum value (default 2^WIDTH - 1)
//
// Inputs:
//   clk       : Clock
//   rst       : Asynchronous reset, active high (loads MIN_VALUE)
//   count_en  : Count enable
//   count_up  : Count direction; 1 = up, 0 = down
//   serial_in : Carry-in / serial enable
//
// Outputs:
//   value : Current counter value
//   done  : Counting boundary reached
// ============================================================================
module up_down_counter #(
    parameter WIDTH     = 8,
    parameter MIN_VALUE = 0,
    parameter MAX_VALUE = (1 << WIDTH) - 1
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             count_en,
    input  wire             count_up,
    input  wire             serial_in,
    output reg  [WIDTH-1:0] value,
    output wire             done
);

    // done reflects reaching the ceiling or floor depending on direction.
    assign done = count_up ? (value == MAX_VALUE) : (value == MIN_VALUE);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            value <= MIN_VALUE;
        end else if (count_en && serial_in) begin
            if (count_up) begin
                if (value >= MAX_VALUE)
                    value <= MIN_VALUE;   // Wrap at the ceiling
                else
                    value <= value + 1'b1;
            end else begin
                if (value <= MIN_VALUE)
                    value <= MAX_VALUE;   // Wrap at the floor
                else
                    value <= value - 1'b1;
            end
        end
    end

endmodule
