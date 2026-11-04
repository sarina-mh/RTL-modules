// Floor(sqrt(x)) by trial bits, one candidate square per cycle.
module integer_sqrt #(parameter W=32)(input clk,rst_n,start,input [W-1:0] x,
    output reg [W-1:0] result,output reg busy,done);
    reg [W-1:0] value,root;integer bit_index;
    wire [W-1:0] candidate=root|({{(W-1){1'b0}},1'b1}<<bit_index);
    wire [2*W-1:0] square=candidate*candidate;
    always @(posedge clk)begin
        if(!rst_n)begin result<=0;busy<=0;done<=0;value<=0;root<=0;bit_index<=0;end
        else begin
            done<=0;
            if(start&&!busy)begin value<=x;root<=0;bit_index<=(W-1)/2;busy<=1;end
            else if(busy)begin
                if(square<=value)root<=candidate;
                if(bit_index==0)begin result<=(square<=value)?candidate:root;busy<=0;done<=1;end
                else bit_index<=bit_index-1;
            end
        end
    end
endmodule
