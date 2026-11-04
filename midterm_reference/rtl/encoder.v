// Module: encoder. Original group: combinational.
// One-hot encoder: valid requires exactly one asserted bit.
module encoder #(parameter N=8, S=(N>1?$clog2(N):1)) (
    input [N-1:0] x, output reg valid, output reg [S-1:0] index
);
    integer i, count;
    always @* begin
        index=0; count=0;
        for(i=0;i<N;i=i+1) if(x[i]) begin index=i; count=count+1; end
        valid=(count==1); if(!valid) index=0;
    end
endmodule
