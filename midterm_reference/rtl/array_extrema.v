// Module: array_extrema. Original group: algorithms.
// Combinational min/max/argmax. Ties retain the first (lowest-index) element.
module array_extrema #(parameter W=8,N=8,SIGNED=0,I=(N>1?$clog2(N):1)) (
    input [N*W-1:0] data,output reg [W-1:0] minimum,maximum,output reg [I-1:0] argmax
);
    integer k;reg [W-1:0] v;
    always @* begin
        minimum=data[0 +: W];maximum=data[0 +: W];argmax=0;v=0;
        for(k=1;k<N;k=k+1) begin
            v=data[k*W +: W];
            if(SIGNED ? ($signed(v)<$signed(minimum)) : (v<minimum)) minimum=v;
            if(SIGNED ? ($signed(v)>$signed(maximum)) : (v>maximum)) begin maximum=v;argmax=k;end
        end
    end
endmodule
