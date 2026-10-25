-- Baked visual guidance for the existing 58-stud combat participation radius.
-- Deliberately adds no obstacles or changes to combat rules.
local A=require(script.Parent.Art)
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local B={}
function B.apply(world)
 assert(not game:GetService('RunService'):IsRunning() and game.PlaceId==0,'Local Edit only')
 assert(not world:FindFirstChild('ArenaBoundary'),'Already built')
 local root=Instance.new('Folder');root.Name='ArenaBoundary';root.Parent=world
 for ki,k in ipairs(C.kingdoms) do
  local center=world[k.name].ArenaFloor.Position+Vector3.new(0,2.5,0)
  local q=C.route(ki,.875);local frame=CFrame.lookAt(center,center-Vector3.new(math.cos(q.angle),0,math.sin(q.angle)))
  local group=Instance.new('Folder');group.Name=k.id;group.Parent=root
  -- Follow every walkable part of the circle, including diagonal side exits.
  local rays=RaycastParams.new();rays.FilterType=Enum.RaycastFilterType.Include
  rays.FilterDescendantsInstances={world.EnvironmentFinish};rays.RespectCanCollide=true
  for j=-62,62 do
   local a=j*.05;local pos=Vector3.new(math.sin(a)*53,-.35,math.cos(a)*53)
   local hit=workspace:Raycast(frame:PointToWorldSpace(pos+Vector3.new(0,5,0)),Vector3.new(0,-10,0),rays)
   if hit and hit.Instance:GetAttribute('MountainArtSupport') then
    A.part(group,'ArenaThresholdInlay',Vector3.new(2.4,.15,.55),frame*CFrame.new(pos)*CFrame.Angles(0,a,0),Color3.fromRGB(211,198,160),Enum.Material.Metal)
   end
  end
  for _,side in ipairs({-1,1}) do
   local marker=A.part(group,'ArenaExitMarker',Vector3.new(1.4,3.6,1.4),frame*CFrame.new(side*15,1.3,51),Color3.fromRGB(153,155,143),Enum.Material.Limestone)
   if side==1 then
    local board=A.part(group,'ArenaExitPlaque',Vector3.new(12,4,.5),frame*CFrame.new(15,4.8,51),Color3.fromRGB(72,83,78),Enum.Material.Slate)
    local gui=Instance.new('SurfaceGui');gui.Name='ExitGuidance';gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(480,160);gui.Parent=board
    local text=Instance.new('TextLabel');text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=1
    text.Text='LEAVING THE ARENA\nEnds the fight';text.TextColor3=Color3.fromRGB(241,231,206);text.Font=Enum.Font.GothamMedium;text.TextSize=35;text.Parent=gui
   end
  end
  task.wait()
 end
 root:SetAttribute('Revision',2)
end
return B
