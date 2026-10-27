"""sync_homebase.py <studio_id> : write the home-base rebuild sources into the open Studio copy (edit DataModel).
Creates missing scripts. Pass the studio id explicitly; never point it at a HUD-chat window."""
import json, pathlib, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
FILES = [  # repo path, parent path from game, name, class
    # Committed on the integration branch after Review06 (phone-candidate prep); synced so the place matches the branch.
    ('mountain/shared/BuildFlags.luau', 'ReplicatedStorage.MountainShared', 'BuildFlags', 'ModuleScript'),
    ('mountain/shared/OffspringAssets.luau', 'ReplicatedStorage.MountainShared', 'OffspringAssets', 'ModuleScript'),
    ('mountain/client/OffspringPresentation.client.luau', 'StarterPlayer.StarterPlayerScripts.MountainClient', 'OffspringPresentation', 'LocalScript'),
    ('mountain/client/UI/Controller.luau', 'StarterPlayer.StarterPlayerScripts.MountainClient.UI', 'Controller', 'ModuleScript'),
    ('mountain/shared/HomeLayout.luau', 'ReplicatedStorage.MountainShared', 'HomeLayout', 'ModuleScript'),
    ('mountain/shared/HomeDecor.luau', 'ReplicatedStorage.MountainShared', 'HomeDecor', 'ModuleScript'),
    ('mountain/shared/Tycoon.luau', 'ReplicatedStorage.MountainShared', 'Tycoon', 'ModuleScript'),
    ('mountain/shared/TycoonConfig.luau', 'ReplicatedStorage.MountainShared', 'TycoonConfig', 'ModuleScript'),
    ('mountain/shared/UIProtocol.luau', 'ReplicatedStorage.MountainShared', 'UIProtocol', 'ModuleScript'),
    ('mountain/server/Main.server.luau', 'ServerScriptService.MountainServer', 'Main', 'Script'),
    ('mountain/server/TycoonWorld.luau', 'ServerScriptService.MountainServer', 'TycoonWorld', 'ModuleScript'),
    ('mountain/server/UIRequests.luau', 'ServerScriptService.MountainServer', 'UIRequests', 'ModuleScript'),
    ('mountain/world/HomePromenade.luau', 'ServerStorage.MountainWorld', 'HomePromenade', 'ModuleScript'),
    ('mountain/client/TycoonConveyors.client.luau', 'StarterPlayer.StarterPlayerScripts.MountainClient', 'TycoonConveyors', 'LocalScript'),
    ('mountain/client/TycoonFeel.client.luau', 'StarterPlayer.StarterPlayerScripts.MountainClient', 'TycoonFeel', 'LocalScript'),
]
studio = sys.argv[1]
only = set(sys.argv[2:])
out = ['local r={}']
for rel, parent, name, cls in FILES:
    if only and name not in only:
        continue
    src = (ROOT / rel).read_text(encoding='utf-8').replace('\r\n', '\n').strip() + '\n'
    assert ']=====]' not in src
    find = 'game' + ''.join(f":FindFirstChild('{x}')" for x in parent.split('.'))
    out.append(f"do local p={find};assert(p,'{parent}');local m=p:FindFirstChild('{name}')"
               f" if not m then m=Instance.new('{cls}');m.Name='{name}';m.Parent=p end"
               f" m.Source=[=====[{src}]=====];table.insert(r,'{name}:'..#m.Source) end")
out.append("return table.concat(r,' ')")
here = pathlib.Path(__file__).parent
(here / 'args.json').write_text(json.dumps({'studio_id': studio, 'datamodel_type': 'Edit', 'code': '\n'.join(out)}), encoding='utf-8')
subprocess.run([sys.executable, str(here / 'rmcp.py'), 'call', 'execute_luau', str(here / 'args.json')], check=True)
