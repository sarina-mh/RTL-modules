// Finite real Fourier series on theta=2*pi*phase/64:
// y=c[0]+sum(h=1..H){c[h]*cos(h*theta)+s[h]*sin(h*theta)}.
// c[0] is the actual constant term (predivide a0 by 2 if using that convention).
// Signed fixed-point coefficients/results; H>=0; sine coefficient s[0] ignored.
// One harmonic MAC per cycle; output saturates and sets overflow.
module fourier_series #(parameter W=32,Q=20,H=3)(
    input clk,rst_n,start,input [5:0] phase,
    input [(H+1)*W-1:0] cosine_coefficients,sine_coefficients,
    output reg signed [W-1:0] result,output reg busy,done,overflow
);
    localparam signed [63:0] MAXIMUM=(64'sd1<<(W-1))-1,MINIMUM=-(64'sd1<<(W-1));
    reg [(H+1)*W-1:0] c,s;reg [5:0] saved_phase;integer harmonic;
    reg signed [63:0] total,next_total;reg signed [127:0] product;
    wire [5:0] angle=saved_phase*harmonic;
    wire signed [W-1:0] cosine,negative_sine;
    wire signed [W-1:0] ch=c[((harmonic<=H)?harmonic:0)*W+:W];
    wire signed [W-1:0] sh=s[((harmonic<=H)?harmonic:0)*W+:W];
    twiddle_rom #(W,Q) table_rom(angle,cosine,negative_sine);
    always @*begin
        product=$signed(ch)*$signed(cosine)-$signed(sh)*$signed(negative_sine);
        next_total=total+(product>>>Q);
    end
    always @(posedge clk)begin
        if(!rst_n)begin c<=0;s<=0;saved_phase<=0;harmonic<=1;total<=0;result<=0;busy<=0;done<=0;overflow<=0;end
        else begin
            done<=0;
            if(start&&!busy)begin
                c<=cosine_coefficients;s<=sine_coefficients;saved_phase<=phase;harmonic<=1;
                total<=$signed(cosine_coefficients[0+:W]);busy<=1;overflow<=0;
            end else if(busy)begin
                if(H==0 || harmonic==H)begin
                    if((H==0?total:next_total)>MAXIMUM)begin result<=MAXIMUM;overflow<=1;end
                    else if((H==0?total:next_total)<MINIMUM)begin result<=MINIMUM;overflow<=1;end
                    else result<=(H==0)?total:next_total;
                    busy<=0;done<=1;
                end else begin total<=next_total;harmonic<=harmonic+1;end
            end
        end
    end
endmodule
