"""Verify current runtime sources and every Terrain property against pinned authority."""
import argparse,hashlib,json
from pathlib import Path
from package_free_climb import Place,runtime_sources
ROOT=Path(__file__).resolve().parents[2];EV=ROOT/'evidence/mountain_quality_2026-10-26'
DLL=Path('C:/Program Files/Git/mingw64/bin/libzstd.dll')
def sha(data):return hashlib.sha256(data).hexdigest()
def source_map(place):return {place.paths[r]:i['Source'] for r,i in place.instances.items() if 'Source' in i}
def terrain(place):return {c['prop']:sha(c['raw'][4:]) for c in place.chunks if c.get('prop') and place.classes[c['cid']]['name']=='Terrain'}
def normal(s):return s.replace('\r\n','\n').strip()
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('place',type=Path);p.add_argument('--name',default='final-file-integrity');a=p.parse_args()
 raw=a.place.read_bytes();current=Place(raw,DLL);baseline=Place((EV/'baseline/Review03.SprintEntrances.rbxl').read_bytes(),DLL)
 source=source_map(current);old=source_map(baseline);expected=runtime_sources()
 mismatches=[name for name,code in expected.items() if name not in source or normal(source[name])!=normal(code)]
 changed=[name for name in old if name not in source or normal(source[name])!=normal(old[name])]
 allowed={'ServerStorage.MountainWorld.FreeClimb'}
 terrain_before,terrain_after=terrain(baseline),terrain(current)
 drift=[name for name in terrain_before.keys()|terrain_after.keys() if terrain_before.get(name)!=terrain_after.get(name)]
 temporary=[path for path in current.paths.values() if 'MountainQA' in path or 'FreeClimbQA' in path or 'Acceptance' in path]
 result={'place':str(a.place.resolve()),'sha256':sha(raw),'bytes':len(raw),'instances':len(current.instances),'runtime_sources':len(expected),'source_mismatches':mismatches,'changed_baseline_sources':changed,'new_sources':sorted(set(source)-set(old)),'terrain_properties':len(terrain_after),'terrain_drift':drift,'terrain_payload_sha256':terrain_after.get('SmoothGrid'),'temporary_qa':temporary}
 (EV/(a.name+'.json')).write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))
 assert not mismatches and set(changed)<=allowed and not drift and not temporary
