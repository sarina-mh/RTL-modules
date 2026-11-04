// Module: gcd. Original group: algorithms.
// Euclidean subtraction GCD: one subtraction per cycle, no divider inferred.
module gcd #(parameter W=16)(input clk,rst_n,start,input [W-1:0] a,b,
    output reg [W-1:0] result,output reg busy,done);
    reg [W-1:0] x,y;
    always @(posedge clk)
        if(!rst_n) begin x<=0;y<=0;result<=0;busy<=0;done<=0;end
        else begin
            done<=0;
            if(start&&!busy) begin x<=a;y<=b;busy<=1;end
            else if(busy) begin
                if(x==0 || y==0 || x==y) begin
                    result<=(x==0)?y:x;busy<=0;done<=1;
                end else if(x>y) x<=x-y; else y<=y-x;
            end
        end
endmodule
