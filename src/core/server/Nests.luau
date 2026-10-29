-- Solo, per-player environmental guardian puzzles. One chime interaction; no combat or countdown.
local Players=game:GetService("Players")
local HS=game:GetService("HttpService")
local Nests={}
local ctx,Prompts,Visuals,folder
local nests,guards={},{}
local function surface(pos,height)
 local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={workspace.Terrain}
 local h=workspace:Raycast(pos+Vector3.new(0,35,0),Vector3.new(0,-70,0),rp)
 return h and Vector3.new(pos.X,h.Position.Y+height,pos.Z) or pos
end
local function session(plr) return ctx.sessions[plr] end
local function readyAt(plr,kind,id) local s=session(plr) return s and s.data.timers[kind..":"..id] or 0 end
local function ready(plr,kind,id) return ctx.Clock.now()>=readyAt(plr,kind,id) end
local function puzzled(plr,id) local s=session(plr) return s and s.data.expedition.puzzles and s.data.expedition.puzzles[id]==true end
local function near(plr,pos,range)
 local ch=plr.Character local p=ch and ch:FindFirstChild("HumanoidRootPart") local h=ch and ch:FindFirstChildOfClass("Humanoid")
 return p and h and h.Health>0 and (p.Position-pos).Magnitude<=range and (not ch:GetAttribute("CC_TraversalState") or ch:GetAttribute("CC_TraversalState")=="ground")
end
local function updateGuard(plr,n)
 local key=plr.UserId.."|"..n.id local g=guards[key]
 if g then
  local state=puzzled(plr,n.id) and "Distracted" or "Watching"
  g.state=state g.model:SetAttribute("State",state)
  local tell=g.model:FindFirstChild("Tell") if tell then tell.Enabled=false end
  local toward=(state=="Distracted" and n.chime.Position or n.hsPos)-g.pos
  if toward.Magnitude>0.01 then g.model:PivotTo(CFrame.lookAt(g.pos,g.pos+toward*Vector3.new(1,0,1))) end
 end
end
local function spawnGuard(plr,n)
 local key=plr.UserId.."|"..n.id
 if guards[key] then return guards[key] end
 local pos=surface(n.center+Vector3.new(8,3,7),3)
 local m=Visuals.guardian(n.guardian,pos,n.scale)
 m.Name="Guardian_"..n.id m:SetAttribute("OwnerId",plr.UserId) m:SetAttribute("NestId",n.id) m.Parent=folder
 local g={key=key,plr=plr,nest=n,model=m,pos=pos,state="Watching"}
 guards[key]=g updateGuard(plr,n) return g
end
function Nests.watch(plr,id) local n=nests[id] return n and spawnGuard(plr,n) end
function Nests.alert(plr,id) local n=nests[id] if n then updateGuard(plr,n) end end
local function distract(plr,n,prompt)
 if not Prompts.validate(prompt,plr) or not session(plr) then return end
 if puzzled(plr,n.id) then ctx.toast(plr,"The guardian is already watching the chimes. Approach the pup or Heartstone.","info") return end
 ctx.transaction(plr,"puzzle:"..HS:GenerateGUID(false),function(d)
  d.expedition.puzzles=d.expedition.puzzles or {} d.expedition.puzzles[n.id]=true return {ok=true}
 end,function()
  updateGuard(plr,n)
  ctx.toast(plr,"The chimes caught its attention. You can safely net the pup and take the Heartstone.","good")
  ctx.fx(plr,{kind="guardian",state="Distracted",nest=n.id}) ctx.push(plr)
 end)
end
local function claim(plr,n,prompt,kind)
 if not Prompts.validate(prompt,plr) or not session(plr) or not ready(plr,kind,n.id) then return end
 if not puzzled(plr,n.id) then ctx.toast(plr,"Ring the nearby wind chimes to distract the guardian.","info") return end
 local stone=kind=="nest"
 local species=stone and ctx.Bank.rollHatch(n.tier,n.region) or n.pup
 local item=ctx.Inv.newItem(stone and "heartstone" or "creature",{species=species,tier=stone and n.tier or nil,rarity=not stone and ctx.Species.rarity(species) or nil,region=n.region,mutation=plr:GetAttribute("CC_Mutation") or "",source=stone and n.id or "pup:"..n.id,acquiredAt=ctx.Clock.now()})
 item.discovery=item.discovery or {id=item.uid,at=item.acquiredAt}
 item.discovery.place=n.label item.discovery.method=stone and "guardian distraction" or "net capture"
 local pos=stone and n.hsPos or n.pupPos
 ctx.Cargo.acquire(plr,item,{
  pos=pos,label=n.label,
  valid=function() return near(plr,pos,stone and 13 or 22) and ready(plr,kind,n.id) and puzzled(plr,n.id) end,
  write=function(d)
   if ctx.Clock.now()<(d.timers[kind..":"..n.id] or 0) or not d.expedition.puzzles or not d.expedition.puzzles[n.id] then return false,"unavailable" end
   d.timers[kind..":"..n.id]=ctx.Clock.now()+(stone and ctx.C.NEST_RESPAWN or ctx.C.PUP_COOLDOWN)
   local other=stone and "pup" or "nest"
   if (d.timers[other..":"..n.id] or 0)>ctx.Clock.now() then d.expedition.puzzles[n.id]=false end
   return true
  end,
  commit=function(saved)
   updateGuard(plr,n)
   ctx.toast(plr,stone and ("Found a "..n.tier.." Heartstone. Bank it, then place it in a home nest.") or ("Netted "..(ctx.Species.get(species).name)..". Safe in your backpack."),"good")
   ctx.fx(plr,{kind=stone and "heartstone" or "net",tier=n.tier,from=pos+Vector3.new(0,1,0),to=pos,pos=pos})
   ctx.emit(stone and "heartstone" or "net",plr,n.id,saved)
  end,
 })
