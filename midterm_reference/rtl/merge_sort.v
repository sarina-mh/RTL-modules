// Stable bottom-up merge sort. One merge output or copy-back per cycle.
module merge_sort #(parameter W=8,N=8,SIGNED=0)(
    input clk,rst_n,start,input [N*W-1:0] data_in,
    output reg [N*W-1:0] data_out,output reg busy,done
);
    reg [W-1:0] mem[0:N-1],temp[0:N-1];
    integer width,left,middle,limit,i,j,p,k;reg [2:0] state;
    wire le=SIGNED?($signed(mem[i])<=$signed(mem[j])):(mem[i]<=mem[j]);
    always @(posedge clk) begin
        if(!rst_n)begin
            busy<=0;done<=0;data_out<=0;width<=1;left<=0;middle<=0;limit<=0;i<=0;j<=0;p<=0;state<=0;
            for(k=0;k<N;k=k+1)begin mem[k]<=0;temp[k]<=0;end
        end else begin
            done<=0;
            if(start&&!busy)begin
                for(k=0;k<N;k=k+1)mem[k]<=data_in[k*W+:W];
                width<=1;left<=0;state<=(N==1?4:0);busy<=1;
            end else if(busy)case(state)
                0:begin
                    middle<=((left+width)<N)?left+width:N;
                    limit<=((left+2*width)<N)?left+2*width:N;
                    i<=left;j<=((left+width)<N)?left+width:N;p<=left;state<=1;
                end
                1:begin
                    if(p==limit)begin p<=left;state<=2;end
                    else begin
                        if(i<middle && (j>=limit || le))begin temp[p]<=mem[i];i<=i+1;end
                        else begin temp[p]<=mem[j];j<=j+1;end
                        p<=p+1;
                    end
                end
                2:begin
                    mem[p]<=temp[p];
                    if(p==limit-1)state<=3;else p<=p+1;
                end
                3:if(limit<N)begin left<=limit;state<=0;end
                  else if(2*width>=N)state<=4;
                  else begin width<=width*2;left<=0;state<=0;end
                4:begin for(k=0;k<N;k=k+1)data_out[k*W+:W]<=mem[k];busy<=0;done<=1;end
                default:state<=0;
            endcase
        end
    end
endmodule
