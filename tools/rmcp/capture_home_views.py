"""capture_home_views.py <studio_id> <out_dir> : Edit-mode camera shots of the layout C grey-box (top-down, streets, garden), one MCP session."""
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
    r = call('tools/call', {'name': 'execute_luau', 'arguments': {'studio_id': studio, 'datamodel_type': 'Edit', 'code': code}})
    return ''.join(c.get('text', '') for c in r.get('result', {}).get('content', []))
def shot(name):
    r = call('tools/call', {'name': 'screen_capture', 'arguments': {'studio_id': studio, 'capture_id': name}})
    for c in r.get('result', {}).get('content', []):
        if c.get('type') == 'image': (out / f'{name}.png').write_bytes(base64.b64decode(c['data'])); return True
    return False
a, y = 4096, 22
views = [v for v in [
 ('01_topdown', (a, 1000, 150), (a, 16, 150), 'up'),
 ('02_vstreet_gateplaza_south', (a + 15, y, -150), (a, 16, 100), None),
 ('03_vstreet_blockA', (a + 22, y, -40), (a, 18, 200), None),
 ('04_vstreet_blockB_north', (a - 22, y, 300), (a, 30, -166), None),
 ('05_hstreet_crossing_west', (a + 30, y, 90), (a - 195, 18, 90), None),
 ('06_hstreet_westend_east', (a - 186, y, 75), (a + 100, 18, 100), None),
 ('07_hstreet_eastend_west', (a + 186, y, 105), (a - 100, 18, 80), None),
 ('08_garden_blockA_west', (a - 20, 40, -40), (a - 110, 14, -26), None),
] if len(sys.argv) < 4 or v[0] in sys.argv[3].split(',')]
prev = luau("local c=workspace.CurrentCamera;return tostring(c.CFrame)")
res = {}
for name, pos, look, up in views:
    upv = 'Vector3.new(0,0,-1)' if up else 'Vector3.yAxis'
    luau(f"local c=workspace.CurrentCamera;c.FieldOfView=70;c.CFrame=CFrame.lookAt(Vector3.new({pos[0]},{pos[1]},{pos[2]}),Vector3.new({look[0]},{look[1]},{look[2]}),{upv});task.wait(1.5);return 'ok'")
    res[name] = shot(name)
print(json.dumps(res)); p.kill()
