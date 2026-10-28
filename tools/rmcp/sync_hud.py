"""sync_hud.py <studio_id> [--preview-icons] : write every HUD source into the open Studio copy (edit DataModel).
Missing targets are created (ModuleScript, or LocalScript for *.client.luau) under their existing parent.
Repo files that don't exist yet are skipped and listed.
--preview-icons points Theme.icons at rbxasset://textures/hudv2/<name>.png (local preview only, never committed)."""
import json, pathlib, re, subprocess, sys

UI = "StarterPlayer.StarterPlayerScripts.MountainClient.UI"
FILES = {  # repo path -> Studio path from game
    'mountain/client/UI/Theme.luau': f"{UI}.Theme",
    'mountain/client/UI/Widgets.luau': f"{UI}.Widgets",
    'mountain/client/UI/Motion.luau': f"{UI}.Motion",
    'mountain/client/UI/Controller.luau': f"{UI}.Controller",
    'mountain/client/UI/Hud.luau': f"{UI}.Hud",
    'mountain/client/UI/Screens.luau': f"{UI}.Screens",
    'mountain/client/UI/Shop.luau': f"{UI}.Shop",
    'mountain/client/UI/Feedback.luau': f"{UI}.Feedback",
    'mountain/client/UI/TycoonHub.luau': f"{UI}.TycoonHub",
    'mountain/client/Sprint.client.luau': "StarterPlayer.StarterPlayerScripts.MountainClient.Sprint",
    'mountain/shared/UIPresentation.luau': "ReplicatedStorage.MountainShared.UIPresentation",
    'mountain/shared/UIProtocol.luau': "ReplicatedStorage.MountainShared.UIProtocol",
    'mountain/shared/HudState.luau': "ReplicatedStorage.MountainShared.HudState",
}
studio, preview = sys.argv[1], '--preview-icons' in sys.argv
out = ['local r={}']
skipped = []
for rel, path in FILES.items():
    f = pathlib.Path(rel)
    if not f.exists():
        skipped.append(rel); continue
    src = f.read_text(encoding='utf-8').replace('\r\n', '\n').strip() + '\n'
    if preview and rel.endswith('Theme.luau'):
        sub = lambda line: re.sub(r"(\['?([\w-]+)'?\]|\b(\w+))=0(?=[,}])", lambda m: f"{m.group(1)}='rbxasset://textures/hudv2/{m.group(2) or m.group(3)}.png'", line)
        src = '\n'.join(sub(l) if l.lstrip().startswith('icons={') else l for l in src.split('\n'))
    parts = path.split('.')
    parent = 'game' + ''.join(f":FindFirstChild('{x}')" for x in parts[:-1])
    cls = 'LocalScript' if rel.endswith('.client.luau') else 'ModuleScript'
    out.append(
        f"do local p={parent};assert(p,'parent of {path}');local m=p:FindFirstChild('{parts[-1]}');local new=false\n"
        f" if not m then m=Instance.new('{cls}');m.Name='{parts[-1]}';m.Parent=p;new=true end\n"
        f" assert(m:IsA('{cls}'),'{path} is '..m.ClassName);m.Source=[=====[{src}]=====]\n"
        f" table.insert(r,(new and '+' or '')..'{parts[-1]}:'..#m.Source) end")
out.append("return table.concat(r,' ')")
if skipped: print('skipped (no repo file yet):', ', '.join(skipped))
here = pathlib.Path(__file__).parent
(here / 'args.json').write_text(json.dumps({'studio_id': studio, 'datamodel_type': 'Edit', 'code': '\n'.join(out)}), encoding='utf-8')
subprocess.run([sys.executable, str(here / 'rmcp.py'), 'call', 'execute_luau', str(here / 'args.json')], check=True)
