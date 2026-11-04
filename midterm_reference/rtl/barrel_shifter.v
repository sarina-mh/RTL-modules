// Module: barrel_shifter. Original group: combinational.
module barrel_shifter #(parameter W=8, S=(W>1?$clog2(W+1):1)) (
    input [W-1:0] x, input [S-1:0] amount,
    input right,arithmetic,rotate, output reg [W-1:0] y
);
    integer n;
    always @* begin
        n=amount;
        if(rotate) begin
            n=n%W;
            if(right) y=(x>>n)|(x<<(W-n));
            else y=(x<<n)|(x>>(W-n));
        end else if(right) begin
            if(arithmetic) y=$signed(x)>>>n; else y=x>>n;
        end else y=x<<n;
    end
endmodule
