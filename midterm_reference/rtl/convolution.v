// Full linear convolution y[t]=sum_k a[k]*b[t-k], length NA+NB-1.
// Unsigned or signed integer inputs, one valid MAC per cycle.
module convolution #(parameter W=8,NA=4,NB=3,SIGNED=0,AW=2*W+$clog2((NA<NB)?NA:NB))(
    input clk,rst_n,start,input [NA*W-1:0] a,input [NB*W-1:0] b,
    output reg [(NA+NB-1)*AW-1:0] result,output reg busy,done
);
    reg [NA*W-1:0] sa;reg [NB*W-1:0] sb;reg [AW-1:0] total;integer t,k;
    wire valid_pair=(t>=k && t-k<NB);
    wire [W-1:0] x=sa[k*W+:W],y=sb[((valid_pair)?t-k:0)*W+:W];
    wire [2*W-1:0] product;wire [AW-1:0] extended;
    generate if(SIGNED)begin : signed_math
        wire signed [AW-1:0] sign_extended;
        assign product=$signed(x)*$signed(y);assign sign_extended=$signed(product);
        assign extended=valid_pair?sign_extended:{AW{1'b0}};
    end else begin : unsigned_math
        assign product=x*y;assign extended=valid_pair?product:{AW{1'b0}};
    end endgenerate
    always @(posedge clk)begin
        if(!rst_n)begin sa<=0;sb<=0;result<=0;total<=0;t<=0;k<=0;busy<=0;done<=0;end
        else begin
            done<=0;
            if(start&&!busy)begin sa<=a;sb<=b;total<=0;t<=0;k<=0;busy<=1;end
            else if(busy)begin
                if(k==NA-1)begin
                    result[t*AW+:AW]<=total+extended;total<=0;k<=0;
                    if(t==NA+NB-2)begin busy<=0;done<=1;end else t<=t+1;
                end else begin total<=total+extended;k<=k+1;end
            end
        end
    end
endmodule
