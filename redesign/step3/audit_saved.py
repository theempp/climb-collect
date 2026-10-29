"""Read-only Step 3 binary, checkpoint and original-file preservation audit."""
import sys,json,hashlib,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path[:0]=[str(ROOT/'redesign/step2/audit-deps'),str(ROOT/'tools')]
from rbxl_audit import chunks,rstr
folder=ROOT/'redesign/step3'
place=folder/'MountainEmpire.Step3.Environment.Review.rbxl'
classes={}; counts={}; names=[]; terrain_bytes=0
for kind,_,d in chunks(place.read_bytes()):
    if kind=='INST':
        cid=struct.unpack_from('<i',d)[0]; cname,p=rstr(d,4)
        count=struct.unpack_from('<I',d,p+1)[0]
        classes[cid]=(cname,count); counts[cname]=count
    elif kind=='PROP':
        cid=struct.unpack_from('<i',d)[0]; pname,p=rstr(d,4); typ=d[p];p+=1
        if pname=='Name' and typ==1:
            for _ in range(classes[cid][1]):
                name,p=rstr(d,p); names.append(name)
        if pname=='SmoothGrid': terrain_bytes=len(d)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert sum(counts.get(k,0) for k in ('Script','LocalScript','ModuleScript'))==0
part_count=sum(counts.get(k,0) for k in ('Part','WedgePart','CornerWedgePart','SpawnLocation'))
live=json.loads((folder/'geometry-audit.json').read_text())
assert part_count==live['parts'],(part_count,live['parts'])
assert all(f'Lodge_{i:02d}' in names for i in range(1,9))
assert names.count('CrestHanger')==8
assert 'AlpineEnvironment_Step3' in names and not any(n=='MountainPeakMassing' for n in names)
assert terrain_bytes>1000
assert sha(place)==sha(folder/'MountainEmpire.Step3.Environment.Checkpoint.rbxl')
step2hash='51c65eb2e6eddb94473e46b2d25d9631b912259f599b8313566d9d3d0234b597'
for name in ['MountainEmpire.Step2.Lodges.Review.rbxl','MountainEmpire.Step2.Lodges.Checkpoint.rbxl']:
    assert sha(ROOT/'redesign/step2'/name)==step2hash
assert sha(folder/'MountainEmpire.Step3.BeforeEnvironment.Checkpoint.rbxl')==step2hash
originals=json.loads((ROOT/'redesign/step2/original-hashes.json').read_text(encoding='utf-8-sig'))
for item in originals: assert sha(Path(item['Path']))==item['Hash'].lower(),item['Path']
for name in ['MountainEmpire.Step1.Review.rbxl','MountainEmpire.Step1.FinalCheckpoint.rbxl']:
    assert sha(ROOT/'redesign/step1'/name)=='e9b6773cbae26848e0592c0c862d00f28d2af690dcfcac7bcda3364cacc315ff'
for name in ['MountainEmpire.Step1.LargerPlots.rbxl','MountainEmpire.Step1.LargerPlots.Checkpoint.rbxl']:
    assert sha(ROOT/'redesign/step1-revision2'/name)=='0739107ebf395d077f4733d8410b23ce99d3cb080c3fa504ade5d79338f7daba'
report={'savedBinaryVerified':True,'bytes':place.stat().st_size,'sha256':sha(place),'parts':part_count,'scripts':0,'terrainPropertyBytes':terrain_bytes,'checkpointIdentical':True,'originalRootPlacesUnchanged':len(originals),'steps1and2Unchanged':True,'classes':counts}
(folder/'saved-file-audit.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
