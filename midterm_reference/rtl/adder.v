// Module: adder. Original group: combinational.
module adder #(parameter W=8)(input [W-1:0] a,b, input cin, output [W-1:0] y, output cout);
    assign {cout,y}={1'b0,a}+{1'b0,b}+cin;
endmodule
