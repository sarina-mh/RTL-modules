// Lower-bound binary search on an ASCENDING sorted array; first match wins.
module binary_search #(parameter W=8,N=8,SIGNED=0,I=(N>1?$clog2(N):1))(
    input clk,rst_n,start,input [N*W-1:0] data_in,input [W-1:0] target,
    output reg found,output reg [I-1:0] index,output reg busy,done
);
    reg [N*W-1:0] data;reg [W-1:0] key;integer low,high,middle;
    wire [W-1:0] current=data[((middle<N)?middle:0)*W+:W];
    wire less=SIGNED?($signed(current)<$signed(key)):(current<key);
    always @*middle=(low+high)/2;
    always @(posedge clk)begin
        if(!rst_n)begin found<=0;index<=0;busy<=0;done<=0;data<=0;key<=0;low<=0;high<=0;end
        else begin
            done<=0;
            if(start&&!busy)begin data<=data_in;key<=target;low<=0;high<=N;busy<=1;end
            else if(busy)begin
                if(low==high)begin
                    found<=(low<N && current==key);index<=(low<N && current==key)?low:0;busy<=0;done<=1;
                end else if(less)low<=middle+1;else high<=middle;
            end
        end
    end
endmodule
