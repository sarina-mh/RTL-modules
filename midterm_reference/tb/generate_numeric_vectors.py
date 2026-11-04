"""Independent math/cmath references for fixed-point numerical examples."""
from pathlib import Path
import cmath,json,math,random
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'build/vectors';OUT.mkdir(parents=True,exist_ok=True)
manifest=[]
def word(x,w):return f'{x&((1<<w)-1):x}'
for w,q in ((16,12),(32,20)):
    scale=1<<q;rng=random.Random(451+q);maximum=(1<<(w-1))-1
    cases=[]
    for t in range(260):
        if t<9:
            xe=(-scale,-scale//2,-1,0,1,scale//2,scale,scale-1,-scale+1)[t]
            xt=(-math.floor(math.pi*scale),-scale,-1,0,1,scale,math.floor(math.pi*scale),scale//2,-scale//2)[t]
            xw=(-4*scale,-scale,-1,0,1,scale,4*scale,2*scale,-2*scale)[t]
        else:xe=rng.randint(-scale,scale);xt=rng.randint(-math.floor(math.pi*scale),math.floor(math.pi*scale));xw=rng.randint(-4*scale,4*scale)
        exp=round(math.exp(xe/scale)*scale);sin=round(math.sin(xt/scale)*scale);cos=round(math.cos(xt/scale)*scale)
        wide=round(math.exp(xw/scale)*scale);ov=int(wide>maximum);wide=min(wide,maximum)
        cases.append([xe,xt,xw,exp,sin,cos,wide,ov])
    (OUT/f'taylor_{w}_{q}.txt').write_text('\n'.join(' '.join(word(x,w) for x in row) for row in cases)+'\n',encoding='ascii')
    manifest.append(dict(kind='taylor/exp',w=w,q=q,cases=len(cases),tolerance_lsb=64))
for n,q,inverse in ((1,12,0),(4,12,1),(8,20,0),(16,12,0),(64,20,0)):
    w=32;scale=1<<q;rng=random.Random(451+n+q+inverse);rows=[]
    for t in range(24):
        data=[]
        for j in range(n):
            if t==0:r=i=0
            elif t==1:r=(scale if j==0 else 0);i=0
            elif t==2:r=scale//4;i=-scale//8
            elif t==3:r=round(math.cos(2*math.pi*j/n)*scale/4);i=0
            else:r=rng.randint(-scale//2,scale//2);i=rng.randint(-scale//2,scale//2)
            data.append(complex(r/scale,i/scale))
        transformed=[sum(data[j]*cmath.exp((1 if inverse else -1)*2j*math.pi*k*j/n) for j in range(n))/(n if inverse else 1) for k in range(n)]
        # One flat row per case: all real inputs, imaginary inputs, then references.
        row=[round(x.real*scale) for x in data]+[round(x.imag*scale) for x in data]+[round(x.real*scale) for x in transformed]+[round(x.imag*scale) for x in transformed]
        rows.append(' '.join(word(x,w) for x in row))
    (OUT/f'fourier_{n}_{q}_{inverse}.txt').write_text('\n'.join(rows)+'\n',encoding='ascii')
    manifest.append(dict(kind='DFT/FFT',n=n,q=q,inverse=inverse,cases=len(rows),tolerance_lsb=4*n+8))
for h,q in ((0,12),(3,20),(8,12)):
    w=32;scale=1<<q;rng=random.Random(999+h+q);rows=[]
    for phase in range(64):
        cs=[rng.randint(-scale//2,scale//2) for _ in range(h+1)]
        ss=[rng.randint(-scale//2,scale//2) for _ in range(h+1)]
        angle=2*math.pi*phase/64
        expected=cs[0]+sum(cs[j]*math.cos(j*angle)+ss[j]*math.sin(j*angle) for j in range(1,h+1))
        rows.append(' '.join(word(x,w) for x in [phase]+cs+ss+[round(expected)]))
    (OUT/f'series_{h}_{q}.txt').write_text('\n'.join(rows)+'\n',encoding='ascii')
    manifest.append(dict(kind='Fourier series',harmonics=h,q=q,cases=64,tolerance_lsb=4*h+4))
rng=random.Random(987);rows=[]
for t in range(1200):
    w=16;mask=(1<<w)-1;x=t if t<256 else rng.randrange(1<<w);a=rng.randrange(1<<w);exponent=rng.randrange(256)
    n=t if t<256 else rng.randrange(64)
    fact=math.factorial(n);f0,f1=0,1
    for _ in range(n):f0,f1=f1,f0+f1
    row=[x,a,exponent,n,fact&mask,int(fact>mask),f0&mask,int(f0>mask),pow(a,exponent,1<<w),math.isqrt(x)]
    rows.append(' '.join(word(v,64) for v in row))
(OUT/'exam_scalar.txt').write_text('\n'.join(rows)+'\n',encoding='ascii')
manifest.append(dict(kind='exam_scalar',cases=len(rows),width=16))
(ROOT/'numeric_vector_manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('Generated numeric and exam vectors: '+str(manifest),flush=True)
