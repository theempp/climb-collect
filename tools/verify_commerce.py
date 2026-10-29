"""Compile manifest sources; optionally reconcile a saved place and unchanged terrain.
Run from project root: python tools/verify_commerce.py [saved.rbxl]
"""
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools' / '.audit-deps'))
from rbxl_audit import chunks, rstr

def normalize(s):
    return '\n'.join(line.rstrip() for line in s.replace('\r\n', '\n').split('\n')).rstrip()

def properties(path):
    classes, sizes, sources, terrain = {}, {}, [], {}
    for tag, _, data in chunks(path.read_bytes()):
        if tag == 'INST':
            cid = struct.unpack_from('<i', data)[0]
            name, p = rstr(data, 4)
            classes[cid] = name
            sizes[cid] = struct.unpack_from('<I', data, p + 1)[0]
        elif tag == 'PROP':
            cid = struct.unpack_from('<i', data)[0]
            prop, p = rstr(data, 4)
            kind, p = data[p], p + 1
            if classes.get(cid) == 'Terrain':
                terrain[prop] = hashlib.sha256(data[p:]).hexdigest()
            if prop == 'Source' and kind == 1:
                for _ in range(sizes[cid]):
                    s, p = rstr(data, p)
                    sources.append(normalize(s))
    return set(sources), terrain

manifest = re.findall(r'\{ "([^"]+\.luau)", "([^"]+)", "([^"]+)", "([^"]+)" \}', (ROOT / 'tools/sync_core.luau').read_text())
files = sorted(set(row[0] for row in manifest) | {'src/runtime/TraverseClient.client.luau'})
failures = []
for name in files:
    p = subprocess.run([str(ROOT / 'tools/.luau/luau-compile.exe'), '--null', str(ROOT / name)], capture_output=True, text=True)
    if p.returncode:
        failures.append({'file': name, 'output': p.stdout + p.stderr})
report = {'compiled': len(files), 'compileFailures': failures, 'manifestSources': len(manifest)}
if len(sys.argv) > 1:
    saved = ROOT / sys.argv[1]
    sources, terrain = properties(saved)
    _, baseline_terrain = properties(ROOT / 'evidence/commerce_2026-10-22/ClimbAndCollect.BeforeCommerce.rbxl')
    missing = [name for name, *_ in manifest if normalize((ROOT / name).read_text(encoding='utf-8')) not in sources]
    report.update(saved=str(saved), bytes=saved.stat().st_size, sha256=hashlib.sha256(saved.read_bytes()).hexdigest(), missingSavedSources=missing,
                  unchangedTerrain=terrain == baseline_terrain, terrainPropertiesCompared=sorted(terrain))
out = ROOT / 'evidence/commerce_2026-10-22' / ('saved-verification.json' if len(sys.argv) > 1 else 'compile.json')
out.write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps(report, indent=2))
sys.exit(bool(failures or report.get('missingSavedSources') or report.get('unchangedTerrain') is False))
