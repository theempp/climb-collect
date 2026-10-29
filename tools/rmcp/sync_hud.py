"""sync_hud.py <studio_id> [--preview-icons] [--changed <rev>] [--dry] : write sources into the open Studio copy (edit DataModel).
Default set = the HUD files below. --changed <rev> adds every mountain/{server,shared,client} source changed since <rev>.
Repo path -> Studio path follows mountain.project.json; *.server.luau = Script, *.client.luau = LocalScript, else ModuleScript.
Missing targets are created under their existing parent; repo files that don't exist yet are skipped and listed.
Asserts game.PlaceId==0 before writing. --preview-icons points Theme.icons at rbxasset://textures/hudv2/<name>.png (local preview only)."""
import json, pathlib, re, subprocess, sys

ROOTS = {'mountain/server': 'ServerScriptService.MountainServer', 'mountain/shared': 'ReplicatedStorage.MountainShared',
         'mountain/client': 'StarterPlayer.StarterPlayerScripts.MountainClient'}
SKIP = {'mountain/server/StudioTests.luau'}  # QA module, stripped from the phone-candidate lineage
HUD = ['mountain/client/UI/Theme.luau', 'mountain/client/UI/Widgets.luau', 'mountain/client/UI/Motion.luau',
       'mountain/client/UI/Controller.luau', 'mountain/client/UI/Hud.luau', 'mountain/client/UI/Screens.luau',
       'mountain/client/UI/Shop.luau', 'mountain/client/UI/Feedback.luau', 'mountain/client/UI/TycoonHub.luau',
       'mountain/client/UI/ClientState.luau', 'mountain/client/Sprint.client.luau', 'mountain/shared/UIPresentation.luau',
       'mountain/shared/UIProtocol.luau', 'mountain/shared/HudState.luau']

def target(rel):
    for base, studio in ROOTS.items():
        if rel.startswith(base + '/'):
            parts = rel[len(base) + 1:].split('/')
            leaf = parts[-1]
            cls = 'Script' if leaf.endswith('.server.luau') else 'LocalScript' if leaf.endswith('.client.luau') else 'ModuleScript'
            parts[-1] = re.sub(r'(\.server|\.client)?\.luau$', '', leaf)
            return studio + '.' + '.'.join(parts), cls
    raise SystemExit('no Studio root for ' + rel)

args = sys.argv[1:]
studio, preview, dry = args[0], '--preview-icons' in args, '--dry' in args
files = list(HUD)
if '--changed' in args:
    rev = args[args.index('--changed') + 1]
    names = subprocess.run(['git', 'diff', '--name-only', rev, '--', *ROOTS], capture_output=True, text=True, check=True).stdout.split()
    names += subprocess.run(['git', 'ls-files', '--others', '--exclude-standard', '--', *ROOTS], capture_output=True, text=True, check=True).stdout.split()  # P7: working tree + new files
    files += [n for n in names if n.endswith('.luau') and n not in files]
out = ["assert(game.PlaceId==0,'PlaceId is '..game.PlaceId..': refusing to sync into a linked place')", 'local r={}']
skipped = []
for rel in files:
    f = pathlib.Path(rel)
    if rel in SKIP or not f.exists():
        skipped.append(rel); continue
    path, cls = target(rel)
    src = f.read_text(encoding='utf-8').replace('\r\n', '\n').strip() + '\n'
    if preview and rel.endswith('Theme.luau'):
        sub = lambda line: re.sub(r"(\['?([\w-]+)'?\]|\b(\w+))=0(?=[,}])", lambda m: f"{m.group(1)}='rbxasset://textures/hudv2/{m.group(2) or m.group(3)}.png'", line)
        src = '\n'.join(sub(l) if l.lstrip().startswith('icons={') else l for l in src.split('\n'))
    parts = path.split('.')
    parent = 'game' + ''.join(f":FindFirstChild('{x}')" for x in parts[:-1])
    if dry:
        print(f'{rel} -> {path} ({cls})'); continue
    out.append(
        f"do local p={parent};assert(p,'parent of {path}');local m=p:FindFirstChild('{parts[-1]}');local new=false\n"
        f" if not m then m=Instance.new('{cls}');m.Name='{parts[-1]}';m.Parent=p;new=true end\n"
        f" assert(m:IsA('{cls}'),'{path} is '..m.ClassName);m.Source=[=====[{src}]=====]\n"
        f" table.insert(r,(new and '+' or '')..'{parts[-1]}:'..#m.Source) end")
out.append("return table.concat(r,' ')")
if skipped: print('skipped:', ', '.join(skipped))
if dry: sys.exit(0)
here = pathlib.Path(__file__).parent
(here / 'args.json').write_text(json.dumps({'studio_id': studio, 'datamodel_type': 'Edit', 'code': '\n'.join(out)}), encoding='utf-8')
subprocess.run([sys.executable, str(here / 'rmcp.py'), 'call', 'execute_luau', str(here / 'args.json')], check=True)
