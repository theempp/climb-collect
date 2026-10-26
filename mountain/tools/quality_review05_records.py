"""Back up and append the verified Review05 milestone; never overwrite existing notes."""
from pathlib import Path
from datetime import datetime
import hashlib,json,shutil
from quality_evidence import ROOT,EV
r=json.loads((EV/'review05-delivery-static.json').read_text());assert r['passed'] and r['exact_voxel_recipe_reproduced']
nav=Path('C:/Users/HOME!/Desktop/climb&collect');vault=Path('C:/Users/HOME!/Documents/Obsidian Vault/Climb & Collect')
report=(ROOT/'design/mountain-quality-review05-report.md').as_posix()
summary=f"2026-10-26 MountainQuality Review05 extends native surrounding hills beside all six sections and wraps the summit, superseding the earlier silhouette restriction. Local playable SHA256 {r['sha256']}. All77 current runtime sources plus6 historical saved sources,3964 exact mountain parts,996 effective collider physics,protected scene/Lighting preserved. Intentional bounded terrain additions retain3 native changed payloads; never restore the older whole Terrain over this review. Exact protected voxel and three-stage plus guarded native-correction recipe reproduction audits pass. Fresh26 CLI suites/100543 assertions/77 compiles,9925 geometry,792 planting,39 coverage,630 terrain-edge samples;165 traversal steps/12 keyboard jumps,98 outer-edge steps and{r['raid_steps']} fresh-home raid/cargo/hazard steps pass.26 comparison pairs include Galaxy A06 scenery simulation. Editor overview triangles416530â†’459784 (repeat455224),draws246â†’307;60Hz-capped medians,not physical-device acceptance. Original broad route bands/terraces and repeated older peaks remain; owner aesthetics,physical devices,hosted/network and latest combined integration are open. Evidence: {report}. Graph excludes this isolated implementation source."
brief=f"2026-10-26 Review05 continues the surrounding mountain/hills along all six sections and behind Astral. Cold playable,unchanged parts/physics/runtime,exact protected voxel/recipe checks and fresh traversal/edge/raid tests verified. Editor overview cost risesabout9â€“10% triangles and61 draws; physical phones and owner aesthetics remain open. Evidence: {report}."
entries={nav/'design/mountain-quality-upgrade-2026-10-26.md':'\n\n## Verified continuation â€” Review05\n\n'+summary+'\n',vault/'Climb & Collect.md':'\n\n- '+brief+'\n',vault/'Milestones.md':'\n\n- #milestone '+brief+'\n',vault/'Decisions.md':f'\n\n- 2026-10-26 #decision Review05 owner direction supersedes keeping the old silhouette: extend hills/mountain through the full route and wrap the summit. Preserve tested face/anchors/physics; outside hills are scenery,not guaranteed new walk routes. Keep intentional new terrain; never blanket-restore an older Terrain. Native occupancy is1/256; exact spatial material/occupancy export supplements fingerprints. Evidence: {report}.\n',vault/'Open Questions.md':f'\n\n- 2026-10-26 Review05 remaining: owner aesthetics/human timing,broad route bands/terrace geometry and repeated lower peaks,physical phone/GPU/memory,hosted/network and latest combined integration. Historical multiplayer is not fresh Review05 evidence. New terrain continuity and local cold tests are verified. Evidence: {report}.\n'}
assert 'Verified continuation â€” Review05' not in (nav/'design/mountain-quality-upgrade-2026-10-26.md').read_text(encoding='utf-8')
backup=EV/'record-backups'/('review05-'+datetime.now().strftime('%Y%m%d-%H%M%S'));backup.mkdir(parents=True)
rows=[]
for i,(p,text) in enumerate(entries.items()):
 raw=p.read_bytes();dest=backup/(str(i)+'-'+p.name);shutil.copy2(p,dest);assert dest.read_bytes()==raw
 rows.append({'path':str(p),'backup':str(dest),'before_sha256':hashlib.sha256(raw).hexdigest()})
for (p,text),row in zip(entries.items(),rows):
 assert hashlib.sha256(p.read_bytes()).hexdigest()==row['before_sha256'],'Concurrent edit; stop'
 with p.open('ab') as f:f.write(text.encode('utf-8'))
 row['after_sha256']=hashlib.sha256(p.read_bytes()).hexdigest()
(EV/'review05-record-backups.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
print(json.dumps({'backup':str(backup),'records':len(rows),'verified':True}))
