"""Read-only comparison of art checkpoint against VerifiedTraversal gameplay surfaces."""
from pathlib import Path
from collections import Counter
import xml.etree.ElementTree as ET
import json,sys,hashlib,re

root=Path(__file__).resolve().parents[2]
baseline=root/'evidence/mountain_2026-10-24/ImpossibleMountain.VerifiedTraversal.rbxlx'
target=Path(sys.argv[1])

def props(item):
    return {p.get('name'):p for p in item.find('Properties')}

def value(p):
    if len(p): return tuple((c.tag,value(c)) for c in p)
    text=p.text or ''
    try: return round(float(text),3)
    except ValueError: return text

def snapshot(path):
    doc=ET.parse(path)
    world=next(i for i in doc.iter('Item') if props(i).get('Name') is not None and props(i)['Name'].text=='ImpossibleMountain')
    colliders=Counter();prompts=Counter()
    for item in world.iter('Item'):
        p=props(item)
        if p.get('CanCollide') is not None and p['CanCollide'].text=='true':
            fields=('Name','CFrame','size','CanCollide','CanQuery','Anchored','Material','Shape','Color3uint8')
            colliders[(item.get('class'),tuple((k,value(p[k])) for k in fields if k in p))]+=1
        if item.get('class')=='ProximityPrompt':
            # Presentation-only repair: ignore corrupt legacy separator glyphs, compare words.
            if 'ActionText' in p:
                p['ActionText'].text=' '.join(re.sub('[^A-Za-z0-9 ]','',p['ActionText'].text or '').split())
            prompts[tuple((k,value(v)) for k,v in sorted(p.items()) if k in ('Name','ActionText','HoldDuration','MaxActivationDistance','RequiresLineOfSight','Enabled'))]+=1
    return colliders,prompts

before,bp=snapshot(baseline);after,ap=snapshot(target)
assert before==after, f'Collider drift: removed {sum((before-after).values())}, added {sum((after-before).values())}'
assert bp==ap,'Prompt contract changed'
protected=json.loads((root/'evidence/mountain_2026-10-24/protected-before.json').read_text())
original=Path('C:/Users/HOME!/Desktop/climb&collect')
for rel,expected in protected.items():
    assert hashlib.sha256((original/rel).read_bytes()).hexdigest()==expected,rel
print(json.dumps({'baseline':str(baseline),'target':str(target),'unchanged_colliders':sum(before.values()),'unchanged_prompt_contracts':sum(bp.values()),'protected_places':len(protected)},indent=2))
