"""sync_hud.py <studio_id> [--preview-icons] : write every HUD v2 source into the open Studio copy (edit DataModel).
--preview-icons points Theme.icons at rbxasset://textures/hudv2/<name>.png (local preview only, never committed)."""
import json, pathlib, re, subprocess, sys

FILES = {  # repo path -> Studio path from game
    'mountain/client/UI/Theme.luau': "StarterPlayer.StarterPlayerScripts.MountainClient.UI.Theme",
    'mountain/client/UI/Widgets.luau': "StarterPlayer.StarterPlayerScripts.MountainClient.UI.Widgets",
    'mountain/client/UI/Controller.luau': "StarterPlayer.StarterPlayerScripts.MountainClient.UI.Controller",
    'mountain/client/UI/Screens.luau': "StarterPlayer.StarterPlayerScripts.MountainClient.UI.Screens",
    'mountain/client/UI/Feedback.luau': "StarterPlayer.StarterPlayerScripts.MountainClient.UI.Feedback",
    'mountain/client/UI/TycoonHub.luau': "StarterPlayer.StarterPlayerScripts.MountainClient.UI.TycoonHub",
    'mountain/client/Sprint.client.luau': "StarterPlayer.StarterPlayerScripts.MountainClient.Sprint",
    'mountain/shared/UIPresentation.luau': "ReplicatedStorage.MountainShared.UIPresentation",
}
studio, preview = sys.argv[1], '--preview-icons' in sys.argv
out = ['local r={}']
for rel, path in FILES.items():
    src = pathlib.Path(rel).read_text(encoding='utf-8').replace('\r\n', '\n').strip() + '\n'
    if preview and rel.endswith('Theme.luau'):
        sub = lambda line: re.sub(r"(\['?([\w-]+)'?\]|\b(\w+))=0(?=[,}])", lambda m: f"{m.group(1)}='rbxasset://textures/hudv2/{m.group(2) or m.group(3)}.png'", line)
        src = '\n'.join(sub(l) if l.lstrip().startswith('icons={') else l for l in src.split('\n'))
    find = 'game' + ''.join(f":FindFirstChild('{x}')" for x in path.split('.'))
    out.append(f"do local m={find};assert(m,'{path}');m.Source=[=====[{src}]=====];table.insert(r,'{path.split('.')[-1]}:'..#m.Source) end")
out.append("return table.concat(r,' ')")
here = pathlib.Path(__file__).parent
(here / 'args.json').write_text(json.dumps({'studio_id': studio, 'datamodel_type': 'Edit', 'code': '\n'.join(out)}), encoding='utf-8')
subprocess.run([sys.executable, str(here / 'rmcp.py'), 'call', 'execute_luau', str(here / 'args.json')], check=True)
