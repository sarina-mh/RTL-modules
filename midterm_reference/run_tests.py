"""Run with py run_tests.py (Windows) or python3 run_tests.py (Linux).
The -O2 make overrides avoid this machine's GCC16/libstdc++ -Os link failure.
"""
from pathlib import Path
import argparse, hashlib, json, subprocess, sys, time
from environment import command
from test_config import SUITES
HERE=Path(__file__).resolve().parent
parser=argparse.ArgumentParser()
parser.add_argument('--only',nargs='*')
args=parser.parse_args()
build=HERE/'build';build.mkdir(exist_ok=True)
results=[]
names=args.only or SUITES
if set(names)-set(SUITES):parser.error('Unknown suite')
if 'floating_point' in names:subprocess.run([sys.executable,str(HERE/'tb/generate_vectors.py')],check=True)
if {'numerical','exam_algorithms'}.intersection(names):
    subprocess.run([sys.executable,str(HERE/'tb/generate_numeric_vectors.py')],check=True)
for name in names:
    top='tb_'+name
    script=('set -e; verilator --language 1800-2017 --cc --main --exe --timing -Wall -Wno-fatal '
            f'--top-module {top} --Mdir build/{name} tb/{top}.sv rtl/*.v; '
            f'make -C build/{name} -f V{top}.mk OPT_GLOBAL=-O2 OPT_FAST=-O2 -j4; '
            f'build/{name}/V{top}')
    print('Building/running '+name+'...',flush=True);start=time.monotonic()
    proc=subprocess.run(command(script),stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf-8',errors='replace')
    (build/f'{name}.txt').write_text(proc.stdout,encoding='utf-8')
    output=[line for line in proc.stdout.splitlines() if line.startswith('PASS') or '%Error' in line or 'Assertion failed' in line]
    record=dict(name=name,passed=proc.returncode==0 and f'PASS {top}' in proc.stdout,seconds=round(time.monotonic()-start,2),output=output)
    results.append(record);print(json.dumps(record),flush=True)
    (HERE/'results.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
    if not record['passed']:print(proc.stdout[-5000:]);sys.exit(1)
hashes={p.relative_to(HERE).as_posix():hashlib.sha256(p.read_bytes().replace(b'\r\n',b'\n')).hexdigest() for folder in ('rtl','tb') for p in sorted((HERE/folder).glob('*')) if p.is_file()}
(HERE/'source_hashes.json').write_text(json.dumps(hashes,indent=2),encoding='utf-8')
print('All requested suites passed.')
