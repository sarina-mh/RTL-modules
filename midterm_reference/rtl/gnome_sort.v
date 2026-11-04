// Gnome sort: walk forward when ordered, swap/backtrack on inversion.
module gnome_sort #(parameter W=8,N=8,SIGNED=0)(
    input clk,rst_n,start,input [N*W-1:0] data_in,
    output reg [N*W-1:0] data_out,output reg busy,done
);
    reg [W-1:0] mem[0:N-1];integer p,k;
    wire ordered=SIGNED?($signed(mem[(p>0&&p<N)?p-1:0])<=$signed(mem[(p<N)?p:0])):
                                (mem[(p>0&&p<N)?p-1:0]<=mem[(p<N)?p:0]);
    always @(posedge clk)begin
        if(!rst_n)begin busy<=0;done<=0;data_out<=0;p<=0;for(k=0;k<N;k=k+1)mem[k]<=0;end
        else begin
            done<=0;
            if(start&&!busy)begin for(k=0;k<N;k=k+1)mem[k]<=data_in[k*W+:W];p<=1;busy<=1;end
            else if(busy)begin
                if(p>=N)begin for(k=0;k<N;k=k+1)data_out[k*W+:W]<=mem[k];busy<=0;done<=1;end
                else if(p==0 || ordered)p<=p+1;
                else begin mem[p-1]<=mem[p];mem[p]<=mem[p-1];p<=p-1;end
            end
        end
    end
endmodule
