"""capture_swirl.py <studio_id> <out_dir> [k=.25] : Play-mode frame sequences of the tier-up swirl (intel C world.tierup).
Needs StudioAids on + HomeDevTier. Slows the swirl with the QA time scale k (MotionTimeScale; server swap and client beats both
honour it), holds the camera on the plot, triggers each raise with HomeDevTier and takes back-to-back screen captures.
Frames: <seq>_t<effect s>.png (effect time at real speed). Sequences: own plot 1->2, 2->3, 3->4; reduce (own plot, Reduce
effects on, 1->2); visitor (neighbour plot raised 1->2, 50 % caps). Each frame also logs the visible pool part count."""
import base64, json, os, subprocess, sys, threading, queue, time, pathlib
studio, out = sys.argv[1], pathlib.Path(sys.argv[2]); out.mkdir(parents=True, exist_ok=True)
k = float(sys.argv[3]) if len(sys.argv) > 3 else .25
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
call('initialize', {'protocolVersion': '2024-11-05', 'capabilities': {}, 'clientInfo': {'name': 'swirl', 'version': '1'}}, 60)
p.stdin.write(b'{"jsonrpc":"2.0","method":"notifications/initialized"}\n'); p.stdin.flush(); time.sleep(8)
def luau(dm, code):
    r = call('tools/call', {'name': 'execute_luau', 'arguments': {'studio_id': studio, 'datamodel_type': dm, 'code': code}})
    return ''.join(c.get('text', '') for c in r.get('result', {}).get('content', []))
def shot(name):
    r = call('tools/call', {'name': 'screen_capture', 'arguments': {'studio_id': studio, 'capture_id': name}})
    for c in r.get('result', {}).get('content', []):
        if c.get('type') == 'image': (out / f'{name}.png').write_bytes(base64.b64decode(c['data'])); return True
    return False
PLOT = "workspace.Sanctuary.SanctuaryPlots:FindFirstChild(string.format('Plot_%02d',{s}))"
# WorldFx pool probe (StudioAids): attributes on workspace.WorldFxPool (MCP Luau has its own VM, no shared _G).
POOL = """local f=workspace:FindFirstChild('WorldFxPool');if not f then return '0' end
return tostring(f:GetAttribute('cubes') or 0)..'/'..tostring(f:GetAttribute('orbs') or 0)..'/'..tostring(f:GetAttribute('rings') or 0)"""
hold = """local slot,ex,ey,ez,lx,ly,lz=...
local floor=workspace.Sanctuary.SanctuaryPlots:FindFirstChild(string.format('Plot_%02d',slot)).Plot_80x100
local base=floor.CFrame*CFrame.new(0,floor.Size.Y/2,0)
local cf=CFrame.lookAt((base*CFrame.new(ex,ey,ez)).Position,(base*CFrame.new(lx,ly,lz)).Position)
local c=workspace.CurrentCamera;if _G.CC_CAMHOLD then _G.CC_CAMHOLD:Disconnect() end
c.CameraType=Enum.CameraType.Scriptable;c.FieldOfView=60;c.CFrame=cf
_G.CC_CAMHOLD=game:GetService('RunService').RenderStepped:Connect(function() c.CameraType=Enum.CameraType.Scriptable;c.CFrame=cf end)
task.wait(1);return 'ok'"""
VIEW = ((-16, 26, -10), (0, 14, 30))
own = int(luau('Client', "return game.Players.LocalPlayer:GetAttribute('SanctuaryPlot') or 0").strip() or 0)
assert own, 'no SanctuaryPlot on the local player'
neighbour = own % 8 + 1
log = {'k': k, 'own': own, 'neighbour': neighbour, 'seqs': {}}
luau('Server', f"game.ReplicatedStorage:SetAttribute('MotionTimeScale',{k});return 'ok'")
luau('Client', "_G.CC_HIDDEN={};for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') and g.Enabled then g.Enabled=false;table.insert(_G.CC_HIDDEN,g) end end;return #_G.CC_HIDDEN")
RANK = {1: 1, 2: 5, 3: 15, 4: 30}
def dev(slot, tier): return luau('Server', f"return table.concat({{game.ServerStorage.HomeDevTier:Invoke({slot},{tier},{RANK[tier]})}},' ')")
def seq(name, slot, frm, to, reduce=False):
    luau('Client', f"game.Players.LocalPlayer:SetAttribute('MountainReducedMotion',{'true' if reduce else 'nil'});return 'ok'")
    dev(slot, frm); time.sleep(.5)
    luau('Client', f"return (function(...) {hold} end)({','.join(str(v) for v in (slot, *VIEW[0], *VIEW[1]))})")
    frames = []; dev(slot, to); t_ref = time.monotonic()
    off = float(luau('Client', f"local m={PLOT.format(s=slot)};return workspace:GetServerTimeNow()-(m:GetAttribute('TierUpAt') or workspace:GetServerTimeNow())").strip() or 0)
    t_ref -= off  # python clock at TierUpAt (real seconds)
    while (time.monotonic() - t_ref) * k < 6.8:
        t = (time.monotonic() - t_ref) * k
        nm = f'{name}_t{t:.2f}'
        if shot(nm): frames.append({'t': round(t, 2), 'pool': luau('Client', POOL).strip()})
    log['seqs'][name] = frames
seq('t12', own, 1, 2); seq('t23', own, 2, 3); seq('t34', own, 3, 4)
seq('reduce', own, 1, 2, reduce=True)
seq('visitor', neighbour, 1, 2)
luau('Client', "game.Players.LocalPlayer:SetAttribute('MountainReducedMotion',nil);for _,g in _G.CC_HIDDEN or {} do g.Enabled=true end;_G.CC_HIDDEN=nil;if _G.CC_CAMHOLD then _G.CC_CAMHOLD:Disconnect();_G.CC_CAMHOLD=nil end;workspace.CurrentCamera.CameraType=Enum.CameraType.Custom;return 'ok'")
luau('Server', f"game.ReplicatedStorage:SetAttribute('MotionTimeScale',nil);game.ServerStorage.HomeDevTier:Invoke({own},nil,nil);game.ServerStorage.HomeDevTier:Invoke({neighbour},nil,nil);return 'ok'")
(out / 'swirl_log.json').write_text(json.dumps(log, indent=1)); print(json.dumps({s: len(f) for s, f in log['seqs'].items()})); p.kill()
