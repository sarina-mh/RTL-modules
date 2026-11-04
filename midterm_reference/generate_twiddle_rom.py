"""Regenerate the fixed 64-position Fourier twiddle ROM, Q30 constants.
Only this development script uses floating-point trig; RTL uses integers only.
"""
from pathlib import Path
import math
root=Path(__file__).resolve().parent
lines=['// exp(-j*2*pi*phase/64), constant Q30 coefficients rescaled to Q.',
       '// 8<=W<=32, 4<=Q<=24, W>=Q+2. No runtime real arithmetic.',
       'module twiddle_rom #(parameter W=32,Q=20)(input [5:0] phase,',
       '    output reg signed [W-1:0] real_part,imag_part);',
       '    reg signed [63:0] r,i;',
       '    always @*begin', '        r=0;i=0;', '        case(phase)']
def literal(x):return ('-' if x<0 else '')+"64'sd"+str(abs(x))
for k in range(64):
    r=round(math.cos(2*math.pi*k/64)*(1<<30));i=round(-math.sin(2*math.pi*k/64)*(1<<30))
    lines.append(f"            6'd{k}:begin r={literal(r)};i={literal(i)};end")
lines.extend(['            default:begin r=0;i=0;end','        endcase',
              '        real_part=r >>> (30-Q);imag_part=i >>> (30-Q);',
              '    end','endmodule'])
(root/'rtl/twiddle_rom.v').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print('Generated 64 fixed twiddle positions.')
