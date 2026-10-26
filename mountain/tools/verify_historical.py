from quality_session import *
import xml.etree.ElementTree as ET
from collections import Counter

def fingerprint(s):
    b=s.replace('\r\n','\n').strip().encode();h=0
    for c in b:h=(h*31+c)%2147483647
    return {'hash':h,'length':len(b)}

reports=[]
for key,filename in [('oldBaseline','ClimbCollect.FreeClimb.Baseline01.rbxlx'),('oldGeometry','ClimbCollect.FreeClimb.Geometry01.rbxlx'),('oldReview01','ClimbCollect.FreeClimb.Review01.rbxl')]:
    p=Path('C:/Users/HOME!/Desktop/climb-collect-free-climb-build/outputs')/filename
    raw=p.read_bytes();sources={};classes=Counter()
    if p.suffix=='.rbxl':
        place=Place(raw,DLL)
        for r,i in place.instances.items():
            classes[i['class']]+=1
            if 'Source' in i:sources[place.paths[r]]=fingerprint(i['Source'])
    else:
        def walk(item,prefix):
            props=item.find('Properties');name=props.find("*[@name='Name']").text
            path=prefix+'.'+name if prefix else name;classes[item.attrib['class']]+=1
            s=props.find("*[@name='Source']")
            if s is not None:sources[path]=fingerprint(s.text or '')
            for c in item.findall('Item'):walk(c,path)
        for item in ET.fromstring(raw).findall('Item'):walk(item,'')
    live=json.loads((EVIDENCE/(key+'.json')).read_text())
    differences=[name for name in sources if sources[name]!=live['sources'].get(name)]
    parts=['Part','MeshPart','WedgePart','CornerWedgePart','SpecialMesh','TrussPart','ProximityPrompt','SpawnLocation']
    counts={c:[classes[c],live['classes'].get(c,0)] for c in parts}
    report={'name':filename,'sha256':sha(raw),'source_matches':not differences,'differences':differences,'geometry_class_counts':counts,'verified':not differences and all(a==b for a,b in counts.values())}
    if report['verified']:
        target=EVIDENCE/'baseline'/filename
        if not target.exists():target.write_bytes(raw)
        assert sha(target.read_bytes())==sha(raw)
        report['verified_copy']=str(target)
    reports.append(report)
(EVIDENCE/'historical-close-verification.json').write_text(json.dumps(reports,indent=2))
print(json.dumps(reports,indent=2))
