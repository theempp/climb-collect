"""Back up and append the verified local Review06 milestone, preserving prior notes."""
from pathlib import Path
from datetime import datetime
import hashlib,json,shutil
from quality_evidence import ROOT,EV
r=json.loads((EV/'review06-delivery.json').read_text());assert r['passed']
nav=Path('C:/Users/HOME!/Desktop/climb&collect')
vault=Path('C:/Users/HOME!/Documents/Obsidian Vault/Climb & Collect')
report=(ROOT/'design/mountain-quality-review06-report.md').as_posix()
summary=f"2026-10-26 MountainQuality Review06 softens section bands and the center seam using shared rocky colors, irregular surface patches, outer spurs/firs and a higher snowline; a sharper rear native ridgeline frames the summit. Two new scoped sources add client-only altitude particles/tint with quality scaling. Local playable SHA256 {r['sha256']}. All 83 prior sources, 3964 original parts, 996 effective collider physics and 54,793,408 protected voxel cells remain preserved; 1420 cosmetic parts added. Cold native-save equality and repeat recipe checks pass. 27 suites/105322 assertions/79 compiles; 165 traversal steps/12 keyboard jumps, 98 edge steps and {r['raid_steps']} fresh-home raid/cargo/hazard checks pass. The sandstone test now permits its intended six-stud drop at entry; no gameplay change. 647 natural effect samples verify departure clearing. Streaming Play medians16.60-16.73ms and summit full-effect16.63ms are capped desktop observations, not comparable to prior editor cost or phone acceptance. Evidence: {report}. Broad physical terraces/straight route, owner aesthetics, devices, hosted/network, fresh multiplayer and combined integration remain open. Navigation graph excludes this implementation checkout."
brief=f"2026-10-26 Review06 verified locally: natural section transitions, rear summit ridge and altitude-driven local atmosphere; original gameplay/colliders/protected voxels preserved. Cold-save, repeat recipe, traversal, edge and fresh raid/cargo/hazard checks pass. Physical route remains broad/straight; owner aesthetics and phone/hosted/combined acceptance remain open. Evidence: {report}."
entries={
 nav/'design/mountain-quality-upgrade-2026-10-26.md':'\n\n## Verified naturalization - Review06\n\n'+summary+'\n',
 vault/'Climb & Collect.md':'\n\n- '+brief+'\n',
 vault/'Milestones.md':'\n\n- #milestone '+brief+'\n',
 vault/'Decisions.md':f'\n\n- 2026-10-26 #decision Review06 keeps the tested physical route and blends its presentation with continuous earthy colors, irregular cosmetic patches and outer scenery. Native summit occupancy is confined behind z=-1424; protected domains remain exact. Altitude effects are client-only and bounded by actual player position, with reduced particle rates for touch/low graphics/slow frames. No global weather or gameplay changes. Evidence: {report}.\n',
 vault/'Open Questions.md':f'\n\n- 2026-10-26 Review06: owner aesthetic acceptance, broad straight physical terraces, real phone/GPU/memory, hosted persistence/network, fresh multiplayer and latest combined integration remain open. Corrected QA assumption: sandstone can drop six studs before arrival; the new runner permits that entry height while still requiring damage, survival and walk-only recovery. Streaming Play measurements cannot be compared directly with Review05 full-residency Edit measurements. Evidence: {report}.\n'
}
assert 'Verified naturalization - Review06' not in next(iter(entries)).read_text(encoding='utf-8')
backup=EV/'record-backups'/('review06-'+datetime.now().strftime('%Y%m%d-%H%M%S'));backup.mkdir(parents=True)
rows=[]
for i,p in enumerate(entries):
 raw=p.read_bytes();dest=backup/(str(i)+'-'+p.name);shutil.copy2(p,dest);assert dest.read_bytes()==raw
 rows.append({'path':str(p),'backup':str(dest),'before_sha256':hashlib.sha256(raw).hexdigest()})
for (p,text),row in zip(entries.items(),rows):
 assert hashlib.sha256(p.read_bytes()).hexdigest()==row['before_sha256'],'Concurrent edit; stop'
 with p.open('ab') as f:f.write(text.encode('utf-8'))
 row['after_sha256']=hashlib.sha256(p.read_bytes()).hexdigest()
(EV/'review06-record-backups.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
print(json.dumps({'backup':str(backup),'records':len(rows),'verified':True}))
