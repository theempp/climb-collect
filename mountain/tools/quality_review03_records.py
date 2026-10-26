"""Append the verified local milestone, backing up and hashing every affected record first."""
from pathlib import Path
from datetime import datetime
import hashlib,json,shutil
from quality_evidence import ROOT,EV
nav=Path('C:/Users/HOME!/Desktop/climb&collect')
vault=Path('C:/Users/HOME!/Documents/Obsidian Vault/Climb & Collect')
report=str(ROOT/'design/mountain-quality-review03-report.md')
summary=f'''2026-10-26 MountainQuality Review03 continuation: v3 low clustered biome planting and simple accents reduce repeated scenery while preserving the silhouette. Saved and cold-reopened Review03 SHA256 eb77b97a1f69c4e24818196d60131c425e9413794bb939aa3983288fa8d44577; all70 Terrain payloads/77 sources,3585 exact mountain parts,929 unchanged regional colliders and protected scene/Lighting verified. Fresh26 suites/100543 assertions/77 compiles,9546 scene geometry checks,724 planting-contact checks,165 traversal steps with12 actual keyboard jumps,120 cold raid/cargo/hazard steps pass.26 matched comparison pairs. Controlled final new-old-new overview opaque triangles167692→122806 (~27% reduction); draw calls mixed,60Hz-capped desktop, Terrain LOD varies, no physical-device/FPS claim. Historical nine multiplayer checks were not rerun. Corrected assumptions: plant roots must use actual triangles, and native save can rewrite PhysicsGrid as well as SmoothGrid. Both payloads restored with all other chunks preserved; failed checkpoint retained. Broad ramps/terraces, oval rocks, sparse vegetation, biome transition composition and phone panel coverage remain unresolved; owner aesthetic, hardware, hosted/network and latest combined integration remain open. Evidence: {report}. Graph freshness covers navigation/vault only, not isolated runtime source.'''
entries={nav/'design/mountain-quality-upgrade-2026-10-26.md':'\n\n## Verified continuation — Review03\n\n'+summary+'\n',
 vault/'Climb & Collect.md':'\n\n- '+summary+'\n',
 vault/'Milestones.md':'\n\n- #milestone '+summary+'\n',
 vault/'Decisions.md':f'\n\n- 2026-10-26 #decision MountainQuality v3 keeps all929 tested regional colliders while improving decoration across all six biomes. Plant grounding samples the actual WalkSurface; do not infer contact from the smooth profile. Keep the silhouette and clear escape/encounter areas. Native save audits must compare all70 Terrain payloads, including PhysicsGrid; restore only from that integration copy’s own authority into a new file and cold reopen. Scoped integration remains two helpers and one hook; never rebuild a baked root. Evidence and remaining art/performance limitations: {report}.\n',
 vault/'Open Questions.md':f'\n\n- 2026-10-26 MountainQuality Review03: large-scale rock/terrace composition, lushness, repeated oval masses, biome transitions and phone center-panel coverage remain weaknesses despite verified gameplay. Controlled opaque triangle cost is lower, but draw calls are mixed and physical phone/GPU/memory, hosted save/network, current combined integration and owner art acceptance remain open. Nine multiplayer checks are historical, not freshly rerun. Evidence: {report}; review03-performance-comparison.json records Terrain LOD exclusions and capped-frame limits.\n'}
assert json.loads((EV/'review03-delivery-verification.json').read_text())['passed']
assert all('Verified continuation — Review03' not in p.read_text(encoding='utf-8') for p in [nav/'design/mountain-quality-upgrade-2026-10-26.md'])
backup=EV/'record-backups'/('review03-'+datetime.now().strftime('%Y%m%d-%H%M%S'));backup.mkdir(parents=True)
rows=[]
for i,(p,text) in enumerate(entries.items()):
 raw=p.read_bytes();dest=backup/(str(i)+'-'+p.name);shutil.copy2(p,dest)
 assert dest.read_bytes()==raw
 rows.append({'path':str(p),'backup':str(dest),'before_sha256':hashlib.sha256(raw).hexdigest()})
for (p,text),row in zip(entries.items(),rows):
 assert hashlib.sha256(p.read_bytes()).hexdigest()==row['before_sha256'],'Concurrent record change; stop before writing'
 with p.open('ab') as f:f.write(text.encode('utf-8'))
 row['after_sha256']=hashlib.sha256(p.read_bytes()).hexdigest()
(EV/'review03-record-backups.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
print(json.dumps({'backups':str(backup),'records':len(rows),'verified':True}))
