"""Review04 evidence audit; does not modify historical delivery evidence."""
import argparse, hashlib, json
from collections import Counter
from pathlib import Path
from PIL import Image
from quality_evidence import EV, ROOT, load, digest, canonical
from quality_review03_delivery import read, write
from quality_compare_scene import normalized, compare

def static():
    a=normalized(read('review04-ready-quality_scene_fingerprint'))
    b=normalized(read('review04-cold-quality_scene_fingerprint'))
    errors,delta=compare(a,b);assert not errors,errors[:10]
    old=read('review03-final-cold-scene')
    def key(r):return (r['path'],r['class'],tuple(round(n,5) for n in r['size']),tuple(round(n,5) for n in r['cf']))
    expected=Counter(key(r) for r in old if r['collide'])
    actual=Counter(key(r) for r in b if r['collide'])
    assert expected==actual
    physics=read('review04-cold-physics');assert physics['passed'] and physics['checked']==996
    labels=read('review04-cold-label-audit');assert labels['count']==58 and not labels['errors']
    # Historical MCP text serialization corrupted bullets/arrows. Exact current labels
    # are checked against binary Review03 above; omit Text only from the old snapshot comparison.
    def without_text(x):
        if isinstance(x,dict):return {k:without_text(v) for k,v in x.items() if k!='Text'}
        if isinstance(x,list):return sorted((without_text(v) for v in x),key=lambda y:json.dumps(y,sort_keys=True))
        return x
    baseline=read('review03-final-cold-snapshot');snapshot=read('review04-cold-quality_snapshot')
    assert digest(without_text(baseline['protected']))==digest(without_text(snapshot['protected']))
    assert baseline['lighting']==snapshot['lighting']
    geometry=read('review04-cold-quality_scene_check');ground=read('review04-cold-quality_review02_grounding')
    assert geometry['passed'] and ground['passed']
    return write('review04-scene-audit',{'passed':True,'parts':len(b),'cold_scene_exact':a==b,'max_delta':delta,
        'colliders_unchanged':sum(actual.values()),'effective_physics_checked':physics['checked'],
        'protected_equal':True,'lighting_equal':True,'binary_authority_label_checks':labels['count'],
        'geometry_checks':geometry['checks'],'grounding_checks':ground['checked'],'grounding_max_error':ground['maximumError']})

def performance():
    old,a,b=(read('review04-performance-'+n) for n in ('old','new-a','new-b'))
    assert old['viewport']==a['viewport']==b['viewport'] and old['quality']==a['quality']==b['quality']
    assert not any(s['streaming'] for s in (old,a,b))
    rows=[]
    def passes(v):return {p['Name']:p['Sizes'] for p in v['render']['Children']}
    for ov,av,bv in zip(old['views'],a['views'],b['views']):
        assert ov['id']==av['id']==bv['id']
        op,ap,bp=map(passes,(ov,av,bv))
        assert ap['Opaque']['Triangles']==bp['Opaque']['Triangles']
        assert all(v['medianMs']<25 for v in (ov,av,bv))
        rows.append({'view':ov['id'],'old':ov,'new_a':av,'new_b':bv,
            'opaque_increase_percent':100*(ap['Opaque']['Triangles']/op['Opaque']['Triangles']-1),
            'terrain_counts_match':op.get('Terrain')==ap.get('Terrain')==bp.get('Terrain')})
    return write('review04-performance-comparison',{'viewport':old['viewport'],'quality':old['quality'],
        'streaming':False,'frames_per_view':120,'parts_old':old['parts'],'parts_new':a['parts'],'rows':rows,
        'method':'Same-process foreground new-old-new scenery swap, seven fixed cameras, FOV60, full residency.',
        'limits':['Art increases geometry cost; no optimization claim.','60Hz-capped desktop, not physical-device acceptance.',
            'Terrain LOD varies; compare opaque pass separately.','Background-throttled sample rejected and retained.']})

