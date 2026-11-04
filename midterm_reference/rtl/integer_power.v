// Exponentiation by squaring, modulo 2**W. Defines a**0=1, including 0**0.
module integer_power #(parameter W=16,E=8)(input clk,rst_n,start,
    input [W-1:0] a,input [E-1:0] exponent,output reg [W-1:0] result,output reg busy,done);
    reg [W-1:0] base,total;reg [E-1:0] power_left;
    always @(posedge clk)begin
        if(!rst_n)begin result<=0;busy<=0;done<=0;base<=0;total<=0;power_left<=0;end
        else begin
            done<=0;
            if(start&&!busy)begin base<=a;total<=1;power_left<=exponent;busy<=1;end
            else if(busy)begin
                if(power_left==0)begin result<=total;busy<=0;done<=1;end
                else begin if(power_left[0])total<=total*base;base<=base*base;power_left<=power_left>>1;end
            end
        end
    end
endmodule
