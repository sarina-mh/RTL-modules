"""Locate the reference root and construct a local Verilator shell command."""
from pathlib import Path
import os,shlex
HERE=Path(__file__).resolve().parent
def command(script):
    if os.name=='nt':
        bash=Path(os.environ.get('MSYS2_ROOT',r'C:\msys64'))/'usr/bin/bash.exe'
        if not bash.exists():raise RuntimeError('Install MSYS2 UCRT64 Verilator, GCC, make, Python; set MSYS2_ROOT for a custom location')
        cwd='/'+HERE.drive[0].lower()+HERE.as_posix()[2:]
        return [str(bash),'-lc','export PATH=/ucrt64/bin:/usr/bin:$PATH; export VERILATOR_ROOT=/ucrt64/share/verilator; cd '+shlex.quote(cwd)+'; '+script]
    return ['bash','-lc','cd '+shlex.quote(str(HERE))+'; '+script]
