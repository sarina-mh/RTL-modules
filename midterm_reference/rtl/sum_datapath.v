// Module: sum_datapath. Original group: fsm.
module sum_datapath #(parameter W=8,N=8,AW=W+$clog2(N),I=(N>1?$clog2(N):1)) (
    input clk,rst_n,clear,step,input [I-1:0] index,input [N*W-1:0] data_in,
    output reg [AW-1:0] sum
);
    reg [N*W-1:0] data;
    always @(posedge clk)
        if(!rst_n) begin sum<=0;data<=0;end
        else if(clear) begin sum<=0;data<=data_in;end
        else if(step) sum<=sum+data[index*W +: W];
endmodule
