// Module: fp16_multiplier. Original group: floating_point.
// Also compile: fp_stream.v, fp_arithmetic.v.
module fp16_multiplier(input clk,rst_n,in_valid,output in_ready,input [15:0] a,b,
    output out_valid,input out_ready,output [15:0] result);
    fp_stream #(5,10,2) core(clk,rst_n,in_valid,in_ready,a,b,out_valid,out_ready,result);
endmodule
