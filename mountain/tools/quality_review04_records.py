"""Append verified Review04 pointers with byte-verified backups and concurrency guards."""
from pathlib import Path
from datetime import datetime
import hashlib,json,shutil
from quality_evidence import ROOT,EV
nav=Path('C:/Users/HOME!/Desktop/climb&collect')
vault=Path('C:/Users/HOME!/Documents/Obsidian Vault/Climb & Collect')
r=json.loads((EV/'review04-delivery-verification.json').read_text());assert r['passed']
report=(ROOT/'design/mountain-quality-review04-report.md').as_posix()
summary=f'''2026-10-26 MountainQuality Review04: v4 hewn rock shoulders, fuller canopy/understory, tapered minerals and six biome landmarks retain the outer silhouette. Saved/cold-open SHA256 {r['review']['sha256']};77 source matches,all70 Terrain payloads,3964 exact mountain parts,996 unchanged collider transforms/effective physics,protected scene/Lighting.26 CLI suites/100543 assertions/77 compiles;9925 scene and792 planting checks;{r['traversal_steps']} natural traversal steps/12 actual keyboard jumps and{r['raid_steps']} raid/cargo/hazard steps pass.26 matched desktop/phone terrain pairs. Overview opaque triangles122806→209598 (+70.67%) with capped desktop~16.6ms; geometry cost rises, no hardware performance approval. Independent review found and verified fixes for material-dependent physics and fallible CSG ordering. Native save also rewrote Terrain Materials; all3 changed payloads restored before cold tests. Broad bands/terrace edges, straight lane seam, sparse middle slopes and partly hidden crown remain art limits. Owner aesthetic, physical devices, hosted/network and latest combined integration remain open. No publication/push/merge/purchase or other-chat edits. Evidence: {report}. Navigation/vault graph excludes isolated runtime source.'''
brief=f'2026-10-26 Review04 local mountain art milestone: cold playable,996 collider physics preserved,26 suites,165 route steps/12 keyboard jumps,120 raid/hazard steps verified. Added art costs70.67% more overview opaque triangles; broad bands, lane seam and summit visibility remain unresolved. Corrected material-physics and CSG-order assumptions; all70 Terrain payloads preserved. Evidence: {report}. Owner/hardware/hosted/combined acceptance remains open.'
entries={
 nav/'design/mountain-quality-upgrade-2026-10-26.md':'\n\n## Verified continuation — Review04\n\n'+summary+'\n',
 vault/'Climb & Collect.md':'\n\n- '+brief+'\n',
 vault/'Milestones.md':'\n\n- #milestone '+brief+'\n',
 vault/'Decisions.md':f'\n\n- 2026-10-26 #decision Review04 preserves effective collider physics explicitly when changing visual Materials; transform equality alone is insufficient. Prepare fallible CSG before deleting old art. Audit every Terrain payload (including Materials) and cold reopen. Keep design values here, reconcile newer combined overrides before integration. Evidence: {report}.\n',
 vault/'Open Questions.md':f'\n\n- 2026-10-26 Review04 remaining acceptance: broad six-band/terrace composition, lane seam, sparse center ground and summit focal visibility; physical phone cost after opaque geometry increased70.67%; owner aesthetics, hosted/network and current combined integration. Fresh gameplay passed; multiplayer9 remains historical. Evidence: {report}.\n'}
assert 'Verified continuation — Review04' not in (nav/'design/mountain-quality-upgrade-2026-10-26.md').read_text(encoding='utf-8')
backup=EV/'record-backups'/('review04-'+datetime.now().strftime('%Y%m%d-%H%M%S'));backup.mkdir(parents=True)
rows=[]
for i,(p,text) in enumerate(entries.items()):
 raw=p.read_bytes();dest=backup/(str(i)+'-'+p.name);shutil.copy2(p,dest);assert dest.read_bytes()==raw
 rows.append({'path':str(p),'backup':str(dest),'before_sha256':hashlib.sha256(raw).hexdigest()})
for (p,text),row in zip(entries.items(),rows):
 assert hashlib.sha256(p.read_bytes()).hexdigest()==row['before_sha256'],'Concurrent edit; stop before writing'
 with p.open('ab') as f:f.write(text.encode('utf-8'))
 row['after_sha256']=hashlib.sha256(p.read_bytes()).hexdigest()
(EV/'review04-record-backups.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
print(json.dumps({'backup':str(backup),'records':len(rows),'verified':True}))
