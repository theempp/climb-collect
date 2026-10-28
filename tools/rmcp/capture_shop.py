"""capture_shop.py <studio_id> <out_dir> : during Play, Shop scroll states + hatch reveal via the UIProbe (STOP 3)."""
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
probe = "local pr=game.Players.LocalPlayer.PlayerGui.MountainHUD.UIProbe;local root=game.Players.LocalPlayer.PlayerGui.MountainHUD.SafeRoot;"
# Shop scroll states for STOP 3: top, mini hero, then each section header landed at the top of the scroll (offset - 4, task A rule).
luau(probe + "pr:Invoke('open','Shop');task.wait(1) return 1")
print('top', shot('shop_01_top'))
luau(probe + "root.HubShade.Hub.Content.Scroll.CanvasPosition=Vector2.new(0,40);task.wait(.6) return 1")
print('mini', shot('shop_02_mini'))
k = 2
for title in ['COINS', 'PASSES', 'BOOSTS', 'EGGS', 'BAT SKINS', 'BATS']:
    k += 1
    r = luau(probe + f"""local s=root.HubShade.Hub.Content.Scroll
for _,h in ipairs(s:GetDescendants()) do if h.Name=='SectionHeader' and h:FindFirstChild('Title') and h.Title.Text=='{title}' then
 s.CanvasPosition=Vector2.new(0,math.max(0,h.AbsolutePosition.Y-s.AbsolutePosition.Y+s.CanvasPosition.Y-4));task.wait(.6);return 'ok' end end return 'missing'""")
    print(title, r, shot(f"shop_{k:02d}_{title.replace(' ', '').lower()}"), flush=True)
    luau(probe + "local s=root.HubShade.Hub.Content.Scroll;s.CanvasPosition+=Vector2.new(0,100);task.wait(.6) return 1")
    print(title, 'low', shot(f"shop_{k:02d}b_{title.replace(' ', '').lower()}_low"), flush=True)
luau(probe + "pr:Invoke('close');pr:Invoke('reveal');task.wait(.8) return 1")
print('reveal', shot('reveal'))
luau(probe + "pr:Invoke('close') return 1")
p.kill()
