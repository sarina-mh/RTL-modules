// Module: counter. Original group: sequential.
module counter #(parameter W=8)(input clk,rst_n,clear,en,down,load,
    input [W-1:0] load_value, output reg [W-1:0] count);
    always @(posedge clk)
        if(!rst_n) count<=0; else if(clear) count<=0;
        else if(load) count<=load_value;
        else if(en) count<=down ? count-1'b1 : count+1'b1;
endmodule
