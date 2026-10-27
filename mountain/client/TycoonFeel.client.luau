-- Visual-only production feel: creature idle motion, machine wheels, full-store beacons, collect and bank moments.
-- Everything is client-local, distance culled and bounded. Reduced motion or simplified VFX leave a static, readable state.
local Players=game:GetService('Players')
local Tags=game:GetService('CollectionService')
local Run=game:GetService('RunService')
local Tween=game:GetService('TweenService')
local player=Players.LocalPlayer
local RANGE=110
local creatures,gears,beacons,banks,spines={},{},{},{},{}
local folder=Instance.new('Folder');folder.Name='LocalProductionFeel';folder.Parent=workspace
local function track(tag,set,onAdd)
 for _,v in ipairs(Tags:GetTagged(tag)) do set[v]=true;if onAdd then onAdd(v) end end
 local a=Tags:GetInstanceAddedSignal(tag):Connect(function(v) set[v]=true;if onAdd then onAdd(v) end end)
 local r=Tags:GetInstanceRemovedSignal(tag):Connect(function(v) set[v]=nil end)
 return a,r
end
local base={}
local conns={}
local function keep(a,r) table.insert(conns,a);table.insert(conns,r) end
keep(track('HabitatCreature',creatures,function(m) task.defer(function() if m.Parent then base[m]=m:GetPivot() end end) end))
keep(track('MachineGear',gears))
keep(track('HabitatBeacon',beacons))
keep(track('ProductionBank',banks))
keep(track('TycoonConveyor',spines))
local function ring(cf,color)
 local p=Instance.new('Part');p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Shape=Enum.PartType.Cylinder
 p.Material=Enum.Material.Neon;p.Color=color;p.Size=Vector3.new(.2,2,2);p.CFrame=cf*CFrame.Angles(0,0,math.pi/2);p.Parent=folder
 local t=Tween:Create(p,TweenInfo.new(.6,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(.2,14,14),Transparency=1})
 t.Completed:Connect(function() p:Destroy() end);t:Play()
end
local function burst(cf,color,count)
 for i=1,count do
  local p=Instance.new('Part');p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Shape=Enum.PartType.Ball
  p.Material=Enum.Material.Neon;p.Color=color;p.Size=Vector3.new(.9,.9,.9);p.CFrame=cf*CFrame.new((i-count/2)*.9,2,0);p.Parent=folder
  local t=Tween:Create(p,TweenInfo.new(.7+i*.05,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=p.Position+Vector3.new(0,7+i,0),Transparency=1})
  t.Completed:Connect(function() p:Destroy() end);t:Play()
 end
end
local function quiet() return player:GetAttribute('MountainReducedMotion') or player:GetAttribute('MountainSimplifiedVFX') end
local last={}
local function pulses(part,attr,fn)
 local v=part:GetAttribute(attr)
 if v==nil then return end
 if last[part]==nil then last[part]=v;return end
 if v~=last[part] then last[part]=v;fn() end
end
local elapsed=0
local connection=Run.RenderStepped:Connect(function(dt)
 elapsed+=dt;if elapsed<1/30 then return end
 local step=elapsed;elapsed=0
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart');if not root then return end
 local pos=root.Position;local t=workspace:GetServerTimeNow();local reduced=quiet()
 for model in pairs(creatures) do
  local b=base[model]
  if b and model.Parent then
   if (b.Position-pos).Magnitude<RANGE and not reduced then
    local seed=model:GetAttribute('IdleSeed') or 0
    model:PivotTo(b*CFrame.new(0,math.sin(t*1.6+seed)*.18,0)*CFrame.Angles(0,math.sin(t*.5+seed)*.12,0))
   else model:PivotTo(b) end
  end
 end
 for gear in pairs(gears) do
  local spin=gear:GetAttribute('Spin') or 0
  if spin>0 and not reduced and (gear.Position-pos).Magnitude<RANGE then gear.CFrame*=CFrame.Angles(spin*step,0,0) end
 end
 for beacon in pairs(beacons) do
  if beacon.Transparency<1 and not reduced and (beacon.Position-pos).Magnitude<RANGE then beacon.Size=Vector3.one*(1.4+math.sin(t*5)*.3) end
 end
 for bank in pairs(banks) do pulses(bank,'BankSeq',function()
  if (bank.Position-pos).Magnitude<RANGE and not reduced then ring(bank.CFrame,Color3.fromRGB(246,211,137));burst(bank.CFrame,Color3.fromRGB(246,211,137),6) end
 end) end
 for spine in pairs(spines) do pulses(spine,'CollectSeq',function()
  if (spine.Position-pos).Magnitude<RANGE and not reduced then ring(spine.CFrame,Color3.fromRGB(205,238,214)) end
 end) end
end)
script.Destroying:Connect(function() connection:Disconnect();for _,c in ipairs(conns) do c:Disconnect() end;folder:Destroy() end)
