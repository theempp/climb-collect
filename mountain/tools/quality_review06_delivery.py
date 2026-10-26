"""Review06 source, geometry, protected voxel and cold-save acceptance."""
import json,hashlib
from pathlib import Path
from quality_evidence import ROOT,EV,load
from package_free_climb import Place,runtime_sources
from quality_verify_place import source_map,normal,terrain
DLL=Path('C:/Program Files/Git/mingw64/bin/libzstd.dll')
def read(n):return load(n)
def data(n):
 r=read(n);assert r['ok'],n;return r['data']
def frozen_scene(r):
 r=r['protected']
 r['ImpossibleMountain']=[p for p in r['ImpossibleMountain'] if p['name']!='NaturalLandscape']
 r['ImpossibleMountain'].sort(key=lambda x:json.dumps(x,sort_keys=True))
 return r
def audit():
 basepath=ROOT/'outputs/ClimbCollect.MountainQuality.Review05.rbxl'
 assert hashlib.sha256(basepath.read_bytes()).hexdigest()=='c4e48fa124af56140815adddb377d3a314cb6f081be7b37bebb45ee7800c5927'
 path=ROOT/'outputs/ClimbCollect.MountainQuality.Review06.rbxl';raw=path.read_bytes()
 old=Place(basepath.read_bytes(),DLL);new=Place(raw,DLL)
 before,after=source_map(old),source_map(new)
 assert all(normal(after[k])==normal(v) for k,v in before.items()),'Existing runtime source changed'
 expected=runtime_sources();assert all(normal(after[k])==normal(v) for k,v in expected.items())
 assert set(after)-set(before)=={'ReplicatedStorage.MountainShared.AlpineProfile','StarterPlayer.StarterPlayerScripts.MountainClient.AltitudeAtmosphere'}
 a=read('review06-before-quality_snapshot');b=data('review06-cold-quality_snapshot')
 assert a['lighting']==b['lighting'] and frozen_scene(a)==frozen_scene(b),'Protected scene drift'
 oldparts=read('review06-before-quality_scene_fingerprint');newparts=data('review06-cold-quality_scene_fingerprint')
 original=[p for p in newparts if '.NaturalTransitions.' not in p['path'] and '.NaturalLandscape.' not in p['path']]
 def physical_record(p):return {k:v for k,v in p.items() if k not in ('color','material')}
 assert sorted(map(lambda p:json.dumps(physical_record(p),sort_keys=True),oldparts))==sorted(map(lambda p:json.dumps(physical_record(p),sort_keys=True),original)),'Original geometry/visibility changed'
 added=[p for p in newparts if p not in original]
 assert all(not p['collide'] and not p['query'] and not p['touch'] and p['anchored'] for p in added)
 vox=read('review06-before-exact-voxels');cold=data('review06-cold-quality_terrain_exact')
 assert cold==data('review06-final-quality_terrain_exact'),'Native save changed intended voxels'
 for k in ('sanctuary','playable','legacyMountain'):assert vox['regions'][k]==cold['regions'][k],k
 for k in ('quality_scene_check','quality_landscape_boundary','quality_review04_physics'):
  assert data('review06-cold-'+k)['passed'],k
 assert read('review06-idempotency')['terrain_equal'] and read('review06-idempotency')['scene_equal']
 checks=read('review06-regression');assert all(x['exit']==0 for x in checks['suites']+checks['compiles'])
 for n in ('walk','edges','raid'):
  r=read('review06-'+n);assert r['done'] and r['passed'],n
 walk=read('review06-walk');jumps=[x for x in walk['log'] if x.get('jump')]
 assert len(jumps)==12 and all(x['jumpObserved'] and x['airborneObserved'] and x['landingObserved'] for x in jumps)
 fx=read('review06-altitude-walk');assert min(x['intensity'] for x in fx)==0 and max(x['intensity'] for x in fx)>.99
 assert all(not x['enabled'] for x in fx if x['target']==0)
 assert read('review06-cold-startup')['passed']
 assert read('review06-lifecycle')['passed'],'Death/respawn effect lifecycle'
 temporary=[x for x in new.paths.values() if 'MountainQA' in x or 'FreeClimbQA' in x or 'LocalAltitudeAtmosphere' in x]
 assert not temporary
 ta,tb=terrain(old),terrain(new);drift=[k for k in ta.keys()|tb.keys() if ta.get(k)!=tb.get(k)]
 assert set(drift)<= {'Materials','PhysicsGrid','SmoothGrid'}
 result={'passed':True,'place':str(path),'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw),'runtime_sources':len(expected),'unchanged_saved_sources':len(before),'new_sources':sorted(set(after)-set(before)),
 'preserved_original_parts':len(oldparts),'added_noncolliding_parts':len(added),'colliders':996,'exact_protected_cells':sum(vox['regions'][k]['cells'] for k in ('sanctuary','playable','legacyMountain')),'native_cold_voxels':True,'terrain_payload_changes':drift,'suites':len(checks['suites']),'compiles':len(checks['compiles']),'walk_steps':len(walk['log']),'jumps':len(jumps),'edge_steps':len(read('review06-edges')['log']),'raid_steps':len(read('review06-raid')['log']),'effect_samples':len(fx),'temporary_qa':temporary}
 (EV/'review06-delivery.json').write_text(json.dumps(result,indent=2));return result
if __name__=='__main__':print(json.dumps(audit(),indent=2))
