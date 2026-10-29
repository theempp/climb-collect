from pathlib import Path
import json,zipfile,hashlib,subprocess,os,shutil
PROJECT=Path(r'C:\Users\HOME!\Desktop\climb&collect')
BACKUP=Path(json.loads((PROJECT/'evidence/recovery_2026-10-24/location.json').read_text())['backup'])
manifest=json.loads((BACKUP/'manifest.json').read_text())
assert manifest['complete'] and manifest['archive_all_entries_verified']
restore=BACKUP/'restore-test'/'mountain'
assert not restore.exists()
restore.parent.mkdir(exist_ok=False)
env=dict(os.environ,GIT_OPTIONAL_LOCKS='0')
def run(*args,cwd=None):
 p=subprocess.run(list(args),cwd=cwd,capture_output=True,text=True,env=env)
 if p.returncode:raise RuntimeError(p.stdout+p.stderr)
 return p.stdout
print('Cloning independent repository from saved bundle...',flush=True)
run('git','clone','--no-checkout',str(BACKUP/'climb-collect-all-refs.bundle'),str(restore))
run('git','checkout','-b','recovery/mountain-snapshot','8d2d2635035f580f292ab89221200b1f6ed3981b',cwd=restore)
print('Restoring all mountain working files into independent checkout...',flush=True)
with zipfile.ZipFile(BACKUP/'mountain-complete.zip') as z:
 for i,entry in enumerate(manifest['files']):
  rel=entry['path']
  if rel=='.git':
   target=BACKUP/'restore-test'/'original-git-link.txt'
  else:
   target=restore/rel
   assert target.resolve().is_relative_to(restore.resolve())
  target.parent.mkdir(parents=True,exist_ok=True)
  with z.open(rel) as src,target.open('wb') as dst:shutil.copyfileobj(src,dst,1024*1024)
  with target.open('rb') as f:assert hashlib.file_digest(f,'sha256').hexdigest()==entry['sha256'],rel
  if i%500==0:print('Restored and verified',i+1,'/',manifest['file_count'],flush=True)
for d in manifest['directories']:(restore/d).mkdir(parents=True,exist_ok=True)
actual=set()
for base,dirs,files in os.walk(restore):
 if Path(base)==restore:dirs[:]=[d for d in dirs if d!='.git']
 for f in files:actual.add((Path(base)/f).relative_to(restore).as_posix())
expected={e['path'] for e in manifest['files'] if e['path']!='.git'}
assert actual==expected,{'extra':list(actual-expected),'missing':list(expected-actual)}
assert run('git','rev-parse','HEAD',cwd=restore).strip()=='8d2d2635035f580f292ab89221200b1f6ed3981b'
original_status=(BACKUP/'git-metadata/mountain/status.txt').read_bytes()
restored_status=subprocess.check_output(['git','status','--porcelain=v1','-uall'],cwd=restore,env=env)
# Exact restored bytes can have different raw status metadata in a fresh checkout.
source=Path(json.loads((BACKUP/'baseline.json').read_text())['mountain']['root'])
assert run('git','diff','--binary','HEAD',cwd=source)==run('git','diff','--binary','HEAD',cwd=restore),'Tracked content diff differs'
luau=PROJECT/'tools/.luau/luau.exe'
rules=run(str(luau),'mountain/tests/rules.luau','mountain/tests/traversal.luau','mountain/tests/route_geometry.luau',cwd=restore)
audit=run('python','mountain/tools/audit_saved.py','evidence/mountain_2026-10-24/ImpossibleMountain.Natural.Final56.rbxlx','--terrain-reference','evidence/mountain_2026-10-24/ImpossibleMountain.Natural.Final54.rbxlx','--require-current-world',cwd=restore)
result={'restored_checkout':str(restore),'files_verified':manifest['file_count'],'git_link_saved_separately':True,
 'standalone_git_from_bundle':True,'status_exactly_matches_source_snapshot':original_status==restored_status,'tracked_content_diff_matches_source':True,'rules':rules,'saved_audit':json.loads(audit),'complete':True}
(BACKUP/'restore-verification.json').write_text(json.dumps(result,indent=2))
(PROJECT/'evidence/recovery_2026-10-24/restore-verification.json').write_text(json.dumps(result,indent=2))
print(json.dumps({k:v for k,v in result.items() if k!='saved_audit'},indent=2),flush=True)
