"""capture_extras.py <studio_id> <out_dir> : during Play (StudioAids on), P7 final extras: gamepad focus (dock, hub tab, Shop buy)
and Reduce-effects end states (each HUD state, Shop, reveal) via UIProbe motionPrefs."""
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
call('initialize', {'protocolVersion': '2024-11-05', 'capabilities': {}, 'clientInfo': {'name': 'capx', 'version': '1'}}, 60)
p.stdin.write(b'{"jsonrpc":"2.0","method":"notifications/initialized"}\n'); p.stdin.flush(); time.sleep(8)
def luau(code):
    r = call('tools/call', {'name': 'execute_luau', 'arguments': {'studio_id': studio, 'datamodel_type': 'Client', 'code': code}})
    return ''.join(c.get('text', '') for c in r.get('result', {}).get('content', []))
def shot(name):
    r = call('tools/call', {'name': 'screen_capture', 'arguments': {'studio_id': studio, 'capture_id': name}})
    for c in r.get('result', {}).get('content', []):
        if c.get('type') == 'image': (out / f'{name}.png').write_bytes(base64.b64decode(c['data'])); return True
    return False
pre = "local gs=game:GetService('GuiService');local gui=game.Players.LocalPlayer.PlayerGui.MountainHUD;local pr=gui.UIProbe;local root=gui.SafeRoot;"
def first(where):  # first visible selectable GuiButton under <where>, by screen order
    return pre + f"""local best;for _,o in ipairs({where}:GetDescendants()) do if o:IsA('GuiButton') and o.Selectable and o.Visible and o.AbsoluteSize.X>0 then
 if not best or o.AbsolutePosition.Y<best.AbsolutePosition.Y-1 or (math.abs(o.AbsolutePosition.Y-best.AbsolutePosition.Y)<=1 and o.AbsolutePosition.X<best.AbsolutePosition.X) then best=o end end end
gs.SelectedObject=best;task.wait(.3) return best and best:GetFullName() or 'none'"""
luau(pre + "pr:Invoke('close');pr:Invoke('hudState','rest');task.wait(1) return 1")
print('dock', luau(first("root:FindFirstChild('Dock',true)")), shot('gamepad_01_dock'))
luau(pre + "gs.SelectedObject=nil;pr:Invoke('open','Settings');task.wait(.8) return 1")
print('tab', luau(first("root.HubShade.Hub.Tabs")), shot('gamepad_02_settings_tab'))
luau(pre + "gs.SelectedObject=nil;pr:Invoke('open','Shop');pr:Invoke('tab','Coins');task.wait(1.2) return 1")
print('buy', luau(first("root.HubShade.Hub.Content")), shot('gamepad_03_shop_content'))
luau(pre + "gs.SelectedObject=nil;pr:Invoke('close');pr:Invoke('reveal');task.wait(6.5) return 1"); print('reveal landed', shot('reveal_landed'))
luau(pre + "pr:Invoke('close');pr:Invoke('motionPrefs',{reducedMotion=true,simplifiedVFX=true}) return 1")
for st in ['rest', 'carry', 'chase', 'sanctuary', 'battle']:
    luau(pre + f"pr:Invoke('close');pr:Invoke('hudState','{st}');task.wait(1) return 1"); print('reduced', st, shot(f'reduced_{st}'))
luau(pre + "pr:Invoke('hudState','live');pr:Invoke('open','Shop');task.wait(1) return 1"); print('reduced shop', shot('reduced_shop'))
luau(pre + "pr:Invoke('close');pr:Invoke('reveal');task.wait(6.5) return 1"); print('reduced reveal', shot('reduced_reveal'))
luau(pre + "pr:Invoke('close');pr:Invoke('motionPrefs',nil);pr:Invoke('hudState','live') return 1")
p.kill()