def gallery():
    names=[v['id'] for v in read('views')]+[f'phone-section-{k}-terrace' for k in range(1,7)]
    records=[];cards=[]
    for name in names:
        sides=[];sizes=[]
        for side in ('before','after'):
            p=EV/('review04-'+side)/(name+'.jpg')
            with Image.open(p) as im:sizes.append(im.size);im.verify()
            records.append({'path':p.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'size':sizes[-1]})
            sides.append(f'<figure><figcaption>{"Review03" if side=="before" else "Review04"}</figcaption><img loading="lazy" src="review04-{side}/{name}.jpg"></figure>')
        assert sizes[0]==sizes[1],(name,sizes)
        if name.startswith('phone'):assert sizes[0][0]<900
        cards.append(f'<section><h2>{name}</h2><div>{"".join(sides)}</div></section>')
    html='''<!doctype html><meta charset="utf-8"><title>Mountain Review04 comparison</title><style>body{background:#141b21;color:#e6ecef;font:16px system-ui;margin:30px}section{margin:36px 0}section>div{display:grid;grid-template-columns:1fr 1fr;gap:14px}figure{margin:0}figcaption{padding:8px;background:#25313c}img{width:100%}p{max-width:1050px;line-height:1.6}</style><h1>Review03 → Review04</h1><p>Matched current-session cameras and viewport. Hewn rocks, fuller canopy, grouped planting, tapered minerals, waterfall source/basin, erosion layers, basalt fins and a stone crown. All collider geometry and effective physics preserved. Six broad bands, long terrace boundaries and the straight lane seam remain visible. Phone pairs are Galaxy A06 landscape terrain-only Studio simulation, not live UI or physical-device testing. Added art raises opaque triangle cost about71% in the controlled overview.</p>'''+''.join(cards)
    (EV/'review04-comparison.html').write_text(html,encoding='utf-8')
    return write('review04-images',records)

def delivery():
    scene=static();perf=performance();images=gallery();integrity=read('review04-file-integrity')
    manifest=json.loads((ROOT/'design/mountain-quality-manifest.json').read_text())
    assert manifest['helper_version']==4 and manifest['review']==integrity
    for name,sha in manifest['runtime_files'].items():assert hashlib.sha256((ROOT/name).read_text(encoding='utf-8').encode()).hexdigest()==sha
    for n,sha in [('01','c3000ce9b6eb626098089719d5fa30503f7947aeb2252d6f151cb1ec0edee680'),('03','eb77b97a1f69c4e24818196d60131c425e9413794bb939aa3983288fa8d44577')]:
        assert hashlib.sha256((ROOT/f'outputs/ClimbCollect.MountainQuality.Review{n}.rbxl').read_bytes()).hexdigest()==sha
    assert hashlib.sha256(Path(integrity['place']).read_bytes()).hexdigest()==integrity['sha256']
    assert not integrity['terrain_drift'] and not integrity['source_mismatches'] and not integrity['temporary_qa']
    idem=read('review04-idempotency');assert idem['version']==4 and idem['sameFolders'] and idem['partsUnchanged'] and idem['streaming'] and not idem['http']
    raid=read('review04-cold-raid-and-hazards');walk=read('review04-observed-jump-traversal')
    assert raid['done'] and raid['passed'] and walk['done'] and walk['passed']
    jumps=[s for s in walk['log'] if s.get('jump')]
    assert len(jumps)==12 and all(s['jumpObserved'] and s['airborneObserved'] and s['landingObserved'] and s['maxUp']>10 for s in jumps)
    regression=read('review04-final-regression');assert len(regression['suites'])==26 and len(regression['compiles'])==77
    assert all(s['exit']==0 for s in regression['suites']+regression['compiles'])
    assert len(images)==52
    return write('review04-delivery-verification',{'passed':True,'review':integrity,'scene':scene,'image_pairs':26,
        'raid_steps':len(raid['log']),'traversal_steps':len(walk['log']),'observed_keyboard_jumps':len(jumps),
        'regression_suites':26,'compiles':77,'idempotency':idem,
        'limits':['Owner aesthetic acceptance unresolved.','Physical-device, hosted/network and current combined-place integration unverified.','Nine multiplayer checks historical, not rerun.']})

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('mode',choices=['static','performance','gallery','delivery']);a=p.parse_args()
    r=globals()[a.mode]();print(json.dumps(r if a.mode=='static' else {'mode':a.mode,'passed':True},indent=2))
