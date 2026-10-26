"""Restore every differing Terrain property from a pinned checkpoint into a NEW file."""
import argparse, hashlib, json, struct
from pathlib import Path
from package_free_climb import Place
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('source',type=Path);p.add_argument('reference',type=Path);p.add_argument('destination',type=Path)
p.add_argument('--zstd-dll',type=Path,required=True);a=p.parse_args()
assert not a.destination.exists(), 'Destination must be new'
s=Place(a.source.read_bytes(),a.zstd_dll);r=Place(a.reference.read_bytes(),a.zstd_dll)
def terrain(place):
 return {c['prop']:c for c in place.chunks if c.get('prop') and place.classes[c['cid']]['name']=='Terrain'}
st,rt=terrain(s),terrain(r);assert st.keys()==rt.keys()
changed={name for name in st if st[name]['raw'][4:]!=rt[name]['raw'][4:]}
replacements={}
for name in changed:
 raw=st[name]['raw'][:4]+rt[name]['raw'][4:]
 replacements[id(st[name])]=struct.pack('<4sIII',b'PROP',0,len(raw),0)+raw
output=s.header+b''.join(replacements.get(id(c),c['original']) for c in s.chunks)
d=Place(output,a.zstd_dll)
assert all(terrain(d)[n]['raw'][4:]==rt[n]['raw'][4:] for n in rt)
assert len(s.chunks)==len(d.chunks)
for before,after in zip(s.chunks,d.chunks):
 if id(before) not in replacements: assert before['original']==after['original']
with a.destination.open('xb') as f:f.write(output)
report={'source':str(a.source),'reference':str(a.reference),'output':str(a.destination),
 'sha256':hashlib.sha256(output).hexdigest(),'changed_properties':sorted(changed),
 'terrain_properties_exact':len(rt),'other_chunks_preserved':len(s.chunks)-len(changed)}
a.destination.with_suffix('.terrain-audit.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
