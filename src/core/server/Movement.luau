-- Ground movement authority. Traversal owns stamina and the only update clock.
local RS=game:GetService('ReplicatedStorage')
local C=require(RS.CC_Core.MovementConfig)
local Rules=require(RS.CC_Core.MovementRules)
local Anchors=require(script.Parent.LobbyAnchors)
local M={}
local ctx
local states={}
local serial=0
local function freshToken() serial+=1;return serial end
local function actor(p)
 local ch=p.Character
 return ch,ch and ch:FindFirstChildOfClass('Humanoid'),ch and ch:FindFirstChild('HumanoidRootPart')
end
function M.onCharacter(p,ch)
 if p.Character~=ch then return end
 local s={character=ch,generation=freshToken(),seq=0,locks={},requested=false,exhausted=false,speed=C.walkSpeed,requests={}}
 states[p]=s;ch:SetAttribute('CC_MovementGeneration',s.generation)
end
function M.cancel(p)
 local s=states[p];if s then s.requested=false;s.sprinting=false end
end
function M.lock(p,key,duration)
 local s=states[p];if not s then return nil end
 local token=freshToken()
 s.locks[key]={token=token,expires=duration and workspace:GetServerTimeNow()+math.max(0,duration)}
 M.cancel(p);return token
end
function M.unlock(p,key,token)
 local s=states[p];local lock=s and s.locks[key]
 if lock and lock.token==token then s.locks[key]=nil end
end
function M.approvedSpeed(p)
 local s=states[p];return s and s.speed or C.walkSpeed
end
function M.step(p,traversal,dt,now,grounded)
 local ch,h,r=actor(p)
 local s=states[p]
 if ch and (not s or s.character~=ch) then M.onCharacter(p,ch);s=states[p] end
 if not s then return {stamina=traversal.stamina,walkSpeed=0,requested=false,sprinting=false} end
 local zone='mountain'
 if ch:GetAttribute('CC_HomeVisit') then zone='home'
 elseif r then
  local ok,inside=pcall(Anchors.contains,r.Position,workspace:FindFirstChild('World'))
  if ok and inside then zone='lobby' end
 end
 if s.zone~=zone then M.cancel(p) end
 s.zone=zone
 local locked=false
 for key,lock in pairs(s.locks) do
  if lock.expires and now>=lock.expires then s.locks[key]=nil else locked=true end
 end
 locked=locked or not r or not h or r.Anchored or h.PlatformStand or ch:GetAttribute('CC_SummitSaving')==true
 local moving=r and (r.AssemblyLinearVelocity*Vector3.new(1,0,1)).Magnitude>C.motionThreshold or false
 if grounded and traversal.mode~='fall' then s.airSince=nil else s.airSince=s.airSince or now end
 local out=Rules.step(s,{zone=zone,mode=traversal.mode,alive=h~=nil and h.Health>0,grounded=grounded,moving=moving,locked=locked,stamina=traversal.stamina,maxStamina=p:GetAttribute('CC_StaminaMax') or 100,airborneFor=s.airSince and now-s.airSince or 0},dt,C)
 s.requested,s.exhausted,s.sprinting,s.speed=out.requested,out.exhausted,out.sprinting,out.walkSpeed
 if h then h.WalkSpeed=out.walkSpeed end
 ch:SetAttribute('CC_MovementZone',zone)
 ch:SetAttribute('CC_Sprinting',out.sprinting)
 ch:SetAttribute('CC_SprintRequested',out.requested)
 ch:SetAttribute('CC_SprintAvailable',zone=='mountain' and grounded and traversal.mode=='ground' and not locked and not out.exhausted and h~=nil and h.Health>0)
 ch:SetAttribute('CC_SprintExhausted',out.exhausted)
 ch:SetAttribute('CC_MoveSpeed',out.walkSpeed)
 ch:SetAttribute('CC_MovementLocked',locked)
 return out
end
function M.state(p,snapshot)
 local s=states[p];if s then snapshot.movement={zone=s.zone,sprinting=s.sprinting,exhausted=s.exhausted} end
end
function M.onLeave(p) states[p]=nil end
local allowed={action=true,enabled=true,generation=true,seq=true}
local function handle(p,packet)
 local s=states[p]
 if not s or not ctx.sessions[p] or p.Character~=s.character or type(packet)~='table' then return end
 for key in pairs(packet) do if not allowed[key] then return end end
 if (packet.action~='sprint' and packet.action~='suppress') or type(packet.enabled)~='boolean'
  or packet.generation~=s.generation or not (type(packet.seq)=='number' and packet.seq==packet.seq and packet.seq%1==0 and packet.seq>s.seq and packet.seq<1e12) then return end
 local now=workspace:GetServerTimeNow()
 local recent={};for _,t in ipairs(s.requests) do if now-t<1 then table.insert(recent,t) end end
 s.requests=recent;if #recent>=10 then return end
 table.insert(recent,now);s.seq=packet.seq
 if packet.action=='suppress' then
  if packet.enabled then M.lock(p,'clientModal',1.5) else s.locks.clientModal=nil;M.cancel(p) end
 elseif not packet.enabled then M.cancel(p)
 elseif s.character:GetAttribute('CC_SprintAvailable')==true then s.requested=true end
end
function M.init(c)
 ctx=c;ctx.Movement=M;ctx.handlers.movement=handle
 ctx.on('hit',function(p) M.lock(p,'guardian',ctx.C.STAGGER_SECONDS) end)
end
return M
