// Unsigned n!; wraps modulo 2**W and reports any overflow. 0! = 1.
module factorial #(parameter W=32,B=8)(input clk,rst_n,start,input [B-1:0] n,
    output reg [W-1:0] result,output reg busy,done,overflow);
    reg [W-1:0] total;reg [B-1:0] limit;reg [B:0] p;
    wire [W+B:0] product=total*p;
    always @(posedge clk)begin
        if(!rst_n)begin result<=0;busy<=0;done<=0;overflow<=0;total<=1;limit<=0;p<=1;end
        else begin
            done<=0;
            if(start&&!busy)begin total<=1;limit<=n;p<=1;busy<=1;overflow<=0;end
            else if(busy)begin
                if(p>limit)begin result<=total;busy<=0;done<=1;end
                else begin total<=product[W-1:0];if(|product[W+B:W])overflow<=1;p<=p+1'b1;end
            end
        end
    end
endmodule
