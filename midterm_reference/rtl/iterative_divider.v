// Module: iterative_divider. Original group: algorithms.
// W restoring steps. /0 completes immediately with quotient all ones.
module iterative_divider #(parameter W=8)(input clk,rst_n,start,input [W-1:0] a,b,
    output reg [W-1:0] quotient,remainder,output reg busy,done,divide_by_zero);
    reg [W-1:0] dividend,divisor,q;reg [W:0] rem_reg;
    reg [W:0] next_rem;reg [W-1:0] next_q;integer left;
    always @* begin
        next_rem={rem_reg[W-1:0],dividend[W-1]}; next_q=q<<1;
        if(next_rem>={1'b0,divisor}) begin next_rem=next_rem-divisor;next_q[0]=1;end
    end
    always @(posedge clk)
        if(!rst_n) begin quotient<=0;remainder<=0;busy<=0;done<=0;divide_by_zero<=0;
            dividend<=0;divisor<=0;q<=0;rem_reg<=0;left<=0;
        end else begin
            done<=0;
            if(start&&!busy) begin
                divide_by_zero<=(b==0);
                if(b==0) begin quotient<={W{1'b1}};remainder<=a;done<=1;end
                else begin dividend<=a;divisor<=b;q<=0;rem_reg<=0;left<=W;busy<=1;end
            end else if(busy) begin
                dividend<=dividend<<1;q<=next_q;rem_reg<=next_rem;left<=left-1;
                if(left==1) begin quotient<=next_q;remainder<=next_rem[W-1:0];busy<=0;done<=1;end
            end
        end
endmodule
