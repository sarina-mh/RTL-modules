// Comb sort with a 1.3 shrink factor. Final gap=1 repeats until no swaps.
module comb_sort #(parameter W=8,N=8,SIGNED=0)(
    input clk,rst_n,start,input [N*W-1:0] data_in,
    output reg [N*W-1:0] data_out,output reg busy,done
);
    reg [W-1:0] mem[0:N-1];integer gap,p,k,new_gap;reg changed,finish;
    wire greater=SIGNED?($signed(mem[p])>$signed(mem[(p+gap<N)?p+gap:0])):(mem[p]>mem[(p+gap<N)?p+gap:0]);
    always @*begin new_gap=(gap*10)/13;if(new_gap<1)new_gap=1;end
    always @(posedge clk)begin
        if(!rst_n)begin busy<=0;done<=0;data_out<=0;gap<=1;p<=0;changed<=0;finish<=0;
            for(k=0;k<N;k=k+1)mem[k]<=0;
        end else begin
            done<=0;
            if(start&&!busy)begin
                for(k=0;k<N;k=k+1)mem[k]<=data_in[k*W+:W];
                gap<=((N*10)/13>0)?(N*10)/13:1;p<=0;changed<=0;finish<=(N==1);busy<=1;
            end else if(busy)begin
                if(finish)begin for(k=0;k<N;k=k+1)data_out[k*W+:W]<=mem[k];busy<=0;done<=1;end
                else begin
                    if(greater)begin mem[p]<=mem[p+gap];mem[p+gap]<=mem[p];changed<=1;end
                    if(p+gap==N-1)begin
                        if(gap==1 && !changed && !greater)finish<=1;
                        else begin gap<=new_gap;p<=0;changed<=0;end
                    end else p<=p+1;
                end
            end
        end
    end
endmodule
