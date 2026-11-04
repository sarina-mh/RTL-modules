// Module: register_en. Original group: sequential.
// Priority: reset > load > enabled capture > hold.
module register_en #(parameter W=8)(input clk,rst_n,en,load,
    input [W-1:0] d,load_value, output reg [W-1:0] q);
    always @(posedge clk)
        if(!rst_n) q<=0; else if(load) q<=load_value; else if(en) q<=d;
endmodule
