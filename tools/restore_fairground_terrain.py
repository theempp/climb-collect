"""Preserve the exact baseline terrain serialization in this named local review file.

Studio reserialized SmoothGrid on save. This narrowly replaces that one property
chunk, after requiring every other Terrain property to match. No voxel generation.
The pre-restoration review file is retained in the evidence directory.
"""
from pathlib import Path
import hashlib
import json
import shutil
import struct
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools/.audit-deps'))
import zstandard
from rbxl_audit import chunks, rstr

EVIDENCE = ROOT / 'evidence/fairground_2026-10-22'
BASE = ROOT / 'ClimbAndCollect.BeforeFairground.rbxl'
REVIEW = ROOT / 'ClimbAndCollect.Fairground.Review.rbxl'

def terrain(buf):
    classes, props = {}, {}
    for tag, _, data in chunks(buf):
        if tag == 'INST':
            classes[struct.unpack_from('<i', data)[0]] = rstr(data, 4)[0]
        elif tag == 'PROP':
            cid = struct.unpack_from('<i', data)[0]
            name, at = rstr(data, 4)
            if classes[cid] == 'Terrain':
                props[name] = (data, data[at:])
    return props

before, current = BASE.read_bytes(), REVIEW.read_bytes()
a, b = terrain(before), terrain(current)
changed = [key for key in set(a) | set(b) if a.get(key, (None,None))[1] != b.get(key, (None,None))[1]]
assert not (set(changed) - {'SmoothGrid'}), changed
if changed:
    backup = EVIDENCE / 'ClimbAndCollect.Review.BeforeTerrainRestore.rbxl'
    if not backup.exists():
        shutil.copy2(REVIEW, backup)
    out, pos = bytearray(current[:32]), 32
    replaced = 0
    for tag, _, data in chunks(current):
        clen, ulen, _ = struct.unpack_from('<III', current, pos + 4)
        end = pos + 16 + (clen or ulen)
        if tag == 'PROP' and data == b['SmoothGrid'][0]:
            payload = data[:4] + a['SmoothGrid'][0][4:]
            compressed = zstandard.ZstdCompressor(level=3).compress(payload)
            out.extend(b'PROP' + struct.pack('<III', len(compressed), len(payload), 0) + compressed)
            replaced += 1
        else:
            out.extend(current[pos:end])
        pos = end
    assert replaced == 1
    assert {k:v[1] for k,v in terrain(bytes(out)).items()} == {k:v[1] for k,v in a.items()}
    REVIEW.write_bytes(out)
    report = {'restoredProperty':'Terrain.SmoothGrid','otherTerrainPropertiesUnchanged':True,
              'backup':str(backup),'baselineSha256':hashlib.sha256(before).hexdigest(),
              'reviewSha256':hashlib.sha256(out).hexdigest(),
              'note':'Exact original serialized terrain restored after Studio save; repeat verification after future Studio saves.'}
    (EVIDENCE / 'terrain-restoration.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(report,indent=2))
else:
    print('All serialized Terrain properties already match the backup.')
