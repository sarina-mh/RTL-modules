"""Check every public module with strict Verilog-2005 parsing."""
import json,re,subprocess
from pathlib import Path
import sys
from environment import command
from catalog import entries,closure
ROOT=Path(__file__).resolve().parent
(ROOT/'build').mkdir(exist_ok=True)
rows=entries();modules=[r['module'] for r in rows]
script='#!/usr/bin/env bash\nset -euo pipefail\n'
script+='\n'.join('verilator --language 1364-2005 --lint-only -Wall -Wno-fatal --top-module '+name+' '+' '.join(closure(name,rows)) for name in modules)+'\n'
(ROOT/'build/lint_all.sh').write_text(script,encoding='utf-8',newline='\n')
result=subprocess.run(command('bash build/lint_all.sh'),stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf-8',errors='replace')
(ROOT/'build/lint.txt').write_text(result.stdout,encoding='utf-8')
bad=[s for s in result.stdout.splitlines() if any(x in s for x in ('%Error','Warning-LATCH','Warning-MULTIDRIVEN','Warning-UNOPTFLAT'))]
report=dict(modules=len(modules),passed=result.returncode==0 and not bad,errors=bad)
(ROOT/'lint_results.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report));sys.exit(0 if report['passed'] else 1)
