// Iterative radix-2 DIT FFT/IFFT; bit-reversed input loading, natural output.
// N in {1,2,4,8,16,32,64}; one butterfly per cycle; fixed-point W/Q.
// Forward is unnormalized. Inverse divides the final result by N.
// Intermediate butterfly overflow SATURATES and sets sticky overflow; inputs
// need sufficient headroom because inverse normalization happens at the end.
module fft_radix2 #(parameter W=32,Q=20,N=8,INVERSE=0)(
    input clk,rst_n,start,input [N*W-1:0] real_in,imag_in,
    output reg [N*W-1:0] real_out,imag_out,output reg busy,done,overflow
);
    localparam LOGN=(N>1?$clog2(N):0);
    localparam signed [63:0] MAXIMUM=(64'sd1<<(W-1))-1,MINIMUM=-(64'sd1<<(W-1));
    reg signed [W-1:0] re[0:N-1],im[0:N-1];
    integer span,base,j,k,upper,lower;reg reporting;
    wire [5:0] phase=j*(64/span);
    wire signed [W-1:0] wr,wi_forward;
    wire signed [W-1:0] wi=INVERSE?-wi_forward:wi_forward;
    reg signed [127:0] pr,pi;
    reg signed [63:0] tr,ti,ar,ai,br,bi;
    twiddle_rom #(W,Q) table_rom(phase,wr,wi_forward);
    function integer reversed;input integer value;integer bit_index;
        begin reversed=0;for(bit_index=0;bit_index<LOGN;bit_index=bit_index+1)reversed=(reversed<<1)|((value>>bit_index)&1);end
    endfunction
    function [W-1:0] clip;input signed [63:0] value;
        begin if(value>MAXIMUM)clip=MAXIMUM;else if(value<MINIMUM)clip=MINIMUM;else clip=value;end
    endfunction
    always @*begin
        upper=base+j;lower=base+j+span/2;
        pr=0;pi=0;tr=0;ti=0;ar=0;ai=0;br=0;bi=0;
        if(upper<N && lower<N)begin
            pr=$signed(re[lower])*$signed(wr)-$signed(im[lower])*$signed(wi);
            pi=$signed(re[lower])*$signed(wi)+$signed(im[lower])*$signed(wr);
            tr=pr>>>Q;ti=pi>>>Q;
            ar=$signed(re[upper])+tr;ai=$signed(im[upper])+ti;
            br=$signed(re[upper])-tr;bi=$signed(im[upper])-ti;
        end
    end
    always @(posedge clk)begin
        if(!rst_n)begin
            real_out<=0;imag_out<=0;busy<=0;done<=0;overflow<=0;span<=2;base<=0;j<=0;reporting<=0;
            for(k=0;k<N;k=k+1)begin re[k]<=0;im[k]<=0;end
        end else begin
            done<=0;
            if(start&&!busy)begin
                for(k=0;k<N;k=k+1)begin re[reversed(k)]<=real_in[k*W+:W];im[reversed(k)]<=imag_in[k*W+:W];end
                span<=2;base<=0;j<=0;reporting<=(N==1);busy<=1;overflow<=0;
            end else if(busy)begin
                if(reporting)begin
                    for(k=0;k<N;k=k+1)begin
                        real_out[k*W+:W]<=INVERSE?($signed(re[k])/N):re[k];
                        imag_out[k*W+:W]<=INVERSE?($signed(im[k])/N):im[k];
                    end
                    busy<=0;done<=1;
                end else begin
                    re[upper]<=clip(ar);im[upper]<=clip(ai);re[lower]<=clip(br);im[lower]<=clip(bi);
                    if(ar>MAXIMUM||ar<MINIMUM||ai>MAXIMUM||ai<MINIMUM||br>MAXIMUM||br<MINIMUM||bi>MAXIMUM||bi<MINIMUM)overflow<=1;
                    if(j==span/2-1)begin
                        j<=0;
                        if(base+span>=N)begin
                            base<=0;if(span==N)reporting<=1;else span<=span*2;
                        end else base<=base+span;
                    end else j<=j+1;
                end
            end
        end
    end
endmodule
