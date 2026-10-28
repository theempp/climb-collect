"""Run every CLI suite (Luau + Python wrappers) and compile every runtime source. Prints a one-line summary."""
from pathlib import Path
import os, subprocess, sys

ROOT = Path(__file__).resolve().parents[1]
CLI_DIR = Path(os.environ.get('LUAU_DIR', str(Path.home() / 'Desktop/climb&collect/tools/.luau')))
LUAU, COMPILE = CLI_DIR / 'luau.exe', CLI_DIR / 'luau-compile.exe'
# Suites whose standalone .luau needs a Python service wrapper (documented since PhoneCandidate02).
WRAPPED = {'combat_raids', 'run_persistence'}
env = dict(os.environ, LUAU_CLI=str(LUAU))
passed, failed = [], []
for f in sorted((ROOT / 'tests').glob('*.luau')):
    if f.stem in WRAPPED:
        continue
    r = subprocess.run([str(LUAU), f.name], cwd=f.parent, capture_output=True, text=True, timeout=600)
    (passed if r.returncode == 0 else failed).append((f.name, (r.stdout + r.stderr).strip().splitlines()[-1:] or ['']))
for f in sorted((ROOT / 'tests').glob('run_*.py')):
    r = subprocess.run([sys.executable, str(f)], cwd=ROOT.parent, capture_output=True, text=True, timeout=900, env=env)
    (passed if r.returncode == 0 else failed).append((f.name, (r.stdout + r.stderr).strip().splitlines()[-1:] or ['']))
bad = []
srcs = [p for d in ('server', 'shared', 'client', 'world', 'v1') if (ROOT / d).exists() for p in (ROOT / d).rglob('*.luau')]
for p in srcs:
    r = subprocess.run([str(COMPILE), '--null', str(p)], capture_output=True, text=True)
    if r.returncode != 0:
        bad.append((p.relative_to(ROOT), r.stderr.strip()[:200]))
for name, tail in passed:
    print('PASS', name, '|', tail[0][:120])
for name, tail in failed:
    print('FAIL', name, '|', tail[0][:300])
for p, e in bad:
    print('COMPILE FAIL', p, e)
print(f'SUMMARY suites {len(passed)}/{len(passed)+len(failed)} pass; compiled {len(srcs)-len(bad)}/{len(srcs)}')
sys.exit(1 if failed or bad else 0)
