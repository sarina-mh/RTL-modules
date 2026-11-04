// Module: comparator. Original group: combinational.
module comparator #(parameter W=8, SIGNED=0)(input [W-1:0] a,b, output lt,eq,gt);
    assign lt=SIGNED ? ($signed(a)<$signed(b)) : (a<b);
    assign eq=(a==b);
    assign gt=SIGNED ? ($signed(a)>$signed(b)) : (a>b);
endmodule
