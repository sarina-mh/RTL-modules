// Complex direct DFT/IDFT. N must divide 64 (1,2,4,8,16,32,64).
// Same fixed-point scale on input/output; forward is unnormalized, inverse /N.
// One complex multiply-accumulate per cycle; W<=32,Q<=24,W>=Q+4.
// Accumulation uses 64 bits; choose signal headroom to avoid internal overflow.
module dft_fixed #(parameter W=32,Q=20,N=8,INVERSE=0)(
    input clk,rst_n,start,input [N*W-1:0] real_in,imag_in,
    output reg [N*W-1:0] real_out,imag_out,output reg busy,done,overflow
);
    localparam signed [63:0] MAXIMUM=(64'sd1<<(W-1))-1,MINIMUM=-(64'sd1<<(W-1));
    reg [N*W-1:0] saved_real,saved_imag;integer bin,sample,k;reg reporting;
    wire [5:0] phase=((bin*sample)%N)*(64/N);
    wire signed [W-1:0] wr,wi_forward;
    wire signed [W-1:0] wi=INVERSE?-wi_forward:wi_forward;
    wire signed [W-1:0] xr=saved_real[sample*W+:W],xi=saved_imag[sample*W+:W];
    reg signed [63:0] sum_real,sum_imag,next_real,next_imag,normalized_real,normalized_imag;
    reg signed [127:0] pr,pi;
    twiddle_rom #(W,Q) table_rom(phase,wr,wi_forward);
    function [W-1:0] clip;input signed [63:0] value;
        begin if(value>MAXIMUM)clip=MAXIMUM;else if(value<MINIMUM)clip=MINIMUM;else clip=value;end
    endfunction
    always @*begin
        pr=$signed(xr)*$signed(wr)-$signed(xi)*$signed(wi);
        pi=$signed(xr)*$signed(wi)+$signed(xi)*$signed(wr);
        next_real=sum_real+(pr>>>Q);next_imag=sum_imag+(pi>>>Q);
        normalized_real=INVERSE?(next_real/N):next_real;
        normalized_imag=INVERSE?(next_imag/N):next_imag;
    end
    always @(posedge clk)begin
        if(!rst_n)begin
            saved_real<=0;saved_imag<=0;real_out<=0;imag_out<=0;busy<=0;done<=0;overflow<=0;
            bin<=0;sample<=0;sum_real<=0;sum_imag<=0;reporting<=0;
        end else begin
            done<=0;
            if(start&&!busy)begin
                saved_real<=real_in;saved_imag<=imag_in;bin<=0;sample<=0;sum_real<=0;sum_imag<=0;
                busy<=1;overflow<=0;reporting<=0;
            end else if(busy)begin
                if(reporting)begin busy<=0;done<=1;end
                else if(sample==N-1)begin
                    real_out[bin*W+:W]<=clip(normalized_real);imag_out[bin*W+:W]<=clip(normalized_imag);
                    if(normalized_real>MAXIMUM || normalized_real<MINIMUM || normalized_imag>MAXIMUM || normalized_imag<MINIMUM)overflow<=1;
                    sample<=0;sum_real<=0;sum_imag<=0;
                    if(bin==N-1)reporting<=1;else bin<=bin+1;
                end else begin sum_real<=next_real;sum_imag<=next_imag;sample<=sample+1;end
            end
        end
    end
endmodule
