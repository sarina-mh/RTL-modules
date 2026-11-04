// Module: shift_add_multiplier. Original group: algorithms.
module shift_add_multiplier #(parameter W=8)(input clk,rst_n,start,input [W-1:0] a,b,
    output reg [2*W-1:0] product,output reg busy,done);
    reg [2*W-1:0] acc,multiplicand;reg [W-1:0] multiplier;integer bits_left;
    always @(posedge clk)
        if(!rst_n) begin acc<=0;multiplicand<=0;multiplier<=0;product<=0;busy<=0;done<=0;bits_left<=0;end
        else begin
            done<=0;
            if(start&&!busy) begin
                acc<=0;multiplicand<=a;multiplier<=b;bits_left<=W;busy<=1;
            end else if(busy) begin
                if(multiplier[0]) acc<=acc+multiplicand;
                multiplicand<=multiplicand<<1;multiplier<=multiplier>>1;bits_left<=bits_left-1;
                if(bits_left==1) begin
                    product<=acc+(multiplier[0]?multiplicand:{(2*W){1'b0}});busy<=0;done<=1;
                end
            end
        end
endmodule
