// Module: saturating_counter. Original group: sequential.
module saturating_counter #(parameter W=8)(input clk,rst_n,en,down, output reg [W-1:0] count);
    always @(posedge clk)
        if(!rst_n) count<=0;
        else if(en) begin
            if(down && count!=0) count<=count-1'b1;
            else if(!down && count!={W{1'b1}}) count<=count+1'b1;
        end
endmodule
