// exp(-j*2*pi*phase/64), constant Q30 coefficients rescaled to Q.
// 8<=W<=32, 4<=Q<=24, W>=Q+2. No runtime real arithmetic.
module twiddle_rom #(parameter W=32,Q=20)(input [5:0] phase,
    output reg signed [W-1:0] real_part,imag_part);
    reg signed [63:0] r,i;
    always @*begin
        r=0;i=0;
        case(phase)
            6'd0:begin r=64'sd1073741824;i=64'sd0;end
            6'd1:begin r=64'sd1068571464;i=-64'sd105245103;end
            6'd2:begin r=64'sd1053110176;i=-64'sd209476638;end
            6'd3:begin r=64'sd1027506862;i=-64'sd311690799;end
            6'd4:begin r=64'sd992008094;i=-64'sd410903207;end
            6'd5:begin r=64'sd946955747;i=-64'sd506158392;end
            6'd6:begin r=64'sd892783698;i=-64'sd596538995;end
            6'd7:begin r=64'sd830013654;i=-64'sd681174602;end
            6'd8:begin r=64'sd759250125;i=-64'sd759250125;end
            6'd9:begin r=64'sd681174602;i=-64'sd830013654;end
            6'd10:begin r=64'sd596538995;i=-64'sd892783698;end
            6'd11:begin r=64'sd506158392;i=-64'sd946955747;end
            6'd12:begin r=64'sd410903207;i=-64'sd992008094;end
            6'd13:begin r=64'sd311690799;i=-64'sd1027506862;end
            6'd14:begin r=64'sd209476638;i=-64'sd1053110176;end
            6'd15:begin r=64'sd105245103;i=-64'sd1068571464;end
            6'd16:begin r=64'sd0;i=-64'sd1073741824;end
            6'd17:begin r=-64'sd105245103;i=-64'sd1068571464;end
            6'd18:begin r=-64'sd209476638;i=-64'sd1053110176;end
            6'd19:begin r=-64'sd311690799;i=-64'sd1027506862;end
            6'd20:begin r=-64'sd410903207;i=-64'sd992008094;end
            6'd21:begin r=-64'sd506158392;i=-64'sd946955747;end
            6'd22:begin r=-64'sd596538995;i=-64'sd892783698;end
            6'd23:begin r=-64'sd681174602;i=-64'sd830013654;end
            6'd24:begin r=-64'sd759250125;i=-64'sd759250125;end
            6'd25:begin r=-64'sd830013654;i=-64'sd681174602;end
            6'd26:begin r=-64'sd892783698;i=-64'sd596538995;end
            6'd27:begin r=-64'sd946955747;i=-64'sd506158392;end
            6'd28:begin r=-64'sd992008094;i=-64'sd410903207;end
            6'd29:begin r=-64'sd1027506862;i=-64'sd311690799;end
            6'd30:begin r=-64'sd1053110176;i=-64'sd209476638;end
            6'd31:begin r=-64'sd1068571464;i=-64'sd105245103;end
            6'd32:begin r=-64'sd1073741824;i=64'sd0;end
            6'd33:begin r=-64'sd1068571464;i=64'sd105245103;end
            6'd34:begin r=-64'sd1053110176;i=64'sd209476638;end
            6'd35:begin r=-64'sd1027506862;i=64'sd311690799;end
            6'd36:begin r=-64'sd992008094;i=64'sd410903207;end
            6'd37:begin r=-64'sd946955747;i=64'sd506158392;end
            6'd38:begin r=-64'sd892783698;i=64'sd596538995;end
            6'd39:begin r=-64'sd830013654;i=64'sd681174602;end
            6'd40:begin r=-64'sd759250125;i=64'sd759250125;end
            6'd41:begin r=-64'sd681174602;i=64'sd830013654;end
            6'd42:begin r=-64'sd596538995;i=64'sd892783698;end
            6'd43:begin r=-64'sd506158392;i=64'sd946955747;end
            6'd44:begin r=-64'sd410903207;i=64'sd992008094;end
            6'd45:begin r=-64'sd311690799;i=64'sd1027506862;end
            6'd46:begin r=-64'sd209476638;i=64'sd1053110176;end
            6'd47:begin r=-64'sd105245103;i=64'sd1068571464;end
            6'd48:begin r=64'sd0;i=64'sd1073741824;end
            6'd49:begin r=64'sd105245103;i=64'sd1068571464;end
            6'd50:begin r=64'sd209476638;i=64'sd1053110176;end
            6'd51:begin r=64'sd311690799;i=64'sd1027506862;end
            6'd52:begin r=64'sd410903207;i=64'sd992008094;end
            6'd53:begin r=64'sd506158392;i=64'sd946955747;end
            6'd54:begin r=64'sd596538995;i=64'sd892783698;end
            6'd55:begin r=64'sd681174602;i=64'sd830013654;end
            6'd56:begin r=64'sd759250125;i=64'sd759250125;end
            6'd57:begin r=64'sd830013654;i=64'sd681174602;end
            6'd58:begin r=64'sd892783698;i=64'sd596538995;end
            6'd59:begin r=64'sd946955747;i=64'sd506158392;end
            6'd60:begin r=64'sd992008094;i=64'sd410903207;end
            6'd61:begin r=64'sd1027506862;i=64'sd311690799;end
            6'd62:begin r=64'sd1053110176;i=64'sd209476638;end
            6'd63:begin r=64'sd1068571464;i=64'sd105245103;end
            default:begin r=0;i=0;end
        endcase
        real_part=r >>> (30-Q);imag_part=i >>> (30-Q);
    end
endmodule
