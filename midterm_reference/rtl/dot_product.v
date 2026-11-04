// Sequential dot product. AW>=2*W+ceil(log2(N)) retains full precision.
module dot_product #(parameter W=8,N=8,SIGNED=0,AW=2*W+$clog2(N))(
    input clk,rst_n,start,input [N*W-1:0] a,b,
    output reg [AW-1:0] result,output reg busy,done
);
    reg [N*W-1:0] sa,sb;reg [AW-1:0] total;integer p;
    wire [W-1:0] x=sa[p*W+:W],y=sb[p*W+:W];wire [2*W-1:0] product;
    wire [AW-1:0] extended;
    generate if(SIGNED)begin : signed_math
        assign product=$signed(x)*$signed(y);assign extended=$signed(product);
    end else begin : unsigned_math
        assign product=x*y;assign extended=product;
    end endgenerate
    always @(posedge clk)begin
        if(!rst_n)begin sa<=0;sb<=0;total<=0;result<=0;p<=0;busy<=0;done<=0;end
        else begin
            done<=0;
            if(start&&!busy)begin sa<=a;sb<=b;total<=0;p<=0;busy<=1;end
            else if(busy)begin
                total<=total+extended;
                if(p==N-1)begin result<=total+extended;busy<=0;done<=1;end else p<=p+1;
            end
        end
    end
endmodule
