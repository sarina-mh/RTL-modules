// Module: array_sum_controller. Original group: fsm.
// Controller template used by array_sum. One element is accumulated per RUN cycle.
module array_sum_controller #(parameter N=8,I=(N>1?$clog2(N):1)) (
    input clk,rst_n,start,output reg clear,step,busy,done,output reg [I-1:0] index
);
    localparam IDLE=0,RUN=1,REPORT=2;reg [1:0] state;
    always @* begin clear=0;step=0;busy=(state!=IDLE);done=(state==REPORT);
        if(state==IDLE && start) clear=1;
        if(state==RUN) step=1;
    end
    always @(posedge clk)
        if(!rst_n) begin state<=IDLE;index<=0;end
        else case(state)
            IDLE: if(start) begin index<=0;state<=RUN;end
            RUN: if(index==N-1) state<=REPORT;else index<=index+1'b1;
            REPORT: state<=IDLE;
            default: state<=IDLE;
        endcase
endmodule

// Module: array_sum_datapath. Original group: fsm.
module array_sum_datapath #(parameter W=8,N=8,AW=W+$clog2(N),I=(N>1?$clog2(N):1)) (
    input clk,rst_n,clear,step,input [I-1:0] index,input [N*W-1:0] data_in,
    output reg [AW-1:0] sum
);
    reg [N*W-1:0] data;
    always @(posedge clk)
        if(!rst_n) begin sum<=0;data<=0;end
        else if(clear) begin sum<=0;data<=data_in;end
        else if(step) sum<=sum+data[index*W +: W];
endmodule

// Module: array_sum. Original group: fsm.
// Complete controller/datapath example. Data is latched when start is accepted.
module array_sum #(parameter W=8,N=8,AW=W+$clog2(N),I=(N>1?$clog2(N):1)) (
    input clk,rst_n,start,input [N*W-1:0] data_in,output [AW-1:0] sum,output busy,done
);
    wire clear,step;wire [I-1:0] index;
    array_sum_controller #(N,I) ctrl(clk,rst_n,start,clear,step,busy,done,index);
    array_sum_datapath #(W,N,AW,I) dp(clk,rst_n,clear,step,index,data_in,sum);
endmodule
