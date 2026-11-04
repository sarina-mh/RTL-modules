// Stable binary LSD radix sort. Each pass scatters zeros then ones.
// No exponential histogram; signed ordering flips the sign bit in the last pass.
module radix_sort #(parameter W=8,N=8,SIGNED=0)(
    input clk,rst_n,start,input [N*W-1:0] data_in,
    output reg [N*W-1:0] data_out,output reg busy,done
);
    reg [W-1:0] mem[0:N-1],temp[0:N-1];integer bit_index,p,out_index,k;reg [2:0] state;
    wire digit=mem[p][bit_index]^(SIGNED && bit_index==W-1);
    always @(posedge clk)begin
        if(!rst_n)begin busy<=0;done<=0;data_out<=0;bit_index<=0;p<=0;out_index<=0;state<=0;
            for(k=0;k<N;k=k+1)begin mem[k]<=0;temp[k]<=0;end
        end else begin
            done<=0;
            if(start&&!busy)begin
                for(k=0;k<N;k=k+1)mem[k]<=data_in[k*W+:W];
                bit_index<=0;p<=0;out_index<=0;state<=0;busy<=1;
            end else if(busy)case(state)
                0:begin
                    if(!digit)begin temp[out_index]<=mem[p];out_index<=out_index+1;end
                    if(p==N-1)begin p<=0;state<=1;end else p<=p+1;
                end
                1:begin
                    if(digit)begin temp[out_index]<=mem[p];out_index<=out_index+1;end
                    if(p==N-1)begin p<=0;state<=2;end else p<=p+1;
                end
                2:begin
                    mem[p]<=temp[p];
                    if(p==N-1)begin
                        p<=0;out_index<=0;
                        if(bit_index==W-1)state<=3;else begin bit_index<=bit_index+1;state<=0;end
                    end else p<=p+1;
                end
                3:begin for(k=0;k<N;k=k+1)data_out[k*W+:W]<=mem[k];busy<=0;done<=1;end
                default:state<=0;
            endcase
        end
    end
endmodule
