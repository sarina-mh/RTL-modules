// Module: sum_controller. Original group: fsm.
// Controller template used by array_sum. One element is accumulated per RUN cycle.
module sum_controller #(parameter N=8,I=(N>1?$clog2(N):1)) (
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
