-- Idempotent additions to the isolated baked world. Never touches Phase 1 or Terrain.
local A=require(script.Parent.Art)
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local T={}
function T.apply(world)
 assert(world.Name=='ImpossibleMountain' and not workspace:FindFirstChild('MountainEmpire_Phase1'),'Wrong world')
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
    A.label(ladder,'Rope ascent • move toward rope',half+2)
   end
  end
 end
 local sand=world:FindFirstChild('Sunstone Desert'):FindFirstChild('ChallengeAccess')
 assert(sand and sand:IsA('BasePart'),'Missing sand challenge approach')
 sand.Name='ShiftingSand';sand.Material=Enum.Material.Sand;sand.Color=Color3.fromRGB(225,184,111)
 sand:SetAttribute('Kind','ShiftingSand');sand:SetAttribute('Kingdom',3);sand.Parent=world.Dynamics
 A.label(sand,'Shifting sand • walk against the flow',5)
 local lift=world.Dynamics:FindFirstChild('KingdomLift_6')
 assert(lift,'Missing Astral platform')
 lift:SetAttribute('GravityField',true)
 A.label(lift,'Gravity platform • jump lightly',5)
 for i=1,12 do
  local angle=i*math.pi/6
  A.part(lift,'GravityInlay',Vector3.new(.25,.12,1.5),lift.CFrame*CFrame.new(math.cos(angle)*4.8,.57,math.sin(angle)*4.8)*CFrame.Angles(0,-angle,0),Color3.fromRGB(147,196,233),Enum.Material.Metal)
 end
 world:SetAttribute('TraversalRevision',1)
end
return T