end
function Nests.init(c)
 ctx=c Prompts=require(script.Parent.Prompts) Visuals=require(script.Parent.Visuals)
 local core=workspace.World.Core
 folder=Instance.new("Folder") folder.Name="Guardians" folder.Parent=core
 local live=Instance.new("Folder") live.Name="NestFinds" live.Parent=core
 for _,m in ipairs(core.Nests:GetChildren()) do
  local id=m:GetAttribute("NestId")
  if id then
   local region=m:GetAttribute("Region") or 1 local species=ctx.Species.query({region=region,kind="guardian"})[1]
   local n={id=id,model=m,region=region,center=m:GetAttribute("Center"),hsPos=m:GetAttribute("HeartstonePos"),pupPos=m:GetAttribute("PupPos"),tier=m:GetAttribute("Tier") or "Common",label=m:GetAttribute("Label") or id,guardian=species and species.id or "stub_guardian_1",pup=species and species.pup or "stub_epic_1",scale=m:GetAttribute("GuardianScale") or 1}
   n.pupPos=surface(n.pupPos,1.8) n.hsPos=surface(n.hsPos,1.7)
   nests[id]=n
   local chime=Instance.new("Part") chime.Name="WindChimes_"..id chime.Size=Vector3.new(1,2.5,1) chime.Anchored=true chime.CanCollide=false chime.Material=Enum.Material.Metal chime.Color=Color3.fromRGB(213,177,115)
   local at=n.pupPos+Vector3.new(3,4,0)
   local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={workspace.Terrain}
   local hit=workspace:Raycast(at,Vector3.new(0,-30,0),rp)
   chime.Position=hit and hit.Position+Vector3.new(0,1.5,0) or n.pupPos+Vector3.new(3,1.5,0)
   chime.Parent=live n.chime=chime
   local cp=Prompts.make(chime,{Name="DistractPrompt",ActionText="Ring wind chimes",ObjectText="Distract guardian",HoldDuration=0.5,MaxActivationDistance=12})
   cp.Triggered:Connect(function(plr) distract(plr,n,cp) end)
   local hs=Visuals.heartstone(n.hsPos,n.tier) hs.Name="Heartstone_"..id hs:SetAttribute("NestId",id) hs.Parent=live
   local hp=Prompts.make(hs.PrimaryPart,{Name="HeartstonePrompt",ActionText="Take Heartstone",ObjectText=n.label,HoldDuration=ctx.C.HEARTSTONE_HOLD[n.tier] or 3,MaxActivationDistance=9})
   hp.Triggered:Connect(function(plr) claim(plr,n,hp,"nest") end)
   local pup=Visuals.creature(n.pup,n.pupPos) pup.Name="Pup_"..id pup:SetAttribute("NestId",id) pup:SetAttribute("Pup",true) pup.Parent=live
   local np=Prompts.make(pup.PrimaryPart,{Name="NetPrompt",ActionText="Throw net",ObjectText=ctx.Species.get(n.pup).name,HoldDuration=ctx.C.NET_TIERS.cloth.hold,MaxActivationDistance=ctx.C.NET_TIERS.cloth.range})
   np.Triggered:Connect(function(plr) claim(plr,n,np,"pup") end)
  end
 end
 task.spawn(function()
  while true do task.wait(0.5)
   for _,plr in ipairs(Players:GetPlayers()) do
    local root=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    for _,n in pairs(nests) do
     local key=plr.UserId.."|"..n.id local g=guards[key]
     if root and (root.Position-n.center).Magnitude<130 then spawnGuard(plr,n)
     elseif g then g.model:Destroy() guards[key]=nil end
    end
   end
  end
 end)
end
function Nests.onLeave(plr)
 for key,g in pairs(guards) do if g.plr==plr then g.model:Destroy() guards[key]=nil end end
end
function Nests.state(plr,st)
 st.nests={} st.guardians={}
 for id in pairs(nests) do st.nests[id]={heartstoneAt=readyAt(plr,"nest",id),pupAt=readyAt(plr,"pup",id),distracted=puzzled(plr,id)} end
 for _,g in pairs(guards) do if g.plr==plr then table.insert(st.guardians,{nest=g.nest.id,state=g.state}) end end
end
function Nests.nestPos(id) return nests[id] and nests[id].center end
function Nests.pupPos(id) return nests[id] and nests[id].pupPos end
function Nests.hsPos(id) return nests[id] and nests[id].hsPos end
function Nests.distractionPos(id) return nests[id] and nests[id].chime.Position end
Nests._guards=guards Nests._nests=nests
return Nests
