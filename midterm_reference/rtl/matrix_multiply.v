// Row-major A[R,K] times B[K,C]. One multiply-accumulate per clock.
// Signed/unsigned full-precision output by default; lane (r*C+c) is result[r,c].
module matrix_multiply #(parameter W=8,R=2,K=3,C=2,SIGNED=0,AW=2*W+$clog2(K))(
    input clk,rst_n,start,input [R*K*W-1:0] a,input [K*C*W-1:0] b,
    output reg [R*C*AW-1:0] result,output reg busy,done
);
    reg [R*K*W-1:0] sa;reg [K*C*W-1:0] sb;
    integer row,col,term;reg [AW-1:0] total;
    wire [W-1:0] x=sa[(row*K+term)*W+:W],y=sb[(term*C+col)*W+:W];
    wire [2*W-1:0] product;wire [AW-1:0] extended;
    generate if(SIGNED)begin : signed_math
        assign product=$signed(x)*$signed(y);assign extended=$signed(product);
    end else begin : unsigned_math
        assign product=x*y;assign extended=product;
    end endgenerate
    always @(posedge clk)begin
        if(!rst_n)begin sa<=0;sb<=0;result<=0;total<=0;row<=0;col<=0;term<=0;busy<=0;done<=0;end
        else begin
            done<=0;
            if(start&&!busy)begin sa<=a;sb<=b;row<=0;col<=0;term<=0;total<=0;busy<=1;end
            else if(busy)begin
                if(term==K-1)begin
                    result[(row*C+col)*AW+:AW]<=total+extended;total<=0;term<=0;
                    if(col==C-1)begin col<=0;if(row==R-1)begin busy<=0;done<=1;end else row<=row+1;end
                    else col<=col+1;
                end else begin total<=total+extended;term<=term+1;end
            end
        end
    end
endmodule
