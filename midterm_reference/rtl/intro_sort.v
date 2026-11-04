// Introspective quicksort: Lomuto partitioning with a per-partition depth budget;
// switches to in-place heapsort when the budget is exhausted. No recursion.
// DEPTH=0 directly exercises the heap fallback. N-entry explicit range stack.
module intro_sort #(parameter W=8,N=8,SIGNED=0,DEPTH=2*$clog2(N))(
    input clk,rst_n,start,input [N*W-1:0] data_in,
    output reg [N*W-1:0] data_out,output reg busy,done
);
    reg [W-1:0] mem[0:N-1],pivot;
    integer slo[0:N-1],shi[0:N-1],sd[0:N-1];
    integer sp,lo,hi,depth,i,j,k,size,root,build_root,child;reg building;reg [3:0] state;
    function greater;input [W-1:0] a,b;
        begin greater=SIGNED?($signed(a)>$signed(b)):(a>b);end
    endfunction
    always @*begin
        child=2*root+1;
        if(child+1<size)if(greater(mem[lo+child+1],mem[lo+child]))child=child+1;
    end
    always @(posedge clk)begin
        if(!rst_n)begin
            busy<=0;done<=0;data_out<=0;pivot<=0;sp<=0;lo<=0;hi<=0;depth<=0;i<=0;j<=0;
            size<=0;root<=0;build_root<=0;building<=0;state<=0;
            for(k=0;k<N;k=k+1)begin mem[k]<=0;slo[k]<=0;shi[k]<=0;sd[k]<=0;end
        end else begin
            done<=0;
            if(start&&!busy)begin
                for(k=0;k<N;k=k+1)mem[k]<=data_in[k*W+:W];
                slo[0]<=0;shi[0]<=N-1;sd[0]<=DEPTH;sp<=1;state<=0;busy<=1;
            end else if(busy)case(state)
                0:if(sp==0)state<=4;
                  else begin lo<=slo[sp-1];hi<=shi[sp-1];depth<=sd[sp-1];sp<=sp-1;state<=1;end
                1:if(lo>=hi)state<=0;
                  else if(depth==0)state<=5;
                  else begin pivot<=mem[hi];i<=lo;j<=lo;state<=2;end
                2:if(j==hi)state<=3;
                  else begin
                      if(!greater(mem[j],pivot))begin mem[i]<=mem[j];mem[j]<=mem[i];i<=i+1;end
                      j<=j+1;
                  end
                3:begin
                    mem[i]<=mem[hi];mem[hi]<=mem[i];
                    if(lo<i-1 && i+1<hi)begin
                        slo[sp]<=lo;shi[sp]<=i-1;sd[sp]<=depth-1;
                        slo[sp+1]<=i+1;shi[sp+1]<=hi;sd[sp+1]<=depth-1;sp<=sp+2;
                    end else if(lo<i-1)begin slo[sp]<=lo;shi[sp]<=i-1;sd[sp]<=depth-1;sp<=sp+1;end
                    else if(i+1<hi)begin slo[sp]<=i+1;shi[sp]<=hi;sd[sp]<=depth-1;sp<=sp+1;end
                    state<=0;
                end
                4:begin for(k=0;k<N;k=k+1)data_out[k*W+:W]<=mem[k];busy<=0;done<=1;end
                5:begin
                    size<=hi-lo+1;root<=(hi-lo+1)/2-1;build_root<=(hi-lo+1)/2-1;building<=1;state<=6;
                end
                6:if(child<size && greater(mem[lo+child],mem[lo+root]))begin
                    mem[lo+root]<=mem[lo+child];mem[lo+child]<=mem[lo+root];root<=child;
                  end else state<=7;
                7:if(building&&build_root>0)begin root<=build_root-1;build_root<=build_root-1;state<=6;end
                  else begin building<=0;state<=8;end
                8:if(size<=1)state<=0;
                  else begin mem[lo]<=mem[lo+size-1];mem[lo+size-1]<=mem[lo];size<=size-1;root<=0;state<=6;end
                default:state<=0;
            endcase
        end
    end
endmodule
