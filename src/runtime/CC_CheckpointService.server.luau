-- Authoritative fall/checkpoint and server-movement boundary. Client fall reports are hints only.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local Run=game:GetService("RunService")
local Rules=require(RS:WaitForChild("CC_Core"):WaitForChild("TraversalRules"))
local FALL_DROP=24
local states={}
local function make(parent,class,name)
 local x=parent:FindFirstChild(name) or Instance.new(class); x.Name=name; x.Parent=parent; return x
end
local remotes=make(RS,"Folder","CC_Remotes")
local fellEv=make(remotes,"RemoteEvent","Fell")
local cpEv=make(remotes,"RemoteEvent","Checkpoint")
local api=make(SS,"Folder","CC_CheckpointAPI")
local fellBE=make(api,"BindableEvent","Fell")
local campBE=make(api,"BindableEvent","CampReached")
local observedBE=make(api,"BindableEvent","MovementObserved")
local travelBE=make(api,"BindableEvent","AuthorizedTravel")
local checkpointBE=make(api,"BindableEvent","CheckpointConfirmed")
local setCp=make(api,"BindableFunction","SetCheckpoint")
local auth=make(api,"BindableFunction","AuthorizeMove")
local validateMove=make(api,"BindableFunction","ValidateMovement")
local function state(plr) states[plr]=states[plr] or {}; return states[plr] end
local function root(plr)
 local ch=plr.Character; return ch,ch and ch:FindFirstChildOfClass("Humanoid"),ch and ch:FindFirstChild("HumanoidRootPart")
end
local function safeMode(ch)
 local m=ch:GetAttribute("CC_TraversalState")
 return m=="climb" or m=="rope" or m=="hanging" or m=="flight" or m=="travel"
end
local function resetBaseline(plr,pos)
 local s=state(plr); s.groundY=pos and pos.Y or nil; s.airY=nil; s.prev=pos; s.prevAt=os.clock(); s.grace=os.clock()+0.5
end
local function spawnAt(plr,pos)
 local ch,_,r=root(plr)
 if r then travelBE:Fire(plr,'respawn',pos);resetBaseline(plr,pos); r.AssemblyLinearVelocity=Vector3.zero; ch:PivotTo(CFrame.new(pos)) end
end
local function validObservedMove(plr)
 local s=state(plr); local _,_,r=root(plr)
 if not r then return false end
 if s.prev and s.prevAt then
  local delta=r.Position-s.prev
  if not Rules.movementAllowed((delta*Vector3.new(1,0,1)).Magnitude,delta.Y,os.clock()-s.prevAt) then
   plr:SetAttribute("CC_MovementInvalidUntil",workspace:GetServerTimeNow()+8)
   observedBE:Fire(plr,r.Position,false,false,0)
   s.pending=nil; spawnAt(plr,s.prev); return false
  end
 end
 return true
end
validateMove.OnInvoke=function(plr)
 if workspace:GetServerTimeNow()<(plr:GetAttribute("CC_MovementInvalidUntil") or 0) then return false end
 if not validObservedMove(plr) then return false end
 -- A bank request can arrive between touchdown and the next fall heartbeat.
 -- Keep the cargo carried until that already-measured drop receives its normal outcome.
 local s=state(plr); local _,_,r=root(plr)
 local baseline=s.airY or s.groundY
 return not baseline or baseline-r.Position.Y<=FALL_DROP
end
local function basePosition()
 local sp=workspace:FindFirstChildOfClass("SpawnLocation")
 return sp and sp.Position+Vector3.yAxis*4 or Vector3.new(0,50,2160)
end
local function acceptFall(plr,drop)
 local s=state(plr)
 local ch,_,r=root(plr)
 if not r or not Rules.finite(drop) or drop<FALL_DROP or safeMode(ch) or ch:GetAttribute("CC_HomeVisit") then return end
 if os.clock()-(s.lastFall or -10)<1.5 then return end
 s.lastFall=os.clock(); s.falls=(s.falls or 0)+1
 plr:SetAttribute("CC_Falls",s.falls)
 local landingY=r.Position.Y
 spawnAt(plr,s.pos and s.pos+Vector3.yAxis*4 or basePosition())
 fellBE:Fire(plr,landingY)
end
-- No client-supplied drop is authoritative. The server's measured airborne baseline is required.
fellEv.OnServerEvent:Connect(function(plr)
 local s=state(plr); local _,_,r=root(plr)
 if r and s.airY then acceptFall(plr,s.airY-r.Position.Y) end
end)
auth.OnInvoke=function(plr,pos,kind)
 if typeof(pos)~="Vector3" then return false end
 travelBE:Fire(plr,kind,pos);resetBaseline(plr,pos)
 plr:SetAttribute("CC_LastTravelKind",tostring(kind or "server"))
 plr:SetAttribute("CC_MovementInvalidUntil",nil)
 return true
end
setCp.OnInvoke=function(plr,name)
 local s=state(plr); resetBaseline(plr,nil)
 if name==nil then s.name,s.pos,s.order=nil,nil,nil; plr:SetAttribute("CC_Checkpoint",""); return nil end
 local w=workspace:FindFirstChild("World"); local f=w and w:FindFirstChild("Checkpoints")
 for _,t in ipairs(f and f:GetChildren() or {}) do
  if t:GetAttribute("Checkpoint")==name and t:GetAttribute("Route")~="Ledge" and t:GetAttribute("Route")~="Spire" then
   s.name,s.pos,s.order=name,t.Position-Vector3.yAxis*(t.Size.Y/2-1),t:GetAttribute("Order")
   local idx=tonumber(string.match(name,"^Camp(%d)$")); s.highest=math.max(s.highest or 0,idx or 0)
   plr:SetAttribute("CC_Checkpoint",name); return s.pos
  end
 end
 return nil
