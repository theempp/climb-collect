from pathlib import Path
import json,hashlib,sys
root=Path(__file__).resolve().parents[1]/'evidence/fairground_2026-10-22'
def normalize(p):
 d=json.loads(p.read_text(encoding='utf8'))
 if 'parts' in d:
  merged={}
  for part in d['parts']:
   for k,v in json.loads((root/(part+'.json')).read_text(encoding='utf8')).items():
    if isinstance(v,list):merged.setdefault(k,[]).extend(v)
    else:merged[k]=v
  d=merged
 for k,v in d.items():
  if isinstance(v,list):d[k]=sorted([json.dumps(x,sort_keys=True) for x in v])
 return d
a=normalize(root/'protected-baseline.json');b=normalize(root/'protected-review.json')
out={'unchanged':a==b,'changedRoots':[k for k in a if a[k]!=b.get(k)],'roots':list(a),'properties':'geometry, appearance, asset IDs, attributes, tags, script/value/link properties; original mountain traversal definitions'}
if len(sys.argv)>1:
 place=Path(sys.argv[1]);out['checkedPlace']=str(place.resolve());out['checkedPlaceSha256']=hashlib.sha256(place.read_bytes()).hexdigest()
(root/'protected-verification.json').write_text(json.dumps(out,indent=2));print(json.dumps(out,indent=2));raise SystemExit(0 if a==b else 1)
