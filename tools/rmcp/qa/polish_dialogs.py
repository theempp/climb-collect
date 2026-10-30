"""polish_dialogs.py <studio_id> <out_dir> <prefix> : during Play (StudioAids on), the confirm and reward dialogs via UIProbe 'dialog', plus pill/dialog rects."""
import base64, json, os, subprocess, sys, threading, queue, time, pathlib

studio, out, prefix = sys.argv[1], pathlib.Path(sys.argv[2]), sys.argv[3]; out.mkdir(parents=True, exist_ok=True)
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
call('initialize', {'protocolVersion': '2024-11-05', 'capabilities': {}, 'clientInfo': {'name': 'dlg', 'version': '1'}}, 60)
p.stdin.write(b'{"jsonrpc":"2.0","method":"notifications/initialized"}\n'); p.stdin.flush(); time.sleep(8)
def luau(code):
    r = call('tools/call', {'name': 'execute_luau', 'arguments': {'studio_id': studio, 'datamodel_type': 'Client', 'code': code}})
    return ''.join(c.get('text', '') for c in r.get('result', {}).get('content', []))
def shot(name):
    r = call('tools/call', {'name': 'screen_capture', 'arguments': {'studio_id': studio, 'capture_id': name}})
    for c in r.get('result', {}).get('content', []):
        if c.get('type') == 'image': (out / f'{name}.png').write_bytes(base64.b64decode(c['data'])); return True
    return False
probe = "local gui=game.Players.LocalPlayer.PlayerGui.MountainHUD;local pr=gui.UIProbe;"
rect = """local d;for _,o in ipairs(gui:GetDescendants()) do if o.Name=='Dialog' and o:IsA('GuiObject') and o.Visible then d=o end end
local t=d and d:FindFirstChild('TitleRibbon',true)
return d and t and string.format('dialog x%d w%d y%d | pill cx%.1f top%.1f h%d w%d',d.AbsolutePosition.X,d.AbsoluteSize.X,d.AbsolutePosition.Y,t.AbsolutePosition.X+t.AbsoluteSize.X/2,t.AbsolutePosition.Y-d.AbsolutePosition.Y,t.AbsoluteSize.Y,t.AbsoluteSize.X) or 'no dialog/pill'"""
for kind in ('confirm', 'reward'):
    luau(probe + "pr:Invoke('close');pr:Invoke('hudState','rest');task.wait(.5) return 1")
    print(kind, luau(probe + f"pr:Invoke('dialog','{kind}');task.wait(1.2) " + rect), shot(f'{prefix}_dialog_{kind}'), flush=True)
luau(probe + "pr:Invoke('close');pr:Invoke('hudState','live') return 1")
p.kill()
