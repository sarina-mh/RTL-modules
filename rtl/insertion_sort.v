// ============================================================================
// Module: insertion_sort  (Insertion sort)
// ----------------------------------------------------------------------------
// Description:
//   Sorts an array of N unsigned elements in ascending order using the
//   insertion-sort algorithm. The array is sampled from data_in when start is
//   asserted. For i = 1 .. N-1, the key mem[i] is inserted into the already
//   sorted prefix by shifting larger elements one position to the right.
//   One shift is performed per clock cycle.
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
module insertion_sort #(
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

    localparam IDLE  = 3'd0;
    localparam PICK  = 3'd1;
    localparam SHIFT = 3'd2;
    localparam PLACE = 3'd3;
    localparam NEXT  = 3'd4;
    localparam FIN   = 3'd5;

    reg [WIDTH-1:0] mem [0:N-1];
    reg [WIDTH-1:0] key;
    reg [2:0]       state;

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

                        i <= 1;
                        if (N <= 1) begin
                            state <= FIN;
                        end else begin
                            busy  <= 1'b1;
                            state <= PICK;
                        end
                    end
                end

                // Capture the element to insert and start scanning left.
                PICK: begin
                    key   <= mem[i];
                    j     <= i - 1;
                    state <= SHIFT;
                end

                // Shift larger elements one position to the right.
                SHIFT: begin
                    if (j >= 0) begin
                        if (mem[j] > key) begin
                            mem[j+1] <= mem[j];
                            j        <= j - 1;
                        end else begin
                            state <= PLACE;
                        end
                    end else begin
                        state <= PLACE;
                    end
                end

                // Store the key in its final position.
                PLACE: begin
                    mem[j+1] <= key;
                    state    <= NEXT;
                end

                // Move to the next element or finish.
                NEXT: begin
                    if (i == N-1) begin
                        state <= FIN;
                    end else begin
                        i     <= i + 1;
                        state <= PICK;
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
