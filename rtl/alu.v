// Module: alu. Original group: combinational.
// op: 0 add, 1 subtract, 2 AND, 3 OR, 4 XOR, 5 left shift,
// 6 arithmetic right shift, 7 signed less-than. carry/overflow apply to 0/1.
module alu #(parameter W=8)(input [W-1:0] a,b, input [2:0] op,
    output reg [W-1:0] y, output zero,negative, output reg carry,overflow);
    wire [W-1:0] arith; wire c,v;
    alu_helper_add_sub #(W) u_arith(a,b,op==1,arith,c,v);
    always @* begin
        y=0; carry=0; overflow=0;
        case(op)
            0,1: begin y=arith; carry=c; overflow=v; end
            2: y=a&b;
            3: y=a|b;
            4: y=a^b;
            5: y=a<<b;
            6: y=$signed(a)>>>b;
            7: y=($signed(a)<$signed(b));
        endcase
    end
    assign zero=(y==0); assign negative=y[W-1];
endmodule


// ---------------- PRIVATE HELPERS ----------------
module alu_helper_add_sub #(parameter W=8)(input [W-1:0] a,b, input sub,
    output [W-1:0] y, output carry,overflow);
    wire [W-1:0] adjusted_b=b^{W{sub}};
    assign {carry,y}={1'b0,a}+{1'b0,adjusted_b}+sub;
    assign overflow=(a[W-1]==adjusted_b[W-1]) && (y[W-1]!=a[W-1]);
endmodule
