// ============================================================================
// Module: array_max_min  (Array maximum/minimum finder)
// ----------------------------------------------------------------------------
// Description:
//   Finds the maximum and minimum elements of an array of N unsigned values.
//   The input array is scanned directly from data_in, one element per clock
//   cycle. The first element initializes both max_val and min_val.
//
//   Handshake:
//     - Pulse start for at least one clock while busy is low.
//     - busy goes high during the scan and low again when finished.
//     - done is a one-cycle pulse when max_val and min_val are valid.
//
// Parameters:
//   N     : Number of elements in the array (default 8)
//   WIDTH : Bit width of each element (default 8)
//
// Inputs:
//   clk      : Clock
//   rst      : Asynchronous reset, active high
//   start    : Start searching (pulse)
//   data_in  : Flattened input array, N*WIDTH bits
//              (element k = data_in[k*WIDTH +: WIDTH])
//
// Outputs:
//   max_val : Largest element found
//   min_val : Smallest element found
//   done    : One-cycle completion pulse
//   busy    : High while scanning
// ============================================================================
module array_max_min #(
    parameter N     = 8,
    parameter WIDTH = 8
)(
    input  wire               clk,
    input  wire               rst,
    input  wire               start,
    input  wire [N*WIDTH-1:0] data_in,
    output reg  [WIDTH-1:0]   max_val,
    output reg  [WIDTH-1:0]   min_val,
    output reg                done,
    output reg                busy
);

    localparam IDLE = 2'd0;
    localparam SCAN = 2'd1;
    localparam FIN  = 2'd2;

    reg [1:0] state;
    integer k;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state   <= IDLE;
            done    <= 1'b0;
            busy    <= 1'b0;
            max_val <= {WIDTH{1'b0}};
            min_val <= {WIDTH{1'b0}};
            k       <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    busy <= 1'b0;
                    if (start) begin
                        // Initialize both with the first element.
                        max_val <= data_in[0 +: WIDTH];
                        min_val <= data_in[0 +: WIDTH];
                        k       <= 1;
                        if (N <= 1) begin
                            state <= FIN;
                        end else begin
                            busy  <= 1'b1;
                            state <= SCAN;
                        end
                    end
                end

                // Compare one element per cycle.
                SCAN: begin
                    if (k < N) begin
                        if (data_in[k*WIDTH +: WIDTH] > max_val)
                            max_val <= data_in[k*WIDTH +: WIDTH];

                        if (data_in[k*WIDTH +: WIDTH] < min_val)
                            min_val <= data_in[k*WIDTH +: WIDTH];

                        k <= k + 1;
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
