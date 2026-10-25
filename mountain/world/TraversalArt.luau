-- Idempotent additions to the isolated baked world. Never touches Phase 1 or Terrain.
local A=require(script.Parent.Art)
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local T={}
function T.repairBranches(world)
 T.repairLabels(world)
 if world:GetAttribute('BranchAccessRevision')==1 then return end
 for k,kingdom in ipairs(C.kingdoms) do
  local q=C.route(k,.29);local outward=Vector3.new(math.cos(q.angle),0,math.sin(q.angle))
  local center=Vector3.new(q.x,q.y,q.z)+outward*48
  local frame=CFrame.lookAt(center,center-outward)
  local walls={}
  for _,part in ipairs(world[kingdom.name]:GetChildren()) do
   if part.Name=='CaveWall' and (part.Position-center).Magnitude<30 then table.insert(walls,part)
   elseif part.Name=='CaveVault' and (part.Position-center).Magnitude<30 then part.CFrame=frame*CFrame.new(0,14,5) end
  end
  table.sort(walls,function(a,b)return a.Position.X<b.Position.X end)
  for i,part in ipairs(walls) do part.CFrame=frame*CFrame.new(if i==1 then -14 else 14,7,5) end
 end
 world:SetAttribute('BranchAccessRevision',1)
end
function T.repairLabels(world)
 -- Earlier baked checkpoints contain repeatedly mis-decoded UTF-8 separators.
 -- Rebuild known display labels from catalog data; leave prompt contracts intact.
 local count=0
 for _,model in ipairs(world.Encounters:GetChildren()) do
  local species=C.byId[string.lower(model.Name)]
  if species and model.PrimaryPart then
   local gui=model.PrimaryPart:FindFirstChild('Label')
   local label=gui and gui:FindFirstChildOfClass('TextLabel')
   if label then label.Text=species.name..' / '..species.rarity;count+=1 end
  end
 end
 for _,v in ipairs(world:GetDescendants()) do
  if v:IsA('TextLabel') and v.Parent.Name=='Label' then
   local part=v.Parent.Parent
   if part.Name=='ClimbLadder' and part:GetAttribute('RopeLadder') then v.Text='Rope ascent / move toward rope';count+=1
   elseif part.Name=='ShiftingSand' then v.Text='Shifting sand / walk against the flow';count+=1
   elseif part.Name=='KingdomLift_6' then v.Text='Gravity platform / jump lightly';count+=1 end
  end
 end
 return count
end
function T.apply(world)
 assert(world.Name=='ImpossibleMountain' and not workspace:FindFirstChild('MountainEmpire_Phase1'),'Wrong world')
 T.repairBranches(world)
 T.repairLabels(world)
 if world:GetAttribute('TraversalRevision')==1 then return end
 local azure=world:FindFirstChild('Azure Falls')
 local index=0
 for _,ladder in ipairs(azure:GetChildren()) do
  if ladder:IsA('TrussPart') then
   index+=1
   if index%2==0 then
    ladder.Transparency=1;ladder:SetAttribute('RopeLadder',true)
    local f=Instance.new('Folder');f.Name='FunctionalRopeLadder';f.Parent=azure
    local half=ladder.Size.Y/2
    for _,side in ipairs({-1,1}) do
     A.link(f,'LoadBearingRope',ladder.Position+Vector3.new(side*1.2,-half,0),ladder.Position+Vector3.new(side*1.2,half,0),.3,Color3.fromRGB(186,156,102),Enum.Material.Fabric)
    end
    for y=-half,half,1.5 do
     A.part(f,'RopeRung',Vector3.new(2.7,.3,.4),CFrame.new(ladder.Position+Vector3.new(0,y,0)),Color3.fromRGB(142,107,67),Enum.Material.Wood)
    end
    A.label(ladder,'Rope ascent / move toward rope',half+2)
   end
  end
 end
 local sand=world:FindFirstChild('Sunstone Desert'):FindFirstChild('ChallengeAccess')
 assert(sand and sand:IsA('BasePart'),'Missing sand challenge approach')
 sand.Name='ShiftingSand';sand.Material=Enum.Material.Sand;sand.Color=Color3.fromRGB(225,184,111)
 sand:SetAttribute('Kind','ShiftingSand');sand:SetAttribute('Kingdom',3);sand.Parent=world.Dynamics
 A.label(sand,'Shifting sand / walk against the flow',5)
 local lift=world.Dynamics:FindFirstChild('KingdomLift_6')
 assert(lift,'Missing Astral platform')
 lift:SetAttribute('GravityField',true)
 A.label(lift,'Gravity platform / jump lightly',5)
 for i=1,12 do
  local angle=i*math.pi/6
  A.part(lift,'GravityInlay',Vector3.new(.25,.12,1.5),lift.CFrame*CFrame.new(math.cos(angle)*4.8,.57,math.sin(angle)*4.8)*CFrame.Angles(0,-angle,0),Color3.fromRGB(147,196,233),Enum.Material.Metal)
 end
 world:SetAttribute('TraversalRevision',1)
end
return T
