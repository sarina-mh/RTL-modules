// ============================================================================
// Module: binary_search  (Binary search)
// ----------------------------------------------------------------------------
// Description:
//   Searches for key in a sorted array of N unsigned elements using binary
//   search. The array is read directly from data_in and one comparison is
//   performed per clock cycle. When a match is found, found is asserted and
//   index holds the matching position. If the key is not present, found stays
//   low and index is zero.
//
//   Handshake:
//     - Pulse start for at least one clock while busy is low.
//     - busy goes high during the search and low again when finished.
//     - done is a one-cycle pulse when found and index are valid.
//
// Parameters:
//   N     : Number of elements in the array (default 8)
//   WIDTH : Bit width of each element and of the key (default 8)
//   IDX_W : Index width; automatically ceil(log2(N))
//
// Inputs:
//   clk      : Clock
//   rst      : Asynchronous reset, active high
//   start    : Start searching (pulse)
//   data_in  : Flattened sorted array, N*WIDTH bits
//              (element k = data_in[k*WIDTH +: WIDTH])
//   key      : Value to search for (WIDTH bits)
//
// Outputs:
//   found : Asserted when key is present
//   index : Position of key when found (IDX_W bits)
//   done  : One-cycle completion pulse
//   busy  : High while searching
// ============================================================================
module binary_search #(
    parameter N     = 8,
    parameter WIDTH = 8,
    parameter IDX_W = (N <= 2) ? 1 : $clog2(N)
)(
    input  wire               clk,
    input  wire               rst,
    input  wire               start,
    input  wire [N*WIDTH-1:0] data_in,
    input  wire [WIDTH-1:0]   key,
    output reg                found,
    output reg  [IDX_W-1:0]   index,
    output reg                done,
    output reg                busy
);

    localparam IDLE   = 2'd0;
    localparam SEARCH = 2'd1;
    localparam FIN    = 2'd2;

    reg [1:0] state;

    // Signed integers are used so hi can become -1 without wrapping around.
    integer lo, hi;

    // Midpoint is computed combinationally; arithmetic shift keeps the sign.
    wire signed [31:0] mid;
    assign mid = (lo + hi) >>> 1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            found <= 1'b0;
            index <= {IDX_W{1'b0}};
            done  <= 1'b0;
            busy  <= 1'b0;
            lo    <= 0;
            hi    <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done  <= 1'b0;
                    busy  <= 1'b0;
                    found <= 1'b0;
                    index <= {IDX_W{1'b0}};
                    if (start) begin
                        lo <= 0;
                        hi <= N - 1;
                        if (N <= 0) begin
                            state <= FIN;
                        end else begin
                            busy  <= 1'b1;
                            state <= SEARCH;
                        end
                    end
                end

                SEARCH: begin
                    if (lo <= hi) begin
                        if (data_in[mid*WIDTH +: WIDTH] == key) begin
                            found <= 1'b1;
                            index <= mid;
                            state <= FIN;
                        end else if (data_in[mid*WIDTH +: WIDTH] < key) begin
                            lo <= mid + 1;
                        end else begin
                            hi <= mid - 1;
                        end
                    end else begin
                        state <= FIN;
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
