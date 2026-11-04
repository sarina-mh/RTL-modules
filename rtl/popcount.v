// Module: popcount. Original group: combinational.
module popcount #(parameter W=8, C=$clog2(W+1))(input [W-1:0] x, output reg [C-1:0] count);
    integer i;
    always @* begin count=0; for(i=0;i<W;i=i+1) count=count+x[i]; end
endmodule
