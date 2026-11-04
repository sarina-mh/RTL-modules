// Module: accumulator. Original group: sequential.
module accumulator #(parameter W=16)(input clk,rst_n,clear,en,
    input [W-1:0] value, output reg [W-1:0] sum);
    always @(posedge clk)
        if(!rst_n) sum<=0; else if(clear) sum<=0; else if(en) sum<=sum+value;
endmodule
