"""capture_motion.py <studio_id> <out_dir> [demo ...] : during Play (StudioAids on), frame sequences of the P6 motion.
Slows Motion with the QA time scale (UIProbe motionScale), starts each demo (UIProbe motionDemo) and takes back-to-back
screen captures; every frame is named with the elapsed motion time (s, at real speed) read from the probe."""
import base64, json, os, subprocess, sys, threading, queue, time, pathlib

studio, out = sys.argv[1], pathlib.Path(sys.argv[2]); out.mkdir(parents=True, exist_ok=True)
DEMOS = {  # demo -> (motion length s at real speed, time scale)
    'carry': (2.7, .1), 'run': (1.6, .1), 'banner': (2.6, .1), 'toast': (1.6, .12), 'moment': (2.6, .1),
    'reveal': (6.3, .12), 'chaseTap': (3.6, .25), 'card': (.3, .04), 'xp': (1.6, .12), 'rail': (4.2, .2), 'shop': (6.0, 1),
}
want = sys.argv[3:] or list(DEMOS)
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
call('initialize', {'protocolVersion': '2024-11-05', 'capabilities': {}, 'clientInfo': {'name': 'capm', 'version': '1'}}, 60)
p.stdin.write(b'{"jsonrpc":"2.0","method":"notifications/initialized"}\n'); p.stdin.flush(); time.sleep(8)
def luau(code):
    r = call('tools/call', {'name': 'execute_luau', 'arguments': {'studio_id': studio, 'datamodel_type': 'Client', 'code': code}})
    return ''.join(c.get('text', '') for c in r.get('result', {}).get('content', []))
def shot(path):
    r = call('tools/call', {'name': 'screen_capture', 'arguments': {'studio_id': studio, 'capture_id': path.stem}})
    for c in r.get('result', {}).get('content', []):
        if c.get('type') == 'image': path.write_bytes(base64.b64decode(c['data'])); return True
    return False
probe = "local pr=game.Players.LocalPlayer.PlayerGui.MountainHUD.UIProbe;"
log = {}
for demo in want:
    length, scale = DEMOS[demo]
    luau(probe + f"pr:Invoke('close');pr:Invoke('hudState','live');pr:Invoke('motionScale',{scale});task.wait(.3) return 1")
    start = json.loads(luau(probe + f"return pr:Invoke('motionDemo','{demo}').t0") or '0')
    frames = []; k = 0
    while True:
        t = json.loads(luau(probe + f"return pr:Invoke('motionDemo','clock')") or '0') - start
        real = round(t * scale, 2)
        if real > length: break
        k += 1; f = out / f'{demo}_{k:02d}_t{real:.2f}.png'
        if shot(f): frames.append(f.name)
    log[demo] = frames; print(demo, len(frames), flush=True)
luau(probe + "pr:Invoke('motionScale',1);pr:Invoke('close');pr:Invoke('hudState','live') return 1")
(out / 'frames.json').write_text(json.dumps(log, indent=1))
p.kill()
