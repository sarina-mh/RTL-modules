"""Exact rational oracle, independent of RTL guard-bit arithmetic.

No third-party dependencies. All finite operations are performed as Fraction,
then rounded once using integer quotient/remainder and ties-to-even.
"""
from fractions import Fraction
from pathlib import Path
import json
import random
import struct

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'build/vectors';OUT.mkdir(parents=True,exist_ok=True)

def decode(word,e,f):
    bias=(1<<(e-1))-1; exp=(word>>f)&((1<<e)-1);frac=word&((1<<f)-1)
    sign=bool(word>>(e+f))
    if exp==(1<<e)-1:return sign,('nan' if frac else 'inf'),None
    mant=frac if exp==0 else (1<<f)|frac
    power=(exp if exp else 1)-bias-f
    value=Fraction(mant<<power) if power>=0 else Fraction(mant,1<<(-power))
    return sign,('zero' if not mant else 'finite'),(-value if sign else value)

def rounded(value,sign,e,f):
    if not value:return int(sign)<<(e+f)
    bias=(1<<(e-1))-1;p=abs(value.numerator);q=value.denominator
    exponent=p.bit_length()-q.bit_length()
    if exponent>=0:
        if p<q<<exponent:exponent-=1
    elif p<<(-exponent)<q:exponent-=1
    quantum=max(exponent-f,1-bias-f)
    num,den=(p,q<<quantum) if quantum>=0 else (p<<(-quantum),q)
    mant,rem=divmod(num,den)
    if 2*rem>den or (2*rem==den and mant%2):mant+=1
    if mant>=(1<<(f+1)):mant>>=1;quantum+=1
    if mant<(1<<f):exp=0
    else:exp=quantum+f+bias
    if exp>=(1<<e)-1:exp=(1<<e)-1;mant=0
    return (int(sign)<<(e+f)) | (exp<<f) | (mant&((1<<f)-1))

def reference(op,a,b,e,f):
    sa,ka,va=decode(a,e,f);sb,kb,vb=decode(b,e,f)
    nan=(((1<<e)-1)<<f)|(1<<(f-1))
    if ka=='nan' or kb=='nan':return nan
    if op==1:sb=not sb;vb=-vb if vb is not None else None
    sign=sa^sb;inf=((1<<e)-1)<<f
    if op in (0,1):
        if ka==kb=='inf' and sa!=sb:return nan
        if ka=='inf':return (int(sa)<<(e+f))|inf
        if kb=='inf':return (int(sb)<<(e+f))|inf
        value=va+vb
        return rounded(value,(value<0) if value else (sa and sb),e,f)
    if op==2:
        if (ka=='inf' and kb=='zero') or (kb=='inf' and ka=='zero'):return nan
        if ka=='inf' or kb=='inf':return (int(sign)<<(e+f))|inf
        return rounded(va*vb,sign,e,f)
    if (ka==kb=='inf') or (ka==kb=='zero'):return nan
    if ka=='inf' or kb=='zero':return (int(sign)<<(e+f))|inf
    if kb=='inf' or ka=='zero':return int(sign)<<(e+f)
    return rounded(va/vb,sign,e,f)

def row(a,b,e,f):
    sa,ka,va=decode(a,e,f);sb,kb,vb=decode(b,e,f)
    unordered=(ka=='nan' or kb=='nan')
    if unordered:lt=eq=gt=False
    else:
        aa=(-float('inf') if sa else float('inf')) if ka=='inf' else va
        bb=(-float('inf') if sb else float('inf')) if kb=='inf' else vb
        lt,eq,gt=aa<bb,aa==bb,aa>bb
    compare=(int(lt)<<3)|(int(eq)<<2)|(int(gt)<<1)|int(unordered)
    exp=(a>>f)&((1<<e)-1);frac=a&((1<<f)-1)
    classify=(int(ka=='zero')<<4)|(int(exp==0 and frac!=0)<<3)|(int(0<exp<(1<<e)-1)<<2)|(int(ka=='inf')<<1)|int(ka=='nan')
    return [a,b]+[reference(op,a,b,e,f) for op in range(4)]+[compare,classify]

manifest=[]
for e,f in ((3,2),(5,10),(8,23)):
    w=1+e+f;mask=(1<<w)-1;sign=1<<(w-1);inf=((1<<e)-1)<<f;bias=(1<<(e-1))-1
    positive=[0,1,2,(1<<f)-1,1<<f,(1<<f)+1,(bias<<f)-1,bias<<f,(bias<<f)+1,inf-1,inf,inf+1,inf|(1<<(f-1))]
    edges=positive+[x|sign for x in positive]
    pairs=[(a,b) for a in edges for b in edges]
    rng=random.Random(0xCAD+e+f)
    if w<=6:pairs=[(a,b) for a in range(1<<w) for b in range(1<<w)]
    elif w==16:
        pairs.extend((a,(a*40503+0x16ad)&mask) for a in range(1<<w))
        pairs.extend((rng.getrandbits(w),rng.getrandbits(w)) for _ in range(4096))
    else:pairs.extend((rng.getrandbits(w),rng.getrandbits(w)) for _ in range(16000))
    path=OUT/f'fp_{e}_{f}.txt'
    with path.open('w',encoding='ascii') as stream:
        for a,b in pairs:stream.write(' '.join(f'{x:x}' for x in row(a,b,e,f))+'\n')
    manifest.append(dict(e=e,f=f,cases=len(pairs),operations=4,oracle='fractions.Fraction, exact round-to-nearest-even'))
# Cross-check binary16 oracle against Python's separately implemented half pack.
rng=random.Random(191)
for _ in range(2000):
    a=rng.randrange(65536);b=rng.randrange(65536)
    av=struct.unpack('>e',a.to_bytes(2,'big'))[0];bv=struct.unpack('>e',b.to_bytes(2,'big'))[0]
    for op,value in ((0,av+bv),(1,av-bv),(2,av*bv)):
        if value!=value:expected=0x7e00
        else:
            try:expected=int.from_bytes(struct.pack('>e',value),'big')
            except OverflowError:expected=0xfc00 if value<0 else 0x7c00
        assert reference(op,a,b,5,10)==expected
(ROOT/'vector_manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('Generated exact floating-point vectors: '+str(manifest),flush=True)
