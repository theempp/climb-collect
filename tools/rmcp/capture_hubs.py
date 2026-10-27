"""capture_hubs.py <studio_id> <out_dir> : during Play, open every hub/tab via the UIProbe and screen_capture each (one MCP session)."""
import base64, json, os, subprocess, sys, threading, queue, time, pathlib

studio, out = sys.argv[1], pathlib.Path(sys.argv[2]); out.mkdir(parents=True, exist_ok=True)
bat = os.path.expandvars(r'%LOCALAPPDATA%\Roblox\mcp.bat')
p = subprocess.Popen(['cmd.exe', '/c', bat], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, cwd=os.path.dirname(bat))
q = queue.Queue(); threading.Thread(target=lambda: [q.put(l) for l in p.stdout], daemon=True).start()
n = [1]
def call(method, params=None, timeout=120):
    n[0] += 1; i = n[0]
    p.stdin.write((json.dumps({'jsonrpc': '2.0', 'id': i, 'method': method, 'params': params or {}}) + '\n').encode()); p.stdin.flush()
    while True:
        try: m = json.loads(q.get(timeout=timeout))
        except ValueError: continue
        if m.get('id') == i: return m
call('initialize', {'protocolVersion': '2024-11-05', 'capabilities': {}, 'clientInfo': {'name': 'cap', 'version': '1'}}, 60)
p.stdin.write(b'{"jsonrpc":"2.0","method":"notifications/initialized"}\n'); p.stdin.flush(); time.sleep(8)
def luau(code):
    r = call('tools/call', {'name': 'execute_luau', 'arguments': {'studio_id': studio, 'datamodel_type': 'Client', 'code': code}})
    return ''.join(c.get('text', '') for c in r.get('result', {}).get('content', []))
def shot(name):
    r = call('tools/call', {'name': 'screen_capture', 'arguments': {'studio_id': studio, 'capture_id': name}})
    for c in r.get('result', {}).get('content', []):
        if c.get('type') == 'image': (out / f'{name}.png').write_bytes(base64.b64decode(c['data'])); return True
    return False
probe = "local pr=game.Players.LocalPlayer.PlayerGui.MountainHUD.UIProbe;"
tabs = json.loads(luau(probe + """local root=game.Players.LocalPlayer.PlayerGui.MountainHUD.SafeRoot;local r={}
for _,h in ipairs({'Creatures','Discovery','Sanctuary','Mountain','Social','Profile','Shop','Settings'}) do pr:Invoke('open',h);task.wait(.05)
 local t={};for _,o in ipairs(root.HubShade.Hub.Tabs:GetChildren()) do if o:IsA('TextButton') and o.Name:sub(1,3)=='Tab' then table.insert(t,o.Name:sub(4)) end end;table.insert(r,{h,t}) end
pr:Invoke('close');return game.HttpService:JSONEncode(r)"""))
shot('00_hud')
k = 0
for hub, ts in tabs:
    for tab in ts:
        k += 1
        luau(probe + f"pr:Invoke('open','{hub}');pr:Invoke('tab','{tab}');task.wait(.4) return 1")
        name = f"{k:02d}_{hub}_{tab.replace(' ', '')}"; print(name, shot(name), flush=True)
# Creature detail (first owned creature) through the QA-only 'detail' probe action.
luau(probe + "pr:Invoke('open','Creatures');pr:Invoke('detail');task.wait(.4) return 1"); print('detail', shot(f'{k+1:02d}_Creatures_Detail'))
luau(probe + "pr:Invoke('close') return 1")
p.kill()
