"""Read-only saved-place and preservation audit for Step 2."""
import sys, json, hashlib, struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path[:0]=[str(ROOT/'redesign/step2/audit-deps'),str(ROOT/'tools')]
from rbxl_audit import chunks,rstr
folder=ROOT/'redesign/step2'
place=folder/'MountainEmpire.Step2.Lodges.Review.rbxl'
classes={}
counts={}
names=[]
for kind,_,d in chunks(place.read_bytes()):
    if kind=='INST':
        cid=struct.unpack_from('<i',d)[0]
        cname,p=rstr(d,4)
        count=struct.unpack_from('<I',d,p+1)[0]
        classes[cid]=(cname,count)
        counts[cname]=count
    elif kind=='PROP':
        cid=struct.unpack_from('<i',d)[0]
        pname,p=rstr(d,4)
        typ=d[p];p+=1
        if pname=='Name' and typ==1:
            for _ in range(classes[cid][1]):
                name,p=rstr(d,p)
                names.append(name)
assert sum(counts.get(k,0) for k in ('Script','LocalScript','ModuleScript'))==0
assert counts['Part']+counts['WedgePart']+counts['SpawnLocation']==1171
assert all(f'Lodge_{i:02d}' in names for i in range(1,9))
assert names.count('CrestHanger')==8
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(place)==sha(folder/'MountainEmpire.Step2.Lodges.Checkpoint.rbxl')
old='0739107ebf395d077f4733d8410b23ce99d3cb080c3fa504ade5d79338f7daba'
for name in ['MountainEmpire.Step1.LargerPlots.rbxl','MountainEmpire.Step1.LargerPlots.Checkpoint.rbxl']:
    assert sha(ROOT/'redesign/step1-revision2'/name)==old
assert sha(folder/'MountainEmpire.Step2.BeforeLodges.Checkpoint.rbxl')==old
originals=json.loads((folder/'original-hashes.json').read_text(encoding='utf-8-sig'))
for item in originals:
    assert sha(Path(item['Path']))==item['Hash'].lower(),item['Path']
for name in ['MountainEmpire.Step1.Review.rbxl','MountainEmpire.Step1.FinalCheckpoint.rbxl']:
    assert sha(ROOT/'redesign/step1'/name)=='e9b6773cbae26848e0592c0c862d00f28d2af690dcfcac7bcda3364cacc315ff'
report={'savedBinaryVerified':True,'bytes':place.stat().st_size,'sha256':sha(place),
        'lodges':8,'parts':1171,'scripts':0,'originalRootPlacesUnchanged':len(originals),
        'step1ReviewAndRevision2Unchanged':True,'checkpointIdentical':True,'classes':counts}
(folder/'saved-file-audit.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({k:v for k,v in report.items() if k!='classes'},indent=2))

