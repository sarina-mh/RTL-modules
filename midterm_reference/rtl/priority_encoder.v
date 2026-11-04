// Module: priority_encoder. Original group: combinational.
module priority_encoder #(parameter N=8, S=(N>1?$clog2(N):1)) (
    input [N-1:0] x, output reg valid, output reg [S-1:0] index
);
    integer i;
    always @* begin
        valid=0; index=0;
        // Later assignments give the highest index priority.
        for(i=0;i<N;i=i+1) if(x[i]) begin valid=1; index=i; end
    end
endmodule
