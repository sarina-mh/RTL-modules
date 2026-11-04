// Module: dff. Original group: sequential.
// All sequential blocks use synchronous active-low reset.
module dff #(parameter W=1)(input clk,rst_n, input [W-1:0] d, output reg [W-1:0] q);
    always @(posedge clk) if(!rst_n) q<=0; else q<=d;
endmodule
