// Module: demux. Original group: combinational.
module demux #(parameter W=8, N=4, S=(N>1?$clog2(N):1)) (
    input [W-1:0] data, input [S-1:0] sel, output reg [N*W-1:0] y
);
    always @* begin y=0; if (sel<N) y[sel*W +: W]=data; end
endmodule
