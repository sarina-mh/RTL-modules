// Odd-even transposition sort; N alternating even/odd adjacent passes.
module odd_even_sort #(parameter W=8,N=8,SIGNED=0)(
    input clk,rst_n,start,input [N*W-1:0] data_in,
    output reg [N*W-1:0] data_out,output reg busy,done
);
    reg [W-1:0] mem[0:N-1];integer pass,p,k;reg finish;
    wire greater=SIGNED?($signed(mem[(p<N)?p:0])>$signed(mem[(p+1<N)?p+1:0])):
                                (mem[(p<N)?p:0]>mem[(p+1<N)?p+1:0]);
    always @(posedge clk)begin
        if(!rst_n)begin busy<=0;done<=0;data_out<=0;pass<=0;p<=0;finish<=0;for(k=0;k<N;k=k+1)mem[k]<=0;end
        else begin
            done<=0;
            if(start&&!busy)begin
                for(k=0;k<N;k=k+1)mem[k]<=data_in[k*W+:W];
                pass<=0;p<=0;finish<=(N==1);busy<=1;
            end else if(busy)begin
                if(finish)begin for(k=0;k<N;k=k+1)data_out[k*W+:W]<=mem[k];busy<=0;done<=1;end
                else if(p+1>=N)begin
                    if(pass==N-1)finish<=1;else begin pass<=pass+1;p<=1-(pass%2);end
                end else begin
                    if(greater)begin mem[p]<=mem[p+1];mem[p+1]<=mem[p];end p<=p+2;
                end
            end
        end
    end
endmodule
