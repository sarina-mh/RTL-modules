// Module: shift_register. Original group: sequential.
module shift_register #(parameter W=8)(input clk,rst_n,en,right,serial_in,load,
    input [W-1:0] parallel_in, output reg [W-1:0] q, output serial_out);
    assign serial_out=right ? q[0] : q[W-1];
    always @(posedge clk)
        if(!rst_n) q<=0;
        else if(load) q<=parallel_in;
        else if(en) begin
            if(right) q<=(q>>1) | ({{(W-1){1'b0}},serial_in}<<(W-1));
            else q<=(q<<1) | serial_in;
        end
endmodule
