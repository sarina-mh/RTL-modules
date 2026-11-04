// Module: leading_zero_count. Original group: combinational.
module leading_zero_count #(parameter W=8, C=$clog2(W+1)) (
    input [W-1:0] x, output reg [C-1:0] count
);
    integer i; reg found;
    always @* begin
        count=0; found=0;
        for(i=W-1;i>=0;i=i-1) begin
            if(x[i]) found=1;
            else if(!found) count=count+1'b1;
        end
    end
endmodule
