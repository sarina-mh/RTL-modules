// Counting sort for SMALL integer keys (1 <= W <= 10 recommended).
// Histogram storage grows as 2**W. Signed order uses sign-bit biased keys.
module counting_sort #(parameter W=4,N=8,SIGNED=0)(
    input clk,rst_n,start,input [N*W-1:0] data_in,
    output reg [N*W-1:0] data_out,output reg busy,done
);
    localparam RANGE=(1<<W);
    reg [N*W-1:0] data;integer histogram[0:RANGE-1];integer p,key,out_index,k;reg [1:0] state;
    wire [W-1:0] bias=SIGNED?(1<<(W-1)):0;
    wire [W-1:0] current=data[p*W+:W]^bias;
    always @(posedge clk)begin
        if(!rst_n)begin busy<=0;done<=0;data_out<=0;data<=0;p<=0;key<=0;out_index<=0;state<=0;end
        else begin
            done<=0;
            if(start&&!busy)begin data<=data_in;p<=0;key<=0;out_index<=0;busy<=1;state<=0;end
            else if(busy)case(state)
                0:begin histogram[key]<=0;if(key==RANGE-1)begin key<=0;state<=1;end else key<=key+1;end
                1:begin histogram[current]<=histogram[current]+1;
                    if(p==N-1)state<=2;else p<=p+1;
                end
                2:if(histogram[key]>0)begin
                    data_out[out_index*W+:W]<=key^bias;histogram[key]<=histogram[key]-1;out_index<=out_index+1;
                    if(out_index==N-1)state<=3;
                end else key<=key+1;
                3:begin busy<=0;done<=1;end
            endcase
        end
    end
endmodule
