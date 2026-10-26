"""Review03 evidence audit. Historical Review01 delivery evidence is never overwritten."""
import argparse, hashlib, json
from pathlib import Path
from collections import Counter
from PIL import Image
from quality_evidence import EV, ROOT, load, canonical, digest
from quality_compare_scene import normalized, compare

def read(name):
 r=load(name)
 if isinstance(r,dict) and 'content' in r:
  assert not r.get('isError');r=canonical(json.loads(next(c['text'] for c in r['content'] if c['type']=='text')))
 return r
def write(name,value):
 (EV/(name+'.json')).write_text(json.dumps(value,indent=2),encoding='utf-8')
 return value
def static():
 a,b=normalized(read('review03-scene')),normalized(read('review03-final-cold-scene'))
 errors,delta=compare(a,b);assert not errors
 old=read('colliders-v2');regions={r['name'].split('.')[2] for r in old}
 def key(path,cls,size,cf):return (path,cls,tuple(round(n,5) for n in size),tuple(round(n,5) for n in cf))
 expected=Counter(key(r['name'],r['class'],r['size'],r['cf']) for r in old)
 actual=Counter(key(r['path'],r['class'],r['size'],r['cf']) for r in b if r['collide'] and r['path'].split('.')[2] in regions)
 assert actual==expected
 snapshot=read('review03-final-cold-snapshot');base=read('baseline-scene')
 assert digest(snapshot['protected'])==digest(base['protected']) and snapshot['lighting']==base['lighting']
 geometry=read('review03-final-cold-geometry');ground=read('review03-final-cold-grounding')
 assert geometry['passed'] and ground['passed']
 return write('review03-scene-audit',{'passed':True,'cold_scene_exact':a==b,'parts':len(b),'maximum_delta':delta,
  'regional_colliders_unchanged':sum(actual.values()),'protected_equal':True,'lighting_equal':True,
  'geometry_checks':geometry['checks'],'grounding_checks':ground['checked'],'grounding_maximum_error':ground['maximumError']})
def performance():
 old,a,b=(read('review03-performance-'+n) for n in ('old','new-a','new-b'))
 assert old['viewport']==a['viewport']==b['viewport'] and old['quality']==a['quality']==b['quality']
 assert not any(x['streaming'] for x in (old,a,b))
 rows=[]
 def passes(v):return {p['Name']:p['Sizes'] for p in v['render']['Children']}
 for ov,av,bv in zip(old['views'],a['views'],b['views']):
  assert ov['id']==av['id']==bv['id']
  op,ap,bp=map(passes,(ov,av,bv));ot=op['Opaque']['Triangles'];at=ap['Opaque']['Triangles'];bt=bp['Opaque']['Triangles']
  assert at<ot and bt<ot and abs(at-bt)/max(at,bt)<.03
  assert all(v['medianMs']<25 for v in (ov,av,bv))
  rows.append({'view':ov['id'],'old':ov,'new_a':av,'new_b':bv,'opaque_reduction_percent_range':[100*(1-max(at,bt)/ot),100*(1-min(at,bt)/ot)],
    'all_terrain_counts_match':op.get('Terrain')==ap.get('Terrain')==bp.get('Terrain')})
 return write('review03-performance-comparison',{'viewport':old['viewport'],'quality':old['quality'],'streaming':False,'frames_per_view':120,
  'method':'Same process and camera; swap scenery only, new-old-new. Foreground verified. Full residency; dynamic entities and terrain LOD can still vary.',
  'parts_old':old['parts'],'parts_new':a['parts'],'rows':rows,
  'limits':['60Hz-capped desktop; no FPS improvement or physical-device claim.',
   'Exclude totals where Terrain detail differs. Opaque counts isolate scenery more reliably.',
   'Final whole-view opaque counts repeat; draw calls vary and are not an optimization claim.',
   'Not directly comparable to historical 122270/307622 wide-view measurements.',
   'Background-throttled run retained in review03-performance-rejected.json.']})
