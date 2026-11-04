// ============================================================================
// Module: bubble_sort  (Bubble sort)
// ----------------------------------------------------------------------------
// Description:
//   Sorts an array of N unsigned elements in ascending order using the
//   bubble-sort algorithm. The array is sampled from data_in when start is
//   asserted. Repeated passes compare adjacent elements and swap them when
//   they are out of order; after pass i the largest i+1 elements are in place.
//   One comparison is performed per clock cycle.
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
module bubble_sort #(
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
    localparam CMP  = 2'd1;
    localparam FIN  = 2'd2;

    reg [WIDTH-1:0] mem [0:N-1];
    reg [1:0]       state;

    integer i, j, k;

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

                        i <= 0;
                        j <= 0;
                        if (N <= 1) begin
                            state <= FIN;
                        end else begin
                            busy  <= 1'b1;
                            state <= CMP;
                        end
                    end
                end

                // Compare and swap one adjacent pair per cycle.
                CMP: begin
                    if (mem[j] > mem[j+1]) begin
                        mem[j]   <= mem[j+1];
                        mem[j+1] <= mem[j];
                    end

                    if (j == N-2-i) begin
                        j <= 0;
                        if (i == N-2) begin
                            state <= FIN;
                        end else begin
                            i     <= i + 1;
                            state <= CMP;
                        end
                    end else begin
                        j <= j + 1;
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
