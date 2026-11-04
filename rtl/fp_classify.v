// Module: fp_classify. Original group: floating_point.
module fp_classify #(parameter E=5,F=10,W=1+E+F)(input [W-1:0] x,
    output sign,is_zero,is_subnormal,is_normal,is_inf,is_nan);
    wire exp_zero=(x[F +: E]==0);wire exp_ones=(&x[F +: E]);
    wire frac_zero=(x[F-1:0]==0);
    assign sign=x[W-1];assign is_zero=exp_zero&&frac_zero;
    assign is_subnormal=exp_zero&&!frac_zero;assign is_normal=!exp_zero&&!exp_ones;
    assign is_inf=exp_ones&&frac_zero;assign is_nan=exp_ones&&!frac_zero;
endmodule
