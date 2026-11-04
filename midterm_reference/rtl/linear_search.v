// Sequential linear search; first match wins. index=0 when not found.
module linear_search #(parameter W=8,N=8,I=(N>1?$clog2(N):1))(
    input clk,rst_n,start,input [N*W-1:0] data_in,input [W-1:0] target,
    output reg found,output reg [I-1:0] index,output reg busy,done
);
    reg [N*W-1:0] data;reg [W-1:0] key;integer p;
    always @(posedge clk)begin
        if(!rst_n)begin found<=0;index<=0;busy<=0;done<=0;data<=0;key<=0;p<=0;end
        else begin
            done<=0;
            if(start&&!busy)begin data<=data_in;key<=target;p<=0;busy<=1;end
            else if(busy)begin
                if(data[p*W+:W]==key)begin found<=1;index<=p;busy<=0;done<=1;end
                else if(p==N-1)begin found<=0;index<=0;busy<=0;done<=1;end
                else p<=p+1;
            end
        end
    end
endmodule
