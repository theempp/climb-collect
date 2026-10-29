-- Isolated actors and a fresh service: never changes a live player's profile.
local T={}
function T.run()
 local module=script.Parent:FindFirstChild('Movement')
 assert(module,'Movement service missing')
 local copy=module:Clone();copy.Parent=script.Parent
 local M=require(copy)
 local attrs={CC_StaminaMax=100}
 local p={GetAttribute=function(_,k)return attrs[k]end}
 local function character()
  local ch=Instance.new('Model');local h=Instance.new('Humanoid');h.Parent=ch
  local r=Instance.new('Part');r.Name='HumanoidRootPart';r.Position=Vector3.new(10000,100,10000);r.Parent=ch
  p.Character=ch;return ch,h,r
 end
 local ctx={sessions={[p]={}},handlers={},C={STAGGER_SECONDS=1.2},on=function()end}
 M.init(ctx)
 local ch,h,r=character();M.onCharacter(p,ch)
 local s={mode='ground',stamina=50}
 local seq=0
 local function request(action,enabled,extra)
  seq+=1;local packet=extra or {};packet.action=action;packet.enabled=enabled
  packet.generation=ch:GetAttribute('CC_MovementGeneration');packet.seq=seq
  return ctx.handlers.movement(p,packet)
 end
 local count=0
 local function check(ok,label) assert(ok,label);count+=1 end
 local function tick(dt)
  local out=M.step(p,s,dt,workspace:GetServerTimeNow(),true);s.stamina=out.stamina;return out
 end
 r.AssemblyLinearVelocity=Vector3.new(16,0,0)
 tick(0);request('sprint',true);local out=tick(0.1)
 check(out.sprinting and math.abs(s.stamina-49)<0.001,'shared pool drain')
 s.mode='climb';out=tick(0.1)
 check(not out.requested and s.stamina==49,'climb preserves spent stamina')
 s.stamina-=2.5;s.mode='ground';out=tick(0.1)
 check(math.abs(s.stamina-47.8)<0.001 and not out.sprinting,'cancel recovers without resume')
 local a=M.lock(p,'test');local b=M.lock(p,'test')
 M.unlock(p,'test',a);check(tick(0).walkSpeed==0,'old token cannot unlock replacement')
 M.unlock(p,'test',b);check(tick(0).walkSpeed==16,'matching token unlocks')
 local oldGeneration=ch:GetAttribute('CC_MovementGeneration');local old=ch
 ch,h,r=character();M.onCharacter(p,ch);tick(0)
 ctx.handlers.movement(p,{action='sprint',enabled=true,generation=oldGeneration,seq=999})
 check(not tick(0).requested,'old character request rejected')
 M.unlock(p,'test',b);check(tick(0).walkSpeed==16,'old character unlock harmless')
 request('sprint',true,{speed=200,zone='lobby',stamina=999})
 check(not tick(0).requested,'extra authority fields rejected')
 attrs.CC_StaminaMax=20;s.stamina=70;check(tick(0).stamina==20,'maximum clamps')
 M.onLeave(p);check(M.approvedSpeed(p)==16,'leave clears service state')
 old:Destroy();ch:Destroy();copy:Destroy()
 return {passed=count,failed=0,kind='isolated fixtures'}
end
return T
