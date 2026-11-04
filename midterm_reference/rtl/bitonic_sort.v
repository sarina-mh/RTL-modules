// Iterative bitonic comparator network schedule. N MUST be a power of two.
// One pair is visited per cycle; ascending output, signed/unsigned keys.
module bitonic_sort #(parameter W=8,N=8,SIGNED=0)(
    input clk,rst_n,start,input [N*W-1:0] data_in,
    output reg [N*W-1:0] data_out,output reg busy,done
);
    reg [W-1:0] mem[0:N-1];integer span,distance,p,peer,k;reg finish;
    wire greater=SIGNED?($signed(mem[p])>$signed(mem[peer])):(mem[p]>mem[peer]);
    wire less=SIGNED?($signed(mem[p])<$signed(mem[peer])):(mem[p]<mem[peer]);
    always @*peer=p^distance;
    always @(posedge clk)begin
        if(!rst_n)begin busy<=0;done<=0;data_out<=0;span<=2;distance<=1;p<=0;finish<=0;
            for(k=0;k<N;k=k+1)mem[k]<=0;
        end else begin
            done<=0;
            if(start&&!busy)begin
                for(k=0;k<N;k=k+1)mem[k]<=data_in[k*W+:W];
                span<=2;distance<=1;p<=0;finish<=(N==1);busy<=1;
            end else if(busy)begin
                if(finish)begin for(k=0;k<N;k=k+1)data_out[k*W+:W]<=mem[k];busy<=0;done<=1;end
                else begin
                    if(peer>p && peer<N)begin
                        if(((p&span)==0 && greater)||((p&span)!=0 && less))begin
                            mem[p]<=mem[peer];mem[peer]<=mem[p];
                        end
                    end
                    if(p==N-1)begin
                        p<=0;
                        if(distance>1)distance<=distance/2;
                        else if(span==N)finish<=1;
                        else begin span<=span*2;distance<=span;end
                    end else p<=p+1;
                end
            end
        end
    end
endmodule
