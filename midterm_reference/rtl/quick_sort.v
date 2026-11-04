// Iterative Lomuto quicksort. Explicit N-entry stack replaces recursion.
// Ascending order; W,N >= 1. start is accepted only while !busy.
module quick_sort #(parameter W=8,N=8,SIGNED=0)(
    input clk,rst_n,start,input [N*W-1:0] data_in,
    output reg [N*W-1:0] data_out,output reg busy,done
);
    reg [W-1:0] mem[0:N-1],pivot;
    integer stack_lo[0:N-1],stack_hi[0:N-1];
    integer sp,lo,hi,i,j,k;reg [2:0] state;
    wire le=SIGNED?($signed(mem[j])<=$signed(pivot)):(mem[j]<=pivot);
    always @(posedge clk) begin
        if(!rst_n) begin
            busy<=0;done<=0;data_out<=0;sp<=0;lo<=0;hi<=0;i<=0;j<=0;pivot<=0;state<=0;
            for(k=0;k<N;k=k+1)begin mem[k]<=0;stack_lo[k]<=0;stack_hi[k]<=0;end
        end else begin
            done<=0;
            if(start&&!busy)begin
                for(k=0;k<N;k=k+1)mem[k]<=data_in[k*W+:W];
                stack_lo[0]<=0;stack_hi[0]<=N-1;sp<=1;busy<=1;state<=0;
            end else if(busy)case(state)
                0:if(sp==0)state<=4;
                  else begin lo<=stack_lo[sp-1];hi<=stack_hi[sp-1];sp<=sp-1;state<=1;end
                1:if(lo>=hi)state<=0;
                  else begin pivot<=mem[hi];i<=lo;j<=lo;state<=2;end
                2:if(j==hi)state<=3;
                  else begin
                      if(le)begin mem[i]<=mem[j];mem[j]<=mem[i];i<=i+1;end
                      j<=j+1;
                  end
                3:begin
                    mem[i]<=mem[hi];mem[hi]<=mem[i];
                    // The two partitions are disjoint and exclude the pivot.
                    if(lo<i-1 && i+1<hi)begin
                        stack_lo[sp]<=lo;stack_hi[sp]<=i-1;
                        stack_lo[sp+1]<=i+1;stack_hi[sp+1]<=hi;sp<=sp+2;
                    end else if(lo<i-1)begin stack_lo[sp]<=lo;stack_hi[sp]<=i-1;sp<=sp+1;end
                    else if(i+1<hi)begin stack_lo[sp]<=i+1;stack_hi[sp]<=hi;sp<=sp+1;end
                    state<=0;
                end
                4:begin
                    for(k=0;k<N;k=k+1)data_out[k*W+:W]<=mem[k];
                    busy<=0;done<=1;
                end
                default:state<=0;
            endcase
        end
    end
endmodule
