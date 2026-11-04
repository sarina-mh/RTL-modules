// In-place max-heap sort, one sift-down comparison/swap per cycle.
module heap_sort #(parameter W=8,N=8,SIGNED=0)(
    input clk,rst_n,start,input [N*W-1:0] data_in,
    output reg [N*W-1:0] data_out,output reg busy,done
);
    reg [W-1:0] mem[0:N-1];integer build_root,root,size,child,k;
    reg building;reg [2:0] state;
    function greater;input [W-1:0] a,b;
        begin greater=SIGNED?($signed(a)>$signed(b)):(a>b);end
    endfunction
    always @*begin
        child=2*root+1;
        if(child+1<size)if(greater(mem[child+1],mem[child]))child=child+1;
    end
    always @(posedge clk)begin
        if(!rst_n)begin
            busy<=0;done<=0;data_out<=0;build_root<=0;root<=0;size<=0;building<=0;state<=0;
            for(k=0;k<N;k=k+1)mem[k]<=0;
        end else begin
            done<=0;
            if(start&&!busy)begin
                for(k=0;k<N;k=k+1)mem[k]<=data_in[k*W+:W];
                size<=N;build_root<=N/2-1;root<=N/2-1;building<=1;state<=(N==1?3:0);busy<=1;
            end else if(busy)case(state)
                0:begin
                    if(child<size && greater(mem[child],mem[root]))begin
                        mem[root]<=mem[child];mem[child]<=mem[root];root<=child;
                    end else state<=1;
                end
                1:if(building && build_root>0)begin build_root<=build_root-1;root<=build_root-1;state<=0;end
                  else begin building<=0;state<=2;end
                2:if(size<=1)state<=3;
                  else begin mem[0]<=mem[size-1];mem[size-1]<=mem[0];size<=size-1;root<=0;state<=0;end
                3:begin for(k=0;k<N;k=k+1)data_out[k*W+:W]<=mem[k];busy<=0;done<=1;end
                default:state<=0;
            endcase
        end
    end
endmodule
