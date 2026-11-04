// Module: fp_compare. Original group: floating_point.
// Ordered comparison: NaN makes unordered=1 and lt/eq/gt=0; signed zeros compare equal.
module fp_compare #(parameter E=5,F=10,W=1+E+F)(input [W-1:0] a,b,
    output reg lt,eq,gt,output unordered);
    wire na=(&a[F +: E]) && (|a[F-1:0]);
    wire nb=(&b[F +: E]) && (|b[F-1:0]);
    assign unordered=na||nb;
    always @* begin
        lt=0;eq=0;gt=0;
        if(!unordered) begin
            if(a==b || ((a[W-2:0]==0)&&(b[W-2:0]==0))) eq=1;
            else begin
                if(a[W-1]!=b[W-1]) lt=a[W-1];
                else if(a[W-1]) lt=a[W-2:0]>b[W-2:0];
                else lt=a[W-2:0]<b[W-2:0];
                gt=!lt;
            end
        end
    end
endmodule
