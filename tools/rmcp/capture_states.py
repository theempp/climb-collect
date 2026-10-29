"""capture_states.py <studio_id> <out_dir> <prefix> : during Play (StudioAids on), every HUD state fixture via UIProbe hudState."""
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
call('initialize', {'protocolVersion': '2024-11-05', 'capabilities': {}, 'clientInfo': {'name': 'caps', 'version': '1'}}, 60)
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
print('root', luau("local r=game.Players.LocalPlayer.PlayerGui.MountainHUD.SafeRoot.AbsoluteSize;local v=workspace.CurrentCamera.ViewportSize;return string.format('%dx%d vp %dx%d',r.X,r.Y,v.X,v.Y)"))
for st in (sys.argv[4:] or ['rest', 'carry', 'regrab', 'chase', 'sanctuary', 'battle']):
    luau(probe + f"pr:Invoke('close');pr:Invoke('hudState','{st}');task.wait(1.6) return 1")
    print(st, shot(f'{prefix}_{st}'), flush=True)
luau(probe + "pr:Invoke('hudState','live') return 1")
p.kill()
