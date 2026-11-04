// Module: sync_fifo. Original group: memory.
// First-word fall-through FIFO. Full allows replacement only with a simultaneous pop.
// Empty simultaneous push/pop accepts the push and rejects the pop (no bypass).
module sync_fifo #(parameter W=8, DEPTH=4, A=(DEPTH>1?$clog2(DEPTH):1), C=$clog2(DEPTH+1)) (
    input clk,rst_n,push,pop, input [W-1:0] data_in,
    output [W-1:0] data_out, output full,empty, output reg [C-1:0] count
);
    reg [W-1:0] mem[0:DEPTH-1]; reg [A-1:0] rd,wr;
    wire take_pop=pop && !empty;
    wire take_push=push && (!full || take_pop);
    assign empty=(count==0); assign full=(count==DEPTH);
    assign data_out=empty ? {W{1'b0}} : mem[rd];
    always @(posedge clk)
        if(!rst_n) begin rd<=0; wr<=0; count<=0; end
        else begin
            if(take_push) begin mem[wr]<=data_in; wr<=(wr==DEPTH-1)?0:wr+1'b1; end
            if(take_pop) rd<=(rd==DEPTH-1)?0:rd+1'b1;
            case({take_push,take_pop})
                2'b10: count<=count+1'b1;
                2'b01: count<=count-1'b1;
                default: count<=count;
            endcase
        end
endmodule
