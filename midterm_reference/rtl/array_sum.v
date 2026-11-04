// Module: array_sum. Original group: fsm.
// Also compile: sum_controller.v, sum_datapath.v.
// Complete controller/datapath example. Data is latched when start is accepted.
module array_sum #(parameter W=8,N=8,AW=W+$clog2(N),I=(N>1?$clog2(N):1)) (
    input clk,rst_n,start,input [N*W-1:0] data_in,output [AW-1:0] sum,output busy,done
);
    wire clear,step;wire [I-1:0] index;
    sum_controller #(N,I) ctrl(clk,rst_n,start,clear,step,busy,done,index);
    sum_datapath #(W,N,AW,I) dp(clk,rst_n,clear,step,index,data_in,sum);
endmodule
