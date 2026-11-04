"""Build a source-only GitHub-ready archive after successful verification."""
from pathlib import Path
import hashlib,json,zipfile
from test_config import SUITES
from catalog import entries
ROOT=Path(__file__).resolve().parent
results=json.loads((ROOT/'results.json').read_text())
assert {item['name'] for item in results}==set(SUITES) and all(item['passed'] for item in results)
lint=json.loads((ROOT/'lint_results.json').read_text())
assert lint['passed'] and lint['modules']==len(entries())
hashes=json.loads((ROOT/'source_hashes.json').read_text())
actual={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes().replace(b'\r\n',b'\n')).hexdigest() for folder in ('rtl','tb') for p in sorted((ROOT/folder).glob('*')) if p.is_file()}
assert hashes==actual,'Sources changed after regression; rerun tests before packaging'
target=ROOT.parent/'midterm_reference.zip'
files=[p for p in ROOT.rglob('*') if p.is_file() and not {'build','__pycache__'}.intersection(p.relative_to(ROOT).parts)]
with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(files):archive.write(path,Path(ROOT.name)/path.relative_to(ROOT))
with zipfile.ZipFile(target) as archive:
    assert archive.testzip() is None
    assert len(archive.namelist())==len(files)
print(f'Created {target}: {len(files)} files, {target.stat().st_size} bytes, CRC verified')
