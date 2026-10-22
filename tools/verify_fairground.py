"""Compile/reconcile review sources and verify the exact original terrain property payloads."""
from pathlib import Path
import sys,struct,hashlib,json,re,subprocess
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
 manifest=re.findall(r'\{ "([^"]+\.luau)", "([^"]+)", "([^"]+)", "([^"]+)" \}',(ROOT/'tools/sync_core.luau').read_text())
 sources,t=read(review);_,bt=read(baseline)
 fail=[]
 for file,*_ in manifest:
  r=subprocess.run([str(ROOT/'tools/.luau/luau-compile.exe'),'--null',str(ROOT/file)],capture_output=True,text=True)
  if r.returncode:fail.append({'file':file,'error':r.stdout+r.stderr})
 missing=[f for f,*_ in manifest if normalize((ROOT/f).read_text(encoding='utf-8')) not in sources]
 result={'review':str(review),'sha256':hashlib.sha256(review.read_bytes()).hexdigest(),'compiled':len(manifest),'compileFailures':fail,'missingSources':missing,'terrainExact':t==bt,'changedTerrain':[k for k in t if t[k]!=bt.get(k)]}
 print(json.dumps(result,indent=2));(ROOT/'evidence/fairground_2026-10-22/saved-verification.json').write_text(json.dumps(result,indent=2))
 return bool(fail or missing or t!=bt)
if __name__=='__main__':sys.exit(main())
