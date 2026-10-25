-- Cosmetic samples, never the authoritative egg inventory. One bounded local pool.
local Players=game:GetService('Players')
local Tags=game:GetService('CollectionService')
local Run=game:GetService('RunService')
local UIS=game:GetService('UserInputService')
local player=Players.LocalPlayer
local folder=Instance.new('Folder');folder.Name='LocalProductionEggs';folder.Parent=workspace
local pool={};local belts={};local elapsed=0
local max=if UIS.TouchEnabled then 12 else 24
for i=1,max do
 local egg=Instance.new('Part');egg.Name='VisualProductionEgg';egg.Shape=Enum.PartType.Ball;egg.Size=Vector3.new(1.1,1.5,1.1)
 egg.Anchored=true;egg.CanCollide=false;egg.CanTouch=false;egg.CanQuery=false;egg.CastShadow=false;egg.Material=Enum.Material.SmoothPlastic;egg.Transparency=1;egg.Parent=folder;pool[i]=egg
end
for _,belt in ipairs(Tags:GetTagged('TycoonConveyor')) do belts[belt]=true end
local added=Tags:GetInstanceAddedSignal('TycoonConveyor'):Connect(function(v) belts[v]=true end)
local removed=Tags:GetInstanceRemovedSignal('TycoonConveyor'):Connect(function(v) belts[v]=nil end)
local connection=Run.RenderStepped:Connect(function(dt)
 elapsed+=dt;if elapsed<1/30 then return end;elapsed=0
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart');local camera=workspace.CurrentCamera;local candidates={}
 if root and camera then for belt in pairs(belts) do
  if belt.Parent and (belt:GetAttribute('ActiveHabitats') or 0)>0 and (belt.Position-root.Position).Magnitude<220 then
   local _,visible=camera:WorldToViewportPoint(belt.Position);if visible then table.insert(candidates,belt) end
  end
 end end
 table.sort(candidates,function(a,b) return (a.Position-root.Position).Magnitude<(b.Position-root.Position).Magnitude end)
 local used=0;local reduced=player:GetAttribute('MountainReducedMotion');local simple=player:GetAttribute('MountainSimplifiedVFX')
 for _,belt in ipairs(candidates) do
  local count=if simple or reduced then 2 else 6
  for i=1,count do
   if used>=max then break end;used+=1;local egg=pool[used]
   local phase=if reduced or (belt:GetAttribute('Automation') or 0)<1 then i/count else (workspace:GetServerTimeNow()*.08+i/count)%1
   egg.CFrame=belt.CFrame*CFrame.new(if i%2==0 then 1.5 else -1.5,1.4,-46+phase*92)
   egg.Color=if (belt:GetAttribute('Automation') or 0)>=2 then Color3.fromRGB(246,211,137) else Color3.fromRGB(205,238,214)
   egg.Transparency=0
  end
 end
 for i=used+1,max do pool[i].Transparency=1 end
end)
script.Destroying:Connect(function() connection:Disconnect();added:Disconnect();removed:Disconnect();folder:Destroy() end)
