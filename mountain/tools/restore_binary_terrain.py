"""Restore only a baked review's SmoothGrid from its explicit immutable authority."""
import argparse,hashlib,json,struct
from pathlib import Path
from package_free_climb import Place
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('source',type=Path);p.add_argument('reference',type=Path);p.add_argument('destination',type=Path)
p.add_argument('--zstd-dll',type=Path,required=True)
a=p.parse_args()
assert not a.destination.exists(),'Use a fresh preservation checkpoint'
src=Place(a.source.read_bytes(),a.zstd_dll);ref=Place(a.reference.read_bytes(),a.zstd_dll)
def grids(place):
 return [c for c in place.chunks if c.get('prop')=='SmoothGrid' and place.classes[c['cid']]['name']=='Terrain']
s,r=grids(src),grids(ref);assert len(s)==len(r)==1
raw=s[0]['raw'][:4]+r[0]['raw'][4:]
replacement=struct.pack('<4sIII',b'PROP',0,len(raw),0)+raw
output=src.header+b''.join(replacement if c is s[0] else c['original'] for c in src.chunks)
dst=Place(output,a.zstd_dll)
for before,after in zip(src.chunks,dst.chunks):
 if before is not s[0]: assert before['original']==after['original'],'Non-terrain chunk changed'
assert grids(dst)[0]['raw'][4:]==r[0]['raw'][4:]
with a.destination.open('xb') as target: target.write(output)
report=dict(source=str(a.source),reference=str(a.reference),output=str(a.destination),
 output_sha256=hashlib.sha256(output).hexdigest(),changed_chunks=1,
 terrain_payload_sha256=hashlib.sha256(r[0]['raw'][4:]).hexdigest(),other_chunks_preserved=len(src.chunks)-1)
a.destination.with_suffix('.terrain-audit.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
