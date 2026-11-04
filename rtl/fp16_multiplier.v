// Module: fp16_multiplier. Original group: floating_point.
module fp16_multiplier(input clk,rst_n,in_valid,output in_ready,input [15:0] a,b,
    output out_valid,input out_ready,output [15:0] result);
    fp16_multiplier_helper_fp_stream #(5,10,2) core(clk,rst_n,in_valid,in_ready,a,b,out_valid,out_ready,result);
endmodule


// ---------------- PRIVATE HELPERS ----------------
module fp16_multiplier_helper_fp_arithmetic #(parameter E=5,F=10,OP=0,W=1+E+F)(
    input [W-1:0] a,b,output reg [W-1:0] result
);
    localparam BIAS=(1<<(E-1))-1;
    localparam EMAX=(1<<E)-1;
    localparam [W-1:0] QNAN=((64'd1*((1<<E)-1))<<F) | (64'd1<<(F-1));
    reg sa,sb,sign_out,na,nb,ia,ib,za,zb;
    integer ea,eb,xa,xb,common_exp,diff,n;
    reg [63:0] ma,mb,va,vb,magnitude,quotient,remainder;

    // Right shift with sticky bit; preserves all discarded information needed
    // by the final rounding operation when at least three guard bits remain.
    function [63:0] shift_jam;
        input [63:0] value;input integer amount;
        reg sticky;
        begin
            if(amount<=0) shift_jam=value;
            else if(amount>=64) shift_jam=(value!=0);
            else begin sticky=((value & ((64'd1<<amount)-1))!=0);
                shift_jam=(value>>amount)|sticky;
            end
        end
    endfunction

    // Pack integer magnitude * 2**exp2, including subnormal rounding.
    function [W-1:0] pack;
        input sign;input [63:0] mag;input integer exp2;
        integer msb,i,unbiased,shift,target_exp;
        reg [63:0] rounded,discarded,half;
        reg [E-1:0] encoded;
        begin
            pack={sign,{(E+F){1'b0}}}; msb=-1;rounded=0;discarded=0;half=0;encoded=0;
            for(i=0;i<64;i=i+1) if(mag[i]) msb=i;
            if(msb>=0) begin
                unbiased=msb+exp2;
                // Subnormal values use a fixed quantum 2**(1-BIAS-F).
                target_exp=(unbiased<1-BIAS)?(1-BIAS):unbiased;
                shift=target_exp-F-exp2;
                if(shift>64) rounded=0;
                else if(shift==64) begin
                    rounded=(mag>64'h8000000000000000)?1:0;
                end else if(shift>0) begin
                    rounded=mag>>shift;
                    discarded=mag & ((64'd1<<shift)-1);
                    half=64'd1<<(shift-1);
                    if(discarded>half || (discarded==half && rounded[0])) rounded=rounded+1;
                end else rounded=mag<<(-shift);
                if(rounded>=(64'd1<<(F+1))) begin rounded=rounded>>1;target_exp=target_exp+1;end
                if(target_exp>BIAS) pack={sign,{E{1'b1}},{F{1'b0}}};
                else if(rounded<(64'd1<<F)) pack={sign,{E{1'b0}},rounded[F-1:0]};
                else begin encoded=target_exp+BIAS;pack={sign,encoded,rounded[F-1:0]};end
            end
        end
    endfunction

    always @* begin
        sa=a[W-1];sb=b[W-1]^(OP==1);
        ea=a[F +: E];eb=b[F +: E];
        ma={1'b0,a[F-1:0]};mb={1'b0,b[F-1:0]};
        na=(ea==EMAX && ma!=0);nb=(eb==EMAX && mb!=0);
        ia=(ea==EMAX && ma==0);ib=(eb==EMAX && mb==0);
        za=(ea==0 && ma==0);zb=(eb==0 && mb==0);
        if(ea!=0) ma=ma|(64'd1<<F);
        if(eb!=0) mb=mb|(64'd1<<F);
        xa=(ea==0?1:ea)-BIAS-F;xb=(eb==0?1:eb)-BIAS-F;
        result=0;va=0;vb=0;magnitude=0;quotient=0;remainder=0;
        common_exp=0;diff=0;sign_out=sa^sb;
        if(na || nb) result=QNAN;
        else if(OP==0 || OP==1) begin
            if(ia && ib && sa!=sb) result=QNAN;
            else if(ia) result={sa,{E{1'b1}},{F{1'b0}}};
            else if(ib) result={sb,{E{1'b1}},{F{1'b0}}};
            else begin
                // Align around the larger exponent with F+4 low guard bits.
                common_exp=(xa>xb?xa:xb);
                va=shift_jam(ma<<(F+4),common_exp-xa);
                vb=shift_jam(mb<<(F+4),common_exp-xb);
                if(sa==sb) begin magnitude=va+vb;sign_out=sa;end
                else if(va>=vb) begin magnitude=va-vb;sign_out=sa;end
                else begin magnitude=vb-va;sign_out=sb;end
                // Exact cancellation rounds to +0, except -0 + -0.
                if(magnitude==0) sign_out=sa & sb;
                result=pack(sign_out,magnitude,common_exp-(F+4));
            end
        end else if(OP==2) begin
            if((ia&&zb)||(ib&&za)) result=QNAN;
            else if(ia||ib) result={sign_out,{E{1'b1}},{F{1'b0}}};
            else result=pack(sign_out,ma*mb,xa+xb);
        end else begin
            if((ia&&ib)||(za&&zb)) result=QNAN;
            else if(ia||zb) result={sign_out,{E{1'b1}},{F{1'b0}}};
            else if(ib||za) result={sign_out,{(E+F){1'b0}}};
            else begin
                // F+5 fractional quotient bits plus jammed remainder provide
                // guard/round/sticky information even for subnormal operands.
                for(n=0;n<F;n=n+1) begin
                    if(!ma[F]) begin ma=ma<<1;xa=xa-1;end
                    if(!mb[F]) begin mb=mb<<1;xb=xb-1;end
                end
                va=ma<<(F+5);quotient=va/mb;remainder=va%mb;
                if(remainder!=0) quotient=quotient|1;
                result=pack(sign_out,quotient,xa-xb-(F+5));
            end
        end
    end
endmodule

module fp16_multiplier_helper_fp_stream #(parameter E=5,F=10,OP=0,W=1+E+F)(
    input clk,rst_n,in_valid,output in_ready,input [W-1:0] a,b,
    output reg out_valid,input out_ready,output reg [W-1:0] result
);
    wire [W-1:0] computed;
    fp16_multiplier_helper_fp_arithmetic #(E,F,OP) arithmetic(a,b,computed);
    assign in_ready=!out_valid || out_ready;
    always @(posedge clk)
        if(!rst_n) begin out_valid<=0;result<=0;end
        else if(in_ready) begin out_valid<=in_valid;if(in_valid) result<=computed;end
endmodule
