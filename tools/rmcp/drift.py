"""drift.py <studio_id> [out.json] : compare every mountain/{server,shared,client} source with the open Studio copy (edit DataModel).
Same normalisation as sync_hud.py (CRLF->LF, strip, one trailing newline); hash h=(h*31+byte)%(2^31-1)."""
import json, pathlib, re, subprocess, sys
ROOTS = {'mountain/server': 'ServerScriptService.MountainServer', 'mountain/shared': 'ReplicatedStorage.MountainShared',
         'mountain/client': 'StarterPlayer.StarterPlayerScripts.MountainClient'}
def target(rel):
    for base, studio in ROOTS.items():
        if rel.startswith(base + '/'):
            parts = rel[len(base) + 1:].split('/'); parts[-1] = re.sub(r'(\.server|\.client)?\.luau$', '', parts[-1])
            return studio + '.' + '.'.join(parts)
def h(s):
    v = 0
    for b in s.encode('utf-8'): v = (v * 31 + b) % 2147483647
    return v
files = sorted(p.as_posix() for base in ROOTS for p in pathlib.Path(base).rglob('*.luau'))
want = {rel: h(pathlib.Path(rel).read_text(encoding='utf-8').replace('\r\n', '\n').strip() + '\n') for rel in files}
code = ["local r={}", "local function h(s) local v=0;for i=1,#s do v=(v*31+string.byte(s,i))%2147483647 end;return v end"]
for rel in files:
    parts = target(rel).split('.')
    get = 'game' + ''.join(f":FindFirstChild('{x}')" for x in parts)
    code.append(f"do local m={get};r['{rel}']=if m then h(m.Source) else -1 end")
code.append("return game:GetService('HttpService'):JSONEncode(r)")
here = pathlib.Path(__file__).parent
(here / 'args.json').write_text(json.dumps({'studio_id': sys.argv[1], 'datamodel_type': 'Edit', 'code': '\n'.join(code)}), encoding='utf-8')
raw = subprocess.run([sys.executable, str(here / 'rmcp.py'), 'call', 'execute_luau', str(here / 'args.json')], capture_output=True, text=True, check=True).stdout
got = json.loads(raw[raw.index('{'):raw.rindex('}') + 1])
drift = [[rel, 'missing' if got.get(rel, -1) == -1 else 'differs'] for rel in files if got.get(rel) != want[rel]]
out = {'sources': len(files), 'match': len(files) - len(drift), 'drift': drift}
print(json.dumps(out, indent=1))
if len(sys.argv) > 2: pathlib.Path(sys.argv[2]).write_text(json.dumps(out, indent=1), encoding='utf-8')
