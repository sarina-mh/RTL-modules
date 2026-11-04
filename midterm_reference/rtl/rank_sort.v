// Stable enumeration/rank sort: count smaller keys plus earlier equal keys.
// N comparisons per item, then place it at its unique rank.
module rank_sort #(parameter W=8,N=8,SIGNED=0)(
    input clk,rst_n,start,input [N*W-1:0] data_in,
    output reg [N*W-1:0] data_out,output reg busy,done
);
    reg [N*W-1:0] data;integer i,j,rank_value,k;reg placing,finish;
    wire [W-1:0] a=data[j*W+:W],b=data[i*W+:W];
    wire smaller=SIGNED?($signed(a)<$signed(b)):(a<b);
    always @(posedge clk)begin
        if(!rst_n)begin busy<=0;done<=0;data_out<=0;data<=0;i<=0;j<=0;rank_value<=0;placing<=0;finish<=0;end
        else begin
            done<=0;
            if(start&&!busy)begin data<=data_in;i<=0;j<=0;rank_value<=0;placing<=0;finish<=0;busy<=1;end
            else if(busy)begin
                if(finish)begin busy<=0;done<=1;end
                else if(placing)begin
                    data_out[rank_value*W+:W]<=b;
                    if(i==N-1)finish<=1;else begin i<=i+1;j<=0;rank_value<=0;placing<=0;end
                end else begin
                    if(smaller || (a==b && j<i))rank_value<=rank_value+1;
                    if(j==N-1)placing<=1;else j<=j+1;
                end
            end
        end
    end
endmodule
