"""polish_taps.py <studio_id> <out.json> : during Play, real mouse clicks on the profile card (tap, tap again, tap outside just above it, dock tap) and the card state after each."""
import json, os, subprocess, sys, threading, queue, time

studio, out = sys.argv[1], sys.argv[2]
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
call('initialize', {'protocolVersion': '2024-11-05', 'capabilities': {}, 'clientInfo': {'name': 'taps', 'version': '1'}}, 60)
p.stdin.write(b'{"jsonrpc":"2.0","method":"notifications/initialized"}\n'); p.stdin.flush(); time.sleep(8)
def text(r): return ''.join(c.get('text', '') for c in r.get('result', {}).get('content', []))
def luau(code): return text(call('tools/call', {'name': 'execute_luau', 'arguments': {'studio_id': studio, 'datamodel_type': 'Client', 'code': code}}))
def click(path): return text(call('tools/call', {'name': 'user_mouse_input', 'arguments': {'studio_id': studio, 'datamodel_type': 'Client', 'actions': [{'action': 'moveTo', 'instance_path': path}, {'action': 'mouseButtonClick', 'mouse_button': 'left'}, {'action': 'wait', 'wait_time_ms': 600}]}}))
G = "local gui=game.Players.LocalPlayer.PlayerGui.MountainHUD;local card=gui:FindFirstChild('PlayerCard',true);local l=card:FindFirstChild('Launcher',true);"
state = G + "return string.format('launcher=%s h=%d y=%d hub=%s',tostring(l.Visible),card.AbsoluteSize.Y,card.AbsolutePosition.Y,tostring(gui.SafeRoot:FindFirstChild('HubShade') and gui.SafeRoot.HubShade.Visible))"
res = {}
# Probe target just outside the card's top edge, in a ScreenGui with the HUD's inset settings (not Active, so it sinks nothing).
res['setup'] = luau(G + """gui.UIProbe:Invoke('close');gui.UIProbe:Invoke('hudState','live');task.wait(1)
local sg=Instance.new('ScreenGui');sg.Name='QATapProbe';sg.IgnoreGuiInset=gui.IgnoreGuiInset;sg.ScreenInsets=gui.ScreenInsets;sg.DisplayOrder=-10;sg.Parent=gui.Parent
local a=Instance.new('Frame');a.Name='Above';a.BackgroundTransparency=1;a.Active=false;a.Size=UDim2.fromOffset(20,8);a.Parent=sg
a.Position=UDim2.fromOffset(card.AbsolutePosition.X+120,card.AbsolutePosition.Y-12)
return card:FindFirstChild('Info',true):GetFullName()..'|'..gui:FindFirstChild('Dock',true):FindFirstChildWhichIsA('GuiButton',true):GetFullName()""")
info, dockBtn = res['setup'].split('|')
info = info.replace('Players.' + info.split('.')[1], 'LocalPlayer', 1); dockBtn = dockBtn.replace('Players.' + dockBtn.split('.')[1], 'LocalPlayer', 1)
res['0_start'] = luau(state)
click(info); res['1_tap'] = luau(state)
click(info); res['2_tapAgain'] = luau(state)
click(info); res['3_tap'] = luau(state)
click('LocalPlayer.PlayerGui.QATapProbe.Above'); res['4_tapOutsideAbove'] = luau(state)
click(info); res['5_tap'] = luau(state)
click(dockBtn); res['6_dockTap'] = luau(state)
res['dockButton'] = dockBtn
luau(G + "gui.UIProbe:Invoke('close');gui.Parent.QATapProbe:Destroy();gui.UIProbe:Invoke('hudState','live') return 1")
json.dump(res, open(out, 'w'), indent=1); print(json.dumps(res, indent=1))
p.kill()
