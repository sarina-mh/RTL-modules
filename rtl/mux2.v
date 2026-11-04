// Module: mux2. Original group: combinational.
module mux2 #(parameter WIDTH=8)(input [WIDTH-1:0] a,b, input sel, output [WIDTH-1:0] y);
    assign y=sel ? b : a;
endmodule
