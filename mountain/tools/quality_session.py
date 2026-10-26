"""Local mountain-quality evidence helpers; never writes other checkouts."""
from pathlib import Path
import argparse, hashlib, json, subprocess, sys, zipfile
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from package_free_climb import Place, runtime_sources

ROOT = Path(__file__).resolve().parents[2]
EVIDENCE = ROOT / 'evidence/mountain_quality_2026-10-26'
DLL = Path('C:/Program Files/Git/mingw64/bin/libzstd.dll')
CLI = ROOT / 'tools/.luau/luau.exe'
COMPILER = ROOT / 'tools/.luau/luau-compile.exe'

def sha(data): return hashlib.sha256(data).hexdigest()

def baseline():
    place_path = EVIDENCE / 'baseline/Review03.SprintEntrances.rbxl'
    data = place_path.read_bytes()
    assert sha(data) == 'af2c14388fc6be0b7b4739c94f7a5417780f3d271bad4f06037d045fc5cb4da5'
    place = Place(data, DLL)
    sources = runtime_sources()
    actual = {place.paths[r]: i['Source'] for r,i in place.instances.items() if 'Source' in i}
    assert all(actual[p].replace('\r\n','\n').strip() == s.strip() for p,s in sources.items())
    files = {}
    with zipfile.ZipFile(EVIDENCE/'baseline/source-a3e896a.zip', 'x', zipfile.ZIP_DEFLATED) as z:
        for p in sorted((ROOT/'mountain').rglob('*')):
            if p.is_file() and '__pycache__' not in p.parts and p.suffix in ('.luau','.py','.md'):
                key = p.relative_to(ROOT).as_posix(); raw=p.read_bytes()
                files[key]=sha(raw);z.writestr(key,raw)
    terrain = {c['prop']:sha(c['raw']) for c in place.chunks if c.get('prop') and place.classes[c['cid']]['name']=='Terrain'}
    report={'source_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
        'place':str(place_path),'place_sha256':sha(data),'runtime_sources':len(sources),
        'source_parity':True,'files':files,'terrain_properties':terrain,'saved_instances':len(place.instances)}
    (EVIDENCE/'baseline/intake.json').write_text(json.dumps(report,indent=2))
    print(json.dumps({k:v for k,v in report.items() if k not in ('files','terrain_properties')},indent=2))

def regression(name):
    suites=[]
    # CLI entry points from the baseline's verified regression list.
    base=json.loads((ROOT/'evidence/sprint_entrances_2026-10-26/regression.json').read_text())
    if (ROOT/'mountain/tests/quality_geometry.luau').exists():
        base['suites'].append({'suite':'quality_geometry.luau'})
    if (ROOT/'mountain/tests/alpine_profile.luau').exists():
        base['suites'].append({'suite':'alpine_profile.luau'})
    for name in ('compact_geometry.luau','arrival_readiness.luau'):
        if (ROOT/'mountain/tests'/name).exists():
            base['suites'].append({'suite':name})
    for row in base['suites']:
        f=ROOT/'mountain/tests'/row['suite']
        result=subprocess.run([sys.executable if f.suffix=='.py' else str(CLI),str(f)],cwd=ROOT,text=True,capture_output=True)
        suites.append({'suite':f.name,'exit':result.returncode,'output':result.stdout+result.stderr})
    compiles=[]
    for folder in ('shared','server','client','world'):
        for p in sorted((ROOT/'mountain'/folder).rglob('*.luau')):
            r=subprocess.run([str(COMPILER),'--null',str(p)],cwd=ROOT,text=True,capture_output=True)
            compiles.append({'file':p.relative_to(ROOT).as_posix(),'exit':r.returncode,'errors':r.stderr})
    report={'suites':suites,'compiles':compiles}
    (EVIDENCE/(name+'.json')).write_text(json.dumps(report,indent=2))
    for row in suites: print(row['suite'],row['exit'],row['output'].strip()[-400:])
    print('COMPILES',len(compiles),'FAILURES',sum(r['exit']!=0 for r in compiles))
    assert all(r['exit']==0 for r in suites+compiles)

def serve():
    class Handler(SimpleHTTPRequestHandler):
        def __init__(self,*a,**kw): super().__init__(*a,directory=str(ROOT),**kw)
        def do_POST(self):
            name=self.path.removeprefix('/')
            if '/' in name or '\\' in name or not name.endswith('.json'):
                self.send_error(400);return
            raw=self.rfile.read(int(self.headers['Content-Length']));json.loads(raw)
            (EVIDENCE/name).write_bytes(raw)
            self.send_response(200);self.end_headers();self.wfile.write(b'ok')
        def log_message(self,*a): pass
    ThreadingHTTPServer(('127.0.0.1',8854),Handler).serve_forever()

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('mode',choices=['baseline','regression','serve']);p.add_argument('--name',default='regression');a=p.parse_args()
    if a.mode=='baseline': baseline()
    elif a.mode=='regression': regression(a.name)
    else: serve()
