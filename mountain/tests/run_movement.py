"""Exercise the actual movement authority with minimal character/signal adapters."""
from service_harness import module, CLI
from pathlib import Path
import subprocess, tempfile
body = "local require=function(v) return v end\nlocal R=" + module('mountain/shared/MovementRules.luau')
body += r'''
local game={ReplicatedStorage={MountainShared={MovementRules=R}}}
local function signal()
 local s={listeners={}}
 function s:Connect(fn)
  local c={fn=fn,live=true};table.insert(self.listeners,c)
  function c:Disconnect() self.live=false end
  return c
 end
 function s:Fire(...) for _,c in ipairs(self.listeners) do if c.live then c.fn(...) end end end
 return s
end
local remote={OnServerEvent=signal()};local now=10
local h={Health=100,Sit=false,PlatformStand=false,Died=signal()}
local c={attrs={},carrySignal=signal()}
function c:FindFirstChildOfClass() return h end
function c:GetAttribute(k) return self.attrs[k] end
function c:SetAttribute(k,v) self.attrs[k]=v end
function c:GetAttributeChangedSignal() return self.carrySignal end
local p={Character=c}
'''
body += '\nlocal M=' + module('mountain/server/Movement.luau')
body += r'''
local checks=0;local function check(v,m) assert(v,m);checks+=1 end
local s=M.new(remote,function() return now end)
s.bind(p,c);check(h.WalkSpeed==16 and c.attrs.Sprinting==false,'bind resets')
remote.OnServerEvent:Fire(p,true);check(h.WalkSpeed==27 and c.attrs.Sprinting,'remote intent')
c.attrs.CarryingCreature=true;c.carrySignal:Fire();check(math.abs(h.WalkSpeed-24.3)<.001,'pickup immediate')
s.request(p,false);check(math.abs(h.WalkSpeed-14.4)<.001,'loaded release immediate')
check(not s.request(p,1000) and h.WalkSpeed==14.4,'arbitrary speed rejected')
check(s.request(p,true) and h.WalkSpeed==24.3,'quick release/repress is never lost')
check(not s.request(p,true),'duplicate press paced')
now+=1;s.request(p,true);h.Sit=true;s.update(p);check(h.WalkSpeed==14.4 and not c.attrs.Sprinting,'seated')
h.Sit=false;s.update(p);check(h.WalkSpeed==24.3,'resume seated intent')
h.Health=0;h.Died:Fire();check(not c.attrs.Sprinting,'death clears')
h.Health=100;s.update(p);check(h.WalkSpeed==14.4,'death intent stays cleared')
c.attrs.CarryingCreature=false;c.carrySignal:Fire();check(h.WalkSpeed==16,'put down immediate')
now+=1;s.request(p,true);s.bind(p,c);check(h.WalkSpeed==16 and not c.attrs.Sprinting,'respawn resets')
s.clear(p);check(not s.request(p,true),'removed player ignored')
print('PASS '..checks..' movement authority checks')
'''
with tempfile.TemporaryDirectory(prefix='movement-') as directory:
    target=Path(directory)/'test.luau'
    target.write_text(body,encoding='utf8')
    subprocess.run([str(CLI),str(target)],check=True)
