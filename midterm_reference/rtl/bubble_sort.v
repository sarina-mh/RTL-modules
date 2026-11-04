// Module: bubble_sort. Original group: algorithms.
// Bubble sort: one adjacent comparison per cycle; early exit after a clean pass.
module bubble_sort #(parameter W=8,N=8,SIGNED=0)(
    input clk,rst_n,start, input [N*W-1:0] data_in,
    output reg [N*W-1:0] data_out, output reg busy,done
);
    reg [W-1:0] mem[0:N-1]; integer j,limit,k; reg changed,finish;
    wire greater=SIGNED ? ($signed(mem[j])>$signed(mem[j+1])) : (mem[j]>mem[j+1]);
    always @(posedge clk) begin
        if(!rst_n) begin busy<=0;done<=0;data_out<=0;j<=0;limit<=0;changed<=0;finish<=0;
            for(k=0;k<N;k=k+1) mem[k]<=0;
        end else begin
            done<=0;
            if(start&&!busy) begin
                for(k=0;k<N;k=k+1) mem[k]<=data_in[k*W +: W];
                busy<=1; j<=0; limit<=N-1; changed<=0; finish<=(N==1);
            end else if(busy) begin
                if(finish) begin
                    for(k=0;k<N;k=k+1) data_out[k*W +: W]<=mem[k];
                    busy<=0;done<=1;
                end else begin
                    if(greater) begin mem[j]<=mem[j+1];mem[j+1]<=mem[j];changed<=1;end
                    if(j==limit-1) begin
                        if(limit==1 || (!changed&&!greater)) finish<=1;
                        else begin limit<=limit-1;j<=0;changed<=0;end
                    end else j<=j+1;
                end
            end
        end
    end
endmodule
