// Module: add_sub. Original group: combinational.
// For subtraction carry=1 means NO unsigned borrow.
module add_sub #(parameter W=8)(input [W-1:0] a,b, input sub,
    output [W-1:0] y, output carry,overflow);
    wire [W-1:0] adjusted_b=b^{W{sub}};
    assign {carry,y}={1'b0,a}+{1'b0,adjusted_b}+sub;
    assign overflow=(a[W-1]==adjusted_b[W-1]) && (y[W-1]!=a[W-1]);
endmodule
