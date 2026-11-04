// Shell sort using halving gaps and gapped insertion, one shift per cycle.
module shell_sort #(parameter W=8,N=8,SIGNED=0)(
    input clk,rst_n,start,input [N*W-1:0] data_in,
    output reg [N*W-1:0] data_out,output reg busy,done
);
    reg [W-1:0] mem[0:N-1],key;integer gap,i,j,k;reg [1:0] state;
    wire greater=SIGNED?($signed(mem[(j>=gap)?j-gap:0])>$signed(key)):(mem[(j>=gap)?j-gap:0]>key);
    always @(posedge clk)begin
        if(!rst_n)begin busy<=0;done<=0;data_out<=0;gap<=0;i<=0;j<=0;key<=0;state<=0;
            for(k=0;k<N;k=k+1)mem[k]<=0;
        end else begin
            done<=0;
            if(start&&!busy)begin
                for(k=0;k<N;k=k+1)mem[k]<=data_in[k*W+:W];
                gap<=N/2;i<=N/2;state<=(N==1?3:0);busy<=1;
            end else if(busy)case(state)
                0:begin key<=mem[i];j<=i;state<=1;end
                1:if(j>=gap && greater)begin mem[j]<=mem[j-gap];j<=j-gap;end
                  else begin mem[j]<=key;state<=2;end
                2:if(i+1<N)begin i<=i+1;state<=0;end
                  else if(gap>1)begin gap<=gap/2;i<=gap/2;state<=0;end
                  else state<=3;
                3:begin for(k=0;k<N;k=k+1)data_out[k*W+:W]<=mem[k];busy<=0;done<=1;end
                default:state<=0;
            endcase
        end
    end
endmodule