def gallery():
 views=read('views');names=[v['id'] for v in views]
 phone=[f'phone-section-{k}-terrace' for k in range(1,7)]
 if all((EV/'review03-after'/(n+'.jpg')).exists() for n in phone):names+=phone
 records=[];cards=[]
 for name in names:
  sides=[];sizes=[]
  for side in ('before','after'):
   p=EV/('review03-'+side)/(name+'.jpg')
   with Image.open(p) as im:sizes.append(im.size);im.verify()
   records.append({'path':p.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'size':sizes[-1]})
   sides.append(f'<figure><figcaption>{"Review01" if side=="before" else "Review03"}</figcaption><img loading="lazy" src="review03-{side}/{name}.jpg"></figure>')
  assert sizes[0]==sizes[1]
  cards.append(f'<section><h2>{name}</h2><div>{"".join(sides)}</div></section>')
 html='''<!doctype html><meta charset="utf-8"><title>Mountain Review03 comparison</title><style>body{background:#141b21;color:#e6ecef;font:16px system-ui;margin:30px}h1{font-size:30px}section{margin:36px 0}section>div{display:grid;grid-template-columns:1fr 1fr;gap:14px}figure{margin:0}figcaption{padding:8px;background:#25313c}img{width:100%}p{max-width:1000px;line-height:1.6}</style><h1>Review01 → Review03</h1><p>Matched camera, field of view and viewport. All six sections, ascent / terrace / descent, and overall silhouette. The lower planting and simple accents reduce repeated small spheres; existing collision, terrain and silhouette are preserved. Broad ramp faces, oval rock repetition, sparse vegetation and abrupt terrace transitions remain visible art limitations. Phone images are Studio simulation, not physical-device performance.</p>'''+''.join(cards)
 (EV/'review03-comparison.html').write_text(html,encoding='utf-8')
 return write('review03-images',records)
def delivery():
 scene=static();perf=performance();images=gallery();integrity=read('review03-file-integrity')
 manifest=json.loads((ROOT/'design/mountain-quality-manifest.json').read_text(encoding='utf-8'))
 assert manifest['review']==integrity and manifest['helper_version']==3
 for name,sha in manifest['runtime_files'].items():assert hashlib.sha256((ROOT/name).read_text(encoding='utf-8').encode()).hexdigest()==sha
 assert hashlib.sha256((ROOT/'outputs/ClimbCollect.MountainQuality.Review01.rbxl').read_bytes()).hexdigest()=='c3000ce9b6eb626098089719d5fa30503f7947aeb2252d6f151cb1ec0edee680'
 idem=read('review03-idempotency');assert idem['version']==3 and idem['sameFolders'] and idem['partsUnchanged'] and idem['streaming'] and not idem['http']
 assert hashlib.sha256(Path(integrity['place']).read_bytes()).hexdigest()==integrity['sha256']
 assert not integrity['terrain_drift'] and not integrity['source_mismatches'] and not integrity['temporary_qa']
 raid=read('review03-cold-raid-and-hazards');walk=read('review03-observed-jump-traversal')
 assert raid['done'] and raid['passed'] and walk['done'] and walk['passed']
 jumps=[s for s in walk['log'] if s.get('jump')]
 assert len(jumps)==12 and all(s['jumpObserved'] and s['airborneObserved'] and s['landingObserved'] and s['maxUp']>10 for s in jumps)
 regression=read('review03-final-regression');assert len(regression['suites'])==26 and len(regression['compiles'])==77
 assert all(s['exit']==0 for s in regression['suites']+regression['compiles'])
 assert len(images)==52
 return write('review03-delivery-verification',{'passed':True,'review':integrity,'scene':scene,'image_pairs':len(images)//2,
  'raid_steps':len(raid['log']),'traversal_steps':len(walk['log']),'observed_keyboard_jumps':len(jumps),
  'regression_suites':26,'compiles':77,'idempotency':idem,'multiplayer':'Historical nine checks retained; no fresh multiplayer claim. All929 colliders and multiplayer runtime source unchanged.',
  'limitations':['Aesthetic acceptance unverified; art remains incomplete.','Physical-device performance and hosted save/network unverified.']})
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('mode',choices=['static','performance','gallery','delivery']);a=p.parse_args()
 r=globals()[a.mode]();print(json.dumps(r if a.mode=='static' else {'mode':a.mode,'passed':True},indent=2))
