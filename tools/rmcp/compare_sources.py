"""compare_sources.py <studio_id> : hash every runtime source (same mapping as package_free_climb.py) in the open place and in the repo."""
import json, pathlib, re, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
PREFIXES = {'shared': 'ReplicatedStorage.MountainShared', 'world': 'ServerStorage.MountainWorld',
            'server': 'ServerScriptService.MountainServer', 'client': 'StarterPlayer.StarterPlayerScripts.MountainClient'}
rows = []
for folder, prefix in PREFIXES.items():
    for path in sorted((ROOT / 'mountain' / folder).rglob('*.luau')):
        rel = path.relative_to(ROOT / 'mountain' / folder)
        rows.append(('.'.join([prefix, *rel.parts[:-1]]), path.name.split('.')[0], '', path.relative_to(ROOT).as_posix()))
def norm(s): return '\n'.join(l.rstrip() for l in s.replace('\r\n', '\n').split('\n')).rstrip()
def h(s):
    v = 0
    for b in s.encode('utf-8'): v = (v * 31 + b) % 2147483647
    return v
code = ['local function norm(s) s=s:gsub("\\r\\n","\\n");local t={};for l in (s.."\\n"):gmatch("(.-)\\n") do table.insert(t,(l:gsub("%s+$",""))) end;return (table.concat(t,"\\n"):gsub("%s+$","")) end',
        'local function h(s) local v=0;for i=1,#s do v=(v*31+s:byte(i))%2147483647 end;return v end', 'local r={}']
for parent, name, cls, path in rows:
    find = 'game' + ''.join(f":FindFirstChild('{x}')" for x in parent.split('.'))
    code.append(f"do local p={find};local m=p and p:FindFirstChild('{name}');r['{path}']=if m then h(norm(m.Source)) else -1 end")
code.append("return game:GetService('HttpService'):JSONEncode(r)")
here = pathlib.Path(__file__).parent
(here / 'args.json').write_text(json.dumps({'studio_id': sys.argv[1], 'datamodel_type': 'Edit', 'code': '\n'.join(code)}), encoding='utf-8')
out = subprocess.run([sys.executable, str(here / 'rmcp.py'), 'call', 'execute_luau', str(here / 'args.json')], capture_output=True, text=True).stdout
studio = json.loads(out.strip().splitlines()[-1])
bad = [p for _, _, _, p in rows if studio.get(p) != h(norm((ROOT / p).read_text(encoding='utf-8')))]
print(json.dumps({'sources': len(rows), 'match': len(rows) - len(bad), 'mismatch': bad}))
