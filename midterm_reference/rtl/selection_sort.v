// Module: selection_sort. Original group: algorithms.
// All algorithms accept start only while idle. done pulses for one cycle.
// Packed array element 0 occupies the least-significant W bits.
// Selection sort: one comparison per cycle, then one swap cycle.
module selection_sort #(parameter W=8,N=8,SIGNED=0)(
    input clk,rst_n,start, input [N*W-1:0] data_in,
    output reg [N*W-1:0] data_out, output reg busy,done
);
    reg [W-1:0] mem[0:N-1]; integer i,j,minimum,k;
    reg swapping;
    wire less=SIGNED ? ($signed(mem[j])<$signed(mem[minimum])) : (mem[j]<mem[minimum]);
    always @(posedge clk) begin
        if(!rst_n) begin
            busy<=0; done<=0; data_out<=0; i<=0; j<=0; minimum<=0; swapping<=0;
            for(k=0;k<N;k=k+1) mem[k]<=0;
        end else begin
            done<=0;
            if(start && !busy) begin
                for(k=0;k<N;k=k+1) mem[k]<=data_in[k*W +: W];
                i<=0; j<=(N>1?1:0); minimum<=0; swapping<=(N==1); busy<=1;
            end else if(busy) begin
                if(!swapping) begin
                    if(less) minimum<=j;
                    if(j==N-1) swapping<=1; else j<=j+1;
                end else begin
                    // Nonblocking assignments implement a simultaneous swap.
                    mem[i]<=mem[minimum]; mem[minimum]<=mem[i];
                    if(i>=N-2) begin
                        for(k=0;k<N;k=k+1) begin
                            if(k==i) data_out[k*W +: W]<=mem[minimum];
                            else if(k==minimum) data_out[k*W +: W]<=mem[i];
                            else data_out[k*W +: W]<=mem[k];
                        end
                        busy<=0; done<=1;
                    end else begin i<=i+1; j<=i+2; minimum<=i+1; swapping<=0; end
                end
            end
        end
    end
endmodule
