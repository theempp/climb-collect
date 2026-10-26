"""Review05 spatial terrain and unchanged runtime/scene audit. No blanket terrain restore."""
import hashlib,json
from pathlib import Path
from quality_evidence import ROOT,EV,load,digest
from package_free_climb import Place,runtime_sources
from quality_verify_place import source_map,terrain
DLL=Path('C:/Program Files/Git/mingw64/bin/libzstd.dll')
def read(n):return load(n)
def write(n,r):
 (EV/(n+'.json')).write_text(json.dumps(r,indent=2),encoding='utf-8');return r
def audit():
 a=read('review05-before-quality_scene_fingerprint');b=read('review05-cold-quality_scene_fingerprint')
 assert a==b,'Baked mountain part drift'
 old=read('review05-before-quality_snapshot');new=read('review05-cold-quality_snapshot')
 assert old['protected']==new['protected'] and old['lighting']==new['lighting']
 initial=read('review05-authority-terrain');ready=read('review05-final-terrain');cold=read('review05-cold-quality_terrain_fingerprint')
 assert ready==cold,'Native save/reopen voxel mismatch'
 for name in ('sanctuary','playable','legacyMountain'):
  assert initial['regions'][name]==cold['regions'][name],name
 assert initial['regions']['landscape']!=cold['regions']['landscape']
 for name in ('quality_landscape_check','quality_scene_check','quality_review02_grounding','quality_review04_physics'):
  assert read('review05-cold-'+name)['passed'],name
 path=ROOT/'outputs/ClimbCollect.MountainQuality.Review05.rbxl';raw=path.read_bytes();p=Place(raw,DLL)
 basePath=ROOT/'outputs/ClimbCollect.MountainQuality.Review04.rbxl';baseRaw=basePath.read_bytes()
 assert hashlib.sha256(baseRaw).hexdigest()=='b0ae05855a36c6623b5cb8cd7bcae8f7cb90bdbcf4f75bfe9cd249c7529129e3'
 base=Place(baseRaw,DLL);assert source_map(base)==source_map(p),'Runtime source drift'
 t,u=terrain(base),terrain(p);drift=sorted(k for k in t.keys()|u.keys() if t.get(k)!=u.get(k))
 assert set(drift)<= {'Materials','PhysicsGrid','SmoothGrid'}
 temporary=[v for v in p.paths.values() if 'MountainQA' in v or 'FreeClimbQA' in v];assert not temporary
 checks=read('review05-regression');assert all(r['exit']==0 for r in checks['suites']+checks['compiles'])
 idem=read('review05-idempotency-final');assert idem['first']==idem['second']==0
 walk=read('review05-cold-walk');edges=read('review05-cold-edges');raid=read('review05-cold-raid')
 assert all(r['done'] and r['passed'] for r in (walk,edges,raid))
 jumps=[r for r in walk['log'] if r.get('jump')]
 assert len(jumps)==12 and all(r['jumpObserved'] and r['airborneObserved'] and r['landingObserved'] and r['maxUp']>10 for r in jumps)
 boundary=read('review05-live-boundary');assert boundary['passed'] and boundary['checks']==630
 exactBase=read('review05-authority-exact-voxels');exactCold=read('review05-cold-exact-voxels')
 for name in ('sanctuary','playable','legacyMountain'):
  assert exactBase['regions'][name]==exactCold['regions'][name],name+': exact voxel drift'
 assert read('review05-authority-terrain-colors')==read('review05-cold-terrain-colors'),'Terrain palette drift'
 reproduced=read('review05-reproduced-corrected-exact-voxels')
 assert reproduced==exactCold,'Recorded bake recipe does not reproduce delivered terrain'
 assert read('review05-recipe-correction-applied')['second']['changed']==0
 result={'passed':True,'place':str(path),'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw),'runtime_sources_unchanged':len(runtime_sources()),'all_saved_sources_unchanged':len(source_map(p)),
  'exact_mountain_parts':len(a),'colliders':read('review05-cold-quality_review04_physics')['checked'],'protected_scene':True,'lighting':True,
  'native_cold_voxels_equal':True,'protected_voxel_domains':['sanctuary','playable','legacyMountain'],
  'terrain_payload_changes':drift,'terrain_properties':len(u),'coverage_checks':read('review05-cold-quality_landscape_check')['checks'],
  'suites':len(checks['suites']),'compiles':len(checks['compiles']),'temporary_qa':temporary,
  'exact_protected_voxel_cells':sum(exactBase['regions'][k]['cells'] for k in ('sanctuary','playable','legacyMountain')),
  'exact_voxel_recipe_reproduced':True,'walk_steps':len(walk['log']),'jumps':len(jumps),'edge_steps':len(edges['log']),'raid_steps':len(raid['log']),
  'limits':['Spatial signatures are supplemented by exact run-length material/occupancy comparison within the documented domains. No whole-Terrain byte-equality claim.',
  'Intentional landscape terrain retained; native serialization changes audited through cold spatial fingerprints.']}
 return write('review05-delivery-static',result)
if __name__=='__main__':print(json.dumps(audit(),indent=2))
