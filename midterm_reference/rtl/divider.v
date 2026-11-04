// Module: divider. Original group: combinational.
// Combinational restoring unsigned division; quotient saturates on /0.
module divider #(parameter W=8)(input [W-1:0] dividend,divisor,
    output reg [W-1:0] quotient,remainder, output divide_by_zero);
    integer i; reg [W:0] rem_work;
    assign divide_by_zero=(divisor==0);
    always @* begin
        quotient=0; rem_work=0; remainder=dividend;
        if(divisor==0) quotient={W{1'b1}};
        else begin
            for(i=W-1;i>=0;i=i-1) begin
                rem_work={rem_work[W-1:0],dividend[i]};
                if(rem_work>={1'b0,divisor}) begin
                    rem_work=rem_work-{1'b0,divisor}; quotient[i]=1;
                end
            end
            remainder=rem_work[W-1:0];
        end
    end
endmodule
