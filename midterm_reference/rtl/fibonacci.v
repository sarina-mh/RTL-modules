// F(0)=0,F(1)=1. Unsigned result wraps modulo 2**W; overflow is sticky.
module fibonacci #(parameter W=32,B=8)(input clk,rst_n,start,input [B-1:0] n,
    output reg [W-1:0] result,output reg busy,done,overflow);
    reg [W-1:0] a,b;reg [B-1:0] limit,p;
    wire [W:0] sum={1'b0,a}+{1'b0,b};
    always @(posedge clk)begin
        if(!rst_n)begin result<=0;busy<=0;done<=0;overflow<=0;a<=0;b<=1;limit<=0;p<=0;end
        else begin
            done<=0;
            if(start&&!busy)begin a<=0;b<=1;limit<=n;p<=0;busy<=1;overflow<=0;end
            else if(busy)begin
                if(p==limit)begin result<=a;busy<=0;done<=1;end
                else begin
                    a<=b;b<=sum[W-1:0];p<=p+1'b1;
                    // b after this edge is F(p+2), one ahead of the result.
                    if(sum[W] && p+1<limit)overflow<=1;
                end
            end
        end
    end
endmodule
