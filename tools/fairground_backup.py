"""Preserve the actual dirty workspace before redesign; never overwrite backups."""
from pathlib import Path
import hashlib, json, shutil, subprocess, zipfile
root=Path(__file__).resolve().parents[1]
out=root/'evidence/fairground_2026-10-22'
out.mkdir(exist_ok=True)
manifest={}
paths=[]
for folder in ['src','tools','design','docs','creatures','references']:
    paths.extend(p for p in (root/folder).rglob('*') if p.is_file() and not any(s in p.parts for s in ['.audit-deps','.luau','__pycache__']))
paths.extend(root/p for p in ['CLAUDE.md','master.md','.gitignore'])
archive=out/'starting-source.zip'
if archive.exists(): raise SystemExit('Backup already exists; refusing overwrite')
with zipfile.ZipFile(archive,'x',zipfile.ZIP_DEFLATED) as z:
    for p in paths:
        rel=p.relative_to(root).as_posix(); raw=p.read_bytes()
        manifest[rel]=hashlib.sha256(raw).hexdigest(); z.writestr(rel,raw)
(out/'starting-manifest.json').write_text(json.dumps(manifest,indent=2))
(out/'starting-status.txt').write_text(subprocess.check_output(['git','status','--short'],cwd=root,text=True))
for name in ['ClimbAndCollect.BeforeFairground.rbxl','ClimbAndCollect.Fairground.Review.rbxl']:
    target=root/name
    if target.exists(): raise SystemExit('Refusing overwrite '+name)
    shutil.copy2(root/'ClimbAndCollect.FootholdExchange.Review.rbxl',target)
print(json.dumps({'files':len(manifest),'archive':str(archive),'placeSHA256':hashlib.sha256((root/'ClimbAndCollect.BeforeFairground.rbxl').read_bytes()).hexdigest()}))
