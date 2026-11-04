// Integer polynomial c[0] + c[1]*x + ... + c[N-1]*x**(N-1).
// Horner evaluation, one coefficient per cycle. Arithmetic wraps modulo 2**W.
module polynomial_horner #(parameter W=16,N=4)(input clk,rst_n,start,
    input [W-1:0] x,input [N*W-1:0] coefficients,
    output reg [W-1:0] result,output reg busy,done);
    reg [W-1:0] saved_x,total;reg [N*W-1:0] coeff;integer p;
    always @(posedge clk)begin
        if(!rst_n)begin result<=0;busy<=0;done<=0;saved_x<=0;total<=0;coeff<=0;p<=0;end
        else begin
            done<=0;
            if(start&&!busy)begin saved_x<=x;coeff<=coefficients;p<=N-1;total<=0;busy<=1;end
            else if(busy)begin
                total<=total*saved_x+coeff[p*W+:W];
                if(p==0)begin result<=total*saved_x+coeff[p*W+:W];busy<=0;done<=1;end else p<=p-1;
            end
        end
    end
endmodule
