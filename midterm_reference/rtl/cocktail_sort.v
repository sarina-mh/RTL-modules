// Bidirectional bubble (cocktail shaker) sort, one adjacent pair per cycle.
module cocktail_sort #(parameter W=8,N=8,SIGNED=0)(
    input clk,rst_n,start,input [N*W-1:0] data_in,
    output reg [N*W-1:0] data_out,output reg busy,done
);
    reg [W-1:0] mem[0:N-1];integer low,high,p,k;reg reverse,finish;
    wire greater=SIGNED?($signed(mem[p])>$signed(mem[(p+1<N)?p+1:0])):(mem[p]>mem[(p+1<N)?p+1:0]);
    always @(posedge clk)begin
        if(!rst_n)begin busy<=0;done<=0;data_out<=0;low<=0;high<=0;p<=0;reverse<=0;finish<=0;
            for(k=0;k<N;k=k+1)mem[k]<=0;
        end else begin
            done<=0;
            if(start&&!busy)begin
                for(k=0;k<N;k=k+1)mem[k]<=data_in[k*W+:W];
                low<=0;high<=N-1;p<=0;reverse<=0;finish<=(N==1);busy<=1;
            end else if(busy)begin
                if(finish)begin for(k=0;k<N;k=k+1)data_out[k*W+:W]<=mem[k];busy<=0;done<=1;end
                else begin
                    if(greater)begin mem[p]<=mem[p+1];mem[p+1]<=mem[p];end
                    if(!reverse)begin
                        if(p==high-1)begin
                            high<=high-1;reverse<=1;p<=high-2;
                            if(high-1<=low)finish<=1;
                        end else p<=p+1;
                    end else if(p==low)begin
                        low<=low+1;reverse<=0;p<=low+1;
                        if(low+1>=high)finish<=1;
                    end else p<=p-1;
                end
            end
        end
    end
endmodule
