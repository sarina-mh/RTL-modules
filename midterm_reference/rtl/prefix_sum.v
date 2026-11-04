// Inclusive unsigned prefix sum. AW defaults to sufficient full precision.
module prefix_sum #(parameter W=8,N=8,AW=W+$clog2(N))(
    input clk,rst_n,start,input [N*W-1:0] data_in,
    output reg [N*AW-1:0] data_out,output reg busy,done
);
    reg [N*W-1:0] data;reg [AW-1:0] total;integer p;
    wire [AW-1:0] next_total=total+data[p*W+:W];
    always @(posedge clk)begin
        if(!rst_n)begin data<=0;data_out<=0;total<=0;p<=0;busy<=0;done<=0;end
        else begin
            done<=0;
            if(start&&!busy)begin data<=data_in;total<=0;p<=0;busy<=1;end
            else if(busy)begin
                total<=next_total;data_out[p*AW+:AW]<=next_total;
                if(p==N-1)begin busy<=0;done<=1;end else p<=p+1;
            end
        end
    end
endmodule
