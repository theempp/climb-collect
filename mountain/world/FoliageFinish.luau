-- Break the old smooth pancake canopy into irregular lobes inside its old bounds.
local A=require(script.Parent.Art)
local F={}
function F.apply(world)
 assert(not game:GetService('RunService'):IsRunning() and game.PlaceId==0,'Local Edit only')
 assert(not world:GetAttribute('FoliageFinishRevision'),'Already applied')
 local archive=Instance.new('Folder');archive.Name='FoliageFinishPrior';archive.Parent=game.ServerStorage
 local count=0
 for _,tree in ipairs(world:GetDescendants()) do
  if tree:IsA('Model') and (tree.Name=='Grown_blossom' or tree.Name=='Grown_azure') then
   for _,old in ipairs(tree:GetChildren()) do
    if old:IsA('BasePart') and old.Name=='Canopy' then
     local size=old.Size;local cf=old.CFrame;local color=old.Color
     for j=0,4 do
      local a=j*math.pi/2+.35
      local offset=if j==0 then Vector3.zero else Vector3.new(math.cos(a)*size.X*.23,math.sin(j*2)*size.Y*.07,math.sin(a)*size.Z*.23)
      A.part(tree,'LeafCrown',Vector3.new(size.X*.48,size.Y*.82,size.Z*.48),cf*CFrame.new(offset),color:Lerp(Color3.fromRGB(227,218,207),(j%3)*.065),Enum.Material.Grass,Enum.PartType.Ball)
     end
     old:SetAttribute('OriginalParent',tree:GetFullName());old.Parent=archive;count+=1
    end
   end
  end
 end
 world:SetAttribute('FoliageFinishRevision',1)
 return count
end
return F
