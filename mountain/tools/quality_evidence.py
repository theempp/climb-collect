"""Canonicalize Studio snapshots and compare protected state without trusting item order."""
import argparse, hashlib, json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
EV=ROOT/'evidence/mountain_quality_2026-10-26'
def canonical(x):
    if isinstance(x,dict):
        # MCP's JSON formatter may encode arrays as numeric-key maps; HTTP JSON does not.
        if x and all(k.isdigit() for k in x):
            return [canonical(x[k]) for k in sorted(x,key=int)]
        out={k:canonical(v) for k,v in x.items()}
        if 'children' in out: out['children'].sort(key=lambda y:json.dumps(y,sort_keys=True))
        return out
    if isinstance(x,list): return [canonical(v) for v in x]
    return x
def load(name):
    path=EV/(name+'.json')
    if path.exists(): return canonical(json.loads(path.read_text()))
    parts=sorted(EV.glob(name+'-*.json'),key=lambda p:int(p.stem.rsplit('-',1)[1]))
    assert parts,name
    result=canonical(json.loads(''.join(json.loads(p.read_text())['data'] for p in parts)))
    if isinstance(result.get('protected',{}).get('ImpossibleMountain'),list):
        result['protected']['ImpossibleMountain'].sort(key=lambda y:json.dumps(y,sort_keys=True))
    path.write_text(json.dumps(result,indent=2));return result
def digest(v):return hashlib.sha256(json.dumps(v,sort_keys=True,separators=(',',':')).encode()).hexdigest()
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('name');p.add_argument('--compare');a=p.parse_args()
    current=load(a.name)
    if a.compare:
        baseline=load(a.compare);result={'baseline':a.compare,'current':a.name,'protected_equal':digest(current['protected'])==digest(baseline['protected']),'lighting_equal':current['lighting']==baseline['lighting'],'protected_sha256':digest(current['protected']),'sections':current['sections'],'counts':current['counts']}
        (EV/(a.name+'-preservation.json')).write_text(json.dumps(result,indent=2))
        print(json.dumps(result,indent=2));assert result['protected_equal'] and result['lighting_equal']
    else:print(json.dumps({'name':a.name,'protected_sha256':digest(current['protected']),'sections':current['sections']},indent=2))
