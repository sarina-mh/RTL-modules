// Module: decoder. Original group: combinational.
module decoder #(parameter A=3)(input [A-1:0] address, input enable, output reg [(1<<A)-1:0] y);
    always @* begin y=0; if (enable) y[address]=1'b1; end
endmodule
