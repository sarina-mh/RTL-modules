// Module: fp_stream. Original group: floating_point.
// Also compile: fp_arithmetic.v.
// One-entry elastic output register: accepts and retires together if ready.
module fp_stream #(parameter E=5,F=10,OP=0,W=1+E+F)(
    input clk,rst_n,in_valid,output in_ready,input [W-1:0] a,b,
    output reg out_valid,input out_ready,output reg [W-1:0] result
);
    wire [W-1:0] computed;
    fp_arithmetic #(E,F,OP) arithmetic(a,b,computed);
    assign in_ready=!out_valid || out_ready;
    always @(posedge clk)
        if(!rst_n) begin out_valid<=0;result<=0;end
        else if(in_ready) begin out_valid<=in_valid;if(in_valid) result<=computed;end
endmodule
