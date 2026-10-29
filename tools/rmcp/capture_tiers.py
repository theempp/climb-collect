"""capture_tiers.py <studio_id> <out_dir> [slot] : Play-mode shots of the S4 tier houses (needs StudioAids on + HomeDevTier).
Per tier: Server sets DevTier/DevRank on the slot, Client holds the camera (RenderStepped) on a plot-local view, screen_capture.
Writes <tier>_<view>.png plus a 19.5:9 centre crop <tier>_<view>_phone.png. HUD ScreenGuis are hidden during the shots and restored. Clears the override at the end."""
import base64, json, os, subprocess, sys, threading, queue, time, pathlib
from PIL import Image
studio, out = sys.argv[1], pathlib.Path(sys.argv[2]); out.mkdir(parents=True, exist_ok=True)
slot = int(sys.argv[3]) if len(sys.argv) > 3 else 1
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
def luau(dm, code):
    r = call('tools/call', {'name': 'execute_luau', 'arguments': {'studio_id': studio, 'datamodel_type': dm, 'code': code}})
    return ''.join(c.get('text', '') for c in r.get('result', {}).get('content', []))
def shot(name):
    r = call('tools/call', {'name': 'screen_capture', 'arguments': {'studio_id': studio, 'capture_id': name}})
    for c in r.get('result', {}).get('content', []):
        if c.get('type') == 'image':
            f = out / f'{name}.png'; f.write_bytes(base64.b64decode(c['data']))
            im = Image.open(f); w, h = im.size; cw = min(w, round(h * 19.5 / 9)); ch = min(h, round(cw * 9 / 19.5)); x0, y0 = (w - cw) // 2, (h - ch) // 2
            im.crop((x0, y0, x0 + cw, y0 + ch)).save(out / f'{name}_phone.png'); return True
    return False
tiers = [(1, 'hut', 1), (2, 'villa', 5), (3, 'manor', 15), (4, 'palace', 30)]
# plot-local (x, y, z) eye -> look; y 0 = floor top, -Z = toward the yard, house centre (0, 30)
views = [('front', (10, 8, 0), (0, 16, 30)), ('high', (-24, 44, -34), (0, 12, 30))]
hold = """local slot,ex,ey,ez,lx,ly,lz=...
local floor=workspace.Sanctuary.SanctuaryPlots:FindFirstChild(string.format('Plot_%02d',slot)).Plot_80x100
local base=floor.CFrame*CFrame.new(0,floor.Size.Y/2,0)
local cf=CFrame.lookAt((base*CFrame.new(ex,ey,ez)).Position,(base*CFrame.new(lx,ly,lz)).Position)
local c=workspace.CurrentCamera;if _G.CC_CAMHOLD then _G.CC_CAMHOLD:Disconnect() end
c.CameraType=Enum.CameraType.Scriptable;c.FieldOfView=60;c.CFrame=cf
_G.CC_CAMHOLD=game:GetService('RunService').RenderStepped:Connect(function() c.CameraType=Enum.CameraType.Scriptable;c.CFrame=cf end)
task.wait(1.5);return 'ok'"""
res = {}
luau('Client', "_G.CC_HIDDEN={};for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') and g.Enabled then g.Enabled=false;table.insert(_G.CC_HIDDEN,g) end end;return #_G.CC_HIDDEN")  # HUD off for the shots
for t, key, rank in tiers:
    res[key] = luau('Server', f"return table.concat({{game.ServerStorage.HomeDevTier:Invoke({slot},{t},{rank})}},' ')")
    for vname, e, l in views:
        args = ','.join(str(v) for v in (slot, *e, *l))
        luau('Client', f"return (function(...) {hold} end)({args})")
        res[f'{key}_{vname}'] = shot(f'{t}_{key}_{vname}')
luau('Client', "for _,g in _G.CC_HIDDEN or {} do g.Enabled=true end;_G.CC_HIDDEN=nil;if _G.CC_CAMHOLD then _G.CC_CAMHOLD:Disconnect();_G.CC_CAMHOLD=nil end;workspace.CurrentCamera.CameraType=Enum.CameraType.Custom;return 'ok'")
res['clear'] = luau('Server', f"return table.concat({{game.ServerStorage.HomeDevTier:Invoke({slot},nil,nil)}},' ')")
print(json.dumps(res)); p.kill()
