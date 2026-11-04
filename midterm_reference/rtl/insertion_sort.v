// Module: insertion_sort. Original group: algorithms.
// Insertion sort: load a key, shift one predecessor per cycle, then insert.
module insertion_sort #(parameter W=8,N=8,SIGNED=0)(
    input clk,rst_n,start, input [N*W-1:0] data_in,
    output reg [N*W-1:0] data_out, output reg busy,done
);
    reg [W-1:0] mem[0:N-1],key; integer i,j,k; reg [1:0] phase;
    wire greater=SIGNED ? ($signed(mem[j])>$signed(key)) : (mem[j]>key);
    always @(posedge clk) begin
        if(!rst_n) begin busy<=0;done<=0;data_out<=0;i<=0;j<=0;key<=0;phase<=0;
            for(k=0;k<N;k=k+1) mem[k]<=0;
        end else begin
            done<=0;
            if(start&&!busy) begin
                for(k=0;k<N;k=k+1) mem[k]<=data_in[k*W +: W];
                busy<=1;i<=1;phase<=(N==1?2:0);
            end else if(busy) case(phase)
                0: begin key<=mem[i];j<=i-1;phase<=1;end
                1: begin
                    if(j>=0 && greater) begin mem[j+1]<=mem[j];j<=j-1;end
                    else begin
                        mem[j+1]<=key;
                        if(i==N-1) phase<=2; else begin i<=i+1;phase<=0;end
                    end
                end
                2: begin
                    for(k=0;k<N;k=k+1) data_out[k*W +: W]<=mem[k];
                    busy<=0;done<=1;
                end
                default: phase<=0;
            endcase
        end
    end
endmodule
