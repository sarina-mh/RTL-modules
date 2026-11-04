// ============================================================================
// Module: selection_sort  (Selection sort)
// ----------------------------------------------------------------------------
// Description:
//   Sorts an array of N unsigned elements in ascending order using the
//   selection-sort algorithm. The array is sampled from data_in when start is
//   asserted; the module then sorts it over multiple clock cycles.
//   For each position i, it scans the remaining elements to find the minimum
//   and swaps it into position i. One comparison is performed per clock cycle.
//
//   Handshake:
//     - Pulse start for at least one clock while busy is low.
//     - busy goes high during sorting and low again when finished.
//     - done is a one-cycle pulse when data_out holds the sorted array.
//
// Parameters:
//   N     : Number of elements in the array (default 8)
//   WIDTH : Bit width of each element (default 8)
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
module selection_sort #(
    parameter N     = 8,
    parameter WIDTH = 8
)(
    input  wire               clk,
    input  wire               rst,
    input  wire               start,
    input  wire [N*WIDTH-1:0] data_in,
    output wire [N*WIDTH-1:0] data_out,
    output reg                done,
    output reg                busy
);

    localparam IDLE = 2'd0;
    localparam SCAN = 2'd1;
    localparam SWAP = 2'd2;
    localparam FIN  = 2'd3;

    reg [WIDTH-1:0] mem [0:N-1];
    reg [1:0]       state;

    integer i, j, min_idx, k;

    // Expose the internal array as a flat output vector.
    genvar g;
    generate
        for (g = 0; g < N; g = g + 1) begin : g_out
            assign data_out[g*WIDTH +: WIDTH] = mem[g];
        end
    endgenerate

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state   <= IDLE;
            done    <= 1'b0;
            busy    <= 1'b0;
            i       <= 0;
            j       <= 0;
            min_idx <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    busy <= 1'b0;
                    if (start) begin
                        // Load the input array into internal memory.
                        for (k = 0; k < N; k = k + 1)
                            mem[k] <= data_in[k*WIDTH +: WIDTH];

                        i <= 0;
                        if (N <= 1) begin
                            state <= FIN;
                        end else begin
                            min_idx <= 0;
                            j       <= 1;
                            busy    <= 1'b1;
                            state   <= SCAN;
                        end
                    end
                end

                // Scan the unsorted part for the minimum element.
                SCAN: begin
                    if (mem[j] < mem[min_idx])
                        min_idx <= j;

                    if (j == N-1)
                        state <= SWAP;
                    else
                        j <= j + 1;
                end

                // Swap the minimum into position i and advance.
                SWAP: begin
                    mem[i]       <= mem[min_idx];
                    mem[min_idx] <= mem[i];

                    if (i == N-2) begin
                        state <= FIN;
                    end else begin
                        i       <= i + 1;
                        min_idx <= i + 1;
                        j       <= i + 2;
                        state   <= SCAN;
                    end
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
