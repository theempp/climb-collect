"""Compile/reconcile review sources and verify the exact original terrain property payloads."""
from pathlib import Path
import sys,struct,hashlib,json,re,subprocess,tempfile,zipfile
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools/.audit-deps'))
from rbxl_audit import chunks,rstr
def normalize(s):return '\n'.join(l.rstrip() for l in s.replace('\r\n','\n').split('\n')).rstrip()
def read(path):
 classes={};sizes={};sources=[];terrain={}
 for tag,_,d in chunks(path.read_bytes()):
  if tag=='INST':
   cid=struct.unpack_from('<i',d)[0];name,p=rstr(d,4);classes[cid]=name;sizes[cid]=struct.unpack_from('<I',d,p+1)[0]
  elif tag=='PROP':
   cid=struct.unpack_from('<i',d)[0];name,p=rstr(d,4);kind=d[p];p+=1
   if classes[cid]=='Terrain':terrain[name]=hashlib.sha256(d[p:]).hexdigest()
   if name=='Source' and kind==1:
    for _ in range(sizes[cid]):s,p=rstr(d,p);sources.append(normalize(s))
 return set(sources),terrain
def main():
 baseline=ROOT/sys.argv[1];review=ROOT/sys.argv[2]
 ref=sys.argv[4] if len(sys.argv)>4 and sys.argv[3]=='--source-ref' else None
 archive=zipfile.ZipFile(ROOT/'evidence/fairground_2026-10-22/starting-source.zip') if ref else None
 changed=set(subprocess.check_output(['git','diff','--name-only','b49d8fa',ref],cwd=ROOT,text=True).splitlines()) if ref else set()
 def source(file):
  if not ref:return (ROOT/file).read_text(encoding='utf-8')
  found=subprocess.run(['git','show',ref+':'+file],cwd=ROOT,capture_output=True)
  return (found.stdout if found.returncode==0 and file in changed else archive.read(file)).decode('utf-8-sig')
 sources,t=read(review);_,bt=read(baseline)
 saved_manifest=next((v for v in sources if 'local MAN = {' in v and 'tools/sync_core.luau' in v),None)
 manifest_source=saved_manifest if ref and 'tools/sync_core.luau' not in changed else source('tools/sync_core.luau')
 manifest=re.findall(r'\{ "([^"]+\.luau)", "([^"]+)", "([^"]+)", "([^"]+)" \}',manifest_source)
 fail=[]
 expected={f:source(f) for f,*_ in manifest}
 if ref and 'tools/sync_core.luau' not in changed:expected['tools/sync_core.luau']=saved_manifest
 with tempfile.TemporaryDirectory(prefix='cc-verify-') as temp:
  for file,value in expected.items():
   path=Path(temp)/Path(file).name;path.write_text(value,encoding='utf-8')
   r=subprocess.run([str(ROOT/'tools/.luau/luau-compile.exe'),'--null',str(path)],capture_output=True,text=True)
   if r.returncode:fail.append({'file':file,'error':r.stdout+r.stderr})
 missing=[f for f,v in expected.items() if normalize(v) not in sources]
 sha=hashlib.sha256(review.read_bytes()).hexdigest()
 report=ROOT/'evidence/fairground_2026-10-22/protected-verification.json'
 protected=json.loads(report.read_text()) if report.exists() else {}
 verified=protected.get('unchanged')==True and protected.get('checkedPlaceSha256')==sha
 result={'review':str(review),'sourceRef':ref or 'working tree','sha256':sha,'compiled':len(manifest),'compileFailures':fail,'missingSources':missing,'terrainExact':t==bt,'changedTerrain':[k for k in t if t[k]!=bt.get(k)],'protectedAssetsVerifiedAfterReopen':verified}
 print(json.dumps(result,indent=2));(ROOT/'evidence/fairground_2026-10-22/saved-verification.json').write_text(json.dumps(result,indent=2))
 return bool(fail or missing or t!=bt or not verified)
if __name__=='__main__':sys.exit(main())
