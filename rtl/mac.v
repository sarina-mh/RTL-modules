// Module: mac. Original group: sequential.
// Product is full precision; accumulation wraps at AW bits.
module mac #(parameter W=8, AW=2*W+4, SIGNED=0)(input clk,rst_n,clear,en,
    input [W-1:0] a,b, output reg [AW-1:0] sum);
    wire [2*W-1:0] product;
    generate if(SIGNED) begin : signed_product
        wire signed [W-1:0] sa=a,sb=b;
        assign product=sa*sb;
    end else begin : unsigned_product
        assign product=a*b;
    end endgenerate
    always @(posedge clk)
        if(!rst_n) sum<=0; else if(clear) sum<=0;
        else if(en) begin
            if(SIGNED) sum<=$signed(sum)+$signed(product); else sum<=sum+product;
        end
endmodule
