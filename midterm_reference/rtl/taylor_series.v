// Fixed-point Taylor series, signed value / 2**Q. MODE: 0 exp, 1 sin, 2 cos.
// Supported: 8<=W<=32, 4<=Q<=24, W>=Q+4, 2<=TERMS<=16.
// Domain: exp |x|<=1; sin/cos |x|<=pi. out_of_range reports invalid domain.
// One term per cycle, truncation after products/divisions; output saturates.
module taylor_series #(parameter W=32,Q=20,TERMS=12,MODE=0)(
    input clk,rst_n,start,input signed [W-1:0] x,
    output reg signed [W-1:0] result,output reg busy,done,out_of_range,overflow
);
    localparam signed [63:0] ONE=64'sd1<<Q;
    localparam signed [63:0] PI_Q=64'sd3373259426>> (30-Q);
    localparam signed [63:0] MAXIMUM=(64'sd1<<(W-1))-1,MINIMUM=-(64'sd1<<(W-1));
    reg signed [63:0] argument,square,term,total,next_term,next_total;
    reg signed [127:0] product,scaled;
    integer k,denominator;
    always @*begin
        denominator=k;
        if(MODE==0)product=term*argument;
        else begin
            product=-term*square;
            denominator=(MODE==1)?((2*k)*(2*k+1)):((2*k-1)*(2*k));
        end
        scaled=product>>>Q;
        next_term=scaled/((denominator>0)?denominator:1);
        next_total=total+next_term;
    end
    always @(posedge clk)begin
        if(!rst_n)begin
            result<=0;busy<=0;done<=0;out_of_range<=0;overflow<=0;
            argument<=0;square<=0;term<=0;total<=0;k<=1;
        end else begin
            done<=0;
            if(start&&!busy)begin
                argument<=x;square<=($signed(x)*$signed({{W{x[W-1]}},x}))>>>Q;
                term<=(MODE==1)?$signed(x):ONE;total<=(MODE==1)?$signed(x):ONE;
                k<=1;busy<=1;overflow<=0;
                out_of_range<=($signed(x)>((MODE==0)?ONE:PI_Q)) || ($signed(x)<-((MODE==0)?ONE:PI_Q));
            end else if(busy)begin
                term<=next_term;total<=next_total;k<=k+1;
                if(k==TERMS-1)begin
                    if(next_total>MAXIMUM)begin result<=MAXIMUM;overflow<=1;end
                    else if(next_total<MINIMUM)begin result<=MINIMUM;overflow<=1;end
                    else result<=next_total;
                    busy<=0;done<=1;
                end
            end
        end
    end
endmodule
