// cos(x) by Taylor series; radians in signed fixed point; domain [-pi,pi].
module cos_taylor #(parameter W=32,Q=20,TERMS=12)(
    input clk,rst_n,start,input signed [W-1:0] x,output signed [W-1:0] result,
    output busy,done,out_of_range,overflow
);
    taylor_series #(W,Q,TERMS,2) core(clk,rst_n,start,x,result,busy,done,out_of_range,overflow);
endmodule
