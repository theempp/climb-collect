"""Append verified compact progress and its unresolved live failure with backups."""
from pathlib import Path
from datetime import datetime
import hashlib,json
root=Path(__file__).resolve().parents[2]
vault=Path('C:/Users/HOME!/Documents/Obsidian Vault/Climb & Collect')
nav=Path('C:/Users/HOME!/Desktop/climb&collect')
marker='Compact rebuild progress — live clearance retest pending'
pointer=(root/'design/compact-mountain-execution.md').as_posix()
text=f'''\n\n## {marker}\n\n2026-10-26: provisional .85 compact rebuild measured native width 2176→1848 and ordinary center climb 80.431→68.380 seconds. Initial cold-save source/terrain checks and 1855 scene checks passed; sanctuary assets/lighting and protected sanctuary/legacy terrain remained exact. Cold local loading took 2.213 seconds; injected dependency timeout and asset failure recovered with Retry. Fresh summit raid failed during pickup escape after the reduced egg spacing. Source now preserves original ±58 egg spacing; 29 suites/83 compiles pass, but the fix is NOT yet applied/retested in Studio. The initial CompactMountain.Review01 file is preliminary and predates this fix. Studio instance limit currently blocks the review session; owner asked to free one unused slot while keeping Review06 Play open. No publish/push/merge. Evidence and outstanding checks: {pointer}. Owner aesthetics, physical devices, fresh multiplayer and combined integration remain open.\n'''
paths=[nav/'design/mountain-quality-upgrade-2026-10-26.md',vault/'Climb & Collect.md',vault/'Milestones.md',vault/'Open Questions.md']
backup=root/'evidence/compact_mountain_2026-10-26/record-backups'/datetime.now().strftime('%Y%m%d-%H%M%S')
backup.mkdir(parents=True,exist_ok=False)
rows=[]
for i,p in enumerate(paths):
    raw=p.read_bytes(); assert marker.encode() not in raw
    b=backup/(str(i)+'-'+p.name);b.write_bytes(raw);assert b.read_bytes()==raw
    rows.append({'path':str(p),'backup':str(b),'sha256':hashlib.sha256(raw).hexdigest()})
for p,r in zip(paths,rows):
    assert hashlib.sha256(p.read_bytes()).hexdigest()==r['sha256'],'Concurrent edit'
    with p.open('ab') as f:f.write(text.encode())
(backup/'manifest.json').write_text(json.dumps(rows,indent=2))
print(json.dumps({'backup':str(backup),'records':len(rows)}))
