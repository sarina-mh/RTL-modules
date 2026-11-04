// Module: mux. Original group: combinational.
// Verilog-2005. Packed lane i occupies data[i*W +: W].
module mux #(parameter W=8, N=4, S=(N>1?$clog2(N):1)) (
    input [N*W-1:0] data, input [S-1:0] sel, output reg [W-1:0] y
);
    // Out-of-range selections produce zero, including non-power-of-two N.
    always @* begin y=0; if (sel<N) y=data[sel*W +: W]; end
endmodule
