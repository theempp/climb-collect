"""Verify the separately saved compact review; never mutate the place."""
from pathlib import Path
import json, hashlib, sys
from package_free_climb import Place, runtime_sources
from quality_verify_place import source_map, normal, terrain, DLL
ROOT=Path(__file__).resolve().parents[2]
EV=ROOT/'evidence/compact_mountain_2026-10-26'
path=ROOT/'outputs'/(sys.argv[1] if len(sys.argv)>1 else 'ClimbCollect.CompactMountain.Review01.rbxl')
raw=path.read_bytes(); p=Place(raw,DLL)
actual=source_map(p); expected=runtime_sources()
base=Place((ROOT/'outputs/ClimbCollect.MountainQuality.Review06.rbxl').read_bytes(),DLL)
old=source_map(base)
mismatches=[n for n,s in expected.items() if n not in actual or normal(s)!=normal(actual[n])]
historic=[n for n in old if n not in expected and (n not in actual or normal(old[n])!=normal(actual[n]))]
temporary=[v for v in p.paths.values() if any(x in v for x in ('MountainQA','ArrivalMissing','ArrivalAssetFailure','ArrivalMissingBootstrap'))]
r={'place':str(path),'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw),'runtime_sources':len(expected),'saved_sources':len(actual),'source_mismatches':mismatches,'historical_source_drift':historic,'temporary_qa':temporary,'terrain_properties':terrain(p)}
(EV/('saved-file-integrity.json' if path.name.endswith('Review01.rbxl') else path.stem+'.integrity.json')).write_text(json.dumps(r,indent=2))
print(json.dumps(r,indent=2));assert not mismatches and not historic and not temporary
