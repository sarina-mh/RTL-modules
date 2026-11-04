// Educational fixed-run TimSort-style hybrid: insertion-sort RUN-sized chunks,
// then stably merge them bottom-up. This is NOT CPython's adaptive natural-run
// stack/galloping implementation. RUN>=1; one shift/merge/copy per cycle.
module tim_sort #(parameter W=8,N=8,SIGNED=0,RUN=4)(
    input clk,rst_n,start,input [N*W-1:0] data_in,
    output reg [N*W-1:0] data_out,output reg busy,done
);
    reg [W-1:0] mem[0:N-1],temp[0:N-1],key;
    integer run_start,run_end,i,j,width,left,middle,limit,p,k;reg [3:0] state;
    function greater;input [W-1:0] a,b;
        begin greater=SIGNED?($signed(a)>$signed(b)):(a>b);end
    endfunction
    always @(posedge clk)begin
        if(!rst_n)begin
            busy<=0;done<=0;data_out<=0;key<=0;run_start<=0;run_end<=0;i<=0;j<=0;
            width<=RUN;left<=0;middle<=0;limit<=0;p<=0;state<=0;
            for(k=0;k<N;k=k+1)begin mem[k]<=0;temp[k]<=0;end
        end else begin
            done<=0;
            if(start&&!busy)begin
                for(k=0;k<N;k=k+1)mem[k]<=data_in[k*W+:W];
                run_start<=0;run_end<=(RUN<N)?RUN:N;i<=1;width<=RUN;left<=0;state<=0;busy<=1;
            end else if(busy)case(state)
                0:if(i>=run_end)begin
                    if(run_end==N)begin if(RUN>=N)state<=7;else state<=3;end
                    else begin run_start<=run_end;run_end<=((run_end+RUN)<N)?run_end+RUN:N;i<=run_end+1;end
                  end else begin key<=mem[i];j<=i-1;state<=1;end
                1:if(j>=run_start && greater(mem[(j>=0)?j:0],key))begin mem[j+1]<=mem[j];j<=j-1;end
                  else begin mem[j+1]<=key;i<=i+1;state<=0;end
                3:begin
                    middle<=((left+width)<N)?left+width:N;limit<=((left+2*width)<N)?left+2*width:N;
                    i<=left;j<=((left+width)<N)?left+width:N;p<=left;state<=4;
                end
                4:if(p==limit)begin p<=left;state<=5;end
                  else begin
                    if(i<middle && (j>=limit || !greater(mem[(i<N)?i:0],mem[(j<N)?j:0])))begin temp[p]<=mem[i];i<=i+1;end
                    else begin temp[p]<=mem[j];j<=j+1;end
                    p<=p+1;
                  end
                5:begin mem[p]<=temp[p];if(p==limit-1)state<=6;else p<=p+1;end
                6:if(limit<N)begin left<=limit;state<=3;end
                  else if(2*width>=N)state<=7;
                  else begin width<=width*2;left<=0;state<=3;end
                7:begin for(k=0;k<N;k=k+1)data_out[k*W+:W]<=mem[k];busy<=0;done<=1;end
                default:state<=0;
            endcase
        end
    end
endmodule