end
local function onTouched(t,hit)
 local plr=Players:GetPlayerFromCharacter(hit.Parent)
 if not plr then return end
 local s=state(plr); local ch,h,r=root(plr)
	 s.pending=t
 if not h or not r or h.Health<=0 or ch:GetAttribute("CC_HomeVisit") or os.clock()<(s.grace or 0) then return end
	 if workspace:GetServerTimeNow()<(plr:GetAttribute("CC_MovementInvalidUntil") or 0) then return end
	 if not validObservedMove(plr) then return end
 local name=t:GetAttribute("Checkpoint"); local route=t:GetAttribute("Route")
 if type(name)~="string" then return end
 local idx=tonumber(string.match(name,"^Camp(%d)$"))
 if not Rules.checkpointAllowed(ch:GetAttribute("CC_TraversalState"),h.FloorMaterial~=Enum.Material.Air,route,idx,s.highest or 0) then return end
 local localPos=t.CFrame:PointToObjectSpace(r.Position); local half=t.Size/2+Vector3.new(4,4,4)
 if math.abs(localPos.X)>half.X or math.abs(localPos.Y)>half.Y or math.abs(localPos.Z)>half.Z then s.pending=nil; return end
 if s.name==name then s.pending=nil; return end
 s.name,s.pos,s.order=name,t.Position-Vector3.yAxis*(t.Size.Y/2-1),t:GetAttribute("Order")
 if route~="*" then s.route=route end
 plr:SetAttribute("CC_Checkpoint",name); plr:SetAttribute("CC_Route",s.route or "")
 cpEv:FireClient(plr,t:GetAttribute("Label") or name)
 checkpointBE:Fire(plr,name,route)
 if t:GetAttribute("Camp") then
  s.highest=math.max(s.highest or 0,idx or 0)
  campBE:Fire(plr,name,s.order)
 end
	 s.pending=nil
end
task.spawn(function()
 local f=workspace:WaitForChild("World"):WaitForChild("Checkpoints")
 local function hook(t) if t:IsA("BasePart") then t.Touched:Connect(function(hit) onTouched(t,hit) end) end end
 for _,t in ipairs(f:GetChildren()) do hook(t) end
 f.ChildAdded:Connect(hook)
end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt; if elapsed<0.15 then return end; elapsed=0
 for plr,s in pairs(states) do
  local ch,h,r=root(plr)
  if h and r and h.Health>0 then
   local now=os.clock(); local pos=r.Position
   local mode=ch:GetAttribute('CC_TraversalState')
   local distance=s.prev and (pos-s.prev).Magnitude or 0
   local continuity=not s.prev or Rules.movementAllowed(((pos-s.prev)*Vector3.new(1,0,1)).Magnitude,pos.Y-s.prev.Y,now-(s.prevAt or now))
   observedBE:Fire(plr,pos,continuity and workspace:GetServerTimeNow()>=(plr:GetAttribute('CC_MovementInvalidUntil') or 0),not ch:GetAttribute('CC_HomeVisit') and (mode==nil or mode=='ground' or mode=='climb' or mode=='rope') and (h.FloorMaterial~=Enum.Material.Air or mode=='climb' or mode=='rope'),distance)
   if ch:GetAttribute("CC_HomeVisit") or safeMode(ch) then
    s.groundY=pos.Y; s.airY=nil; s.prev=pos; s.prevAt=now
   else
    local grounded=h.FloorMaterial~=Enum.Material.Air
    -- Reject implausible horizontal moves; large legitimate vertical falls remain real falls.
    if s.prev and s.prevAt and now>=(s.grace or 0) then
     if not validObservedMove(plr) then continue end
    end
    if grounded then
     local baseline=s.airY or s.groundY
     if baseline and baseline-pos.Y>FALL_DROP then acceptFall(plr,baseline-pos.Y)
     else s.groundY=pos.Y; s.airY=nil end
    else
     s.airY=math.max(s.airY or s.groundY or pos.Y,pos.Y)
     -- A bottomless walkoff still gets its ordinary fall outcome.
     if pos.Y<-100 then acceptFall(plr,math.max(FALL_DROP,s.airY-pos.Y)) end
    end
    s.prev,s.prevAt=r.Position,now
	    if s.pending and s.pending.Parent then onTouched(s.pending,r) end
   end
  end
 end
end)
local Physics=game:GetService("PhysicsService")
pcall(function() Physics:RegisterCollisionGroup("CC_Players") end)
Physics:CollisionGroupSetCollidable("CC_Players","CC_Players",false)
local function character(plr,ch)
 resetBaseline(plr,nil)
 local function assign(p) if p:IsA("BasePart") then p.CollisionGroup="CC_Players" end end
 for _,p in ipairs(ch:GetDescendants()) do assign(p) end; ch.DescendantAdded:Connect(assign)
 task.defer(function()
  ch:WaitForChild("HumanoidRootPart",10)
  local s=state(plr); if s.pos and plr.Character==ch then spawnAt(plr,s.pos+Vector3.yAxis*4) end
 end)
end
local function player(plr)
 state(plr); plr.CharacterAdded:Connect(function(ch) character(plr,ch) end)
 if plr.Character then character(plr,plr.Character) end
end
Players.PlayerAdded:Connect(player)
Players.PlayerRemoving:Connect(function(plr) states[plr]=nil end)
for _,plr in ipairs(Players:GetPlayers()) do player(plr) end
