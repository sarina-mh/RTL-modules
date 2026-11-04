// Copy one element per cycle into the reversed position.
module array_reverse #(parameter W=8,N=8)(input clk,rst_n,start,
    input [N*W-1:0] data_in,output reg [N*W-1:0] data_out,output reg busy,done);
    reg [N*W-1:0] data;integer p;
    always @(posedge clk)begin
        if(!rst_n)begin data<=0;data_out<=0;p<=0;busy<=0;done<=0;end
        else begin
            done<=0;
            if(start&&!busy)begin data<=data_in;p<=0;busy<=1;end
            else if(busy)begin
                data_out[(N-1-p)*W+:W]<=data[p*W+:W];
                if(p==N-1)begin busy<=0;done<=1;end else p<=p+1;
            end
        end
    end
endmodule
