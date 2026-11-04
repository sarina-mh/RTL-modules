// Module: modulo_counter. Original group: sequential.
module modulo_counter #(parameter N=10, W=(N>1?$clog2(N):1)) (
    input clk,rst_n,en, output reg [W-1:0] count, output terminal);
    assign terminal=(count==N-1);
    always @(posedge clk)
        if(!rst_n) count<=0;
        else if(en) begin if(terminal) count<=0; else count<=count+1'b1; end
endmodule
