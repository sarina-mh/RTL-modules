// ============================================================================
// Module: quick_sort  (Iterative quicksort)
// ----------------------------------------------------------------------------
// Description:
//   Sorts an array of N unsigned elements in ascending order using quicksort.
//   Recursion is not allowed in synthesizable RTL, so this implementation uses
//   an explicit LIFO stack of (low, high) index pairs.
//   Partitioning uses the last element as the pivot and performs one
//   comparison per clock cycle. The pivot is then placed in its final position
//   and the two non-empty subranges are pushed onto the stack.
//
//   Handshake:
//     - Pulse start for at least one clock while busy is low.
//     - busy goes high during sorting and low again when finished.
//     - done is a one-cycle pulse when data_out holds the sorted array.
//
// Parameters:
//   N           : Number of elements in the array (default 8)
//   WIDTH       : Bit width of each element (default 8)
//   STACK_DEPTH : Depth of the explicit index stack (default N + 2)
//
// Inputs:
//   clk      : Clock
//   rst      : Asynchronous reset, active high
//   start    : Start sorting (pulse)
//   data_in  : Flattened input array, N*WIDTH bits
//              (element k = data_in[k*WIDTH +: WIDTH])
//
// Outputs:
//   data_out : Flattened sorted array, N*WIDTH bits
//   done     : One-cycle completion pulse
//   busy     : High while sorting
// ============================================================================
module quick_sort #(
    parameter N           = 8,
    parameter WIDTH       = 8,
    parameter STACK_DEPTH = N + 2
)(
    input  wire               clk,
    input  wire               rst,
    input  wire               start,
    input  wire [N*WIDTH-1:0] data_in,
    output wire [N*WIDTH-1:0] data_out,
    output reg                done,
    output reg                busy
);

    localparam IDLE  = 3'd0;
    localparam POP   = 3'd1;
    localparam SETUP = 3'd2;
    localparam PART  = 3'd3;
    localparam PIVOT = 3'd4;
    localparam FIN   = 3'd5;

    reg [WIDTH-1:0] mem [0:N-1];
    reg [WIDTH-1:0] pivot;
    reg [2:0]       state;

    integer low, high, i, j, sp, k;

    // Explicit LIFO stack holding subrange boundaries.
    integer stack_low  [0:STACK_DEPTH-1];
    integer stack_high [0:STACK_DEPTH-1];

    // Expose the internal array as a flat output vector.
    genvar g;
    generate
        for (g = 0; g < N; g = g + 1) begin : g_out
            assign data_out[g*WIDTH +: WIDTH] = mem[g];
        end
    endgenerate

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            done  <= 1'b0;
            busy  <= 1'b0;
            sp    <= 0;
            low   <= 0;
            high  <= 0;
            i     <= 0;
            j     <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    busy <= 1'b0;
                    if (start) begin
                        // Load the input array into internal memory.
                        for (k = 0; k < N; k = k + 1)
                            mem[k] <= data_in[k*WIDTH +: WIDTH];

                        sp <= 0;
                        if (N <= 1) begin
                            state <= FIN;
                        end else begin
                            // Push the full range [0, N-1].
                            stack_low[0]  <= 0;
                            stack_high[0] <= N-1;
                            sp    <= 1;
                            busy  <= 1'b1;
                            state <= POP;
                        end
                    end
                end

                // Pop the next subrange to process.
                POP: begin
                    if (sp == 0) begin
                        state <= FIN;
                    end else begin
                        low   <= stack_low[sp-1];
                        high  <= stack_high[sp-1];
                        sp    <= sp - 1;
                        state <= SETUP;
                    end
                end

                // Skip empty/singleton subranges.
                SETUP: begin
                    if (low < high) begin
                        pivot <= mem[high];
                        i     <= low;
                        j     <= low;
                        state <= PART;
                    end else begin
                        state <= POP;
                    end
                end

                // Lomuto partition: elements < pivot move to the left.
                PART: begin
                    if (j < high) begin
                        if (mem[j] < pivot) begin
                            mem[i] <= mem[j];
                            mem[j] <= mem[i];
                            i      <= i + 1;
                        end
                        j <= j + 1;
                    end else begin
                        state <= PIVOT;
                    end
                end

                // Put the pivot in its final position and push subranges.
                PIVOT: begin
                    mem[i]    <= mem[high];
                    mem[high] <= mem[i];

                    if (i > low) begin
                        // Left subrange [low, i-1] is non-empty.
                        stack_low[sp]  <= low;
                        stack_high[sp] <= i - 1;

                        if (i < high) begin
                            // Right subrange [i+1, high] is also non-empty.
                            stack_low[sp+1]  <= i + 1;
                            stack_high[sp+1] <= high;
                            sp <= sp + 2;
                        end else begin
                            sp <= sp + 1;
                        end
                    end else if (i < high) begin
                        // Only the right subrange [i+1, high] is non-empty.
                        stack_low[sp]  <= i + 1;
                        stack_high[sp] <= high;
                        sp <= sp + 1;
                    end

                    state <= POP;
                end

                FIN: begin
                    busy  <= 1'b0;
                    done  <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
